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

    property string tooltipText: ""
    property real targetY: 0
    property bool isOpen: false

    function showTooltip(text, yPos) {
        tooltipText = text;
        targetY = yPos;
        isOpen = true;
        visible = true;
    }

    function hideTooltip() {
        isOpen = false;
        visible = false;
        tooltipText = "";
    }

    WlrLayershell.namespace: "quickshell-simple-tooltip"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    anchors {
        left: true
        top: true
    }

    margins {
        left: 60
        top: Math.max(10, Math.min(1080 - 40, tooltipWindow.targetY - 16))
    }

    implicitWidth: textItem.implicitWidth + 24
    implicitHeight: 32

    Rectangle {
        id: cardBg
        anchors.fill: parent
        radius: 8
        color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.96)
        border.color: Theme.primary
        border.width: 1

        Text {
            id: textItem
            anchors.centerIn: parent
            text: tooltipWindow.tooltipText
            color: Theme.on_surface
            font.pixelSize: 11
            font.bold: true
            font.family: Theme.fontFamilyDisplay
            wrapMode: Text.NoWrap
        }
    }
}
