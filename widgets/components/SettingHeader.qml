import QtQuick
import QtQuick.Layouts
import "../../theme"

RowLayout {
    id: root

    property string titleText: ""
    property string iconName: "settings"

    spacing: 8
    Layout.topMargin: 12
    Layout.bottomMargin: 4

    VectorIcon {
        name: root.iconName
        color: Theme.primary
        iconSize: 16
    }

    Text {
        text: root.titleText
        color: Theme.on_surface
        font.pixelSize: 13
        font.bold: true
        font.family: Theme.fontFamilyMono
    }
}
