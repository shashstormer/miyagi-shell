import QtQuick
import QtQuick.Layouts
import "../../theme"

Rectangle {
    id: root

    property string iconName: "bell"
    property string value: "0"
    property string label: ""
    property color accentColor: Theme.primary
    property color containerColor: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
    property color borderColor: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25)

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: 68
    radius: 12
    color: containerColor
    border.color: borderColor
    border.width: 1

    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 180 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Rectangle {
            implicitWidth: 36
            implicitHeight: 36
            radius: 18
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15)

            VectorIcon {
                anchors.centerIn: parent
                name: root.iconName
                iconSize: 18
                color: root.accentColor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.value
                color: root.accentColor
                font.pixelSize: 18
                font.bold: true
                font.family: Theme.fontFamilyDisplay
            }

            Text {
                text: root.label
                color: Theme.on_surface_variant
                font.pixelSize: 10
                font.family: Theme.fontFamilyMono
            }
        }
    }
}
