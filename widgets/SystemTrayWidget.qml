import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications
import "../theme"

Rectangle {
    id: root

    property var parentWindow: null
    property var notifPanel: null

    readonly property var trayItems: SystemTray.items ? SystemTray.items.values : []
    readonly property int itemCount: trayItems ? trayItems.length : 0

    readonly property int unreadNotifCount: notifPanel ? notifPanel.unreadCount : 0

    // Tray Widget is visible when items or tray buttons are present and showSystemTray is enabled
    visible: ConfigService.showSystemTray

    implicitWidth: trayRow.implicitWidth + 16
    implicitHeight: 40

    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 0.92)
    border.color: Theme.outline_variant
    border.width: 1.5
    radius: 8

    // Idle Inhibitor State (True = hypridle process killed = ACTIVE)
    property bool isIdleInhibited: false

    function toggleIdleInhibitor() {
        ConfigService.executeAction("toggle_idle_inhibitor", function() {
            ConfigService.fetchIdleStatus(function(inhibited) {
                root.isIdleInhibited = inhibited;
            });
        });
    }

    Timer {
        id: pollTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            ConfigService.fetchIdleStatus(function(inhibited) {
                root.isIdleInhibited = inhibited;
            });
        }
    }

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: 6

        // System Tray Items Repeater
        Repeater {
            model: root.trayItems

            delegate: Rectangle {
                id: itemRect
                required property var modelData
                
                implicitWidth: 30
                implicitHeight: 30
                radius: 6
                color: itemArea.containsMouse ? Theme.primary_fixed : Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.6)
                border.color: itemArea.containsMouse ? Theme.primary : Theme.outline_variant
                border.width: 1

                // Icon rendering with IconImage
                IconImage {
                    id: iconImg
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: (itemRect.modelData && itemRect.modelData.icon) ? itemRect.modelData.icon : ""
                    asynchronous: true
                }

                // Fallback initial letter badge ONLY when icon fails to load or source is empty
                Text {
                    anchors.centerIn: parent
                    visible: (iconImg.status === Image.Error || !iconImg.source || iconImg.source === "") && itemRect.modelData !== null
                    text: {
                        if (!itemRect.modelData) return "•";
                        if (itemRect.modelData.title && itemRect.modelData.title.trim() !== "") {
                            return itemRect.modelData.title.substring(0, 1).toUpperCase();
                        }
                        if (itemRect.modelData.id && itemRect.modelData.id.trim() !== "") {
                            return itemRect.modelData.id.substring(0, 1).toUpperCase();
                        }
                        return "•";
                    }
                    color: itemArea.containsMouse ? Theme.on_primary : Theme.primary
                    font.pixelSize: 11
                    font.bold: true
                    font.family: Theme.fontFamilyMono
                }

                // Native Quickshell QsMenuAnchor anchored ABOVE item
                QsMenuAnchor {
                    id: menuAnchor
                    menu: itemRect.modelData ? itemRect.modelData.menu : null
                    anchor.window: root.parentWindow
                    anchor.edges: Edges.Top
                    anchor.gravity: Edges.Top
                }

                // Tooltip Popup
                ToolTip.visible: itemArea.containsMouse
                ToolTip.text: (modelData && (modelData.title || modelData.tooltipTitle || modelData.id)) ? (modelData.title || modelData.tooltipTitle || modelData.id) : "Tray Item"
                ToolTip.delay: 300

                MouseArea {
                    id: itemArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            if (modelData && modelData.activate) {
                                modelData.activate();
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            if (modelData && modelData.hasMenu && menuAnchor) {
                                var pos = itemRect.mapToItem(null, 0, 0);
                                menuAnchor.anchor.rect = Qt.rect(pos.x, pos.y, itemRect.width, itemRect.height);
                                menuAnchor.open();
                            } else if (modelData && modelData.contextMenu) {
                                modelData.contextMenu();
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            if (modelData && modelData.secondaryActivate) {
                                modelData.secondaryActivate();
                            }
                        }
                    }
                }
            }
        }

        // Idle Inhibitor Tray Toggle Button
        Rectangle {
            id: idleInhibitorBtn
            implicitWidth: 30
            implicitHeight: 30
            radius: 6

            color: root.isIdleInhibited 
                ? (inhibitorArea.containsMouse ? Theme.primary_fixed : Theme.primary)
                : (inhibitorArea.containsMouse ? Theme.primary_fixed : Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.6))

            border.color: root.isIdleInhibited ? Theme.primary_fixed : Theme.outline_variant
            border.width: root.isIdleInhibited ? 1.5 : 1.0

            Behavior on color { ColorAnimation { duration: 150 } }

            Canvas {
                id: coffeeCanvas
                anchors.centerIn: parent
                width: 16; height: 16
                antialiasing: true

                property color iconColor: root.isIdleInhibited 
                    ? (inhibitorArea.containsMouse ? Theme.on_primary_fixed : Theme.on_primary)
                    : (inhibitorArea.containsMouse ? Theme.on_primary_fixed : Theme.on_surface_variant)

                onIconColorChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = iconColor;
                    ctx.strokeStyle = iconColor;
                    ctx.lineWidth = 1.5;

                    if (root.isIdleInhibited) {
                        // Active Coffee Cup Body
                        ctx.beginPath();
                        ctx.moveTo(3, 4);
                        ctx.lineTo(13, 4);
                        ctx.lineTo(12, 11);
                        ctx.arcTo(8, 14, 4, 11, 4);
                        ctx.lineTo(4, 11);
                        ctx.closePath();
                        ctx.fill();

                        // Cup Handle
                        ctx.beginPath();
                        ctx.arc(13, 7.5, 2.5, -Math.PI/2, Math.PI/2);
                        ctx.stroke();

                        // Steam lines
                        ctx.lineWidth = 1.2;
                        ctx.beginPath();
                        ctx.moveTo(5, 1); ctx.lineTo(6, 2.5);
                        ctx.moveTo(8, 0.5); ctx.lineTo(8, 2.5);
                        ctx.moveTo(11, 1); ctx.lineTo(10, 2.5);
                        ctx.stroke();
                    } else {
                        // Inactive Coffee Cup Outline
                        ctx.beginPath();
                        ctx.moveTo(3, 4);
                        ctx.lineTo(13, 4);
                        ctx.lineTo(12, 11);
                        ctx.arcTo(8, 14, 4, 11, 4);
                        ctx.lineTo(4, 11);
                        ctx.closePath();
                        ctx.stroke();

                        // Handle outline
                        ctx.beginPath();
                        ctx.arc(13, 7.5, 2.5, -Math.PI/2, Math.PI/2);
                        ctx.stroke();
                    }
                }

                Connections {
                    target: root
                    function onIsIdleInhibitedChanged() { coffeeCanvas.requestPaint(); }
                }
            }

            // Tooltip Popup
            ToolTip.visible: inhibitorArea.containsMouse
            ToolTip.text: root.isIdleInhibited ? "Idle Inhibitor: ACTIVE (Screen won't sleep)" : "Idle Inhibitor: INACTIVE (Screen will sleep)"
            ToolTip.delay: 200

            MouseArea {
                id: inhibitorArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.toggleIdleInhibitor();
                }
            }
        }
    }
}
