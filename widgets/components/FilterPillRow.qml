import QtQuick
import "../../theme"

Row {
    id: root

    property var model: []
    property string selected: ""
    property int pillHeight: 26
    property int fontSize: 10

    signal optionSelected(string optionId)

    spacing: 6

    Repeater {
        model: root.model
        delegate: Rectangle {
            id: pillItem
            required property var modelData

            readonly property string optId: (typeof pillItem.modelData === "object" && pillItem.modelData && pillItem.modelData.id !== undefined)
                ? pillItem.modelData.id
                : pillItem.modelData
            readonly property string optLabel: (typeof pillItem.modelData === "object" && pillItem.modelData && pillItem.modelData.label !== undefined)
                ? pillItem.modelData.label
                : pillItem.modelData

            readonly property bool isSelected: root.selected === optId

            implicitWidth: pillText.implicitWidth + 14
            implicitHeight: root.pillHeight
            radius: root.pillHeight / 2

            color: isSelected
                ? Theme.primary
                : (pillMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.5))
            border.color: isSelected ? Theme.primary : Theme.outline_variant
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                id: pillText
                anchors.centerIn: parent
                text: pillItem.optLabel
                color: pillItem.isSelected ? Theme.on_primary : Theme.on_surface_variant
                font.pixelSize: root.fontSize
                font.bold: true
                font.family: Theme.fontFamilyDisplay
            }

            MouseArea {
                id: pillMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.optionSelected(pillItem.optId);
                }
            }
        }
    }
}
