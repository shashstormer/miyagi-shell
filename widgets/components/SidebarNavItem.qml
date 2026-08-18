import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../components"

Rectangle {
    id: root

    property string iconName: ""
    property string label: ""
    property bool isSelected: false
    property bool isFocused: false

    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 38
    radius: 10

    color: isSelected 
        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
        : (isFocused 
            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)
            : (itemMouseArea.containsMouse ? Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.35) : "transparent"))

    border.color: (isFocused && InputService.isNonMouse)
        ? Theme.primary
        : (isSelected ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent")
    border.width: (isFocused && InputService.isNonMouse) ? 1.5 : (isSelected ? 1 : 0)

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        VectorIcon {
            name: root.iconName
            color: (root.isSelected || root.isFocused) ? Theme.primary : Theme.on_surface_variant
            iconSize: 16
        }

        Text {
            text: root.label
            color: (root.isSelected || root.isFocused) ? Theme.primary : Theme.on_surface
            font.pixelSize: 13
            font.bold: root.isSelected
            font.family: Theme.fontFamilyDisplay
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: itemMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            InputService.useMouse();
            root.clicked();
        }
    }
}
