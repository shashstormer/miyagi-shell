import QtQuick
import QtQuick.Controls

Item {
    id: controller

    property bool autoHideEnabled: false
    property bool isFlyoutOpen: false
    property int hideDelay: 500
    property int extraHoverPadding: 16

    property bool isHovered: false

    readonly property bool isBarVisible: !autoHideEnabled || isHovered || isFlyoutOpen || hideTimer.running

    // 500ms Delay Timer before auto-hiding
    Timer {
        id: hideTimer
        interval: controller.hideDelay
        repeat: false
        onTriggered: {
            controller.isHovered = false;
        }
    }

    function onMouseEntered() {
        hideTimer.stop();
        controller.isHovered = true;
    }

    function onMouseExited() {
        if (!controller.isFlyoutOpen) {
            hideTimer.restart();
        }
    }

    function forceHide() {
        hideTimer.stop();
        controller.isHovered = false;
    }

    // Keep-Open MouseArea extending slightly beyond the bar area (+16px)
    MouseArea {
        id: keepOpenArea
        anchors.fill: parent
        anchors.margins: -controller.extraHoverPadding
        hoverEnabled: true
        z: -1

        onEntered: controller.onMouseEntered()
        onExited: controller.onMouseExited()
    }
}
