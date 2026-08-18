import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../components"

Rectangle {
    id: root

    property string labelText: ""
    property string descriptionText: ""
    property string iconName: ""
    property bool checked: false
    property bool isFocused: false
    signal toggled(bool newValue)

    function triggerToggle() {
        checked = !checked;
        toggled(checked);
    }

    Layout.fillWidth: true
    implicitHeight: Math.max(44, rowLayout.implicitHeight + 14)
    radius: 10

    color: (isFocused && InputService.isNonMouse)
        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
        : (rowMouse.containsMouse ? Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.35) : "transparent")

    border.color: (isFocused && InputService.isNonMouse) ? Theme.primary : "transparent"
    border.width: (isFocused && InputService.isNonMouse) ? 1.5 : 0

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        VectorIcon {
            visible: root.iconName !== ""
            name: root.iconName
            color: (root.isFocused || root.checked) ? Theme.primary : Theme.on_surface_variant
            iconSize: 15
        }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            Text {
                text: root.labelText
                color: (root.isFocused && InputService.isNonMouse) ? Theme.primary : Theme.on_surface
                font.pixelSize: 13
                font.bold: true
                font.family: Theme.fontFamilyDisplay
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: root.descriptionText !== ""
                text: root.descriptionText
                color: Theme.on_surface_variant
                font.pixelSize: 11
                font.family: Theme.fontFamilyDisplay
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
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
        onClicked: {
            InputService.useMouse();
            root.triggerToggle();
        }
    }
}
