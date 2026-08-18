import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../theme"
import "../components"

PanelWindow {
    id: overviewWindow

    property bool isOpen: false

    visible: isOpen
    color: "transparent"

    WlrLayershell.namespace: "quickshell-overview-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: overviewWindow.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    property int selectedWsIndex: 0

    onIsOpenChanged: {
        if (isOpen) {
            selectedWsIndex = Math.max(0, Math.min(9, ConfigService.activeWorkspaceId - 1));
        }
    }

    function toggleOverview() {
        if (isOpen) {
            cycleNext();
        } else {
            openOverview();
        }
    }

    function openOverview() {
        InputService.closeOtherPanels(overviewWindow);
        isOpen = true;
    }

    function closeOverview() {
        isOpen = false;
    }

    function cycleNext() {
        if (!isOpen) {
            openOverview();
            return;
        }
        selectedWsIndex = (selectedWsIndex + 1) % 10;
    }

    function cyclePrev() {
        if (!isOpen) {
            openOverview();
            return;
        }
        selectedWsIndex = (selectedWsIndex - 1 + 10) % 10;
    }

    function confirmSelection() {
        if (!isOpen) return;
        var targetWs = selectedWsIndex + 1;
        closeOverview();
        ConfigService.switchWorkspace(targetWs);
    }

    // Shortcuts for Tab, Shift+Tab, Return, and ESC keys
    Shortcut {
        sequence: "Tab"
        enabled: overviewWindow.isOpen
        onActivated: overviewWindow.cycleNext()
    }

    Shortcut {
        sequence: "Shift+Tab"
        enabled: overviewWindow.isOpen
        onActivated: overviewWindow.cyclePrev()
    }

    Shortcut {
        sequence: "Return"
        enabled: overviewWindow.isOpen
        onActivated: overviewWindow.confirmSelection()
    }

    Shortcut {
        sequence: "Escape"
        enabled: overviewWindow.isOpen
        onActivated: overviewWindow.closeOverview()
    }

    Connections {
        target: InputService
        enabled: overviewWindow.isOpen

        function onNavLeft() {
            InputService.useKeyboard();
            overviewWindow.cyclePrev();
        }
        function onNavRight() {
            InputService.useKeyboard();
            overviewWindow.cycleNext();
        }
        function onNavUp() {
            InputService.useKeyboard();
            overviewWindow.selectedWsIndex = Math.max(0, overviewWindow.selectedWsIndex - 5);
        }
        function onNavDown() {
            InputService.useKeyboard();
            overviewWindow.selectedWsIndex = Math.min(9, overviewWindow.selectedWsIndex + 5);
        }
        function onNavSelect() {
            overviewWindow.confirmSelection();
        }
        function onNavBack() {
            overviewWindow.closeOverview();
        }
        function onClosePanelsExcept(exceptPanel) {
            if (exceptPanel !== overviewWindow) {
                overviewWindow.closeOverview();
            }
        }
    }

    // Fullscreen Glass Backdrop
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.78)

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: overviewWindow.closeOverview()
        }

        // Overview Header Title
        ColumnLayout {
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                VectorIcon {
                    name: "layout"
                    color: Theme.primary
                    iconSize: 28
                }

                Text {
                    text: "WORKSPACES OVERVIEW"
                    color: Theme.on_surface
                    font.pixelSize: 22
                    font.bold: true
                    font.family: Theme.fontFamilyDisplay
                    font.letterSpacing: 1.5
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Select a workspace to switch"
                color: Theme.on_surface_variant
                font.pixelSize: 12
                font.family: Theme.fontFamilySans
            }
        }

        // Workspaces 1-10 Grid Container
        Item {
            anchors.fill: parent
            anchors.topMargin: 120
            anchors.bottomMargin: 40
            anchors.leftMargin: 60
            anchors.rightMargin: 60

            GridLayout {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 48
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 4
                rowSpacing: 24
                columnSpacing: 24

                Repeater {
                    model: 10 // Workspaces 1 to 10

                    delegate: Item {
                        id: wsCardWrapper

                        readonly property int wsId: index + 1
                        readonly property bool isSelected: overviewWindow.selectedWsIndex === index
                        readonly property bool isActiveWs: ConfigService.activeWorkspaceId === wsId

                        Layout.row: index < 8 ? Math.floor(index / 4) : 2
                        Layout.column: index < 8 ? (index % 4) : (index === 8 ? 1 : 2)

                        // Filter windows for this workspace
                        readonly property var wsWindows: {
                            var list = ConfigService.windowsList || [];
                            var res = [];
                            for (var i = 0; i < list.length; i++) {
                                var w = list[i];
                                var winWs = w.workspace_id !== undefined ? w.workspace_id : ((w.workspace && w.workspace.id !== undefined) ? w.workspace.id : 1);
                                if (winWs === wsId) {
                                    res.push(w);
                                }
                            }
                            return res;
                        }

                        readonly property var openWsWindows: {
                            var wins = wsWindows;
                            var res = [];
                            for (var i = 0; i < wins.length; i++) {
                                if (!wins[i].is_minimized) res.push(wins[i]);
                            }
                            return res;
                        }

                        width: 320
                        height: 210

                        Rectangle {
                            id: wsCard
                            anchors.fill: parent
                            radius: 16
                            color: isSelected
                                ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 0.50)
                                : (isActiveWs ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 0.25) : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.60))

                            border.color: isSelected || cardMouse.containsMouse
                                ? Theme.primary
                                : (isActiveWs ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.8) : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.3))
                            border.width: isSelected || isActiveWs || cardMouse.containsMouse ? 2 : 1

                            scale: isSelected || cardMouse.containsMouse ? 1.03 : 1.0
                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            Behavior on border.color { ColorAnimation { duration: 160 } }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                // Workspace Card Header
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: isActiveWs ? Theme.primary : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.8)

                                        Text {
                                            anchors.centerIn: parent
                                            text: wsId
                                            color: isActiveWs ? Theme.on_primary : Theme.on_surface
                                            font.pixelSize: 11
                                            font.bold: true
                                            font.family: Theme.fontFamilyMono
                                        }
                                    }

                                    Text {
                                        text: "Workspace " + (wsId < 10 ? "0" : "") + wsId
                                        color: Theme.on_surface
                                        font.pixelSize: 13
                                        font.bold: true
                                        font.family: Theme.fontFamilyDisplay
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        visible: isActiveWs
                                        implicitWidth: activeBadgeText.implicitWidth + 12
                                        implicitHeight: 18
                                        radius: 9
                                        color: Theme.primary

                                        Text {
                                            id: activeBadgeText
                                            anchors.centerIn: parent
                                            text: "ACTIVE"
                                            color: Theme.on_primary
                                            font.pixelSize: 8
                                            font.bold: true
                                            font.family: Theme.fontFamilyMono
                                        }
                                    }
                                }

                                // Desktop Layout Canvas (Miniaturized Monitor Preview)
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 8
                                    color: Qt.rgba(0, 0, 0, 0.65)
                                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                    border.width: 1
                                    clip: true

                                    // Empty Workspace Icon Graphic
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        visible: openWsWindows.length === 0
                                        spacing: 4

                                        VectorIcon {
                                            Layout.alignment: Qt.AlignHCenter
                                            name: "layout"
                                            color: Theme.outline
                                            iconSize: 24
                                        }

                                        Text {
                                            text: "EMPTY"
                                            color: Theme.outline
                                            font.pixelSize: 9
                                            font.bold: true
                                            font.family: Theme.fontFamilyMono
                                        }
                                    }

                                    // Real Window Geometry Canvas
                                    Item {
                                        id: miniCanvas
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        visible: openWsWindows.length > 0

                                        Repeater {
                                            model: openWsWindows

                                            delegate: Rectangle {
                                                id: miniWinRect
                                                required property var modelData
                                                required property int index

                                                readonly property var rawPos: modelData.pos || modelData.at || []
                                                readonly property var rawSize: modelData.size || []

                                                readonly property bool hasValidGeo: rawSize && rawSize.length >= 2 && Number(rawSize[0]) > 100 && Number(rawSize[1]) > 100
                                                readonly property int totalCount: openWsWindows.length

                                                readonly property real px: hasValidGeo ? Number(rawPos[0]) : 0
                                                readonly property real py: hasValidGeo ? Number(rawPos[1]) : 0
                                                readonly property real pw: hasValidGeo ? Number(rawSize[0]) : 1920
                                                readonly property real ph: hasValidGeo ? Number(rawSize[1]) : 1080

                                                x: {
                                                    if (hasValidGeo) {
                                                        return Math.max(0, Math.min(miniCanvas.width - width, (px / 1920) * miniCanvas.width));
                                                    }
                                                    if (totalCount === 2 && index === 1) return (miniCanvas.width / 2) + 1;
                                                    if (totalCount >= 3 && (index % 2 === 1)) return (miniCanvas.width / 2) + 1;
                                                    return 0;
                                                }

                                                y: {
                                                    if (hasValidGeo) {
                                                        return Math.max(0, Math.min(miniCanvas.height - height, (py / 1080) * miniCanvas.height));
                                                    }
                                                    if (totalCount >= 3 && index >= 2) return (miniCanvas.height / 2) + 1;
                                                    return 0;
                                                }

                                                width: {
                                                    if (hasValidGeo) {
                                                        return Math.max(20, Math.min(miniCanvas.width, (pw / 1920) * miniCanvas.width));
                                                    }
                                                    if (totalCount === 2 || totalCount >= 3) return (miniCanvas.width / 2) - 2;
                                                    return miniCanvas.width;
                                                }

                                                height: {
                                                    if (hasValidGeo) {
                                                        return Math.max(16, Math.min(miniCanvas.height, (ph / 1080) * miniCanvas.height));
                                                    }
                                                    if (totalCount >= 3) return (miniCanvas.height / 2) - 2;
                                                    return miniCanvas.height;
                                                }

                                                radius: 4
                                                color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.85)
                                                border.color: modelData.is_active ? Theme.primary : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.4)
                                                border.width: modelData.is_active ? 1.5 : 1
                                                clip: true

                                                ScreencopyView {
                                                    anchors.fill: parent
                                                    captureSource: overviewWindow.isOpen ? ConfigService.getToplevelForWin(modelData) : null
                                                    live: true
                                                }
                                            }
                                        }
                                    }
                                }

                                // Bottom App Icons Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Repeater {
                                        model: Math.min(wsWindows.length, 6)

                                        delegate: AppIcon {
                                            required property int index
                                            readonly property var winItem: wsWindows[index]

                                            iconSize: 16
                                            icon: winItem ? (winItem.icon || "") : ""
                                            appClass: winItem ? (winItem.class_name || winItem.class || "") : ""
                                            appTitle: winItem ? (winItem.title || winItem.initialTitle || "") : ""
                                            opacity: winItem && winItem.is_minimized ? 0.45 : 0.95
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: wsWindows.length > 0 ? (wsWindows.length + " window" + (wsWindows.length > 1 ? "s" : "")) : "No windows"
                                        color: Theme.on_surface_variant
                                        font.pixelSize: 10
                                        font.family: Theme.fontFamilyMono
                                    }
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    overviewWindow.closeOverview();
                                    ConfigService.switchWorkspace(wsId);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
