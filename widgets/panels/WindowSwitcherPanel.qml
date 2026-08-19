import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../../theme"
import "../components"

BaseFlyoutPanel {
    id: flyoutWindow

    title: "Focus Application"
    iconName: "grid"
    side: "left"
    cardWidth: 460
    cardHeight: 620
    showSwitch: false
    showRefresh: true
    requiresKeyboardFocus: true

    property string selectedFilter: "All"
    property int selectedIndex: 0
    property string searchQuery: ""

    readonly property var allWindows: ConfigService.windowsList || []

    // Workspace filter list
    readonly property var filterCategories: [
        { id: "All", name: "All Windows", icon: "grid" },
        { id: "ActiveWS", name: "Active WS (" + (ConfigService.activeWorkspaceId || 1) + ")", icon: "layers" },
        { id: "Minimized", name: "Minimized", icon: "minus" },
        { id: "WS 1", name: "WS 1", icon: "layout" },
        { id: "WS 2", name: "WS 2", icon: "layout" },
        { id: "WS 3", name: "WS 3", icon: "layout" },
        { id: "WS 4", name: "WS 4", icon: "layout" },
        { id: "WS 5", name: "WS 5", icon: "layout" },
        { id: "WS 6", name: "WS 6", icon: "layout" },
        { id: "WS 7", name: "WS 7", icon: "layout" },
        { id: "WS 8", name: "WS 8", icon: "layout" },
        { id: "WS 9", name: "WS 9", icon: "layout" },
        { id: "WS 10", name: "WS 10", icon: "layout" }
    ]

    readonly property var filteredWindows: {
        var list = allWindows;
        var q = searchQuery.toLowerCase().trim();
        var filter = selectedFilter;
        var activeWs = ConfigService.activeWorkspaceId || 1;

        return list.filter(function(w) {
            if (!w) return false;
            var winWs = w.workspace_id !== undefined ? w.workspace_id : ((w.workspace && w.workspace.id !== undefined) ? w.workspace.id : 1);
            var isMin = !!w.is_minimized;

            if (filter === "ActiveWS" && winWs !== activeWs) return false;
            if (filter === "Minimized" && !isMin) return false;
            if (filter.startsWith("WS ") && ("WS " + winWs) !== filter) return false;

            if (!q) return true;
            var title = (w.title || "").toLowerCase();
            var appClass = (w.class_name || w.class || "").toLowerCase();
            var initialTitle = (w.initialTitle || "").toLowerCase();
            var wsStr = "ws " + winWs;
            var workspaceStr = "workspace " + winWs;

            return title.indexOf(q) !== -1 ||
                   appClass.indexOf(q) !== -1 ||
                   initialTitle.indexOf(q) !== -1 ||
                   wsStr.indexOf(q) !== -1 ||
                   workspaceStr.indexOf(q) !== -1;
        });
    }

    onRefreshClicked: {
        ConfigService.fetchWindows();
    }

    onIsOpenChanged: {
        if (isOpen) {
            searchQuery = "";
            searchInput.text = "";
            selectedFilter = "All";
            selectedIndex = 0;
            ConfigService.fetchWindows();
            InputService.useKeyboard();
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        repeat: false
        onTriggered: {
            if (flyoutWindow.isOpen && flyoutWindow.requiresKeyboardFocus) {
                searchInput.forceFocus();
            }
        }
    }

    function selectFilter(filterId) {
        selectedFilter = filterId;
        selectedIndex = 0;
        if (winListView.count > 0) {
            winListView.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    function cycleFilter(forward) {
        var idx = 0;
        for (var i = 0; i < filterCategories.length; i++) {
            if (filterCategories[i].id === selectedFilter) {
                idx = i;
                break;
            }
        }
        if (forward) {
            idx = (idx + 1) % filterCategories.length;
        } else {
            idx = (idx - 1 + filterCategories.length) % filterCategories.length;
        }
        selectFilter(filterCategories[idx].id);
    }

    function focusSelected() {
        var list = filteredWindows;
        if (list.length === 0) return;
        var idx = Math.max(0, Math.min(selectedIndex, list.length - 1));
        var target = list[idx];
        if (target) {
            ConfigService.focusWindow(target);
            flyoutWindow.close();
        }
    }

    function navigateList(delta) {
        InputService.useKeyboard();
        var count = filteredWindows.length;
        if (count > 0) {
            var nextIdx = (selectedIndex + (delta % count) + count) % count;
            selectedIndex = nextIdx;
            winListView.positionViewAtIndex(nextIdx, ListView.Contain);
        }
    }

    // Connect to global InputService navigation signals (Keyboard & Gamepads)
    Connections {
        target: InputService
        enabled: flyoutWindow.isOpen

        function onNavUp() {
            flyoutWindow.navigateList(-1);
        }

        function onNavDown() {
            flyoutWindow.navigateList(1);
        }

        function onNavLeft() {
            flyoutWindow.cycleFilter(false);
        }

        function onNavRight() {
            flyoutWindow.cycleFilter(true);
        }

        function onNavNextTab() {
            flyoutWindow.cycleFilter(true);
        }

        function onNavPrevTab() {
            flyoutWindow.cycleFilter(false);
        }

        function onNavSelect() {
            flyoutWindow.focusSelected();
        }

        function onNavBack() {
            if (searchQuery.length > 0) {
                searchQuery = "";
                searchInput.text = "";
            } else if (selectedFilter !== "All" || selectedIndex > 0) {
                selectedFilter = "All";
                selectedIndex = 0;
            } else {
                InputService.closeOrReturn(flyoutWindow);
            }
        }
    }

    // Main Column Layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // 1. Top Category Filter Pills
        ScrollView {
            Layout.fillWidth: true
            implicitHeight: 34
            contentHeight: 34
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            clip: true

            Row {
                id: filterPillRow
                spacing: 6

                Repeater {
                    model: flyoutWindow.filterCategories

                    delegate: Rectangle {
                        id: catPill
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: flyoutWindow.selectedFilter === modelData.id
                        readonly property bool isHovered: pillMouse.containsMouse

                        implicitWidth: pillContentRow.implicitWidth + 20
                        implicitHeight: 30
                        radius: 15

                        color: isSelected 
                            ? Theme.primary 
                            : (isHovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.6))

                        border.color: isSelected 
                            ? Theme.primary 
                            : (isHovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.3))
                        border.width: isSelected ? 1.5 : 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            id: pillContentRow
                            anchors.centerIn: parent
                            spacing: 6

                            VectorIcon {
                                name: modelData.icon || "layout"
                                iconSize: 13
                                color: catPill.isSelected ? Theme.on_primary : Theme.on_surface_variant
                            }

                            Text {
                                text: modelData.name || modelData.id
                                color: catPill.isSelected ? Theme.on_primary : Theme.on_surface
                                font.bold: catPill.isSelected
                                font.pixelSize: 11
                                font.family: Theme.fontFamilyDisplay
                            }
                        }

                        MouseArea {
                            id: pillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                InputService.useMouse();
                                flyoutWindow.selectFilter(modelData.id);
                            }
                        }
                    }
                }
            }
        }

        // 2. Windows Scrollable List
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: winListView
                anchors.fill: parent
                clip: true
                spacing: 6
                model: flyoutWindow.filteredWindows
                currentIndex: flyoutWindow.selectedIndex
                highlightMoveDuration: 0

                delegate: PanelCardItem {
                    id: winCard
                    required property var modelData
                    required property int index

                    readonly property string appClass: modelData.class_name ? modelData.class_name : (modelData.class ? modelData.class : "")
                    readonly property bool isMin: !!modelData.is_minimized
                    readonly property bool isActiveWin: !isMin && (!!modelData.is_active || ConfigService.activeWindowTitle === modelData.title)
                    readonly property int winWs: modelData.workspace_id !== undefined ? modelData.workspace_id : ((modelData.workspace && modelData.workspace.id !== undefined) ? modelData.workspace.id : 1)

                    width: winListView.width - 10
                    itemHeight: 56
                    isCurrent: flyoutWindow.selectedIndex === index

                    onItemHovered: {
                        if (InputService.isMouse) {
                            flyoutWindow.selectedIndex = index;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        // Left App Icon in styled container
                        Rectangle {
                            width: 34
                            height: 34
                            radius: 9
                            color: winCard.isHighlighted 
                                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.20) 
                                : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.8)
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 120 } }

                            AppIcon {
                                anchors.centerIn: parent
                                icon: modelData.icon || ""
                                appClass: winCard.appClass
                                appTitle: modelData.title || modelData.initialTitle || ""
                                iconSize: 22
                                isCurrent: winCard.isActiveWin
                            }
                        }

                        // Window Title & Metadata
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            RowLayout {
                                spacing: 6
                                Layout.fillWidth: true

                                Text {
                                    text: modelData.title || winCard.appClass || "Window"
                                    color: winCard.isHighlighted ? Theme.primary : Theme.on_surface
                                    font.bold: true
                                    font.pixelSize: 13
                                    font.family: Theme.fontFamilyDisplay
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Workspace Badge
                                PillBadge {
                                    text: "WS " + winCard.winWs
                                    isInteractive: false
                                    pillHeight: 18
                                    fontSize: 9
                                    horizontalPadding: 6
                                }

                                // Minimized State Pill
                                PillBadge {
                                    visible: winCard.isMin
                                    text: "Minimized"
                                    isInteractive: false
                                    pillHeight: 18
                                    fontSize: 9
                                    horizontalPadding: 6
                                }
                            }

                            Text {
                                text: (winCard.appClass ? (winCard.appClass + " • ") : "") + (modelData.address || "") + (modelData.pid ? (" • PID " + modelData.pid) : "")
                                color: Theme.on_surface_variant
                                font.pixelSize: 10
                                font.family: Theme.fontFamilyDisplay
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Forward Chevron Indicator
                        VectorIcon {
                            name: "chevron-right"
                            iconSize: 14
                            color: winCard.isHighlighted ? Theme.primary : Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.4)
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    onClicked: {
                        ConfigService.focusWindow(modelData);
                        flyoutWindow.close();
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    id: winScrollBar
                    active: true
                    width: 5
                    policy: ScrollBar.AsNeeded
                    anchors.right: parent.right

                    contentItem: Rectangle {
                        implicitWidth: 5
                        radius: 2.5
                        color: winScrollBar.pressed 
                            ? Theme.primary 
                            : (winScrollBar.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.7) : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.25))
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // High-fidelity Empty State
            EmptyState {
                anchors.centerIn: parent
                visible: flyoutWindow.filteredWindows.length === 0
                iconName: "search"
                title: "No windows found"
                description: flyoutWindow.searchQuery !== "" 
                    ? ("No windows matching \"" + flyoutWindow.searchQuery + "\"") 
                    : ("No windows in " + flyoutWindow.selectedFilter)
            }
        }

        // 3. Search Filter Input Box
        SearchInput {
            id: searchInput
            Layout.fillWidth: true
            placeholder: "Search window title, application name, or workspace..."
            debounceMs: 20
            onTextEdited: query => {
                flyoutWindow.searchQuery = query;
                flyoutWindow.selectedIndex = 0;
            }
            onReturnPressed: flyoutWindow.focusSelected()
            onDownPressed: flyoutWindow.navigateList(1)
            onUpPressed: flyoutWindow.navigateList(-1)
            onLeftPressed: flyoutWindow.cycleFilter(false)
            onRightPressed: flyoutWindow.cycleFilter(true)
            onEscapePressed: InputService.triggerBack()
        }

        // 4. Footer Status & Shortcut Helper Bar
        Rectangle {
            Layout.fillWidth: true
            height: 24
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Text {
                    text: flyoutWindow.filteredWindows.length + " windows"
                    color: Theme.on_surface_variant
                    font.pixelSize: 10
                    font.family: Theme.fontFamilyDisplay
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "↵ Focus Window  •  Tab Filter WS  •  Esc Close"
                    color: Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.6)
                    font.pixelSize: 10
                    font.family: Theme.fontFamilyDisplay
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
