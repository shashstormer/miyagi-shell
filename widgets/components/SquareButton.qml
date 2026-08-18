import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

Rectangle {
    id: root

    property string iconName: ""
    property string text: ""
    property bool isActive: false
    property real size: 36
    property alias btnSize: root.size
    property real iconSize: 16
    property real customRadius: 8
    property color customIconColor: "transparent"
    property alias iconColor: root.customIconColor
    property bool hasIndicatorDot: false
    property color indicatorDotColor: Theme.primary
    property real indicatorDotSize: 5

    implicitWidth: (iconName !== "" && text !== "") ? (contentRow.implicitWidth + 18) : ((iconName === "" && text !== "") ? (textComp.implicitWidth + 24) : size)
    implicitHeight: size
    radius: customRadius

    property color normalColor: "transparent"
    property color hoverColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
    property color activeColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)

    color: isActive ? activeColor : (mouseArea.containsMouse ? hoverColor : normalColor)

    border.color: isActive ? Theme.primary : (mouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent")
    border.width: isActive ? 1.5 : (mouseArea.containsMouse ? 1 : 0)

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    signal clicked()
    signal hoverEntered()
    signal hoverExited()

    // Single Icon Layout
    VectorIcon {
        id: iconComp
        anchors.centerIn: parent
        visible: root.iconName !== "" && root.text === ""
        name: root.iconName
        color: root.isActive ? Theme.primary : (mouseArea.containsMouse ? Theme.primary : (root.customIconColor.a > 0 ? root.customIconColor : Theme.on_surface))
        iconSize: root.iconSize
    }

    // Mini Indicator Dot
    Rectangle {
        visible: root.hasIndicatorDot
        width: root.indicatorDotSize
        height: root.indicatorDotSize
        radius: root.indicatorDotSize / 2
        color: root.indicatorDotColor
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 4
    }

    // Single Text Layout
    Text {
        id: textComp
        anchors.centerIn: parent
        visible: root.iconName === "" && root.text !== ""
        text: root.text
        font.pixelSize: 11
        font.bold: root.isActive || mouseArea.containsMouse
        font.family: Theme.fontFamilyDisplay
        color: root.isActive ? Theme.primary : (mouseArea.containsMouse ? Theme.primary : Theme.on_surface)
    }

    // Combined Icon + Text Layout
    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        visible: root.iconName !== "" && root.text !== ""
        spacing: 6

        VectorIcon {
            name: root.iconName
            color: root.isActive ? Theme.primary : (mouseArea.containsMouse ? Theme.primary : (root.customIconColor.a > 0 ? root.customIconColor : Theme.on_surface))
            iconSize: root.iconSize
        }

        Text {
            text: root.text
            font.pixelSize: 11
            font.bold: root.isActive || mouseArea.containsMouse
            font.family: Theme.fontFamilyDisplay
            color: root.isActive ? Theme.primary : (mouseArea.containsMouse ? Theme.primary : Theme.on_surface)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onEntered: root.hoverEntered()
        onExited: root.hoverExited()
    }
}
