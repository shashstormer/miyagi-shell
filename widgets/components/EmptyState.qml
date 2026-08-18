import QtQuick
import QtQuick.Layouts
import "../../theme"

ColumnLayout {
    id: root

    property string iconName: "search"
    property string title: "No items found"
    property string description: ""
    property string actionText: ""
    property int iconSize: 40

    signal actionClicked()

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    spacing: 10

    Item { Layout.fillHeight: true }

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: root.iconSize + 24
        implicitHeight: root.iconSize + 24
        radius: width / 2
        color: Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.4)
        border.color: Theme.outline_variant
        border.width: 1

        VectorIcon {
            anchors.centerIn: parent
            name: root.iconName
            iconSize: root.iconSize
            color: Theme.on_surface_variant
        }
    }

    Text {
        text: root.title
        color: Theme.on_surface
        font.pixelSize: 15
        font.bold: true
        font.family: Theme.fontFamilyDisplay
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignHCenter
    }

    Text {
        visible: root.description !== ""
        text: root.description
        color: Theme.on_surface_variant
        font.pixelSize: 12
        font.family: Theme.fontFamilyDisplay
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: 320
        wrapMode: Text.WordWrap
    }

    PillBadge {
        visible: root.actionText !== ""
        text: root.actionText
        iconName: "refresh"
        isSelected: true
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 6
        onClicked: root.actionClicked()
    }

    Item { Layout.fillHeight: true }
}
