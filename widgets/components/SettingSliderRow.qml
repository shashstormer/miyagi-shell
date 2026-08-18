import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../components"

Rectangle {
    id: root

    property string labelText: ""
    property string descriptionText: ""
    property string iconName: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property real fromValue: from
    property real toValue: to
    property real stepSize: 1
    property string suffix: ""
    property string unitText: suffix
    property bool isFocused: false

    signal valueModified(real newValue)
    signal valueCommitted(real finalValue)

    Layout.fillWidth: true
    implicitHeight: Math.max(46, rowLayout.implicitHeight + 14)
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
        spacing: 12

        VectorIcon {
            visible: root.iconName !== ""
            name: root.iconName
            color: root.isFocused ? Theme.primary : Theme.on_surface_variant
            iconSize: 15
        }

        ColumnLayout {
            spacing: 2
            Layout.preferredWidth: 160
            Layout.fillWidth: false

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

        SmoothSlider {
            id: slider
            Layout.fillWidth: true
            from: root.fromValue
            to: root.toValue
            stepSize: root.stepSize
            externalValue: root.value

            onValueMoved: val => root.valueModified(val)
            onValueCommitted: finalVal => root.valueCommitted(finalVal)
        }

        Text {
            text: Math.round(slider.value) + (root.unitText ? (" " + root.unitText) : (root.suffix ? root.suffix : ""))
            color: Theme.primary
            font.pixelSize: 12
            font.bold: true
            font.family: Theme.fontFamilyMono
            Layout.preferredWidth: 52
            horizontalAlignment: Text.AlignRight
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
