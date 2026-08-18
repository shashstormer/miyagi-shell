import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../theme"
import "./components"

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: barWindow

            required property var modelData
            screen: modelData

            readonly property bool isFsHidden: ConfigService.topBarFullscreenAutoHide && ConfigService.isHyprlandFullscreen
            readonly property bool isDesktopHidden: ConfigService.topBarDesktopAutoHide && !ConfigService.hasActiveWindow
            AutoHideController {
                id: autoHideCtrl
                autoHideEnabled: ConfigService.topBarAutoHide
                isFlyoutOpen: (typeof bluetoothPanel !== "undefined" && bluetoothPanel && bluetoothPanel.isOpen) ||
                              (typeof wifiPanel !== "undefined" && wifiPanel && wifiPanel.isOpen)
                hideDelay: 500
                extraHoverPadding: 16
            }

            readonly property bool isBarActive: ConfigService.isLoaded && ConfigService.enableTopBar && !isFsHidden && !isDesktopHidden
            readonly property bool isBarVisible: autoHideCtrl.isBarVisible

            WlrLayershell.namespace: "quickshell-topbar"
            WlrLayershell.layer: WlrLayer.Top
            exclusionMode: isBarActive && !ConfigService.topBarAutoHide ? ExclusionMode.Normal : ExclusionMode.Ignore
            exclusiveZone: isBarActive && !ConfigService.topBarAutoHide ? 48 : 0
            color: "transparent"

            anchors {
                top: ConfigService.barPosition !== "bottom"
                bottom: ConfigService.barPosition === "bottom"
                left: true
                right: true
            }

            implicitHeight: isBarActive ? (isBarVisible ? 48 : 6) : 0
            visible: isBarActive

            property var now: new Date()
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: barWindow.now = new Date()
            }

            // Flush Top Bar Container Panel (Exact 1:1 match with LeftBar architecture)
            Rectangle {
                id: panelBg
                anchors.fill: parent

                color: Theme.surface_container_lowest
                radius: 0

                // Hover detector on panel container using AutoHideController
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: autoHideCtrl.onMouseEntered()
                    onExited: autoHideCtrl.onMouseExited()
                }

                // Left-most App Grid Launcher Box
                SquareButton {
                    id: appGridBox
                    size: (ConfigService.enableLeftBar && !ConfigService.leftBarAutoHide) ? 54 : 48
                    implicitHeight: parent.height
                    customRadius: 0
                    anchors.left: parent.left
                    anchors.top: parent.top
                    iconName: "grid9"
                    iconSize: 20
                    isActive: typeof appLauncherPanel !== "undefined" && appLauncherPanel && appLauncherPanel.isOpen
                    onClicked: {
                        if (typeof appLauncherPanel !== "undefined" && appLauncherPanel) {
                            InputService.togglePanel(appLauncherPanel);
                        }
                    }
                }

                RowLayout {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: appGridBox.right
                    anchors.right: parent.right
                    anchors.leftMargin: 12
                    anchors.rightMargin: 16
                    spacing: 10
                    visible: barWindow.isBarVisible

                        // LEFT SECTION: Workspace Switcher using SquareButtons (1..10)
                        Row {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                model: 10
                                delegate: SquareButton {
                                    id: wsBtn
                                    required property int index
                                    size: 28
                                    customRadius: 6
                                    text: (index + 1).toString()
                                    isActive: index === ((ConfigService.activeWorkspaceId || 1) - 1)
                                    onClicked: ConfigService.switchWorkspace(index + 1)

                                    onHoverEntered: {
                                        var mappedPos = wsBtn.mapToItem(null, 0, 0);
                                        if (typeof workspacePreviewTooltip !== "undefined" && workspacePreviewTooltip) {
                                            workspacePreviewTooltip.showTooltip(index + 1, mappedPos.x + (wsBtn.width / 2), 0, false);
                                        }
                                    }

                                    onHoverExited: {
                                        if (typeof workspacePreviewTooltip !== "undefined" && workspacePreviewTooltip) {
                                            workspacePreviewTooltip.hideTooltip();
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // CENTER SECTION: Active Window Title
                        Text {
                            Layout.fillWidth: true
                            Layout.maximumWidth: 400
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: ConfigService.activeWindowTitle || ""
                            color: Theme.on_surface
                            font.bold: true
                            font.pixelSize: 12
                            font.family: Theme.fontFamilyDisplay
                            visible: ConfigService.hasActiveWindow && ConfigService.activeWindowTitle !== ""
                        }

                        Item { Layout.fillWidth: true }

                        // RIGHT SECTION: Clock & Date Module
                        SquareButton {
                            id: clockBtn
                            visible: ConfigService.topBarShowClock
                            size: 32
                            customRadius: 8
                            text: Qt.formatDateTime(barWindow.now, "hh:mm:ss  /  ddd MMM d").toUpperCase()
                            isActive: typeof calendarPanel !== "undefined" && calendarPanel && calendarPanel.isOpen

                            onClicked: {
                                if (typeof calendarPanel !== "undefined" && calendarPanel) {
                                    InputService.togglePanel(calendarPanel);
                                }
                            }
                        }

                        // RIGHTMOST SECTION: Notification Bell Button
                        SquareButton {
                            id: notifBellBtn
                            size: 32
                            customRadius: 8
                            iconName: "bell"
                            iconSize: 18
                            isActive: typeof notificationPanel !== "undefined" && notificationPanel && notificationPanel.isOpen

                            onClicked: {
                                if (typeof notificationPanel !== "undefined" && notificationPanel) {
                                    InputService.togglePanel(notificationPanel);
                                }
                            }

                            // Unread count badge
                            Rectangle {
                                readonly property int unreadCount: typeof notificationPanel !== "undefined" && notificationPanel ? notificationPanel.unreadCount : 0
                                visible: unreadCount > 0
                                width: 16
                                height: 16
                                radius: 8
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: -3
                                anchors.rightMargin: -3
                                color: Theme.primary

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.unreadCount > 9 ? "9+" : parent.unreadCount.toString()
                                    color: Theme.on_primary
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

