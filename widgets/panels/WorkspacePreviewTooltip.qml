import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../theme"
import "../components"

PanelWindow {
    id: tooltipWindow
    visible: false
    color: "transparent"

    property int workspaceId: 1
    property real targetX: 0
    property real customY: 0
    property bool isDesktopWidget: false
    property bool isOpen: false

    readonly property bool isBottomBar: ConfigService.barPosition === "bottom"

    Timer {
        id: hideTimer
        interval: 350
        repeat: false
        onTriggered: {
            tooltipWindow.isOpen = false;
            tooltipWindow.visible = false;
        }
    }

    function showTooltip(wsId, xPos, yPos, fromDesktop) {
        hideTimer.stop();
        workspaceId = wsId;
        targetX = xPos;
        customY = yPos || 0;
        isDesktopWidget = !!fromDesktop;
        isOpen = true;
        visible = true;
    }

    function hideTooltip() {
        hideTimer.restart();
    }

    function getToplevelForWin(winData) {
        return ConfigService.getToplevelForWin(winData);
    }

    readonly property real canvasScreenWidth: {
        if (typeof Quickshell !== "undefined" && Quickshell.screens && Quickshell.screens.length > 0 && Quickshell.screens[0].width > 0) {
            return Quickshell.screens[0].width;
        }
        var wins = tooltipWindow.workspaceWindows;
        var maxW = 1920;
        for (var i = 0; i < wins.length; i++) {
            var w = wins[i];
            if (w.pos && w.size && w.pos.length >= 2 && w.size.length >= 2) {
                var right = w.pos[0] + w.size[0];
                if (right > maxW) maxW = right;
            }
        }
        return maxW;
    }

    readonly property real canvasScreenHeight: {
        if (typeof Quickshell !== "undefined" && Quickshell.screens && Quickshell.screens.length > 0 && Quickshell.screens[0].height > 0) {
            return Quickshell.screens[0].height;
        }
        var wins = tooltipWindow.workspaceWindows;
        var maxH = 1080;
        for (var i = 0; i < wins.length; i++) {
            var w = wins[i];
            if (w.pos && w.size && w.pos.length >= 2 && w.size.length >= 2) {
                var bottom = w.pos[1] + w.size[1];
                if (bottom > maxH) maxH = bottom;
            }
        }
        return maxH;
    }

    // Open (non-minimized) Windows List on target workspace for Desktop Canvas
    readonly property var openWorkspaceWindows: {
        var wins = tooltipWindow.workspaceWindows;
        var res = [];
        for (var i = 0; i < wins.length; i++) {
            if (!wins[i].is_minimized) res.push(wins[i]);
        }
        return res;
    }

    // Windows List on target workspace (Both Open & Minimized)
    readonly property var workspaceWindows: {
        var list = ConfigService.windowsList || [];
        var res = [];
        for (var i = 0; i < list.length; i++) {
            var w = list[i];
            var winWs = w.workspace_id !== undefined ? w.workspace_id : ((w.workspace && w.workspace.id !== undefined) ? w.workspace.id : 1);
            if (winWs === workspaceId) {
                res.push(w);
            }
        }
        return res;
    }

    WlrLayershell.namespace: "quickshell-workspace-preview"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    anchors {
        left: true
        top: !tooltipWindow.isDesktopWidget && tooltipWindow.isBottomBar ? false : true
        bottom: !tooltipWindow.isDesktopWidget && tooltipWindow.isBottomBar ? true : false
    }

    margins {
        left: Math.max(12, Math.min(1920 - popupCard.width - 12, tooltipWindow.targetX - (popupCard.width / 2)))
        top: (!tooltipWindow.isDesktopWidget && tooltipWindow.isBottomBar) ? 0 : (tooltipWindow.isDesktopWidget ? tooltipWindow.customY : 54)
        bottom: (!tooltipWindow.isDesktopWidget && tooltipWindow.isBottomBar) ? 54 : 0
    }

    implicitWidth: popupCard.width
    implicitHeight: popupCard.height

    Rectangle {
        id: popupCard
        width: Math.max(260, Math.min(900, windowsRow.implicitWidth + 24))
        height: 200
        radius: 14
        scale: tooltipWindow.isOpen ? 1.0 : 0.94
        opacity: tooltipWindow.isOpen ? 1.0 : 0.0

        color: Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.94)
        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
        border.width: 1.5

        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: hideTimer.stop()
            onExited: hideTimer.restart()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Header Row: Workspace Label & Count Tag
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    implicitWidth: wsLabelRow.implicitWidth + 16
                    implicitHeight: 22
                    radius: 6
                    color: Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 0.75)
                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
                    border.width: 1

                    RowLayout {
                        id: wsLabelRow
                        anchors.centerIn: parent
                        spacing: 6

                        VectorIcon {
                            name: "layers"
                            color: Theme.primary
                            iconSize: 14
                        }

                        Text {
                            text: "WORKSPACE " + (tooltipWindow.workspaceId < 10 ? "0" : "") + tooltipWindow.workspaceId
                            color: Theme.primary
                            font.pixelSize: 10
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            tooltipWindow.hideTooltip();
                            ConfigService.switchWorkspace(tooltipWindow.workspaceId);
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Window Count Tag
                Text {
                    text: tooltipWindow.workspaceWindows.length === 0 ? "Empty Workspace" : (tooltipWindow.workspaceWindows.length + (tooltipWindow.workspaceWindows.length === 1 ? " Window" : " Windows"))
                    color: Theme.on_surface_variant
                    font.pixelSize: 10
                    font.bold: true
                    font.family: Theme.fontFamilyMono
                }
            }

            // Cards Preview Carousel
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: windowsRow.implicitWidth
                contentHeight: windowsRow.implicitHeight
                clip: true

                Row {
                    id: windowsRow
                    spacing: 10

                    // 1. Workspace Desktop Overview Card (Always visible!)
                    Rectangle {
                        id: overviewCard
                        width: 220
                        height: 140
                        radius: 10
                        color: Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 0.35)
                        border.color: Theme.primary
                        border.width: 1.5

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                VectorIcon {
                                    name: "layout"
                                    color: Theme.primary
                                    iconSize: 14
                                }

                                Text {
                                    text: "Workspace " + (tooltipWindow.workspaceId < 10 ? "0" : "") + tooltipWindow.workspaceId
                                    color: Theme.primary
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.family: Theme.fontFamilyDisplay
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    implicitWidth: ovText.implicitWidth + 10
                                    implicitHeight: 16
                                    radius: 8
                                    color: Theme.primary

                                    Text {
                                        id: ovText
                                        anchors.centerIn: parent
                                        text: "SWITCH"
                                        color: Theme.on_primary
                                        font.pixelSize: 8
                                        font.bold: true
                                        font.family: Theme.fontFamilyMono
                                    }
                                }
                            }

                            // Desktop Preview Frame (Real Hyprland Geometry Layout Canvas)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 6
                                color: Qt.rgba(0, 0, 0, 0.6)
                                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
                                border.width: 1
                                clip: true

                                // Empty Workspace Mockup
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    visible: tooltipWindow.openWorkspaceWindows.length === 0
                                    spacing: 4

                                    VectorIcon {
                                        Layout.alignment: Qt.AlignHCenter
                                        name: "layout"
                                        color: Theme.primary
                                        iconSize: 22
                                    }

                                    Text {
                                        text: "DESKTOP " + (tooltipWindow.workspaceId < 10 ? "0" : "") + tooltipWindow.workspaceId
                                        color: Theme.on_surface_variant
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.family: Theme.fontFamilyMono
                                    }
                                }

                                // Real Geometry Windows Canvas
                                Item {
                                    id: realDesktopCanvas
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    visible: tooltipWindow.openWorkspaceWindows.length > 0

                                    Repeater {
                                        model: tooltipWindow.openWorkspaceWindows

                                        delegate: Rectangle {
                                            id: winRect
                                            required property var modelData
                                            required property int index

                                            readonly property var rawPos: modelData.pos || modelData.at || []
                                            readonly property var rawSize: modelData.size || []

                                            readonly property bool hasValidGeo: rawSize && rawSize.length >= 2 && Number(rawSize[0]) > 100 && Number(rawSize[1]) > 100
                                            readonly property int totalCount: tooltipWindow.openWorkspaceWindows.length

                                            readonly property real px: hasValidGeo ? Number(rawPos[0]) : 0
                                            readonly property real py: hasValidGeo ? Number(rawPos[1]) : 0
                                            readonly property real pw: hasValidGeo ? Number(rawSize[0]) : tooltipWindow.canvasScreenWidth
                                            readonly property real ph: hasValidGeo ? Number(rawSize[1]) : tooltipWindow.canvasScreenHeight

                                            x: {
                                                if (hasValidGeo) {
                                                    return Math.max(0, Math.min(realDesktopCanvas.width - width, (px / tooltipWindow.canvasScreenWidth) * realDesktopCanvas.width));
                                                }
                                                if (totalCount === 2 && index === 1) return (realDesktopCanvas.width / 2) + 1;
                                                if (totalCount >= 3 && (index % 2 === 1)) return (realDesktopCanvas.width / 2) + 1;
                                                return 0;
                                            }

                                            y: {
                                                if (hasValidGeo) {
                                                    return Math.max(0, Math.min(realDesktopCanvas.height - height, (py / tooltipWindow.canvasScreenHeight) * realDesktopCanvas.height));
                                                }
                                                if (totalCount >= 3 && index >= 2) return (realDesktopCanvas.height / 2) + 1;
                                                return 0;
                                            }

                                            width: {
                                                if (hasValidGeo) {
                                                    return Math.max(24, Math.min(realDesktopCanvas.width, (pw / tooltipWindow.canvasScreenWidth) * realDesktopCanvas.width));
                                                }
                                                if (totalCount === 2 || totalCount >= 3) return (realDesktopCanvas.width / 2) - 2;
                                                return realDesktopCanvas.width;
                                            }

                                            height: {
                                                if (hasValidGeo) {
                                                    return Math.max(18, Math.min(realDesktopCanvas.height, (ph / tooltipWindow.canvasScreenHeight) * realDesktopCanvas.height));
                                                }
                                                if (totalCount >= 3) return (realDesktopCanvas.height / 2) - 2;
                                                return realDesktopCanvas.height;
                                            }

                                            radius: 3
                                            color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.85)
                                            border.color: modelData.is_active ? Theme.primary : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.4)
                                            border.width: modelData.is_active ? 1.5 : 1
                                            clip: true

                                                        ScreencopyView {
                                                anchors.fill: parent
                                                captureSource: tooltipWindow.isOpen ? tooltipWindow.getToplevelForWin(modelData) : null
                                                live: true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                tooltipWindow.hideTooltip();
                                ConfigService.switchWorkspace(tooltipWindow.workspaceId);
                            }
                        }
                    }

                    // 2. Individual Window Cards
                    Repeater {
                            model: tooltipWindow.workspaceWindows

                            delegate: Rectangle {
                                id: cardItem
                                required property var modelData
                                required property int index

                                readonly property string appClass: modelData.class_name ? modelData.class_name : (modelData.class ? modelData.class : "")
                                readonly property bool isMin: !!modelData.is_minimized
                                readonly property bool isActiveWin: !isMin && !!modelData.is_active

                                readonly property var targetToplevel: tooltipWindow.getToplevelForWin(modelData)

                                width: 175
                                height: 140
                                radius: 10
                                color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.6)
                                border.color: isActiveWin ? Theme.primary : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.3)
                                border.width: isActiveWin ? 1.5 : 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6

                                    // Window Header: Icon & Title
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        AppIcon {
                                            icon: modelData.icon || ""
                                            appClass: appClass
                                            appTitle: modelData.title || modelData.initialTitle || ""
                                            iconSize: 16
                                        }

                                        Text {
                                            text: modelData.title || appClass || "Window"
                                            color: Theme.on_surface
                                            font.pixelSize: 10
                                            font.bold: true
                                            font.family: Theme.fontFamilyDisplay
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    // Live Screencopy Preview Frame
                                    Rectangle {
                                        id: indCardFrame
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 6
                                        color: Qt.rgba(0, 0, 0, 0.5)
                                        border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                        border.width: 1
                                        clip: true

                                        Item {
                                            anchors.fill: parent
                                            clip: true

                                            ScreencopyView {
                                                id: previewView
                                                width: (modelData.size && modelData.size.length >= 2 && modelData.size[0] > 0) ? modelData.size[0] : 1920
                                                height: (modelData.size && modelData.size.length >= 2 && modelData.size[1] > 0) ? modelData.size[1] : 1080
                                                captureSource: tooltipWindow.isOpen ? cardItem.targetToplevel : null
                                                live: true

                                                transform: Scale {
                                                    xScale: indCardFrame.width / (previewView.width > 0 ? previewView.width : 1)
                                                    yScale: indCardFrame.height / (previewView.height > 0 ? previewView.height : 1)
                                                }
                                            }
                                        }

                                        // Fallback Icon
                                        Item {
                                            anchors.centerIn: parent
                                            visible: !cardItem.targetToplevel
                                            width: 24
                                            height: 24

                                            VectorIcon {
                                                anchors.centerIn: parent
                                                name: "grid"
                                                color: Theme.primary
                                                iconSize: 24
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        tooltipWindow.hideTooltip();
                                        ConfigService.switchWorkspace(tooltipWindow.workspaceId);
                                        if (modelData.address) {
                                            ConfigService.executeAction("focus_address_" + modelData.address);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
