import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../theme"

Rectangle {
    id: root

    implicitWidth: wsRow.implicitWidth + 24
    implicitHeight: 42
    visible: ConfigService.showWorkspaces

    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 0.88)
    border.color: Theme.outline_variant
    border.width: 1.5
    radius: 8

    readonly property var workspaceList: {
        var activeId = ConfigService.activeWorkspaceId || 1;
        var set = {};
        set[activeId] = true;
        for (var i = 1; i <= 5; i++) {
            set[i] = true;
        }
        var winList = ConfigService.windowsList;
        if (winList && winList.length > 0) {
            for (var j = 0; j < winList.length; j++) {
                var w = winList[j];
                if (w && w.workspace_id && w.workspace_id > 0) {
                    set[w.workspace_id] = true;
                }
            }
        }
        var keys = Object.keys(set).map(function(k) { return parseInt(k); });
        keys.sort(function(a, b) { return a - b; });
        return keys;
    }

    RowLayout {
        id: wsRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: root.workspaceList

            delegate: Rectangle {
                id: wsItem
                required property var modelData
                property int wsId: modelData
                property bool isActive: (ConfigService.activeWorkspaceId === wsId)
                property int winCount: {
                    var winList = ConfigService.windowsList;
                    if (!winList || winList.length === 0) return 0;
                    var c = 0;
                    for (var i = 0; i < winList.length; i++) {
                        if (winList[i].workspace_id === wsId) c++;
                    }
                    return c;
                }
                property bool hasWindows: winCount > 0

                implicitWidth: isActive ? 32 : (hasWindows ? 28 : 24)
                implicitHeight: 24
                radius: 12

                color: isActive ? Theme.primary : (hasWindows ? Qt.rgba(Theme.secondary_container.r, Theme.secondary_container.g, Theme.secondary_container.b, 0.8) : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.5))
                border.color: isActive ? Theme.primary : (hasWindows ? Theme.secondary : Theme.outline_variant)
                border.width: 1

                Behavior on implicitWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent
                    text: wsId.toString()
                    color: isActive ? Theme.on_primary : (hasWindows ? Theme.on_secondary_container : Theme.on_surface_variant)
                    font.pixelSize: 11
                    font.bold: isActive || hasWindows
                    font.family: Theme.fontFamilySans
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        try {
                            var mappedPos = wsMouse.mapToItem(null, 0, 0);
                            if (mappedPos && typeof workspacePreviewTooltip !== "undefined" && workspacePreviewTooltip) {
                                workspacePreviewTooltip.showTooltip(wsId, mappedPos.x + (wsItem.implicitWidth / 2), mappedPos.y + root.height + 6, true);
                            }
                        } catch (e) {}
                    }

                    onExited: {
                        if (typeof workspacePreviewTooltip !== "undefined" && workspacePreviewTooltip) {
                            workspacePreviewTooltip.hideTooltip();
                        }
                    }

                    onClicked: {
                        ConfigService.switchWorkspace(wsId);
                    }
                }
            }
        }
    }
}
