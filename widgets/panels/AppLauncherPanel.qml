import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../../theme"
import "../components"

BaseFlyoutPanel {
    id: flyoutWindow

    title: "Applications"
    iconName: "grid9"
    side: "left"
    cardWidth: 460
    cardHeight: 600
    showSwitch: false
    showRefresh: true
    requiresKeyboardFocus: true

    property string selectedCategory: "All"
    property int selectedIndex: 0

    readonly property var categoryList: [
        { name: "All", icon: "grid9" },
        { name: "Frequent", icon: "fire" },
        { name: "Pinned", icon: "pin" },
        { name: "Internet", icon: "wifi" },
        { name: "Development", icon: "code" },
        { name: "Media", icon: "headphones" },
        { name: "Graphics", icon: "palette" },
        { name: "Utilities", icon: "sliders" },
        { name: "System", icon: "gear" },
        { name: "Office", icon: "folder" },
        { name: "Games", icon: "game" },
        { name: "Unknown", icon: "help" }
    ]

    property bool justOpened: false

    onRefreshClicked: {
        ConfigService.refreshApplications();
    }

    onIsOpenChanged: {
        if (isOpen) {
            justOpened = true;
            justOpenedTimer.restart();
            selectedIndex = 0;
            InputService.useKeyboard();
            searchInput.text = "";
            ConfigService.fetchApplications("", selectedCategory);
            focusTimer.restart();
        }
    }

    Timer {
        id: justOpenedTimer
        interval: 150
        repeat: false
        onTriggered: flyoutWindow.justOpened = false
    }

    Timer {
        id: focusTimer
        interval: 80
        repeat: false
        onTriggered: searchInput.forceFocus()
    }

    function selectCategory(cat) {
        selectedCategory = cat;
        selectedIndex = 0;
        ConfigService.fetchApplications(searchInput.text, cat);
    }

    function cycleCategory(forward) {
        var idx = 0;
        for (var i = 0; i < categoryList.length; i++) {
            if (categoryList[i].name === selectedCategory) {
                idx = i;
                break;
            }
        }
        if (forward) {
            idx = (idx + 1) % categoryList.length;
        } else {
            idx = (idx - 1 + categoryList.length) % categoryList.length;
        }
        selectCategory(categoryList[idx].name);
    }

    function launchSelected() {
        var list = ConfigService.applicationsList || [];
        if (list.length > 0 && selectedIndex >= 0 && selectedIndex < list.length) {
            var item = list[selectedIndex];
            if (item) {
                ConfigService.launchApplication(item.id, item.exec, item.desktop_file);
                flyoutWindow.close();
            }
        }
    }

    function navigateList(delta) {
        InputService.useKeyboard();
        if (appsListView.count > 0) {
            var nextIdx = Math.max(0, Math.min(appsListView.currentIndex + delta, appsListView.count - 1));
            appsListView.currentIndex = nextIdx;
            selectedIndex = nextIdx;
            appsListView.positionViewAtIndex(nextIdx, ListView.Contain);
        }
    }

    function openContextMenuForSelected() {
        var list = ConfigService.applicationsList || [];
        if (list.length > 0 && selectedIndex >= 0 && selectedIndex < list.length) {
            var item = list[selectedIndex];
            if (item) {
                openContextMenuForItem(item);
            }
        }
    }

    function openContextMenuForItem(item) {
        if (!item) return;
        var isPinned = !!item.pinned;
        var items = [
            {
                text: isPinned ? "Unpin from Favorites" : "Pin to Favorites",
                icon: isPinned ? "star" : "pin",
                destructive: false,
                action: function(data) {
                    ConfigService.togglePinApp(data.id, !data.pinned);
                }
            },
            {
                text: "Launch Application",
                icon: "play",
                destructive: false,
                action: function(data) {
                    ConfigService.launchApplication(data.id, data.exec, data.desktop_file);
                    flyoutWindow.close();
                }
            }
        ];
        appContextMenu.openForTarget(items, item, item.name || "Application", item.category || "");
    }

    function openContextMenuForItemAt(x, y, item) {
        if (!item) return;
        var isPinned = !!item.pinned;
        var items = [
            {
                text: isPinned ? "Unpin from Favorites" : "Pin to Favorites",
                icon: isPinned ? "star" : "pin",
                destructive: false,
                action: function(data) {
                    ConfigService.togglePinApp(data.id, !data.pinned);
                }
            },
            {
                text: "Launch Application",
                icon: "play",
                destructive: false,
                action: function(data) {
                    ConfigService.launchApplication(data.id, data.exec, data.desktop_file);
                    flyoutWindow.close();
                }
            }
        ];
        appContextMenu.openAt(x, y, items, item, item.name || "Application", item.category || "");
    }

    // Connect to global InputService navigation signals (Gamepads & Keyboard)
    Connections {
        target: InputService
        enabled: flyoutWindow.isOpen

        function onNavUp() {
            if (appContextMenu.isOpen) {
                appContextMenu.navigate(-1);
            } else {
                flyoutWindow.navigateList(-1);
            }
        }
        function onNavDown() {
            if (appContextMenu.isOpen) {
                appContextMenu.navigate(1);
            } else {
                flyoutWindow.navigateList(1);
            }
        }
        function onNavLeft() {
            if (!appContextMenu.isOpen) {
                flyoutWindow.cycleCategory(false);
            }
        }
        function onNavRight() {
            if (!appContextMenu.isOpen) {
                flyoutWindow.cycleCategory(true);
            }
        }
        function onNavNextTab() {
            if (!appContextMenu.isOpen) {
                flyoutWindow.cycleCategory(true);
            }
        }
        function onNavPrevTab() {
            if (!appContextMenu.isOpen) {
                flyoutWindow.cycleCategory(false);
            }
        }
        function onNavContextMenu() {
            flyoutWindow.openContextMenuForSelected();
        }
        function onNavSelect() {
            if (appContextMenu.isOpen) {
                appContextMenu.selectCurrent();
            } else if (!flyoutWindow.justOpened) {
                flyoutWindow.launchSelected();
            }
        }
        function onNavBack() {
            if (appContextMenu.isOpen) {
                appContextMenu.close();
            } else if (searchInput.text.length > 0) {
                searchInput.text = "";
            } else if (selectedCategory !== "All" || selectedIndex > 0) {
                selectedCategory = "All";
                selectedIndex = 0;
            } else {
                InputService.closeOrReturn(flyoutWindow);
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // 1. Top Horizontal Scrollable Category Filter Pills
        ScrollView {
            Layout.fillWidth: true
            implicitHeight: 34
            contentHeight: 34
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            clip: true

            Row {
                spacing: 6

                Repeater {
                    model: flyoutWindow.categoryList

                    delegate: PillBadge {
                        required property var modelData
                        text: modelData.name
                        iconName: modelData.icon
                        isSelected: selectedCategory === modelData.name
                        pillHeight: 30
                        onClicked: selectCategory(modelData.name)
                    }
                }
            }
        }

        // 2. Quick Access / Recent Apps Section (shown only when search is empty and category is "All")
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: searchInput.text === "" && selectedCategory === "All" && (ConfigService.recentApplicationsList && ConfigService.recentApplicationsList.length > 0)

            Text {
                text: "FREQUENTLY USED"
                color: Theme.primary
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.2
                font.family: Theme.fontFamilyDisplay
                Layout.leftMargin: 4
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: (ConfigService.recentApplicationsList || []).slice(0, 5)

                    delegate: PanelCardItem {
                        id: recentCard
                        required property var modelData

                        Layout.fillWidth: true
                        itemHeight: 58
                        showActiveIndicator: false

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            AppIcon {
                                icon: modelData.icon || ""
                                appClass: modelData.id || modelData.name || ""
                                appTitle: modelData.name || ""
                                iconSize: 24
                                isHovered: recentCard.isHighlighted
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: modelData.name || ""
                                color: recentCard.isHighlighted ? Theme.primary : Theme.on_surface
                                font.pixelSize: 10
                                font.bold: true
                                font.family: Theme.fontFamilyDisplay
                                elide: Text.ElideRight
                                Layout.maximumWidth: 70
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        onClicked: {
                            ConfigService.launchApplication(modelData.id, modelData.exec, modelData.desktop_file);
                            flyoutWindow.close();
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                Layout.topMargin: 4
                Layout.bottomMargin: 2
            }
        }

        // 3. Main Applications List View (Fills available space)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: appsListView
                anchors.fill: parent
                clip: true
                spacing: 6
                model: ConfigService.applicationsList || []
                currentIndex: selectedIndex
                highlightMoveDuration: 0
                cacheBuffer: 800

                onCurrentIndexChanged: {
                    selectedIndex = currentIndex;
                }

                delegate: PanelCardItem {
                    id: appCard
                    required property var modelData
                    required property int index

                    width: appsListView.width - 10
                    itemHeight: 52
                    isCurrent: appsListView.currentIndex === index

                    onItemHovered: {
                        appsListView.currentIndex = index;
                        selectedIndex = index;
                    }

                    onRightClickedWithPos: (mx, my) => {
                        appsListView.currentIndex = index;
                        selectedIndex = index;
                        var itemData = modelData;
                        var pos = appCard.mapToItem(appContextMenu, mx, my);
                        Qt.callLater(function() {
                            flyoutWindow.openContextMenuForItemAt(pos.x, pos.y, itemData);
                        });
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 12

                        AppIcon {
                            icon: modelData.icon || ""
                            appClass: modelData.id || modelData.name || ""
                            appTitle: modelData.name || ""
                            iconSize: 32
                            isCurrent: appCard.isHighlighted
                            isHovered: false
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // App Details
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            RowLayout {
                                spacing: 6
                                Layout.fillWidth: true

                                Text {
                                    text: modelData.name || "Application"
                                    color: appCard.isHighlighted ? Theme.primary : Theme.on_surface
                                    font.bold: true
                                    font.pixelSize: 13
                                    font.family: Theme.fontFamilyDisplay
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                PillBadge {
                                    visible: modelData.category !== "" && modelData.category !== undefined
                                    text: modelData.category || ""
                                    isInteractive: false
                                    pillHeight: 18
                                    fontSize: 10
                                    horizontalPadding: 6
                                }
                            }

                            Text {
                                text: modelData.generic_name || modelData.description || modelData.exec || ""
                                color: Theme.on_surface_variant
                                font.pixelSize: 11
                                font.family: Theme.fontFamilyDisplay
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Pin / Favorite Button
                        SquareButton {
                            iconName: modelData.pinned ? "star" : "pin"
                            iconSize: 14
                            btnSize: 28
                            iconColor: modelData.pinned ? Theme.primary : Theme.on_surface_variant
                            opacity: (modelData.pinned || appCard.isHighlighted) ? 1.0 : 0.0
                            enabled: opacity > 0.1
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            onClicked: {
                                ConfigService.togglePinApp(modelData.id, !modelData.pinned);
                            }
                        }
                    }

                    onClicked: {
                        ConfigService.launchApplication(modelData.id, modelData.exec, modelData.desktop_file);
                        flyoutWindow.close();
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    id: appScrollBar
                    active: true
                    width: 5
                    policy: ScrollBar.AsNeeded
                    anchors.right: parent.right

                    contentItem: Rectangle {
                        implicitWidth: 5
                        radius: 2.5
                        color: appScrollBar.pressed 
                            ? Theme.primary 
                            : (appScrollBar.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.7) : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.25))
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // Modular Empty State
            EmptyState {
                anchors.centerIn: parent
                visible: (ConfigService.applicationsList || []).length === 0 && !ConfigService.isAppLauncherLoading
                iconName: "search"
                title: "No applications found"
                description: searchInput.text !== "" ? ("No results matching \"" + searchInput.text + "\"") : "No applications in this category"
            }
        }

        // 4. Bottom Search Bar Box
        SearchInput {
            id: searchInput
            Layout.fillWidth: true
            placeholder: "Search applications (e.g. Firefox, Terminal)..."
            debounceMs: 40
            onTextEdited: query => {
                ConfigService.fetchApplications(query, selectedCategory);
            }
            onReturnPressed: {
                if (appContextMenu.isOpen) {
                    appContextMenu.selectCurrent();
                } else {
                    flyoutWindow.launchSelected();
                }
            }
            onDownPressed: {
                if (appContextMenu.isOpen) {
                    appContextMenu.navigate(1);
                } else {
                    flyoutWindow.navigateList(1);
                }
            }
            onUpPressed: {
                if (appContextMenu.isOpen) {
                    appContextMenu.navigate(-1);
                } else {
                    flyoutWindow.navigateList(-1);
                }
            }
            onLeftPressed: {
                if (searchInput.text === "" && !appContextMenu.isOpen) {
                    flyoutWindow.cycleCategory(false);
                }
            }
            onRightPressed: {
                if (searchInput.text === "" && !appContextMenu.isOpen) {
                    flyoutWindow.cycleCategory(true);
                }
            }
            onEscapePressed: {
                if (appContextMenu.isOpen) {
                    appContextMenu.close();
                } else {
                    InputService.triggerBack();
                }
            }
        }

        // 5. Bottom Footer Status Bar
        Rectangle {
            Layout.fillWidth: true
            height: 24
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Text {
                    text: ((ConfigService.applicationsList || []).length) + " applications"
                    color: Theme.on_surface_variant
                    font.pixelSize: 10
                    font.family: Theme.fontFamilyDisplay
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: InputService.isGamepad
                        ? "A Launch  •  > Menu  •  B Back  •  LB/RB Categories"
                        : "Press ↵ to launch  •  Alt / Right-click for Menu  •  Esc to close"
                    color: Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.6)
                    font.pixelSize: 10
                    font.family: Theme.fontFamilyDisplay
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    // Modular Common Context Menu
    ContextMenu {
        id: appContextMenu
    }
}
