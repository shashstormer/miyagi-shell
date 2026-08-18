import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../components"
import "../components/ModelUtils.js" as ModelUtils

Scope {
    id: bluetoothPanelScope

    property bool isOpen: bluetoothWindow.isOpen
    property alias openedFrom: bluetoothWindow.openedFrom
    property int currentView: 0 // 0 = Main Devices List, 1 = Device Config Details Page
    property var selectedDevice: null

    function toggle() {
        if (bluetoothWindow.isOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        bluetoothWindow.open();
        currentView = 0;
        refresh();
        ConfigService.startBluetoothScan(function() { refresh(); });
    }

    function close() {
        bluetoothWindow.close();
    }

    function refresh() {
        ConfigService.fetchBluetoothStatus(function(data) {
            if (!data) return;
            bluetoothWindow.switchChecked = !!data.powered;
            bluetoothWindow.isRefreshing = !!data.discovering;
            scanControlRow.isScanning = !!data.discovering;
            
            var paired = [];
            var available = [];
            if (data.devices) {
                for (var i = 0; i < data.devices.length; i++) {
                    var dev = data.devices[i];
                    if (dev.battery_percentage === null || dev.battery_percentage === undefined) dev.battery_percentage = -1;
                    if (!dev.audio_profiles) dev.audio_profiles = [];
                    if (!dev.active_profile) dev.active_profile = "";

                    if (dev.paired) {
                        paired.push(dev);
                    } else {
                        available.push(dev);
                    }

                    // Keep selectedDevice in sync if currently viewing its details page
                    if (selectedDevice && selectedDevice.address === dev.address) {
                        selectedDevice = dev;
                    }
                }
            }
            ModelUtils.updateListModel(pairedModel, paired, "address", ["name", "connected", "icon", "rssi", "signal_strength", "trusted", "battery_percentage", "active_profile"]);
            ModelUtils.updateListModel(availableModel, available, "address", ["name", "icon", "rssi", "signal_strength", "trusted", "battery_percentage"]);

            if (data.auth_request) {
                authDialog.authData = data.auth_request;
                authDialog.visible = true;
            } else {
                authDialog.visible = false;
            }
        });
    }

    property int selectedIndex: 0
    property int pairedSubIndex: 0 // 0 = Card Connect, 1 = Settings Button
    property int detailsFocusIndex: 0
    readonly property int totalItemCount: pairedModel.count + availableModel.count

    function navigate(delta) {
        InputService.useKeyboard();
        if (currentView === 1) {
            if (delta < 0) {
                if (detailsFocusIndex > 1) {
                    detailsFocusIndex = 1;
                } else if (detailsFocusIndex === 1) {
                    detailsFocusIndex = 0;
                }
            } else if (delta > 0) {
                if (detailsFocusIndex === 0) {
                    detailsFocusIndex = 1;
                } else if (detailsFocusIndex === 1) {
                    detailsFocusIndex = 2; // Focus Connect button
                }
            }
            return;
        }
        if (totalItemCount > 0) {
            selectedIndex = Math.max(-1, Math.min(selectedIndex + delta, totalItemCount - 1));
            bluetoothWindow.isSwitchFocused = (selectedIndex === -1);
            pairedSubIndex = 0;
        } else {
            selectedIndex = -1;
            bluetoothWindow.isSwitchFocused = true;
        }
    }

    function navigateHorizontal(delta) {
        InputService.useKeyboard();
        if (currentView === 1) {
            if (detailsFocusIndex >= 2) {
                if (delta < 0) detailsFocusIndex = 2;
                else if (delta > 0) detailsFocusIndex = 3;
            }
            return;
        }
        if (currentView === 0 && selectedIndex >= 0 && selectedIndex < pairedModel.count) {
            pairedSubIndex = Math.max(0, Math.min(pairedSubIndex + delta, 1));
        }
    }

    function activateSelected() {
        if (authDialog.visible) {
            if (authDialog.authFocusIndex === 1) {
                authDialog.rejectAuth();
            } else {
                authDialog.acceptAuth();
            }
            return;
        }
        if (selectedIndex === -1) {
            ConfigService.toggleBluetooth(!bluetoothWindow.switchChecked, function() { refresh(); });
            return;
        }
        if (currentView === 1) {
            if (detailsFocusIndex === 0) {
                currentView = 0;
                return;
            }
            if (!selectedDevice) return;
            if (detailsFocusIndex === 1) {
                ConfigService.trustBluetoothDevice(selectedDevice.address, !selectedDevice.trusted, refresh);
            } else if (detailsFocusIndex === 2) {
                if (selectedDevice.connected) {
                    ConfigService.disconnectBluetoothDevice(selectedDevice.address, refresh);
                } else {
                    ConfigService.connectBluetoothDevice(selectedDevice.address, refresh);
                }
            } else if (detailsFocusIndex === 3) {
                ConfigService.removeBluetoothDevice(selectedDevice.address, function() {
                    currentView = 0;
                    refresh();
                });
            }
            return;
        }
        if (selectedIndex >= 0 && selectedIndex < pairedModel.count) {
            var item = pairedModel.get(selectedIndex);
            if (item) {
                if (pairedSubIndex === 1) {
                    selectedDevice = {
                        address: item.address,
                        name: item.name,
                        connected: item.connected,
                        trusted: item.trusted,
                        icon: item.icon,
                        battery_percentage: item.battery_percentage,
                        active_profile: item.active_profile
                    };
                    detailsFocusIndex = 0;
                    currentView = 1;
                } else {
                    if (item.connected) {
                        ConfigService.disconnectBluetoothDevice(item.address, refresh);
                    } else {
                        ConfigService.connectBluetoothDevice(item.address, refresh);
                    }
                }
            }
        } else if (selectedIndex >= pairedModel.count && selectedIndex < totalItemCount) {
            var availItem = availableModel.get(selectedIndex - pairedModel.count);
            if (availItem) {
                ConfigService.pairBluetoothDevice(availItem.address, refresh);
            }
        }
    }

    Connections {
        target: InputService
        enabled: bluetoothWindow.isOpen

        function onNavUp() {
            if (authDialog.visible) {
                authDialog.authFocusIndex = Math.max(0, authDialog.authFocusIndex - 1);
                if (authDialog.authFocusIndex === 0 && pinInput.visible) pinInput.forceActiveFocus();
            } else {
                bluetoothPanelScope.navigate(-1);
            }
        }
        function onNavDown() {
            if (authDialog.visible) {
                authDialog.authFocusIndex = Math.min(2, authDialog.authFocusIndex + 1);
                if (authDialog.authFocusIndex === 0 && pinInput.visible) pinInput.forceActiveFocus();
            } else {
                bluetoothPanelScope.navigate(1);
            }
        }
        function onNavLeft() {
            if (authDialog.visible) {
                if (authDialog.authFocusIndex === 2) authDialog.authFocusIndex = 1;
            } else {
                bluetoothPanelScope.navigateHorizontal(-1);
            }
        }
        function onNavRight() {
            if (authDialog.visible) {
                if (authDialog.authFocusIndex === 1) authDialog.authFocusIndex = 2;
            } else {
                bluetoothPanelScope.navigateHorizontal(1);
            }
        }
        function onNavSelect() {
            bluetoothPanelScope.activateSelected();
        }
        function onNavBack() {
            if (authDialog.visible) {
                authDialog.rejectAuth();
            } else if (bluetoothPanelScope.currentView === 1) {
                bluetoothPanelScope.currentView = 0;
            } else if (pairedSubIndex !== 0 || selectedIndex < 0 || detailsFocusIndex !== 0) {
                pairedSubIndex = 0;
                selectedIndex = 0;
                detailsFocusIndex = 0;
                bluetoothWindow.isSwitchFocused = false;
            } else {
                InputService.closeOrReturn(bluetoothWindow);
            }
        }
        function onNavNextTab() {
            ConfigService.toggleBluetooth(!bluetoothWindow.switchChecked, function() { refresh(); });
        }
        function onNavPrevTab() {
            bluetoothWindow.refreshClicked();
        }
    }

    ListModel { id: pairedModel }
    ListModel { id: availableModel }

    BaseFlyoutPanel {
        id: bluetoothWindow
        title: currentView === 1 && selectedDevice ? selectedDevice.name : "Bluetooth"
        iconName: currentView === 1 ? "settings" : "bluetooth"
        cardWidth: 380
        cardHeight: 520
        requiresKeyboardFocus: true

        onRefreshClicked: {
            if (scanControlRow.isScanning) {
                ConfigService.stopBluetoothScan(refresh);
            } else {
                ConfigService.startBluetoothScan(refresh);
            }
        }

        onSwitchToggled: function(checked) {
            ConfigService.toggleBluetooth(checked, function() {
                refresh();
            });
        }

        Timer {
            id: btScanTimer
            interval: 2500
            running: bluetoothWindow.visible
            repeat: true
            onTriggered: refresh()
        }

        // Main Body Container (Page 0 = Main List, Page 1 = Device Details)
        Item {
            anchors.fill: parent

            // PAGE 0: Main Devices List
            ScrollView {
                id: devScrollView
                visible: currentView === 0
                anchors.fill: parent
                clip: true

                ColumnLayout {
                    width: devScrollView.availableWidth > 0 ? devScrollView.availableWidth : 348
                    spacing: 16

                    // Explicit Start / Stop Scan Toolbar
                    Rectangle {
                        id: scanControlRow
                        property bool isScanning: false
                        width: devScrollView.availableWidth > 0 ? devScrollView.availableWidth : 348
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 12
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            VectorIcon {
                                name: "refresh"
                                color: scanControlRow.isScanning ? Theme.primary : Theme.on_surface_variant
                                iconSize: 16
                            }

                            Text {
                                text: scanControlRow.isScanning ? "Scanning for nearby devices..." : "Discovery Idle"
                                color: scanControlRow.isScanning ? Theme.primary : Theme.on_surface_variant
                                font.pixelSize: 12
                                font.bold: scanControlRow.isScanning
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                implicitWidth: 92
                                implicitHeight: 26
                                radius: 13
                                color: scanBtnMouse.containsMouse ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)

                                Text {
                                    anchors.centerIn: parent
                                    text: scanControlRow.isScanning ? "Stop Scan" : "Start Scan"
                                    color: scanBtnMouse.containsMouse ? Theme.on_primary : Theme.primary
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    id: scanBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (scanControlRow.isScanning) {
                                            ConfigService.stopBluetoothScan(refresh);
                                        } else {
                                            ConfigService.startBluetoothScan(refresh);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Section 1: Paired Devices
                    Text {
                        text: "PAIRED DEVICES"
                        color: Theme.primary
                        font.bold: true
                        font.pixelSize: 11
                        font.family: Theme.fontFamilyDisplay
                        visible: pairedModel.count > 0
                    }

                    Repeater {
                        model: pairedModel
                        delegate: PanelCardItem {
                            id: pairedCard
                            required property string address
                            required property string name
                            required property bool connected
                            required property bool trusted
                            required property string icon
                            required property int rssi
                            required property int signal_strength
                            required property int battery_percentage
                            required property string active_profile
                            required property int index

                            property bool isConnecting: false

                            width: devScrollView.availableWidth > 0 ? devScrollView.availableWidth : 348
                            itemHeight: 52
                            isCurrent: bluetoothPanelScope.selectedIndex === index

                            onItemHovered: {
                                bluetoothPanelScope.selectedIndex = index;
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                VectorIcon {
                                    name: icon || "bluetooth"
                                    color: connected || pairedCard.isHighlighted ? Theme.primary : Theme.on_surface_variant
                                    iconSize: 19
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: name
                                        color: pairedCard.isHighlighted ? Theme.primary : Theme.on_surface
                                        font.pixelSize: 13
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    RowLayout {
                                        spacing: 6

                                        Text {
                                            text: isConnecting ? "Connecting..." : (connected ? "Connected" : "Paired")
                                            color: connected ? Theme.primary : Theme.on_surface_variant
                                            font.pixelSize: 11
                                        }

                                        // Battery Progress Ring
                                        RowLayout {
                                            visible: battery_percentage >= 0
                                            spacing: 5

                                            Text {
                                                text: " • "
                                                color: Theme.on_surface_variant
                                                font.pixelSize: 11
                                            }

                                            CircularProgress {
                                                value: battery_percentage
                                                size: 14
                                                color: Theme.primary
                                            }
                                        }
                                    }
                                }

                                // Connect / Disconnect Button
                                PillBadge {
                                    text: isConnecting ? "..." : (connected ? "Disconnect" : "Connect")
                                    pillHeight: 28
                                    fontSize: 11
                                    isSelected: connected
                                    selectedBorderColor: (pairedCard.isCurrent && InputService.isNonMouse && bluetoothPanelScope.pairedSubIndex === 0) ? Theme.primary : "transparent"
                                    defaultBorderColor: (pairedCard.isCurrent && InputService.isNonMouse && bluetoothPanelScope.pairedSubIndex === 0) ? Theme.primary : Theme.outline_variant
                                    onClicked: {
                                        isConnecting = true;
                                        if (connected) {
                                            ConfigService.disconnectBluetoothDevice(address, function() {
                                                isConnecting = false;
                                                refresh();
                                            });
                                        } else {
                                            ConfigService.connectBluetoothDevice(address, function() {
                                                isConnecting = false;
                                                refresh();
                                            });
                                        }
                                    }
                                }

                                // Settings Button (Navigates to Page 1)
                                SquareButton {
                                    iconName: "settings"
                                    iconSize: 15
                                    btnSize: 28
                                    isActive: pairedCard.isCurrent && InputService.isNonMouse && bluetoothPanelScope.pairedSubIndex === 1
                                    iconColor: (pairedCard.isCurrent && InputService.isNonMouse && bluetoothPanelScope.pairedSubIndex === 1) ? Theme.primary : Theme.on_surface_variant
                                    onClicked: {
                                        selectedDevice = {
                                            address: address,
                                            name: name,
                                            connected: connected,
                                            trusted: trusted,
                                            icon: icon,
                                            battery_percentage: battery_percentage,
                                            active_profile: active_profile
                                        };
                                        currentView = 1;
                                    }
                                }
                            }

                            onClicked: {
                                if (connected) {
                                    ConfigService.disconnectBluetoothDevice(address, refresh);
                                } else {
                                    ConfigService.connectBluetoothDevice(address, refresh);
                                }
                            }
                        }
                    }

                    // Section 2: Available Devices
                    Text {
                        text: "AVAILABLE DEVICES"
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
                            required property string address
                            required property string name
                            required property string icon
                            required property int index

                            property bool isPairing: false

                            width: devScrollView.availableWidth > 0 ? devScrollView.availableWidth : 348
                            itemHeight: 48
                            isCurrent: bluetoothPanelScope.selectedIndex === (pairedModel.count + index)

                            onItemHovered: {
                                bluetoothPanelScope.selectedIndex = pairedModel.count + index;
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                VectorIcon {
                                    name: icon || "bluetooth"
                                    color: availCard.isHighlighted ? Theme.primary : Theme.on_surface_variant
                                    iconSize: 18
                                }

                                Text {
                                    text: name
                                    color: availCard.isHighlighted ? Theme.primary : Theme.on_surface
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                // Pair Button
                                PillBadge {
                                    text: isPairing ? "Pairing..." : "Pair"
                                    pillHeight: 28
                                    fontSize: 11
                                    isSelected: true
                                    onClicked: {
                                        isPairing = true;
                                        ConfigService.pairBluetoothDevice(address, function() {
                                            isPairing = false;
                                            refresh();
                                        });
                                    }
                                }
                            }

                            onClicked: {
                                isPairing = true;
                                ConfigService.pairBluetoothDevice(address, function() {
                                    isPairing = false;
                                    refresh();
                                });
                            }
                        }
                    }
                }
            }

            // PAGE 1: Dedicated Device Details & Config Page
            ScrollView {
                id: detailsScrollView
                visible: currentView === 1
                anchors.fill: parent
                clip: true

                ColumnLayout {
                    width: detailsScrollView.availableWidth > 0 ? detailsScrollView.availableWidth : 348
                    spacing: 16

                    // Navigation Back Header
                    Rectangle {
                        width: detailsScrollView.availableWidth > 0 ? detailsScrollView.availableWidth : 348
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 12
                        color: (backMouse.containsMouse || (InputService.isNonMouse && detailsFocusIndex === 0)) ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : "transparent"
                        border.color: (InputService.isNonMouse && detailsFocusIndex === 0) ? Theme.primary : "transparent"
                        border.width: (InputService.isNonMouse && detailsFocusIndex === 0) ? 2 : 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            spacing: 8

                            VectorIcon {
                                name: "arrow_back"
                                color: Theme.primary
                                iconSize: 16
                            }

                            Text {
                                text: "Back to Bluetooth Devices"
                                color: Theme.primary
                                font.bold: true
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                currentView = 0;
                            }
                        }
                    }

                    // Device Header Summary Card
                    Rectangle {
                        width: detailsScrollView.availableWidth > 0 ? detailsScrollView.availableWidth : 348
                        Layout.fillWidth: true
                        implicitHeight: 70
                        radius: 16
                        color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.6)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            VectorIcon {
                                name: selectedDevice ? (selectedDevice.icon || "bluetooth") : "bluetooth"
                                color: selectedDevice && selectedDevice.connected ? Theme.primary : Theme.on_surface_variant
                                iconSize: 28
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: selectedDevice ? selectedDevice.name : "Device Details"
                                    color: Theme.on_surface
                                    font.pixelSize: 15
                                    font.bold: true
                                }

                                Text {
                                    text: selectedDevice ? ("MAC: " + selectedDevice.address) : ""
                                    color: Theme.on_surface_variant
                                    font.pixelSize: 11
                                    font.family: "Monospace"
                                }

                                Text {
                                    visible: !!selectedDevice && !!selectedDevice.connected && (selectedDevice.signal_strength || 0) > 0
                                    text: selectedDevice ? ("Signal Strength: " + (selectedDevice.signal_strength || 0) + "% (" + (selectedDevice.rssi || 0) + " dBm)") : ""
                                    color: Theme.primary
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            // Battery Circle (if present)
                            CircularProgress {
                                visible: selectedDevice && selectedDevice.battery_percentage >= 0
                                value: selectedDevice ? selectedDevice.battery_percentage : 0
                                size: 22
                                color: Theme.primary
                            }
                        }
                    }

                    // Device Trust Setting
                    Rectangle {
                        width: detailsScrollView.availableWidth > 0 ? detailsScrollView.availableWidth : 348
                        Layout.fillWidth: true
                        implicitHeight: 50
                        radius: 14
                        color: Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g, Theme.surface_container_low.b, 0.4)
                        border.color: (InputService.isNonMouse && detailsFocusIndex === 1) ? Theme.primary : "transparent"
                        border.width: (InputService.isNonMouse && detailsFocusIndex === 1) ? 2 : 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Trusted Device"
                                    color: Theme.on_surface
                                    font.bold: true
                                    font.pixelSize: 13
                                }

                                Text {
                                    text: "Auto-connect when nearby"
                                    color: Theme.on_surface_variant
                                    font.pixelSize: 11
                                }
                            }

                            Switch {
                                checked: selectedDevice ? !!selectedDevice.trusted : false
                                onCheckedChanged: {
                                    if (selectedDevice) {
                                        ConfigService.setBluetoothDeviceTrust(selectedDevice.address, checked, refresh);
                                    }
                                }
                            }
                        }
                    }

                    // Audio Profiles & Codecs Section (PipeWire / PulseAudio via wpctl/pactl)
                    ColumnLayout {
                        visible: selectedDevice && selectedDevice.connected && selectedDevice.icon === "audio"
                        width: detailsScrollView.availableWidth > 0 ? detailsScrollView.availableWidth : 348
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "AUDIO CODECS & PROFILES (PipeWire / pactl)"
                            color: Theme.primary
                            font.bold: true
                            font.pixelSize: 11
                            font.family: Theme.fontFamilyDisplay
                        }

                        Repeater {
                            model: selectedDevice && selectedDevice.audio_profiles ? selectedDevice.audio_profiles : []
                            delegate: Rectangle {
                                required property string name
                                required property string description
                                required property string codec_type
                                required property bool available

                                property bool isSelected: selectedDevice && selectedDevice.active_profile === name

                                width: detailsScrollView.availableWidth > 0 ? detailsScrollView.availableWidth : 348
                                Layout.fillWidth: true
                                implicitHeight: 44
                                radius: 12
                                color: isSelected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g, Theme.surface_container_low.b, 0.3)
                                border.color: isSelected ? Theme.primary : "transparent"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: description || name
                                            color: isSelected ? Theme.primary : Theme.on_surface
                                            font.bold: isSelected
                                            font.pixelSize: 12
                                        }

                                        Text {
                                            text: "Profile ID: " + name
                                            color: Theme.on_surface_variant
                                            font.pixelSize: 10
                                            font.family: "Monospace"
                                        }
                                    }

                                    Rectangle {
                                        implicitWidth: 16
                                        implicitHeight: 16
                                        radius: 8
                                        color: isSelected ? Theme.primary : "transparent"
                                        border.color: isSelected ? Theme.primary : Theme.on_surface_variant
                                        border.width: 1.5

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: Theme.on_primary
                                            visible: isSelected
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (selectedDevice) {
                                            var targetAddr = selectedDevice.address;
                                            var targetProf = name;
                                            ConfigService.setBluetoothAudioProfile(targetAddr, targetProf, function() {
                                                refresh();
                                            });
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Device Actions (Disconnect / Unpair)
                    RowLayout {
                        width: detailsScrollView.availableWidth > 0 ? detailsScrollView.availableWidth : 348
                        Layout.fillWidth: true
                        spacing: 12

                        ActionButton {
                            Layout.fillWidth: true
                            text: selectedDevice && selectedDevice.connected ? "Disconnect" : "Connect"
                            iconName: selectedDevice && selectedDevice.connected ? "close" : "bluetooth"
                            variant: selectedDevice && selectedDevice.connected ? "outline" : "primary"
                            isFocused: InputService.isNonMouse && currentView === 1 && detailsFocusIndex === 2
                            onClicked: {
                                if (selectedDevice) {
                                    if (selectedDevice.connected) {
                                        ConfigService.disconnectBluetoothDevice(selectedDevice.address, refresh);
                                    } else {
                                        ConfigService.connectBluetoothDevice(selectedDevice.address, refresh);
                                    }
                                }
                            }
                        }

                        ActionButton {
                            Layout.fillWidth: true
                            text: "Unpair Device"
                            iconName: "close"
                            variant: "danger"
                            isFocused: InputService.isNonMouse && currentView === 1 && detailsFocusIndex === 3
                            onClicked: {
                                if (selectedDevice) {
                                    ConfigService.unpairBluetoothDevice(selectedDevice.address, function() {
                                        currentView = 0;
                                        refresh();
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }

        // PIN / Passkey Authentication Modal Overlay
        Rectangle {
            id: authDialog
            property var authData: null
            property int authFocusIndex: 0
            visible: false

            onVisibleChanged: {
                if (visible) {
                    authFocusIndex = 0;
                    if (pinInput.visible) {
                        pinInput.text = "";
                        pinInput.forceActiveFocus();
                    }
                }
            }

            function acceptAuth() {
                if (authDialog.authData) {
                    var pinVal = pinInput.text;
                    ConfigService.respondBluetoothAuth(authDialog.authData.address, true, pinVal, function() {
                        authDialog.visible = false;
                        refresh();
                    });
                }
            }

            function rejectAuth() {
                if (authDialog.authData) {
                    ConfigService.respondBluetoothAuth(authDialog.authData.address, false, null, function() {
                        authDialog.visible = false;
                        refresh();
                    });
                }
            }

            anchors.fill: parent
            radius: 20
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.96)

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 16

                VectorIcon {
                    name: "bluetooth"
                    color: Theme.primary
                    iconSize: 32
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Pairing Request"
                    color: Theme.on_surface
                    font.bold: true
                    font.pixelSize: 16
                    font.family: Theme.fontFamilyDisplay
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: authDialog.authData ? ("Device: " + authDialog.authData.device_name) : ""
                    color: Theme.on_surface_variant
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignHCenter
                }

                // Display PIN / Passkey
                Text {
                    visible: authDialog.authData && (authDialog.authData.request_type === "display_pin" || authDialog.authData.request_type === "confirm_passkey")
                    text: authDialog.authData && authDialog.authData.passkey ? ("Passkey: " + authDialog.authData.passkey) : (authDialog.authData && authDialog.authData.pin ? ("PIN: " + authDialog.authData.pin) : "")
                    color: Theme.primary
                    font.bold: true
                    font.pixelSize: 20
                    Layout.alignment: Qt.AlignHCenter
                }

                // Glassmorphic PIN Code Input Field
                Rectangle {
                    visible: authDialog.authData && authDialog.authData.request_type === "pin_code"
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: 12
                    color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.7)
                    border.color: (pinInput.activeFocus || authDialog.authFocusIndex === 0) ? Theme.primary : Theme.outline_variant
                    border.width: (pinInput.activeFocus || authDialog.authFocusIndex === 0) ? 2 : 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        VectorIcon {
                            name: "key"
                            color: (pinInput.activeFocus || authDialog.authFocusIndex === 0) ? Theme.primary : Theme.on_surface_variant
                            iconSize: 18
                        }

                        TextInput {
                            id: pinInput
                            Layout.fillWidth: true
                            color: Theme.on_surface
                            font.pixelSize: 13
                            font.family: Theme.fontFamilySans
                            clip: true
                            selectByMouse: true
                            selectedTextColor: Theme.on_primary
                            selectionColor: Theme.primary
                            onAccepted: authDialog.acceptAuth()

                            Text {
                                text: "Enter PIN code (e.g. 0000 or 1234)"
                                color: Theme.on_surface_variant
                                font.pixelSize: 13
                                font.family: Theme.fontFamilySans
                                visible: pinInput.text.length === 0 && !pinInput.activeFocus
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 12
                    Layout.alignment: Qt.AlignHCenter

                    ActionButton {
                        text: "Reject"
                        iconName: "close"
                        variant: "danger"
                        isFocused: authDialog.authFocusIndex === 1
                        onClicked: authDialog.rejectAuth()
                    }

                    ActionButton {
                        text: "Accept"
                        iconName: "bluetooth"
                        variant: "primary"
                        isFocused: authDialog.authFocusIndex === 2
                        onClicked: authDialog.acceptAuth()
                    }
                }
            }
        }
    }
}
