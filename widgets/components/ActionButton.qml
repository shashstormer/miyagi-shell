import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

Rectangle {
    id: rootBtn

    property string text: ""
    property string iconName: ""
    property int iconSize: 16
    property string variant: "primary" // "primary", "secondary", "danger", "surface", "outline"
    property bool disabled: false
    property bool isFocused: false
    signal clicked()

    implicitHeight: 38
    implicitWidth: btnLayout.implicitWidth + 24
    radius: 10

    // Variant Color Resolution
    readonly property color bgBase: {
        if (disabled) return Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2);
        if (isFocused) return variant === "danger" ? Theme.error : Theme.primary;
        if (variant === "danger") return Theme.error;
        if (variant === "secondary") return Theme.secondary_container;
        if (variant === "surface") return Theme.surface_container_high;
        if (variant === "outline") return Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.6);
        return Theme.primary;
    }

    readonly property color fgColor: {
        if (disabled) return Theme.outline;
        if (isFocused) return variant === "danger" ? Theme.on_error : Theme.on_primary;
        if (variant === "danger") return Theme.on_error;
        if (variant === "secondary") return Theme.on_secondary_container;
        if (variant === "surface" || variant === "outline") return Theme.on_surface;
        return Theme.on_primary;
    }

    color: (btnMouse.containsMouse || isFocused) && !disabled
        ? (variant === "outline" || variant === "surface" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.9) : Qt.tint(bgBase, Qt.rgba(1, 1, 1, 0.2)))
        : bgBase

    border.color: isFocused ? (variant === "outline" ? Theme.primary : Theme.on_primary) : (variant === "outline" ? Theme.outline_variant : "transparent")
    border.width: isFocused ? 2.5 : (variant === "outline" ? 1 : 0)

    scale: btnMouse.pressed && !disabled ? 0.96 : (isFocused ? 1.10 : (btnMouse.containsMouse && !disabled ? 1.05 : 1.0))
    opacity: disabled ? 0.5 : 1.0

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 120 } }

    // High-Visibility Outer Focus Ring
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: parent.radius + 3
        color: "transparent"
        border.color: Theme.primary
        border.width: 2.5
        visible: rootBtn.isFocused
    }

    RowLayout {
        id: btnLayout
        anchors.centerIn: parent
        spacing: 8

        VectorIcon {
            visible: rootBtn.iconName !== ""
            name: rootBtn.iconName
            color: rootBtn.fgColor
            iconSize: rootBtn.iconSize
        }

        Text {
            visible: rootBtn.text !== ""
            text: rootBtn.text
            color: rootBtn.fgColor
            font.pixelSize: 12
            font.bold: true
            font.family: Theme.fontFamilyDisplay
        }
    }

    MouseArea {
        id: btnMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: {
            if (!disabled) rootBtn.clicked();
        }
    }
}
