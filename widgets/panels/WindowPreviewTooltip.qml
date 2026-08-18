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

    property var windowData: null
    property real targetY: 0
    property bool isOpen: false

    function showTooltip(data, yPos) {
        windowData = data;
        targetY = yPos;
        isOpen = true;
        visible = true;
    }

    function hideTooltip() {
        isOpen = false;
        visible = false;
        windowData = null;
    }

    // Live Screencopy Toplevel Lookup
    readonly property var targetToplevel: ConfigService.getToplevelForWin(windowData)

    WlrLayershell.namespace: "quickshell-preview-tooltip"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    anchors {
        left: true
        top: true
    }

    margins {
        left: 60
        top: Math.max(10, Math.min(1080 - 180, tooltipWindow.targetY - 20))
    }

    implicitWidth: 260
    implicitHeight: 165

    Rectangle {
        id: cardBg
        anchors.fill: parent
        radius: 12
        color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.96)
        border.color: Theme.primary
        border.width: 1.5

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // TOP HEADER: App Icon & Window Title Next To It
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                AppIcon {
                    icon: tooltipWindow.windowData ? (tooltipWindow.windowData.icon || "") : ""
                    appClass: tooltipWindow.windowData ? (tooltipWindow.windowData.class_name || tooltipWindow.windowData.class || "") : ""
                    appTitle: tooltipWindow.windowData ? (tooltipWindow.windowData.title || tooltipWindow.windowData.initialTitle || "") : ""
                    iconSize: 18
                }

                Text {
                    text: tooltipWindow.windowData ? (tooltipWindow.windowData.title || tooltipWindow.windowData.class_name || tooltipWindow.windowData.class) : ""
                    color: Theme.on_surface
                    font.pixelSize: 11
                    font.bold: true
                    font.family: Theme.fontFamilyDisplay
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // LIVE WINDOW THUMBNAIL PREVIEW (ScreencopyView thumbnail like video seek bar!)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: Qt.rgba(0, 0, 0, 0.6)
                clip: true
                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
                border.width: 1

                ScreencopyView {
                    id: screencopyComp
                    anchors.fill: parent
                    captureSource: tooltipWindow.isOpen ? tooltipWindow.targetToplevel : null
                    live: true
                }

                // Fallback Banner if screencopy is loading or unavailable
                Item {
                    anchors.centerIn: parent
                    visible: !tooltipWindow.targetToplevel
                    width: 32
                    height: 32

                    VectorIcon {
                        anchors.centerIn: parent
                        name: "grid"
                        color: Theme.primary
                        iconSize: 32
                    }
                }
            }
        }
    }
}
