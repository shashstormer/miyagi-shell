import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../theme"
import "./components"
import "./settings"

BaseDialogPanel {
    id: root

    title: "Settings"
    dialogWidth: 920
    dialogHeight: 600
    showCloseButton: true
    showFooter: true
    saveButtonText: "SAVE & SYNC"
    isSaveFocused: (root.focusZone === 2)

    onSaved: {
        ConfigService.saveConfig();
        root.close();
    }

    function open() {
        InputService.closeOtherPanels(root);
        InputService.lockModality(InputService.mode);
        ConfigService.fetchShadersStatus();
        ConfigService.fetchPowerProfile();
        ConfigService.fetchBatteryStatus();
        ConfigService.fetchNotificationPreferences();
        ConfigService.fetchNotificationStats();
        ConfigService.fetchApplications();
        ConfigService.fetchConfig();
        ConfigService.fetchAllSystemStatus();
        focusZone = 0;
        contentFocusIndex = 0;
        contentActionIndex = 0;
        isOpen = true;
    }

    Connections {
        target: InputService

        function onRequestOpenSettings() {
            root.open();
        }

        function onRequestToggleSettings() {
            if (root.isOpen) root.close();
            else root.open();
        }

        function onRequestCloseSettings() {
            root.close();
        }
    }

    property int activeCategoryIndex: 0
    // 0 = Sidebar, 1 = Content, 2 = Footer Save Button
    property int focusZone: 0
    property int contentFocusIndex: 0
    property int contentActionIndex: 0

    onContentFocusIndexChanged: {
        if (focusZone === 1 && contentScrollView.contentHeight > contentScrollView.height) {
            var totalItems = getContentItemCount();
            if (totalItems > 1) {
                var targetRatio = Math.max(0, Math.min(1, contentFocusIndex / (totalItems - 1)));
                contentScrollView.ScrollBar.vertical.position = targetRatio * (1.0 - contentScrollView.ScrollBar.vertical.size);
            }
        }
    }

    readonly property var categories: [
        { id: "display", label: "Display", icon: "sun" },
        { id: "sound", label: "Sound", icon: "audio" },
        { id: "power", label: "Battery & Power", icon: "battery" },
        { id: "network", label: "Network", icon: "wifi" },
        { id: "bluetooth", label: "Bluetooth", icon: "bluetooth" },
        { id: "notifications", label: "Notifications", icon: "bell" },
        { id: "shell", label: "Shell & Desktop", icon: "sliders" },
        { id: "apps", label: "Applications", icon: "grid9" },
        { id: "about", label: "System & About", icon: "info" }
    ]

    function getCurrentView() {
        if (activeCategoryIndex === 0) return displayView;
        if (activeCategoryIndex === 1) return soundView;
        if (activeCategoryIndex === 2) return batteryView;
        if (activeCategoryIndex === 3) return networkView;
        if (activeCategoryIndex === 4) return bluetoothView;
        if (activeCategoryIndex === 5) return notifView;
        if (activeCategoryIndex === 6) return shellView;
        if (activeCategoryIndex === 7) return appsView;
        return aboutView;
    }

    function getContentItemCount() {
        var v = getCurrentView();
        if (v && typeof v.getItemCount === "function") {
            return v.getItemCount();
        }
        return 0;
    }

    function navigateVertical(delta) {
        InputService.useKeyboard();
        if (focusZone === 0) {
            // Sidebar Navigation
            var nextCat = (activeCategoryIndex + delta + categories.length) % categories.length;
            activeCategoryIndex = nextCat;
            contentFocusIndex = 0;
            contentActionIndex = 0;
            onCategoryChanged(categories[nextCat].id);
        } else if (focusZone === 1) {
            // Content Navigation
            var maxItems = getContentItemCount();
            if (maxItems <= 0) {
                if (delta > 0) focusZone = 2;
                return;
            }
            var nextIdx = contentFocusIndex + delta;
            if (nextIdx < 0) {
                focusZone = 0; // Return to sidebar
            } else if (nextIdx >= maxItems) {
                focusZone = 2; // Jump to footer save button
            } else {
                contentFocusIndex = nextIdx;
                contentActionIndex = 0;
            }
        } else if (focusZone === 2) {
            // Footer Save Button Navigation
            if (delta < 0) {
                focusZone = 1;
                contentFocusIndex = Math.max(0, getContentItemCount() - 1);
            }
        }
    }

    function navigateHorizontal(delta) {
        InputService.useKeyboard();
        if (focusZone === 0) {
            if (delta > 0) {
                // Move from Sidebar to Content
                focusZone = 1;
                contentFocusIndex = 0;
                contentActionIndex = 0;
            }
        } else if (focusZone === 1) {
            if (delta < 0 && contentActionIndex === 0) {
                var v = getCurrentView();
                // Check if current view handles horizontal
                if (v && typeof v.handleHorizontal === "function") {
                    v.handleHorizontal(delta);
                }
            } else {
                var cv = getCurrentView();
                if (cv && typeof cv.handleHorizontal === "function") {
                    cv.handleHorizontal(delta);
                }
            }
        } else if (focusZone === 2) {
            if (delta < 0) {
                focusZone = 0;
            }
        }
    }

    function activateSelected() {
        InputService.useKeyboard();
        if (focusZone === 0) {
            focusZone = 1;
            contentFocusIndex = 0;
            contentActionIndex = 0;
        } else if (focusZone === 1) {
            var v = getCurrentView();
            if (v && typeof v.triggerItem === "function") {
                v.triggerItem();
            }
        } else if (focusZone === 2) {
            ConfigService.saveConfig();
            root.close();
        }
    }

    function cycleCategory(delta) {
        InputService.useKeyboard();
        var nextCat = (activeCategoryIndex + delta + categories.length) % categories.length;
        activeCategoryIndex = nextCat;
        contentFocusIndex = 0;
        contentActionIndex = 0;
        onCategoryChanged(categories[nextCat].id);
    }

    function onCategoryChanged(catId) {
        if (catId === "display") {
            ConfigService.fetchGammastepStatus();
            ConfigService.fetchGammastepConfig();
        } else if (catId === "sound") {
            ConfigService.fetchAudioStatus();
            ConfigService.fetchMicStatus();
        } else if (catId === "power") {
            ConfigService.fetchBatteryStatus();
            ConfigService.fetchPowerProfile();
        } else if (catId === "network") {
            ConfigService.fetchWifiStatus();
        } else if (catId === "bluetooth") {
            ConfigService.fetchBluetoothStatus();
        } else if (catId === "notifications") {
            ConfigService.fetchNotificationPreferences();
            ConfigService.fetchNotificationStats();
        } else if (catId === "apps") {
            ConfigService.fetchApplications();
        }
    }

    // Keyboard & Gamepad Universal Navigation Connections
    Connections {
        target: InputService
        enabled: root.isOpen

        function onNavUp() { root.navigateVertical(-1); }
        function onNavDown() { root.navigateVertical(1); }
        function onNavLeft() { root.navigateHorizontal(-1); }
        function onNavRight() { root.navigateHorizontal(1); }
        function onNavSelect() { root.activateSelected(); }
        function onNavBack() {
            if (root.focusZone > 0) {
                root.focusZone = 0;
            } else {
                if (!InputService.closeOrReturn(root)) {
                    root.close();
                }
            }
        }
        function onNavNextTab() { root.cycleCategory(1); }
        function onNavPrevTab() { root.cycleCategory(-1); }
    }

    // Main Body: Left Sidebar + Right Content Area
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ==========================================
        // LEFT SIDEBAR NAVIGATION
        // ==========================================
        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 3

                Repeater {
                    model: root.categories
                    delegate: SidebarNavItem {
                        required property int index
                        required property var modelData

                        iconName: modelData.icon
                        label: modelData.label
                        isSelected: index === root.activeCategoryIndex
                        isFocused: (root.focusZone === 0 && index === root.activeCategoryIndex)

                        onClicked: {
                            root.activeCategoryIndex = index;
                            root.focusZone = 0;
                            root.onCategoryChanged(modelData.id);
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // Vertical Divider
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 1
            color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
        }

        // ==========================================
        // RIGHT SCROLLABLE CONTENT AREA
        // ==========================================
        ScrollView {
            id: contentScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: contentScrollView.availableWidth > 40 ? (contentScrollView.availableWidth - 28) : 660
                x: 14
                spacing: 12

                DisplaySettingsView {
                    id: displayView
                    visible: root.activeCategoryIndex === 0
                    focusIndex: (root.focusZone === 1 && root.activeCategoryIndex === 0) ? root.contentFocusIndex : -1
                    actionIndex: root.contentActionIndex
                }

                SoundSettingsView {
                    id: soundView
                    visible: root.activeCategoryIndex === 1
                    focusIndex: (root.focusZone === 1 && root.activeCategoryIndex === 1) ? root.contentFocusIndex : -1
                    actionIndex: root.contentActionIndex
                }

                BatterySettingsView {
                    id: batteryView
                    visible: root.activeCategoryIndex === 2
                    focusIndex: (root.focusZone === 1 && root.activeCategoryIndex === 2) ? root.contentFocusIndex : -1
                    actionIndex: root.contentActionIndex
                }

                NetworkSettingsView {
                    id: networkView
                    visible: root.activeCategoryIndex === 3
                    focusIndex: (root.focusZone === 1 && root.activeCategoryIndex === 3) ? root.contentFocusIndex : -1
                    actionIndex: root.contentActionIndex
                }

                BluetoothSettingsView {
                    id: bluetoothView
                    visible: root.activeCategoryIndex === 4
                    focusIndex: (root.focusZone === 1 && root.activeCategoryIndex === 4) ? root.contentFocusIndex : -1
                    actionIndex: root.contentActionIndex
                }

                NotificationSettingsView {
                    id: notifView
                    visible: root.activeCategoryIndex === 5
                    focusIndex: (root.focusZone === 1 && root.activeCategoryIndex === 5) ? root.contentFocusIndex : -1
                    actionIndex: root.contentActionIndex
                }

                ShellSettingsView {
                    id: shellView
                    visible: root.activeCategoryIndex === 6
                    focusIndex: (root.focusZone === 1 && root.activeCategoryIndex === 6) ? root.contentFocusIndex : -1
                    actionIndex: root.contentActionIndex
                }

                AppsSettingsView {
                    id: appsView
                    visible: root.activeCategoryIndex === 7
                    focusIndex: (root.focusZone === 1 && root.activeCategoryIndex === 7) ? root.contentFocusIndex : -1
                    actionIndex: root.contentActionIndex
                }

                AboutSettingsView {
                    id: aboutView
                    visible: root.activeCategoryIndex === 8
                    focusIndex: (root.focusZone === 1 && root.activeCategoryIndex === 8) ? root.contentFocusIndex : -1
                    actionIndex: root.contentActionIndex
                }
            }
        }
    }
}
