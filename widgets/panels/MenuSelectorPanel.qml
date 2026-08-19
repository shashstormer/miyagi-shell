import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../../theme"
import "../components"

BaseFlyoutPanel {
    id: selectorWindow

    title: "Quick Menu"
    iconName: "sliders"
    side: "left"
    cardWidth: 420
    cardHeight: 570
    showSwitch: false
    showRefresh: false
    requiresKeyboardFocus: true

    property int selectedIndex: 0
    property string searchQuery: ""

    // References to other panels
    property var bluetoothPanelRef: typeof bluetoothPanel !== "undefined" ? bluetoothPanel : null
    property var wifiPanelRef: typeof wifiPanel !== "undefined" ? wifiPanel : null
    property var microphonePanelRef: typeof microphonePanel !== "undefined" ? microphonePanel : null
    property var volumePanelRef: typeof volumePanel !== "undefined" ? volumePanel : null
    property var appLauncherPanelRef: typeof appLauncherPanel !== "undefined" ? appLauncherPanel : null
    property var notificationPanelRef: typeof notificationPanel !== "undefined" ? notificationPanel : null
    property var batteryPanelRef: typeof batteryPanel !== "undefined" ? batteryPanel : null
    property var calendarPanelRef: typeof calendarPanel !== "undefined" ? calendarPanel : null
    property var settingsPanelRef: typeof settingsPanel !== "undefined" ? settingsPanel : null
    property var windowSwitcherPanelRef: typeof windowSwitcherPanel !== "undefined" ? windowSwitcherPanel : null

    // Static stable definition of all menu items (no reactive bindings in the array itself)
    readonly property var allMenuItems: [
        {
            id: "windows",
            name: "Focus Application",
            description: "Switch & manage windows across all workspaces",
            icon: "window"
        },
        {
            id: "bluetooth",
            name: "Bluetooth",
            description: "Paired devices & bluetooth connections",
            icon: "bluetooth"
        },
        {
            id: "wifi",
            name: "Wi-Fi & Network",
            description: "Wireless networks & connections",
            icon: "wifi"
        },
        {
            id: "microphone",
            name: "Microphone",
            description: "Audio input & microphone control",
            icon: "mic"
        },
        {
            id: "volume",
            name: "Volume & Sound",
            description: "Audio output & playback devices",
            icon: "volume"
        },
        {
            id: "launcher",
            name: "Application Launcher",
            description: "Search & launch desktop applications",
            icon: "grid9"
        },
        {
            id: "notifications",
            name: "Notifications",
            description: "Notification center & history drawer",
            icon: "bell"
        },
        {
            id: "battery",
            name: "Battery & Power",
            description: "Battery health & energy profiles",
            icon: "battery"
        },
        {
            id: "calendar",
            name: "Calendar & Date",
            description: "Calendar, events & time schedule",
            icon: "calendar"
        },
        {
            id: "settings",
            name: "Settings",
            description: "System & desktop configuration",
            icon: "settings"
        }
    ]

    function getItemBadge(itemId) {
        if (itemId === "windows") {
            return (ConfigService.windowsList ? ConfigService.windowsList.length : 0) + " Windows";
        }
        if (itemId === "bluetooth") {
            return ConfigService.bluetoothPowered ? (ConfigService.bluetoothConnected ? "Connected" : "On") : "Off";
        }
        if (itemId === "wifi") {
            return ConfigService.wifiEnabled ? (ConfigService.wifiSsid ? ConfigService.wifiSsid : "On") : "Off";
        }
        if (itemId === "microphone") {
            return ConfigService.micMuted ? "Muted" : ((ConfigService.micVolume !== undefined ? ConfigService.micVolume : 100) + "%");
        }
        if (itemId === "volume") {
            return ConfigService.audioMuted ? "Muted" : ((ConfigService.audioVolume !== undefined ? ConfigService.audioVolume : 100) + "%");
        }
        if (itemId === "launcher") {
            return "Apps";
        }
        if (itemId === "notifications") {
            return typeof notificationPanel !== "undefined" && notificationPanel && notificationPanel.unreadCount > 0 ? (notificationPanel.unreadCount + " New") : "Drawer";
        }
        if (itemId === "battery") {
            return (ConfigService.batteryPercentage !== undefined ? ConfigService.batteryPercentage : 100) + "%";
        }
        if (itemId === "calendar") {
            return Qt.formatDateTime(new Date(), "MMM d");
        }
        if (itemId === "settings") {
            return "Config";
        }
        return "";
    }

    function triggerAction(itemId) {
        selectorWindow.close();
        Qt.callLater(function() {
            if (itemId === "windows" && selectorWindow.windowSwitcherPanelRef) InputService.openPanel(selectorWindow.windowSwitcherPanelRef, selectorWindow);
            else if (itemId === "bluetooth" && selectorWindow.bluetoothPanelRef) InputService.openPanel(selectorWindow.bluetoothPanelRef, selectorWindow);
            else if (itemId === "wifi" && selectorWindow.wifiPanelRef) InputService.openPanel(selectorWindow.wifiPanelRef, selectorWindow);
            else if (itemId === "microphone" && selectorWindow.microphonePanelRef) InputService.openPanel(selectorWindow.microphonePanelRef, selectorWindow);
            else if (itemId === "volume" && selectorWindow.volumePanelRef) InputService.openPanel(selectorWindow.volumePanelRef, selectorWindow);
            else if (itemId === "launcher" && selectorWindow.appLauncherPanelRef) InputService.openPanel(selectorWindow.appLauncherPanelRef, selectorWindow);
            else if (itemId === "notifications" && selectorWindow.notificationPanelRef) InputService.openPanel(selectorWindow.notificationPanelRef, selectorWindow);
            else if (itemId === "battery" && selectorWindow.batteryPanelRef) InputService.openPanel(selectorWindow.batteryPanelRef, selectorWindow);
            else if (itemId === "calendar" && selectorWindow.calendarPanelRef) InputService.openPanel(selectorWindow.calendarPanelRef, selectorWindow);
            else if (itemId === "settings" && selectorWindow.settingsPanelRef) InputService.openPanel(selectorWindow.settingsPanelRef, selectorWindow);
        });
    }

    readonly property var filteredItems: {
        var q = searchQuery.toLowerCase().trim();
        if (!q) return allMenuItems;
        return allMenuItems.filter(function(item) {
            return item.name.toLowerCase().indexOf(q) !== -1 ||
                   item.description.toLowerCase().indexOf(q) !== -1 ||
                   item.id.toLowerCase().indexOf(q) !== -1;
        });
    }

    onIsOpenChanged: {
        if (isOpen) {
            searchQuery = "";
            searchInput.text = "";
            selectedIndex = 0;
            InputService.useKeyboard();
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        repeat: false
        onTriggered: {
            if (selectorWindow.isOpen) {
                searchInput.forceFocus();
            }
        }
    }

    function selectCurrent() {
        if (filteredItems.length === 0) return;
        var idx = Math.max(0, Math.min(selectedIndex, filteredItems.length - 1));
        var item = filteredItems[idx];
        if (item) {
            triggerAction(item.id);
        }
    }

    function navigate(delta) {
        InputService.useKeyboard();
        var count = filteredItems.length;
        if (count <= 0) return;
        var nextIdx = (selectedIndex + (delta % count) + count) % count;
        selectedIndex = nextIdx;
        menuListView.positionViewAtIndex(nextIdx, ListView.Contain);
    }

    // Connect to global InputService navigation signals
    Connections {
        target: InputService
        enabled: selectorWindow.isOpen

        function onNavUp() {
            selectorWindow.navigate(-1);
        }
        function onNavDown() {
            selectorWindow.navigate(1);
        }
        function onNavSelect() {
            selectorWindow.selectCurrent();
        }
        function onNavBack() {
            if (searchQuery.length > 0) {
                searchQuery = "";
                searchInput.text = "";
            } else {
                InputService.closeOrReturn(selectorWindow);
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // 1. Menu Items List View
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: menuListView
                anchors.fill: parent
                clip: true
                spacing: 6
                model: selectorWindow.filteredItems
                currentIndex: selectorWindow.selectedIndex
                highlightMoveDuration: 0

                delegate: PanelCardItem {
                    id: menuCard
                    required property var modelData
                    required property int index

                    width: menuListView.width - 10
                    itemHeight: 50
                    isCurrent: selectorWindow.selectedIndex === index

                    onItemHovered: {
                        if (InputService.isMouse) {
                            selectorWindow.selectedIndex = index;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        spacing: 12

                        // Icon Container
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 8
                            color: menuCard.isHighlighted ? Theme.primary : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.8)
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 150 } }

                            VectorIcon {
                                anchors.centerIn: parent
                                name: modelData.icon || "settings"
                                iconSize: 17
                                color: menuCard.isHighlighted ? Theme.on_primary : Theme.primary
                            }
                        }

                        // Text Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            RowLayout {
                                spacing: 6
                                Layout.fillWidth: true

                                Text {
                                    text: modelData.name || ""
                                    color: menuCard.isHighlighted ? Theme.primary : Theme.on_surface
                                    font.bold: true
                                    font.pixelSize: 13
                                    font.family: Theme.fontFamilyDisplay
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                PillBadge {
                                    readonly property string badgeText: selectorWindow.getItemBadge(modelData.id)
                                    visible: badgeText !== ""
                                    text: badgeText
                                    isInteractive: false
                                    pillHeight: 18
                                    fontSize: 10
                                    horizontalPadding: 6
                                }
                            }

                            Text {
                                text: modelData.description || ""
                                color: Theme.on_surface_variant
                                font.pixelSize: 11
                                font.family: Theme.fontFamilyDisplay
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Forward Arrow Indicator
                        VectorIcon {
                            name: "chevron-right"
                            iconSize: 14
                            color: menuCard.isHighlighted ? Theme.primary : Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.5)
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    onClicked: {
                        selectorWindow.triggerAction(modelData.id);
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    id: menuScrollBar
                    active: true
                    width: 5
                    policy: ScrollBar.AsNeeded
                    anchors.right: parent.right

                    contentItem: Rectangle {
                        implicitWidth: 5
                        radius: 2.5
                        color: menuScrollBar.pressed 
                            ? Theme.primary 
                            : (menuScrollBar.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.7) : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.25))
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            EmptyState {
                anchors.centerIn: parent
                visible: selectorWindow.filteredItems.length === 0
                iconName: "search"
                title: "No menu found"
                description: "No quick menu matching \"" + selectorWindow.searchQuery + "\""
            }
        }

        // 2. Bottom Search Filter Input
        SearchInput {
            id: searchInput
            Layout.fillWidth: true
            placeholder: "Filter menus (e.g. Wifi, Bluetooth, Volume, Settings)..."
            debounceMs: 20
            onTextEdited: query => {
                selectorWindow.searchQuery = query;
                selectorWindow.selectedIndex = 0;
            }
            onReturnPressed: selectorWindow.selectCurrent()
            onDownPressed: selectorWindow.navigate(1)
            onUpPressed: selectorWindow.navigate(-1)
            onEscapePressed: InputService.triggerBack()
        }

        // 3. Footer Navigation Status Bar
        Rectangle {
            Layout.fillWidth: true
            height: 24
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Text {
                    text: selectorWindow.filteredItems.length + " options"
                    color: Theme.on_surface_variant
                    font.pixelSize: 10
                    font.family: Theme.fontFamilyDisplay
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Press ↵ Enter to open  •  Esc to close"
                    color: Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.6)
                    font.pixelSize: 10
                    font.family: Theme.fontFamilyDisplay
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
