import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../theme"

Item {
    id: root

    property string icon: ""
    property alias rawIcon: root.icon
    property string appClass: ""
    property string appTitle: ""
    property int iconSize: 24
    property string fallbackIcon: "grid9"
    property color fallbackColor: (isHovered || isCurrent) ? Theme.primary : Theme.on_surface_variant
    property bool isHovered: false
    property bool isCurrent: false

    implicitWidth: iconSize
    implicitHeight: iconSize
    width: iconSize
    height: iconSize

    function resolveIconSource(rawIcon, cls, title) {
        if (typeof ConfigService !== "undefined" && ConfigService && ConfigService.resolveAppIcon) {
            return ConfigService.resolveAppIcon(rawIcon, cls, title);
        }
        var raw = (rawIcon || "").toString().trim();
        var c = (cls || "").toString().trim().toLowerCase();
        if (raw.startsWith("steam_app_")) return "image://icon/steam_icon_" + raw.replace("steam_app_", "");
        if (c.startsWith("steam_app_")) return "image://icon/steam_icon_" + c.replace("steam_app_", "");
        var iconStr = raw ? raw : (c ? (c.endsWith("client") ? c.replace(/client$/, "") : c) : "");
        if (!iconStr || iconStr === "grid") return "";
        if (iconStr.startsWith("file:")) return iconStr;
        if (iconStr.indexOf("/") !== -1) return "file://" + iconStr;
        return "image://icon/" + iconStr;
    }

    readonly property string iconSource: resolveIconSource(icon, appClass, appTitle)

    IconImage {
        id: imgIcon
        anchors.fill: parent
        source: root.iconSource
        asynchronous: true
        visible: root.iconSource !== "" && (status === Image.Ready || (status === Image.Null && source !== ""))
    }

    VectorIcon {
        anchors.centerIn: parent
        name: root.fallbackIcon
        iconSize: Math.max(12, Math.round(root.iconSize * 0.75))
        color: root.fallbackColor
        visible: !imgIcon.visible || imgIcon.status === Image.Error || root.iconSource === ""
    }
}
