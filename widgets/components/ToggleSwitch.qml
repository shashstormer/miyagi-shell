import QtQuick
import QtQuick.Controls
import "../../theme"

Item {
    id: root

    property bool checked: false
    property bool isFocused: false
    property bool interactive: true
    signal toggled(bool newValue)

    function trigger() {
        if (!interactive) return;
        checked = !checked;
        toggled(checked);
    }

    implicitWidth: 38
    implicitHeight: 22

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked 
            ? Theme.primary 
            : (trackMouse.containsMouse ? Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.40) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.25))
        border.color: root.checked ? Theme.primary : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.5)
        border.width: 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Rectangle {
            id: thumb
            width: parent.height - 6
            height: width
            radius: width / 2
            x: root.checked ? (parent.width - width - 3) : 3
            anchors.verticalCenter: parent.verticalCenter
            color: root.checked ? Theme.on_primary : Theme.on_surface_variant

            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: 150 } }

            scale: trackMouse.pressed ? 1.15 : (trackMouse.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: 120 } }
        }
    }

    MouseArea {
        id: trackMouse
        anchors.fill: parent
        hoverEnabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.trigger()
    }
}
