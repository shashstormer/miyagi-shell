import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../components"

Item {
    id: root

    property int focusIndex: -1
    property int actionIndex: 0

    property var btData: null
    property var pairedDevices: []
    property var availableDevices: []
    property var selectedDevice: null
    property int currentView: 0 // 0 = Main List, 1 = Device Details

    function refreshBt() {
        ConfigService.fetchBluetoothStatus(function(data) {
            if (!data) return;
            root.btData = data;

            var paired = [];
            var avail = [];
            if (data.devices) {
                for (var i = 0; i < data.devices.length; i++) {
                    var dev = data.devices[i];
                    if (dev.battery_percentage === null || dev.battery_percentage === undefined) dev.battery_percentage = -1;
                    if (!dev.audio_profiles) dev.audio_profiles = [];
                    if (!dev.active_profile) dev.active_profile = "";

                    if (dev.paired) {
                        paired.push(dev);
                    } else {
                        avail.push(dev);
                    }

                    if (root.selectedDevice && root.selectedDevice.address === dev.address) {
                        root.selectedDevice = dev;
                    }
                }
            }
            root.pairedDevices = paired;
            root.availableDevices = avail;

            if (data.auth_request) {
                authDialog.authData = data.auth_request;
                authDialog.visible = true;
            } else {
                authDialog.visible = false;
            }
        });
    }

    Component.onCompleted: refreshBt()

    function getItemCount() {
        if (currentView === 1) return 4; // Back, Trust toggle, Connect/Disconnect, Unpair
        var count = 2; // Power, Scan
        count += root.pairedDevices.length;
        count += root.availableDevices.length;
        return count;
    }

    function handleHorizontal(delta) {
        if (currentView === 1) {
            actionIndex = Math.max(0, Math.min(1, actionIndex + delta));
            return;
        }
        actionIndex = Math.max(0, Math.min(1, actionIndex + delta));
    }

    function triggerItem() {
        if (authDialog.visible) {
            if (authDialog.actionIndex === 1) authDialog.rejectAuth();
            else authDialog.acceptAuth();
            return;
        }

        if (currentView === 1) {
            if (focusIndex === 0) {
                currentView = 0;
            } else if (focusIndex === 1 && selectedDevice) {
                ConfigService.trustBluetoothDevice(selectedDevice.address, !selectedDevice.trusted, refreshBt);
            } else if (focusIndex === 2 && selectedDevice) {
                if (selectedDevice.connected) {
                    ConfigService.disconnectBluetoothDevice(selectedDevice.address, refreshBt);
                } else {
                    ConfigService.connectBluetoothDevice(selectedDevice.address, refreshBt);
                }
            } else if (focusIndex === 3 && selectedDevice) {
                ConfigService.removeBluetoothDevice(selectedDevice.address, function() {
                    currentView = 0;
                    refreshBt();
                });
            }
            return;
        }

        if (focusIndex === 0) {
            ConfigService.toggleBluetooth(!ConfigService.bluetoothPowered, function() { root.refreshBt(); });
        } else if (focusIndex === 1) {
            if (ConfigService.bluetoothDiscovering) {
                ConfigService.stopBluetoothScan(function() { root.refreshBt(); });
            } else {
                ConfigService.startBluetoothScan(function() { root.refreshBt(); });
            }
        } else {
            var idx = focusIndex - 2;
            if (idx >= 0 && idx < root.pairedDevices.length) {
                var pDev = root.pairedDevices[idx];
                if (actionIndex === 1) {
                    root.selectedDevice = pDev;
                    root.currentView = 1;
                } else {
                    if (pDev.connected) ConfigService.disconnectBluetoothDevice(pDev.address, refreshBt);
                    else ConfigService.connectBluetoothDevice(pDev.address, refreshBt);
                }
            } else {
                var aIdx = idx - root.pairedDevices.length;
                if (aIdx >= 0 && aIdx < root.availableDevices.length) {
                    var aDev = root.availableDevices[aIdx];
                    ConfigService.pairBluetoothDevice(aDev.address, refreshBt);
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
        // 1. BLUETOOTH HERO STATUS CARD
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
                    color: ConfigService.bluetoothPowered 
                        ? (ConfigService.bluetoothConnected ? Qt.rgba(85/255, 224/255, 128/255, 0.18) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)) 
                        : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.20)
                    Layout.alignment: Qt.AlignVCenter

                    VectorIcon {
                        anchors.centerIn: parent
                        name: ConfigService.bluetoothPowered ? (ConfigService.bluetoothConnected ? "bluetooth_connected" : "bluetooth") : "bluetooth_off"
                        iconSize: 22
                        color: ConfigService.bluetoothPowered ? (ConfigService.bluetoothConnected ? "#55E080" : Theme.primary) : Theme.on_surface_variant
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
                            text: ConfigService.bluetoothConnected ? (ConfigService.bluetoothDeviceName || "Connected Device") : (ConfigService.bluetoothPowered ? "Bluetooth Ready" : "Bluetooth Disabled")
                            color: Theme.on_surface
                            font.pixelSize: 16
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                            elide: Text.ElideRight
                        }

                        PillBadge {
                            text: ConfigService.bluetoothConnected ? "Connected" : (ConfigService.bluetoothPowered ? "On" : "Off")
                            isInteractive: false
                            defaultColor: ConfigService.bluetoothConnected 
                                ? Qt.rgba(85/255, 224/255, 128/255, 0.18) 
                                : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            defaultTextColor: ConfigService.bluetoothConnected ? "#55E080" : Theme.primary
                        }
                    }

                    Text {
                        text: ConfigService.bluetoothPowered 
                            ? (root.pairedDevices.length + " paired devices  •  " + (ConfigService.bluetoothDiscovering ? "Scanning for nearby accessories..." : "Ready to connect"))
                            : "Turn on Bluetooth to connect wireless peripherals"
                        color: Theme.on_surface_variant
                        font.pixelSize: 11
                        font.family: Theme.fontFamilyDisplay
                    }
                }

                SquareButton {
                    text: ConfigService.bluetoothDiscovering ? "Stop" : "Scan"
                    iconName: ConfigService.bluetoothDiscovering ? "stop" : "search"
                    size: 32
                    customRadius: 16
                    isActive: root.focusIndex === 1
                    Layout.alignment: Qt.AlignVCenter
                    enabled: ConfigService.bluetoothPowered
                    onClicked: {
                        if (ConfigService.bluetoothDiscovering) {
                            ConfigService.stopBluetoothScan(function() { root.refreshBt(); });
                        } else {
                            ConfigService.startBluetoothScan(function() { root.refreshBt(); });
                        }
                    }
                }
            }
        }

        // ==========================================
        // 2. DEVICE DETAILS SUB-VIEW (WHEN SELECTED)
        // ==========================================
        SettingCardGroup {
            visible: root.currentView === 1 && root.selectedDevice !== null
            titleText: "Device Details: " + (root.selectedDevice ? (root.selectedDevice.name || root.selectedDevice.alias || "Device") : "")

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                SquareButton {
                    text: "Back to Devices"
                    iconName: "arrow_left"
                    size: 32
                    customRadius: 16
                    isActive: root.focusIndex === 0
                    onClicked: root.currentView = 0
                }

                Item { Layout.fillWidth: true }
            }

            SettingToggleRow {
                labelText: "Trusted Device"
                descriptionText: "Allow automatic pairing and connection"
                checked: root.selectedDevice ? !!root.selectedDevice.trusted : false
                isFocused: root.focusIndex === 1
                onToggled: newValue => {
                    if (root.selectedDevice) ConfigService.trustBluetoothDevice(root.selectedDevice.address, newValue, root.refreshBt);
                }
            }

            // Audio Profile Selector
            SettingPillSelector {
                visible: root.selectedDevice && root.selectedDevice.audio_profiles && root.selectedDevice.audio_profiles.length > 0
                labelText: "Audio Profile (Codec)"
                options: (root.selectedDevice && root.selectedDevice.audio_profiles) ? root.selectedDevice.audio_profiles : []
                selectedIndex: {
                    if (!root.selectedDevice || !root.selectedDevice.audio_profiles) return 0;
                    return Math.max(0, root.selectedDevice.audio_profiles.indexOf(root.selectedDevice.active_profile));
                }
                onOptionSelected: (idx, opt) => {
                    if (root.selectedDevice) ConfigService.setBluetoothAudioProfile(root.selectedDevice.address, opt, root.refreshBt);
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ActionButton {
                    Layout.fillWidth: true
                    text: (root.selectedDevice && root.selectedDevice.connected) ? "Disconnect Device" : "Connect Device"
                    iconName: (root.selectedDevice && root.selectedDevice.connected) ? "bluetooth_off" : "bluetooth_connected"
                    isFocused: root.focusIndex === 2
                    onClicked: {
                        if (!root.selectedDevice) return;
                        if (root.selectedDevice.connected) ConfigService.disconnectBluetoothDevice(root.selectedDevice.address, root.refreshBt);
                        else ConfigService.connectBluetoothDevice(root.selectedDevice.address, root.refreshBt);
                    }
                }

                ActionButton {
                    Layout.fillWidth: true
                    text: "Unpair & Forget"
                    iconName: "ban"
                    variant: "danger"
                    isFocused: root.focusIndex === 3
                    onClicked: {
                        if (!root.selectedDevice) return;
                        ConfigService.removeBluetoothDevice(root.selectedDevice.address, function() {
                            root.currentView = 0;
                            root.refreshBt();
                        });
                    }
                }
            }
        }

        // ==========================================
        // 3. MAIN LIST: BLUETOOTH ADAPTER CONTROLS
        // ==========================================
        SettingCardGroup {
            visible: root.currentView === 0
            titleText: "Bluetooth Radio"

            SettingToggleRow {
                id: btPowerToggle
                labelText: "Bluetooth Power"
                descriptionText: "Enable or disable Bluetooth transmitter"
                checked: ConfigService.bluetoothPowered
                isFocused: root.focusIndex === 0
                onToggled: newValue => ConfigService.toggleBluetooth(newValue, function() { root.refreshBt(); })
            }
        }

        // ==========================================
        // 4. MAIN LIST: PAIRED DEVICES
        // ==========================================
        SettingCardGroup {
            visible: root.currentView === 0 && ConfigService.bluetoothPowered && root.pairedDevices.length > 0
            titleText: "Paired Devices (" + root.pairedDevices.length + ")"

            Repeater {
                model: root.pairedDevices
                delegate: Rectangle {
                    id: devRow
                    required property var modelData
                    required property int index

                    readonly property int itemFocusIndex: 2 + index
                    readonly property bool isRowFocused: root.focusIndex === itemFocusIndex

                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: 10
                    color: isRowFocused
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        : (devMouse.containsMouse ? Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.35) : "transparent")

                    border.color: isRowFocused ? Theme.primary : "transparent"
                    border.width: isRowFocused ? 1.5 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        VectorIcon {
                            name: {
                                var iconType = (modelData.icon || "").toLowerCase();
                                if (iconType.includes("audio") || iconType.includes("headset") || iconType.includes("headphone")) return "headphones";
                                if (iconType.includes("mouse")) return "mouse";
                                if (iconType.includes("keyboard")) return "keyboard";
                                if (iconType.includes("gamepad") || iconType.includes("joystick")) return "gamepad";
                                if (iconType.includes("phone")) return "phone";
                                return "bluetooth";
                            }
                            iconSize: 16
                            color: modelData.connected ? Theme.primary : Theme.on_surface_variant
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                spacing: 6
                                Layout.fillWidth: true

                                Text {
                                    text: modelData.name || modelData.alias || modelData.address || "Bluetooth Device"
                                    color: modelData.connected ? Theme.primary : Theme.on_surface
                                    font.bold: true
                                    font.pixelSize: 12
                                    font.family: Theme.fontFamilyDisplay
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                PillBadge {
                                    visible: modelData.battery_percentage !== undefined && modelData.battery_percentage >= 0
                                    text: (modelData.battery_percentage || 0) + "%"
                                    isInteractive: false
                                    pillHeight: 18
                                    fontSize: 10
                                }
                            }

                            Text {
                                text: (modelData.connected ? "Connected" : "Paired") + "  •  " + (modelData.address || "")
                                color: Theme.on_surface_variant
                                font.pixelSize: 10
                                font.family: Theme.fontFamilyDisplay
                            }
                        }

                        // Settings / Details Gear Button
                        SquareButton {
                            text: "Details"
                            iconName: "sliders"
                            size: 26
                            customRadius: 13
                            isActive: (isRowFocused && root.actionIndex === 1)
                            onClicked: {
                                root.selectedDevice = modelData;
                                root.currentView = 1;
                            }
                        }

                        // Connect / Disconnect Button
                        SquareButton {
                            text: modelData.connected ? "Disconnect" : "Connect"
                            iconName: modelData.connected ? "bluetooth_off" : "bluetooth_connected"
                            size: 26
                            customRadius: 13
                            isActive: modelData.connected
                            activeColor: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15)
                            customIconColor: modelData.connected ? Theme.error : Theme.primary
                            onClicked: {
                                if (modelData.connected) {
                                    ConfigService.disconnectBluetoothDevice(modelData.address, function() { root.refreshBt(); });
                                } else {
                                    ConfigService.connectBluetoothDevice(modelData.address, function() { root.refreshBt(); });
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: devMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedDevice = modelData;
                            root.currentView = 1;
                        }
                    }
                }
            }
        }

        // ==========================================
        // 5. MAIN LIST: DISCOVERED NEARBY DEVICES
        // ==========================================
        SettingCardGroup {
            visible: root.currentView === 0
            titleText: "Available Nearby Devices (" + root.availableDevices.length + ")"

            EmptyState {
                visible: !ConfigService.bluetoothPowered || root.availableDevices.length === 0
                iconName: "bluetooth"
                title: ConfigService.bluetoothPowered ? "No nearby devices found" : "Bluetooth is turned off"
                description: ConfigService.bluetoothPowered ? "Start scanning above to find and pair new Bluetooth devices." : "Turn on Bluetooth above to manage accessories."
            }

            Repeater {
                model: root.availableDevices
                delegate: Rectangle {
                    id: availDevRow
                    required property var modelData
                    required property int index

                    readonly property int itemFocusIndex: 2 + root.pairedDevices.length + index
                    readonly property bool isRowFocused: root.focusIndex === itemFocusIndex

                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: 10
                    color: isRowFocused
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        : (availDevMouse.containsMouse ? Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.35) : "transparent")

                    border.color: isRowFocused ? Theme.primary : "transparent"
                    border.width: isRowFocused ? 1.5 : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        VectorIcon {
                            name: "bluetooth"
                            iconSize: 16
                            color: Theme.on_surface_variant
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.name || modelData.alias || modelData.address || "Bluetooth Device"
                                color: Theme.on_surface
                                font.bold: true
                                font.pixelSize: 12
                                font.family: Theme.fontFamilyDisplay
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.address || ""
                                color: Theme.on_surface_variant
                                font.pixelSize: 10
                                font.family: Theme.fontFamilyDisplay
                            }
                        }

                        SquareButton {
                            text: "Pair"
                            iconName: "plus"
                            size: 26
                            customRadius: 13
                            isActive: isRowFocused
                            onClicked: ConfigService.pairBluetoothDevice(modelData.address, function() { root.refreshBt(); })
                        }
                    }

                    MouseArea {
                        id: availDevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ConfigService.pairBluetoothDevice(modelData.address, function() { root.refreshBt(); })
                    }
                }
            }
        }
    }

    // Modal PIN / Passkey Authentication Dialog
    Rectangle {
        id: authDialog
        visible: false
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        z: 99

        property var authData: null
        property int actionIndex: 0

        function acceptAuth() {
            if (authData) ConfigService.confirmBluetoothPasskey(authData.device, true, function() { root.refreshBt(); });
            visible = false;
        }

        function rejectAuth() {
            if (authData) ConfigService.confirmBluetoothPasskey(authData.device, false, function() { root.refreshBt(); });
            visible = false;
        }

        Rectangle {
            width: 320
            implicitHeight: 180
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
                    text: "Bluetooth Pairing Request"
                    color: Theme.on_surface
                    font.bold: true
                    font.pixelSize: 15
                    font.family: Theme.fontFamilyDisplay
                }

                Text {
                    text: "Device \"" + (authDialog.authData ? (authDialog.authData.name || authDialog.authData.address) : "") + "\" is requesting to pair.\nConfirm PIN code: " + (authDialog.authData ? (authDialog.authData.pin || authDialog.authData.passkey || "******") : "")
                    color: Theme.on_surface_variant
                    font.pixelSize: 12
                    font.family: Theme.fontFamilyDisplay
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ActionButton {
                        Layout.fillWidth: true
                        text: "Reject"
                        iconName: "ban"
                        variant: "danger"
                        isFocused: authDialog.actionIndex === 1
                        onClicked: authDialog.rejectAuth()
                    }

                    ActionButton {
                        Layout.fillWidth: true
                        text: "Accept"
                        iconName: "sparkle"
                        variant: "primary"
                        isFocused: authDialog.actionIndex === 0
                        onClicked: authDialog.acceptAuth()
                    }
                }
            }
        }
    }
}
