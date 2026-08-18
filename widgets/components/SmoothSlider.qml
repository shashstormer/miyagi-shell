import QtQuick
import QtQuick.Controls
import "../../theme"

Slider {
    id: smoothSlider

    from: 0
    to: 100
    stepSize: 1

    property real externalValue: 0
    property bool isUserInteracting: false
    signal valueMoved(real value)
    signal valueCommitted(real value)

    implicitHeight: 32
    implicitWidth: 200

    property real pendingMovedValue: 0

    Timer {
        id: dragGuardTimer
        interval: 600
        repeat: false
        onTriggered: {
            smoothSlider.isUserInteracting = false;
        }
    }

    // 30ms Defer/Debounce Timer for High-Frequency Slider Movements
    Timer {
        id: updateDeferTimer
        interval: 30
        repeat: false
        onTriggered: {
            smoothSlider.valueMoved(smoothSlider.pendingMovedValue);
        }
    }

    Binding on value {
        when: !smoothSlider.pressed && !smoothSlider.isUserInteracting
        value: smoothSlider.externalValue
    }

    onExternalValueChanged: {
        if (!pressed && !isUserInteracting) {
            value = externalValue;
        }
    }

    onMoved: {
        isUserInteracting = true;
        dragGuardTimer.restart();
        var v = Math.round(value);
        pendingMovedValue = v;
        updateDeferTimer.restart();
    }

    onPressedChanged: {
        if (!pressed) {
            isUserInteracting = true;
            dragGuardTimer.restart();
            updateDeferTimer.stop();
            var v = Math.round(value);
            valueCommitted(v);
        }
    }

    Component.onCompleted: {
        value = externalValue;
    }

    // Custom Premium Pill Background Track
    background: Rectangle {
        x: smoothSlider.leftPadding
        y: smoothSlider.topPadding + (smoothSlider.availableHeight - height) / 2
        implicitWidth: 200
        implicitHeight: 10
        width: smoothSlider.availableWidth
        height: implicitHeight
        radius: 5
        color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.35)

        // Active Filled Track Portion
        Rectangle {
            width: Math.max(height, smoothSlider.visualPosition * parent.width)
            height: parent.height
            radius: 5
            color: Theme.primary

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
    }

    // Custom Floating Knob Handle
    handle: Rectangle {
        id: handleRect
        x: smoothSlider.leftPadding + smoothSlider.visualPosition * (smoothSlider.availableWidth - width)
        y: smoothSlider.topPadding + (smoothSlider.availableHeight - height) / 2
        implicitWidth: 22
        implicitHeight: 22
        radius: 11
        color: Theme.primary
        border.color: Theme.surface_container_lowest
        border.width: 2.5

        scale: smoothSlider.pressed ? 1.25 : (handleMouse.containsMouse ? 1.15 : 1.0)

        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        MouseArea {
            id: handleMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
        }
    }
}
