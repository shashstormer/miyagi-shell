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

    readonly property var allMenuItems: [
        {
            id: "bluetooth",
            name: "Bluetooth",
            description: "Paired devices & bluetooth connections",
            icon: "bluetooth",
            badge: ConfigService.bluetoothPowered ? (ConfigService.bluetoothConnected ? "Connected" : "On") : "Off",
            action: function() {
                if (selectorWindow.bluetoothPanelRef) InputService.openPanel(selectorWindow.bluetoothPanelRef, selectorWindow);
            }
        },
        {
            id: "wifi",
            name: "Wi-Fi & Network",
            description: "Wireless networks & connections",
            icon: "wifi",
            badge: ConfigService.wifiEnabled ? (ConfigService.wifiSsid ? ConfigService.wifiSsid : "On") : "Off",
            action: function() {
                if (selectorWindow.wifiPanelRef) InputService.openPanel(selectorWindow.wifiPanelRef, selectorWindow);
            }
        },
        {
            id: "microphone",
            name: "Microphone",
            description: "Audio input & microphone control",
            icon: "mic",
            badge: ConfigService.micMuted ? "Muted" : ((ConfigService.micVolume !== undefined ? ConfigService.micVolume : 100) + "%"),
            action: function() {
                if (selectorWindow.microphonePanelRef) InputService.openPanel(selectorWindow.microphonePanelRef, selectorWindow);
            }
        },
        {
            id: "volume",
            name: "Volume & Sound",
            description: "Audio output & playback devices",
            icon: "volume",
            badge: ConfigService.audioMuted ? "Muted" : ((ConfigService.audioVolume !== undefined ? ConfigService.audioVolume : 100) + "%"),
            action: function() {
                if (selectorWindow.volumePanelRef) InputService.openPanel(selectorWindow.volumePanelRef, selectorWindow);
            }
        },
        {
            id: "launcher",
            name: "Application Launcher",
            description: "Search & launch desktop applications",
            icon: "grid9",
            badge: "Apps",
            action: function() {
                if (selectorWindow.appLauncherPanelRef) InputService.openPanel(selectorWindow.appLauncherPanelRef, selectorWindow);
            }
        },
        {
            id: "notifications",
            name: "Notifications",
            description: "Notification center & history drawer",
            icon: "bell",
            badge: typeof notificationPanel !== "undefined" && notificationPanel && notificationPanel.unreadCount > 0 ? (notificationPanel.unreadCount + " New") : "Drawer",
            action: function() {
                if (selectorWindow.notificationPanelRef) InputService.openPanel(selectorWindow.notificationPanelRef, selectorWindow);
            }
        },
        {
            id: "battery",
            name: "Battery & Power",
            description: "Battery health & energy profiles",
            icon: "battery",
            badge: (ConfigService.batteryPercentage !== undefined ? ConfigService.batteryPercentage : 100) + "%",
            action: function() {
                if (selectorWindow.batteryPanelRef) InputService.openPanel(selectorWindow.batteryPanelRef, selectorWindow);
            }
        },
        {
            id: "calendar",
            name: "Calendar & Date",
            description: "Calendar, events & time schedule",
            icon: "calendar",
            badge: Qt.formatDateTime(new Date(), "MMM d"),
            action: function() {
                if (selectorWindow.calendarPanelRef) InputService.openPanel(selectorWindow.calendarPanelRef, selectorWindow);
            }
        },
        {
            id: "settings",
            name: "Settings",
            description: "System & desktop configuration",
            icon: "settings",
            badge: "Config",
            action: function() {
                if (selectorWindow.settingsPanelRef) InputService.openPanel(selectorWindow.settingsPanelRef, selectorWindow);
            }
        }
    ]

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
            if (selectedIndex < 0 || selectedIndex >= allMenuItems.length) {
                selectedIndex = 0;
            }
            menuListView.currentIndex = selectedIndex;
            menuListView.positionViewAtIndex(selectedIndex, ListView.Contain);
            InputService.useKeyboard();
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 80
        repeat: false
        onTriggered: searchInput.forceFocus()
    }

    function selectCurrent() {
        var currentIdx = (menuListView.currentIndex >= 0 && menuListView.currentIndex < filteredItems.length)
            ? menuListView.currentIndex
            : selectedIndex;
        if (filteredItems.length > 0 && currentIdx >= 0 && currentIdx < filteredItems.length) {
            var item = filteredItems[currentIdx];
            selectorWindow.close();
            if (item && item.action) {
                var act = item.action;
                Qt.callLater(function() {
                    act();
                });
            }
        }
    }

    function navigate(delta) {
        InputService.useKeyboard();
        var count = filteredItems.length;
        if (count > 0) {
            var current = (menuListView.currentIndex >= 0 && menuListView.currentIndex < count)
                ? menuListView.currentIndex
                : selectedIndex;
            var nextIdx = (current + (delta % count) + count) % count;
            selectedIndex = nextIdx;
            menuListView.currentIndex = nextIdx;
            menuListView.positionViewAtIndex(nextIdx, ListView.Contain);
        }
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

                onCurrentIndexChanged: {
                    selectorWindow.selectedIndex = currentIndex;
                }

                delegate: PanelCardItem {
                    id: menuCard
                    required property var modelData
                    required property int index

                    width: menuListView.width - 10
                    itemHeight: 50
                    isCurrent: menuListView.currentIndex === index

                    onItemHovered: {
                        menuListView.currentIndex = index;
                        selectorWindow.selectedIndex = index;
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
                                    visible: modelData.badge !== "" && modelData.badge !== undefined
                                    text: modelData.badge || ""
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
                        selectorWindow.close();
                        if (modelData.action) {
                            modelData.action();
                        }
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
                menuListView.currentIndex = 0;
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
