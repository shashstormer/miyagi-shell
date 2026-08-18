import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../components"
import "../components/ModelUtils.js" as ModelUtils

Scope {
    id: wifiPanelScope

    property bool isOpen: wifiWindow.isOpen
    property alias openedFrom: wifiWindow.openedFrom

    function toggle() {
        if (wifiWindow.isOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        wifiWindow.open();
        refresh();
        ConfigService.startWifiScan(function() { refresh(); });
    }

    function close() {
        wifiWindow.close();
    }

    function refresh() {
        ConfigService.fetchWifiStatus(function(data) {
            if (!data) return;
            wifiWindow.switchChecked = !!data.enabled;
            wifiWindow.isRefreshing = !!data.scanning;
            
            var saved = [];
            var available = [];
            if (data.networks) {
                for (var i = 0; i < data.networks.length; i++) {
                    var net = data.networks[i];
                    if (net.portal_url === null || net.portal_url === undefined) net.portal_url = "";
                    if (net.saved && !net.connected) {
                        saved.push(net);
                    } else if (!net.connected) {
                        available.push(net);
                    }
                }
            }

            activeNetContainer.activeNet = data.connected_network || null;
            ModelUtils.updateListModel(savedModel, saved, "ssid", ["signal", "security", "connected", "saved", "freq", "requires_portal", "portal_url"]);
            ModelUtils.updateListModel(availableModel, available, "ssid", ["signal", "security", "connected", "saved", "freq", "requires_portal", "portal_url"]);
        });
    }

    property int selectedIndex: 0
    property int savedSubIndex: 0 // 0 = Connect, 1 = Delete/Forget Button
    readonly property int totalItemCount: savedModel.count + availableModel.count

    function navigate(delta) {
        InputService.useKeyboard();
        if (totalItemCount > 0) {
            selectedIndex = Math.max(-1, Math.min(selectedIndex + delta, totalItemCount - 1));
            wifiWindow.isSwitchFocused = (selectedIndex === -1);
            savedSubIndex = 0;
        } else {
            selectedIndex = -1;
            wifiWindow.isSwitchFocused = true;
        }
    }

    function navigateHorizontal(delta) {
        InputService.useKeyboard();
        if (passDialog.visible) {
            if (passDialog.passDialogFocusIndex === 3 && delta < 0) {
                passDialog.passDialogFocusIndex = 2; // Switch to Cancel
            } else if (passDialog.passDialogFocusIndex === 2 && delta > 0) {
                passDialog.passDialogFocusIndex = 3; // Switch to Connect
            }
            return;
        }
        if (selectedIndex >= 0 && selectedIndex < savedModel.count) {
            savedSubIndex = Math.max(0, Math.min(savedSubIndex + delta, 1));
        }
    }

    function activateSelected() {
        if (passDialog.visible) {
            if (passDialog.passDialogFocusIndex === 1) {
                showPassCheck.checked = !showPassCheck.checked;
            } else if (passDialog.passDialogFocusIndex === 2) {
                passDialog.visible = false;
                passInput.text = "";
                passDialog.passDialogFocusIndex = 0;
            } else {
                passDialog.submitPassword();
            }
            return;
        }
        if (selectedIndex === -1) {
            ConfigService.toggleWifi(!wifiWindow.switchChecked, function() { refresh(); });
            return;
        }
        if (selectedIndex >= 0 && selectedIndex < savedModel.count) {
            var item = savedModel.get(selectedIndex);
            if (item) {
                if (savedSubIndex === 1) {
                    ConfigService.forgetWifiNetwork(item.ssid, refresh);
                } else {
                    ConfigService.connectWifiNetwork(item.ssid, "", "", refresh);
                }
            }
        } else if (selectedIndex >= savedModel.count && selectedIndex < totalItemCount) {
            var availItem = availableModel.get(selectedIndex - savedModel.count);
            if (availItem) {
                if (availItem.security && availItem.security !== "" && availItem.security !== "--") {
                    passDialog.targetSsid = availItem.ssid;
                    passDialog.visible = true;
                } else {
                    ConfigService.connectWifiNetwork(availItem.ssid, "", "", refresh);
                }
            }
        }
    }

    Connections {
        target: InputService
        enabled: wifiWindow.isOpen

        function onNavUp() {
            if (passDialog.visible) {
                if (passDialog.passDialogFocusIndex >= 2) {
                    passDialog.passDialogFocusIndex = 1;
                } else if (passDialog.passDialogFocusIndex === 1) {
                    passDialog.passDialogFocusIndex = 0;
                    passInput.forceActiveFocus();
                }
            } else {
                wifiPanelScope.navigate(-1);
            }
        }
        function onNavDown() {
            if (passDialog.visible) {
                if (passDialog.passDialogFocusIndex === 0) {
                    passDialog.passDialogFocusIndex = 1;
                } else if (passDialog.passDialogFocusIndex === 1) {
                    passDialog.passDialogFocusIndex = 3; // Focus Connect button by default
                }
            } else {
                wifiPanelScope.navigate(1);
            }
        }
        function onNavLeft() {
            if (passDialog.visible) {
                if (passDialog.passDialogFocusIndex === 3) {
                    passDialog.passDialogFocusIndex = 2; // Switch to Cancel
                } else if (passDialog.passDialogFocusIndex === 2) {
                    passDialog.passDialogFocusIndex = 3; // Switch to Connect
                }
            } else {
                wifiPanelScope.navigateHorizontal(-1);
            }
        }
        function onNavRight() {
            if (passDialog.visible) {
                if (passDialog.passDialogFocusIndex === 2) {
                    passDialog.passDialogFocusIndex = 3; // Switch to Connect
                } else if (passDialog.passDialogFocusIndex === 3) {
                    passDialog.passDialogFocusIndex = 2; // Switch to Cancel
                }
            } else {
                wifiPanelScope.navigateHorizontal(1);
            }
        }
        function onNavSelect() {
            wifiPanelScope.activateSelected();
        }
        function onNavBack() {
            if (passDialog.visible) {
                passDialog.visible = false;
                passInput.text = "";
                passDialog.passDialogFocusIndex = 0;
            } else if (savedSubIndex !== 0 || selectedIndex < 0) {
                savedSubIndex = 0;
                selectedIndex = 0;
                wifiWindow.isSwitchFocused = false;
            } else {
                InputService.closeOrReturn(wifiWindow);
            }
        }
        function onNavNextTab() {
            ConfigService.toggleWifi(!wifiWindow.switchChecked, function() { refresh(); });
        }
        function onNavPrevTab() {
            wifiWindow.refreshClicked();
        }
    }

    ListModel { id: savedModel }
    ListModel { id: availableModel }

    BaseFlyoutPanel {
        id: wifiWindow
        title: "Wi-Fi"
        iconName: "wifi"
        cardWidth: 370
        cardHeight: 500
        requiresKeyboardFocus: true

        onRefreshClicked: {
            ConfigService.startWifiScan(function() {
                refresh();
            });
        }

        onSwitchToggled: function(checked) {
            ConfigService.toggleWifi(checked, function() {
                refresh();
            });
        }

        Timer {
            id: wifiScanTimer
            interval: 3000
            running: wifiWindow.visible
            repeat: true
            onTriggered: refresh()
        }

        // Scrollable Networks List
        ScrollView {
            id: wifiScrollView
            anchors.fill: parent
            clip: true

            ColumnLayout {
                width: wifiScrollView.availableWidth > 0 ? wifiScrollView.availableWidth : 338
                spacing: 16

                // Section 0: Active Connected Network Card
                Item {
                    id: activeNetContainer
                    property var activeNet: null
                    Layout.fillWidth: true
                    implicitHeight: activeNet ? 64 : 0
                    visible: activeNet !== null

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                        border.color: Theme.primary
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            VectorIcon {
                                name: "wifi"
                                color: Theme.primary
                                iconSize: 20
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: activeNetContainer.activeNet ? activeNetContainer.activeNet.ssid : ""
                                    color: Theme.on_surface
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: activeNetContainer.activeNet ? ("Connected  •  " + activeNetContainer.activeNet.signal + "%") : ""
                                    color: Theme.primary
                                    font.pixelSize: 11
                                }
                            }

                            // Captive Portal Login Button
                            PillBadge {
                                visible: activeNetContainer.activeNet && !!activeNetContainer.activeNet.requires_portal
                                text: "Portal Login"
                                iconName: "browser"
                                pillHeight: 30
                                isSelected: true
                                onClicked: ConfigService.openCaptivePortal()
                            }

                            // Disconnect Button
                            PillBadge {
                                text: "Disconnect"
                                pillHeight: 30
                                defaultColor: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15)
                                defaultTextColor: Theme.error
                                defaultBorderColor: Theme.error
                                onClicked: ConfigService.disconnectWifiNetwork(refresh)
                            }
                        }
                    }
                }

                // Section 1: Saved Networks
                Text {
                    text: "SAVED NETWORKS"
                    color: Theme.primary
                    font.bold: true
                    font.pixelSize: 11
                    font.family: Theme.fontFamilyDisplay
                    visible: savedModel.count > 0
                }

                Repeater {
                    model: savedModel
                    delegate: PanelCardItem {
                        id: savedCard
                        required property string ssid
                        required property int signal
                        required property string security
                        required property bool saved
                        required property int index

                        property bool isConnecting: false

                        width: wifiScrollView.availableWidth > 0 ? wifiScrollView.availableWidth : 338
                        itemHeight: 52
                        isCurrent: wifiPanelScope.selectedIndex === index
                        selectedBorderColor: (savedCard.isCurrent && InputService.isNonMouse && wifiPanelScope.savedSubIndex === 0) ? Theme.primary : "transparent"
                        defaultBorderColor: (savedCard.isCurrent && InputService.isNonMouse && wifiPanelScope.savedSubIndex === 0) ? Theme.primary : Theme.outline_variant

                        onItemHovered: {
                            wifiPanelScope.selectedIndex = index;
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            VectorIcon {
                                name: "wifi"
                                color: savedCard.isHighlighted ? Theme.primary : Theme.on_surface_variant
                                iconSize: 18
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: ssid
                                    color: savedCard.isHighlighted ? Theme.primary : Theme.on_surface
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: isConnecting ? "Connecting..." : (signal + "%  •  " + (security || "Open"))
                                    color: Theme.on_surface_variant
                                    font.pixelSize: 11
                                }
                            }

                            // Connect Button
                            PillBadge {
                                text: isConnecting ? "..." : "Connect"
                                pillHeight: 28
                                fontSize: 11
                                isSelected: true
                                selectedBorderColor: (savedCard.isCurrent && InputService.isNonMouse && wifiPanelScope.savedSubIndex === 0) ? Theme.primary : "transparent"
                                defaultBorderColor: (savedCard.isCurrent && InputService.isNonMouse && wifiPanelScope.savedSubIndex === 0) ? Theme.primary : Theme.outline_variant
                                onClicked: {
                                    isConnecting = true;
                                    ConfigService.connectWifiNetwork(ssid, "", "", function() {
                                        isConnecting = false;
                                        refresh();
                                    });
                                }
                            }

                            // Forget / Delete Button
                            SquareButton {
                                iconName: "trash"
                                iconSize: 15
                                btnSize: 28
                                isActive: savedCard.isCurrent && InputService.isNonMouse && wifiPanelScope.savedSubIndex === 1
                                customIconColor: (savedCard.isCurrent && InputService.isNonMouse && wifiPanelScope.savedSubIndex === 1) ? Theme.error : Theme.on_surface_variant
                                normalColor: (savedCard.isCurrent && InputService.isNonMouse && wifiPanelScope.savedSubIndex === 1) ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2) : "transparent"
                                border.color: (savedCard.isCurrent && InputService.isNonMouse && wifiPanelScope.savedSubIndex === 1) ? Theme.error : "transparent"
                                scale: (savedCard.isCurrent && InputService.isNonMouse && wifiPanelScope.savedSubIndex === 1) ? 1.15 : 1.0
                                Behavior on scale { NumberAnimation { duration: 120 } }
                                onClicked: {
                                    ConfigService.forgetWifiNetwork(ssid, refresh);
                                }
                            }
                        }

                        onClicked: {
                            isConnecting = true;
                            ConfigService.connectWifiNetwork(ssid, "", "", function() {
                                isConnecting = false;
                                refresh();
                            });
                        }
                    }
                }

                // Section 2: Available Networks
                Text {
                    text: "AVAILABLE NETWORKS"
                    color: Theme.primary
                    font.bold: true
                    font.pixelSize: 11
                    font.family: Theme.fontFamilyDisplay
                    visible: availableModel.count > 0
                }

                Repeater {
                    model: availableModel
                    delegate: PanelCardItem {
                        id: availCard
                        required property string ssid
                        required property int signal
                        required property string security
                        required property int index

                        property bool isConnecting: false

                        width: wifiScrollView.availableWidth > 0 ? wifiScrollView.availableWidth : 338
                        itemHeight: 48
                        isCurrent: wifiPanelScope.selectedIndex === (savedModel.count + index)

                        onItemHovered: {
                            wifiPanelScope.selectedIndex = savedModel.count + index;
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            VectorIcon {
                                name: "wifi"
                                color: availCard.isHighlighted ? Theme.primary : Theme.on_surface_variant
                                iconSize: 18
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: ssid
                                    color: availCard.isHighlighted ? Theme.primary : Theme.on_surface
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: signal + "%  •  " + (security || "Open")
                                    color: Theme.on_surface_variant
                                    font.pixelSize: 10
                                }
                            }

                            // Connect / Password Prompt Button
                            PillBadge {
                                text: isConnecting ? "..." : "Connect"
                                pillHeight: 28
                                fontSize: 11
                                isSelected: true
                                onClicked: {
                                    if (security && security !== "" && security !== "--") {
                                        passDialog.targetSsid = ssid;
                                        passDialog.visible = true;
                                    } else {
                                        isConnecting = true;
                                        ConfigService.connectWifiNetwork(ssid, "", "", function() {
                                            isConnecting = false;
                                            refresh();
                                        });
                                    }
                                }
                            }
                        }

                        onClicked: {
                            if (security && security !== "" && security !== "--") {
                                passDialog.targetSsid = ssid;
                                passDialog.visible = true;
                            } else {
                                isConnecting = true;
                                ConfigService.connectWifiNetwork(ssid, "", "", function() {
                                    isConnecting = false;
                                    refresh();
                                });
                            }
                        }
                    }
                }
            }
        }

        // Passphrase Prompt Modal Overlay
        Rectangle {
            id: passDialog
            property string targetSsid: ""
            property int passDialogFocusIndex: 0
            visible: false

            onVisibleChanged: {
                if (visible) {
                    passInput.text = "";
                    passDialogFocusIndex = 0;
                    passInput.forceActiveFocus();
                }
            }

            function submitPassword() {
                var pwd = passInput.text;
                var ssid = passDialog.targetSsid;
                passDialog.visible = false;
                passInput.text = "";
                ConfigService.connectWifiNetwork(ssid, pwd, "", function() {
                    refresh();
                });
            }

            anchors.fill: parent
            radius: 20
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.96)

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 16

                VectorIcon {
                    name: "wifi"
                    color: Theme.primary
                    iconSize: 32
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Wi-Fi Passphrase Required"
                    color: Theme.on_surface
                    font.bold: true
                    font.pixelSize: 16
                    font.family: Theme.fontFamilyDisplay
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Connect to: " + passDialog.targetSsid
                    color: Theme.on_surface_variant
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignHCenter
                }

                // Glassmorphic Passphrase Input Field
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: 12
                    color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.7)
                    border.color: (passInput.activeFocus || passDialog.passDialogFocusIndex === 0) ? Theme.primary : Theme.outline_variant
                    border.width: (passInput.activeFocus || passDialog.passDialogFocusIndex === 0) ? 2 : 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        VectorIcon {
                            name: "lock"
                            color: (passInput.activeFocus || passDialog.passDialogFocusIndex === 0) ? Theme.primary : Theme.on_surface_variant
                            iconSize: 18
                        }

                        TextInput {
                            id: passInput
                            Layout.fillWidth: true
                            color: Theme.on_surface
                            font.pixelSize: 13
                            font.family: Theme.fontFamilySans
                            echoMode: showPassCheck.checked ? TextInput.Normal : TextInput.Password
                            clip: true
                            selectByMouse: true
                            selectedTextColor: Theme.on_primary
                            selectionColor: Theme.primary
                            Keys.onDownPressed: event => {
                                InputService.triggerDown();
                                event.accepted = true;
                            }
                            Keys.onUpPressed: event => {
                                InputService.triggerUp();
                                event.accepted = true;
                            }
                            Keys.onLeftPressed: event => {
                                if (passDialog.passDialogFocusIndex !== 0) {
                                    InputService.triggerLeft();
                                    event.accepted = true;
                                }
                            }
                            Keys.onRightPressed: event => {
                                if (passDialog.passDialogFocusIndex !== 0) {
                                    InputService.triggerRight();
                                    event.accepted = true;
                                }
                            }
                            Keys.onReturnPressed: event => {
                                wifiPanelScope.activateSelected();
                                event.accepted = true;
                            }
                            Keys.onEnterPressed: event => {
                                wifiPanelScope.activateSelected();
                                event.accepted = true;
                            }
                            Keys.onEscapePressed: event => {
                                InputService.triggerBack();
                                event.accepted = true;
                            }

                            Text {
                                text: "Enter Wi-Fi Passphrase"
                                color: Theme.on_surface_variant
                                font.pixelSize: 13
                                font.family: Theme.fontFamilySans
                                visible: passInput.text.length === 0 && !passInput.activeFocus
                            }
                        }
                    }
                }

                // Show Passphrase Toggle Row
                Rectangle {
                    implicitWidth: showPassRow.implicitWidth + 24
                    implicitHeight: 34
                    radius: 8
                    scale: passDialog.passDialogFocusIndex === 1 ? 1.05 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    color: passDialog.passDialogFocusIndex === 1
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                        : (showPassMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent")
                    border.color: passDialog.passDialogFocusIndex === 1 ? Theme.primary : "transparent"
                    border.width: passDialog.passDialogFocusIndex === 1 ? 2 : 0

                    RowLayout {
                        id: showPassRow
                        anchors.centerIn: parent
                        spacing: 8

                        VectorIcon {
                            name: showPassCheck.checked ? "eye" : "eye-off"
                            color: showPassCheck.checked ? Theme.primary : Theme.on_surface_variant
                            iconSize: 16
                        }

                        Text {
                            text: "Show Passphrase"
                            color: showPassCheck.checked ? Theme.primary : Theme.on_surface_variant
                            font.pixelSize: 12
                            font.family: Theme.fontFamilySans
                        }
                    }

                    Item {
                        id: showPassCheck
                        property bool checked: false
                    }

                    MouseArea {
                        id: showPassMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            showPassCheck.checked = !showPassCheck.checked;
                            passDialog.passDialogFocusIndex = 1;
                        }
                    }
                }

                RowLayout {
                    spacing: 12
                    Layout.alignment: Qt.AlignHCenter

                    ActionButton {
                        text: "Cancel"
                        iconName: "close"
                        variant: "outline"
                        isFocused: passDialog.passDialogFocusIndex === 2
                        onClicked: {
                            passDialog.visible = false;
                            passInput.text = "";
                            passDialog.passDialogFocusIndex = 0;
                        }
                    }

                    ActionButton {
                        text: "Connect"
                        iconName: "check"
                        variant: "primary"
                        isFocused: passDialog.passDialogFocusIndex === 3
                        onClicked: passDialog.submitPassword()
                    }
                }
            }
        }
    }
}
