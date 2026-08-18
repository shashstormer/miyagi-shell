import QtQuick
import QtQuick.Layouts
import "../../theme"

Rectangle {
    id: root

    property string labelText: ""
    property string iconName: ""
    property bool checked: false
    property bool isFocused: false
    signal toggled(bool newValue)

    function triggerToggle() {
        checked = !checked;
        toggled(checked);
    }

    Layout.fillWidth: true
    implicitHeight: 40
    radius: 10

    color: (isFocused && InputService.isNonMouse)
        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
        : (rowMouse.containsMouse ? Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.3) : "transparent")

    border.color: (isFocused && InputService.isNonMouse) ? Theme.primary : "transparent"
    border.width: (isFocused && InputService.isNonMouse) ? 2 : 0

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 8

        VectorIcon {
            visible: root.iconName !== ""
            name: root.iconName
            color: (root.isFocused || root.checked) ? Theme.primary : Theme.on_surface_variant
            iconSize: 15
        }

        Text {
            text: root.labelText
            color: (root.isFocused && InputService.isNonMouse) ? Theme.primary : Theme.on_surface
            font.pixelSize: 13
            font.bold: root.isFocused
            font.family: Theme.fontFamilySans
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        ToggleSwitch {
            id: toggleSwitch
            checked: root.checked
            isFocused: root.isFocused
            interactive: false
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggerToggle()
    }
}
