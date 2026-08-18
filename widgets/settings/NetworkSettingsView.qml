import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../components"

Item {
    id: root

    property int focusIndex: -1
    property int actionIndex: 0

    property var wifiData: null
    property var activeNet: null
    property var savedNetworks: []
    property var availableNetworks: []
    property bool isScanning: false

    function refreshWifi() {
        ConfigService.fetchWifiStatus(function(data) {
            if (!data) return;
            root.wifiData = data;
            root.activeNet = data.connected_network || null;
            root.isScanning = !!data.scanning;

            var saved = [];
            var avail = [];
            if (data.networks) {
                for (var i = 0; i < data.networks.length; i++) {
                    var net = data.networks[i];
                    if (net.saved && !net.connected) {
                        saved.push(net);
                    } else if (!net.connected) {
                        avail.push(net);
                    }
                }
            }
            root.savedNetworks = saved;
            root.availableNetworks = avail;
        });
    }

    Component.onCompleted: refreshWifi()

    // Navigation item count calculation
    function getItemCount() {
        if (passDialog.visible) return 3; // password input, show pass, connect/cancel
        var count = 2; // Wi-Fi Power, Scan
        if (activeNet) count += 1; // Disconnect
        count += root.savedNetworks.length;
        count += root.availableNetworks.length;
        return count;
    }

    function handleHorizontal(delta) {
        if (passDialog.visible) {
            passDialog.actionIndex = Math.max(0, Math.min(1, passDialog.actionIndex + delta));
            return;
        }
        actionIndex = Math.max(0, Math.min(1, actionIndex + delta));
    }

    function triggerItem() {
        if (passDialog.visible) {
            passDialog.submitPassword();
            return;
        }

        if (focusIndex === 0) {
            ConfigService.toggleWifi(!ConfigService.wifiEnabled, function() { root.refreshWifi(); });
        } else if (focusIndex === 1) {
            ConfigService.startWifiScan(function() { root.refreshWifi(); });
        } else if (activeNet && focusIndex === 2) {
            ConfigService.disconnectWifiNetwork(function() { root.refreshWifi(); });
        } else {
            var offset = activeNet ? 3 : 2;
            var idx = focusIndex - offset;
            if (idx >= 0 && idx < root.savedNetworks.length) {
                var sNet = root.savedNetworks[idx];
                if (actionIndex === 1) {
                    ConfigService.forgetWifiNetwork(sNet.ssid, function() { root.refreshWifi(); });
                } else {
                    ConfigService.connectWifiNetwork(sNet.ssid, "", "", function() { root.refreshWifi(); });
                }
            } else {
                var aIdx = idx - root.savedNetworks.length;
                if (aIdx >= 0 && aIdx < root.availableNetworks.length) {
                    var aNet = root.availableNetworks[aIdx];
                    if (aNet.security && aNet.security !== "Open" && aNet.security !== "--") {
                        passDialog.targetSsid = aNet.ssid;
                        passDialog.visible = true;
                        passInput.forceActiveFocus();
                    } else {
                        ConfigService.connectWifiNetwork(aNet.ssid, "", "", function() { root.refreshWifi(); });
                    }
                }
            }
        }
    }

    implicitHeight: mainLayout.implicitHeight
    Layout.fillWidth: true

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 12

        // ==========================================
        // 1. WI-FI ACTIVE STATUS HERO CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 90
            radius: 14
            color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.55)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                Rectangle {
                    width: 48
                    height: 48
                    radius: 12
                    color: ConfigService.wifiEnabled 
                        ? (ConfigService.wifiConnected ? Qt.rgba(85/255, 224/255, 128/255, 0.18) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)) 
                        : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.20)
                    Layout.alignment: Qt.AlignVCenter

                    VectorIcon {
                        anchors.centerIn: parent
                        name: ConfigService.wifiEnabled ? (ConfigService.wifiConnected ? "wifi_full" : "wifi_disconnected") : "wifi_off"
                        iconSize: 22
                        color: ConfigService.wifiEnabled ? (ConfigService.wifiConnected ? "#55E080" : Theme.primary) : Theme.on_surface_variant
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true

                        Text {
                            text: ConfigService.wifiConnected ? (ConfigService.wifiSsid || "Connected Network") : (ConfigService.wifiEnabled ? "Wi-Fi Disconnected" : "Wi-Fi Disabled")
                            color: Theme.on_surface
                            font.pixelSize: 16
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                            elide: Text.ElideRight
                        }

                        PillBadge {
                            text: ConfigService.wifiConnected ? "Connected" : (ConfigService.wifiEnabled ? "Enabled" : "Off")
                            isInteractive: false
                            defaultColor: ConfigService.wifiConnected 
                                ? Qt.rgba(85/255, 224/255, 128/255, 0.18) 
                                : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            defaultTextColor: ConfigService.wifiConnected ? "#55E080" : Theme.primary
                        }
                    }

                    Text {
                        text: ConfigService.wifiConnected 
                            ? ("Signal: " + ConfigService.wifiSignal + "%  •  IP: " + (root.wifiData ? (root.wifiData.ip_address || "Assigned") : "Assigned") + "  •  " + (root.activeNet ? (root.activeNet.freq || "2.4 GHz") : "Wi-Fi")) 
                            : (ConfigService.wifiEnabled ? "Scan or select a network below to connect" : "Turn on Wi-Fi adapter to discover networks")
                        color: Theme.on_surface_variant
                        font.pixelSize: 11
                        font.family: Theme.fontFamilyDisplay
                    }
                }

                RowLayout {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter

                    SquareButton {
                        visible: ConfigService.wifiConnected
                        text: "Disconnect"
                        iconName: "network_off"
                        size: 32
                        customRadius: 16
                        isActive: root.focusIndex === 2
                        activeColor: Theme.error
                        onClicked: ConfigService.disconnectWifiNetwork(function() { root.refreshWifi(); })
                    }

                    SquareButton {
                        text: root.isScanning ? "Scanning..." : "Scan"
                        iconName: root.isScanning ? "stop" : "search"
                        size: 32
                        customRadius: 16
                        enabled: ConfigService.wifiEnabled && !root.isScanning
                        isActive: root.focusIndex === 1
                        onClicked: ConfigService.startWifiScan(function() { root.refreshWifi(); })
                    }
                }
            }
        }

        // Captive Portal Prompt Banner
        Rectangle {
            visible: ConfigService.wifiRequiresPortal
            Layout.fillWidth: true
            implicitHeight: 46
            radius: 10
            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            border.color: Theme.primary
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                VectorIcon {
                    name: "browser"
                    iconSize: 16
                    color: Theme.primary
                }

                Text {
                    text: "Captive Portal Login Required"
                    color: Theme.primary
                    font.bold: true
                    font.pixelSize: 12
                    font.family: Theme.fontFamilyDisplay
                    Layout.fillWidth: true
                }

                SquareButton {
                    text: "Open Portal"
                    iconName: "external_link"
                    size: 28
                    customRadius: 14
                    isActive: true
                    onClicked: ConfigService.openCaptivePortal()
                }
            }
        }

        // ==========================================
        // 2. WI-FI HARDWARE POWER
        // ==========================================
        SettingCardGroup {
            titleText: "Wireless Adapter"

            SettingToggleRow {
                id: wifiPowerToggle
                labelText: "Wi-Fi Power"
                descriptionText: "Enable or disable wireless networking radio"
                checked: ConfigService.wifiEnabled
                isFocused: root.focusIndex === 0
                onToggled: newValue => ConfigService.toggleWifi(newValue, function() { root.refreshWifi(); })
            }
        }

        // ==========================================
        // 3. SAVED NETWORKS
        // ==========================================
        SettingCardGroup {
            visible: ConfigService.wifiEnabled && root.savedNetworks.length > 0
            titleText: "Saved Networks (" + root.savedNetworks.length + ")"

            Repeater {
                model: root.savedNetworks
                delegate: Rectangle {
                    id: savedRow
                    required property var modelData
                    required property int index

                    readonly property int itemFocusIndex: (root.activeNet ? 3 : 2) + index
                    readonly property bool isRowFocused: root.focusIndex === itemFocusIndex

                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: 10
                    color: isRowFocused
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        : (savedMouse.containsMouse ? Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.35) : "transparent")

                    border.color: isRowFocused ? Theme.primary : "transparent"
                    border.width: isRowFocused ? 1.5 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        VectorIcon {
                            name: (modelData.signal > 60) ? "wifi_full" : ((modelData.signal > 30) ? "wifi_medium" : "wifi_low")
                            iconSize: 16
                            color: Theme.primary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.ssid || "Saved Network"
                                color: Theme.on_surface
                                font.bold: true
                                font.pixelSize: 12
                                font.family: Theme.fontFamilyDisplay
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "Saved  •  " + (modelData.freq || "2.4GHz") + "  •  " + (modelData.security || "WPA2")
                                color: Theme.on_surface_variant
                                font.pixelSize: 10
                                font.family: Theme.fontFamilyDisplay
                            }
                        }

                        // Forget / Delete Button
                        SquareButton {
                            text: "Forget"
                            iconName: "trash"
                            size: 26
                            customRadius: 13
                            isActive: (isRowFocused && root.actionIndex === 1)
                            activeColor: Theme.error
                            onClicked: ConfigService.forgetWifiNetwork(modelData.ssid, function() { root.refreshWifi(); })
                        }

                        // Connect Button
                        SquareButton {
                            text: "Connect"
                            iconName: "network"
                            size: 26
                            customRadius: 13
                            isActive: (isRowFocused && root.actionIndex === 0)
                            onClicked: ConfigService.connectWifiNetwork(modelData.ssid, "", "", function() { root.refreshWifi(); })
                        }
                    }

                    MouseArea {
                        id: savedMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ConfigService.connectWifiNetwork(modelData.ssid, "", "", function() { root.refreshWifi(); })
                    }
                }
            }
        }

        // ==========================================
        // 4. AVAILABLE DISCOVERED NETWORKS
        // ==========================================
        SettingCardGroup {
            titleText: "Available Networks (" + root.availableNetworks.length + ")"

            EmptyState {
                visible: !ConfigService.wifiEnabled || root.availableNetworks.length === 0
                iconName: "wifi"
                title: ConfigService.wifiEnabled ? "No nearby networks found" : "Wi-Fi is turned off"
                description: ConfigService.wifiEnabled ? "Click Scan to search for Wi-Fi access points." : "Turn on Wi-Fi above to see available networks."
            }

            Repeater {
                model: root.availableNetworks
                delegate: Rectangle {
                    id: availRow
                    required property var modelData
                    required property int index

                    readonly property int itemFocusIndex: (root.activeNet ? 3 : 2) + root.savedNetworks.length + index
                    readonly property bool isRowFocused: root.focusIndex === itemFocusIndex

                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: 10
                    color: isRowFocused
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        : (availMouse.containsMouse ? Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.35) : "transparent")

                    border.color: isRowFocused ? Theme.primary : "transparent"
                    border.width: isRowFocused ? 1.5 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        VectorIcon {
                            name: (modelData.signal > 60) ? "wifi_full" : ((modelData.signal > 30) ? "wifi_medium" : "wifi_low")
                            iconSize: 16
                            color: Theme.on_surface_variant
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                spacing: 6
                                Layout.fillWidth: true

                                Text {
                                    text: modelData.ssid || "Hidden Network"
                                    color: Theme.on_surface
                                    font.bold: true
                                    font.pixelSize: 12
                                    font.family: Theme.fontFamilyDisplay
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                VectorIcon {
                                    visible: modelData.security && modelData.security !== "Open" && modelData.security !== "--"
                                    name: "pin"
                                    iconSize: 11
                                    color: Theme.on_surface_variant
                                }
                            }

                            Text {
                                text: "Signal: " + (modelData.signal || 0) + "%  •  " + (modelData.freq || "2.4GHz") + "  •  " + (modelData.security || "WPA2")
                                color: Theme.on_surface_variant
                                font.pixelSize: 10
                                font.family: Theme.fontFamilyDisplay
                            }
                        }

                        SquareButton {
                            text: "Connect"
                            iconName: "network"
                            size: 26
                            customRadius: 13
                            isActive: isRowFocused
                            onClicked: {
                                if (modelData.security && modelData.security !== "Open" && modelData.security !== "--") {
                                    passDialog.targetSsid = modelData.ssid;
                                    passDialog.visible = true;
                                    passInput.forceActiveFocus();
                                } else {
                                    ConfigService.connectWifiNetwork(modelData.ssid, "", "", function() { root.refreshWifi(); });
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: availMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.security && modelData.security !== "Open" && modelData.security !== "--") {
                                passDialog.targetSsid = modelData.ssid;
                                passDialog.visible = true;
                                passInput.forceActiveFocus();
                            } else {
                                ConfigService.connectWifiNetwork(modelData.ssid, "", "", function() { root.refreshWifi(); });
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // 5. EMBEDDED PASSWORD CONNECT DIALOG OVERLAY
    // ==========================================
    Rectangle {
        id: passDialog
        visible: false
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.75)
        radius: 14
        z: 100

        property string targetSsid: ""
        property int actionIndex: 0 // 0 = Connect, 1 = Cancel

        function submitPassword() {
            if (!targetSsid) return;
            ConfigService.connectWifiNetwork(targetSsid, passInput.text, "", function() {
                passDialog.visible = false;
                passInput.text = "";
                root.refreshWifi();
            });
        }

        Rectangle {
            width: 380
            implicitHeight: 220
            anchors.centerIn: parent
            radius: 16
            color: Theme.surface_container
            border.color: Theme.primary
            border.width: 1.5

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Text {
                    text: "Connect to \"" + passDialog.targetSsid + "\""
                    color: Theme.on_surface
                    font.bold: true
                    font.pixelSize: 15
                    font.family: Theme.fontFamilyDisplay
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: "Enter network security key or WPA passphrase:"
                    color: Theme.on_surface_variant
                    font.pixelSize: 11
                    font.family: Theme.fontFamilyDisplay
                }

                TextField {
                    id: passInput
                    Layout.fillWidth: true
                    implicitHeight: 38
                    placeholderText: "Password..."
                    echoMode: showPassCheck.checked ? TextInput.Normal : TextInput.Password
                    color: Theme.on_surface
                    font.pixelSize: 13
                    font.family: Theme.fontFamilyDisplay
                    background: Rectangle {
                        radius: 8
                        color: Theme.surface_container_highest
                        border.color: passInput.activeFocus ? Theme.primary : Theme.outline_variant
                        border.width: 1.5
                    }
                    onAccepted: passDialog.submitPassword()
                }

                CheckBox {
                    id: showPassCheck
                    text: "Show password"
                    checked: false
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ActionButton {
                        Layout.fillWidth: true
                        text: "Cancel"
                        iconName: "ban"
                        variant: "surface"
                        isFocused: passDialog.actionIndex === 1
                        onClicked: {
                            passDialog.visible = false;
                            passInput.text = "";
                        }
                    }

                    ActionButton {
                        Layout.fillWidth: true
                        text: "Connect"
                        iconName: "network"
                        variant: "primary"
                        isFocused: passDialog.actionIndex === 0
                        onClicked: passDialog.submitPassword()
                    }
                }
            }
        }
    }
}
