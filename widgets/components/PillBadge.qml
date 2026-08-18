import QtQuick
import QtQuick.Layouts
import "../../theme"

Rectangle {
    id: root

    property string text: ""
    property string iconName: ""
    property int iconSize: 13
    property int fontSize: 11
    property bool isSelected: false
    property bool isInteractive: true
    property int pillHeight: 28
    property int horizontalPadding: 12
    property int spacing: 5

    readonly property bool isMouseHovered: InputService.isMouse && mouseArea.containsMouse

    property color selectedColor: Theme.primary
    property color selectedTextColor: Theme.on_primary
    property color selectedBorderColor: "transparent"

    property color defaultColor: isMouseHovered ? Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.8) : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.5)
    property color defaultTextColor: isMouseHovered ? Theme.primary : Theme.on_surface_variant
    property color defaultBorderColor: isMouseHovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : Theme.outline_variant

    property alias textColor: root.defaultTextColor
    property alias badgeColor: root.defaultColor

    signal clicked()

    implicitWidth: rowLayout.implicitWidth + (horizontalPadding * 2)
    implicitHeight: pillHeight
    radius: pillHeight / 2

    color: isSelected ? selectedColor : defaultColor
    border.color: isSelected ? selectedBorderColor : defaultBorderColor
    border.width: 1

    scale: isInteractive && mouseArea.pressed ? 0.95 : 1.0

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 100 } }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: root.spacing

        VectorIcon {
            visible: root.iconName !== ""
            name: root.iconName
            iconSize: root.iconSize
            color: root.isSelected ? root.selectedTextColor : root.defaultTextColor
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: root.text !== ""
            text: root.text
            color: root.isSelected ? root.selectedTextColor : root.defaultTextColor
            font.pixelSize: root.fontSize
            font.bold: true
            font.family: Theme.fontFamilyDisplay
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.isInteractive
        hoverEnabled: root.isInteractive
        cursorShape: root.isInteractive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            InputService.useMouse();
            root.clicked();
        }
    }
}
