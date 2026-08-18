import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../components"

Rectangle {
    id: root

    default property alias content: cardColumn.children
    property string titleText: ""
    property string iconName: ""

    Layout.fillWidth: true
    implicitHeight: mainColumn.implicitHeight + 28
    radius: 14
    color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.45)
    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
    border.width: 1

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Section Title Header
        RowLayout {
            visible: root.titleText !== ""
            spacing: 8
            Layout.fillWidth: true

            VectorIcon {
                visible: root.iconName !== ""
                name: root.iconName
                color: Theme.primary
                iconSize: 14
            }

            Text {
                text: root.titleText.toUpperCase()
                color: Theme.primary
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1.1
                font.family: Theme.fontFamilyDisplay
                Layout.fillWidth: true
            }
        }

        ColumnLayout {
            id: cardColumn
            Layout.fillWidth: true
            spacing: 8
        }
    }
}
