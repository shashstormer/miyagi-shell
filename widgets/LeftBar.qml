import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"
import "./components"

Variants {
    id: leftBarVariants
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: barWindow

            required property var modelData
            screen: modelData

            readonly property bool isFsHidden: ConfigService.leftBarFullscreenAutoHide && ConfigService.isHyprlandFullscreen
            readonly property bool isDesktopHidden: ConfigService.leftBarDesktopAutoHide && !ConfigService.hasActiveWindow

            AutoHideController {
                id: autoHideCtrl
                autoHideEnabled: ConfigService.leftBarAutoHide
                isFlyoutOpen: (typeof bluetoothPanel !== "undefined" && bluetoothPanel && bluetoothPanel.isOpen) ||
                              (typeof wifiPanel !== "undefined" && wifiPanel && wifiPanel.isOpen) ||
                              (typeof calendarPanel !== "undefined" && calendarPanel && calendarPanel.isOpen) ||
                              (typeof volumePanel !== "undefined" && volumePanel && volumePanel.isOpen) ||
                              (typeof microphonePanel !== "undefined" && microphonePanel && microphonePanel.isOpen)
                hideDelay: 500
                extraHoverPadding: 16
            }

            readonly property bool isBarActive: ConfigService.isLoaded && ConfigService.enableLeftBar && !isFsHidden && !isDesktopHidden
            readonly property bool isBarVisible: autoHideCtrl.isBarVisible

            // Current Workspace Windows Filtering via ConfigService
            readonly property var currentWorkspaceWindows: ConfigService.getWorkspaceWindows()

            WlrLayershell.namespace: "quickshell-leftbar"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: isBarActive && !ConfigService.leftBarAutoHide ? 54 : 0
            color: "transparent"

            anchors {
                left: true
                top: true
                bottom: true
            }

            implicitWidth: isBarActive ? (isBarVisible ? 54 : 6) : 0
            implicitHeight: barWindow.screen ? barWindow.screen.height : 1080
            visible: isBarActive

            // Flush Left Bar Container Panel
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

                // TOP SECTION: LAYOUT SWITCHER BUTTON & BATTERY WIDGET
                Column {
                    id: layoutGroup
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 36
                    spacing: 10
                    visible: barWindow.isBarVisible

                    SquareButton {
                        id: layoutBtn
                        size: 36
                        customRadius: 8
                        iconName: {
                            var currentLayout = (ConfigService.workspaceLayouts && ConfigService.workspaceLayouts[ConfigService.activeWorkspaceId.toString()]) || "dwindle";
                            if (currentLayout === "master") return "master";
                            if (currentLayout === "scrolling") return "scrolling";
                            if (currentLayout === "monocle") return "monocle";
                            return "dwindle";
                        }
                        iconSize: 18
                        anchors.horizontalCenter: parent.horizontalCenter

                        onHoverEntered: {
                            var currentLayout = (ConfigService.workspaceLayouts && ConfigService.workspaceLayouts[ConfigService.activeWorkspaceId.toString()]) || "dwindle";
                            var label = currentLayout.charAt(0).toUpperCase() + currentLayout.slice(1) + " Layout";
                            var mappedPos = layoutBtn.mapToItem(null, 0, 0);
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) {
                                simpleTooltip.showTooltip(label, mappedPos.y + (layoutBtn.height / 2));
                            }
                        }

                        onHoverExited: {
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) {
                                simpleTooltip.hideTooltip();
                            }
                        }

                        onClicked: {
                            var currentLayout = (ConfigService.workspaceLayouts && ConfigService.workspaceLayouts[ConfigService.activeWorkspaceId.toString()]) || "dwindle";
                            var layouts = ["dwindle", "master", "scrolling", "monocle"];
                            var nextIdx = (layouts.indexOf(currentLayout) + 1) % layouts.length;
                            var nextLayout = layouts[nextIdx];
                            ConfigService.setWorkspaceLayout(ConfigService.activeWorkspaceId, nextLayout);

                            var updatedLabel = nextLayout.charAt(0).toUpperCase() + nextLayout.slice(1) + " Layout";
                            var mappedPos = layoutBtn.mapToItem(null, 0, 0);
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) {
                                simpleTooltip.showTooltip(updatedLabel, mappedPos.y + (layoutBtn.height / 2));
                            }
                        }
                    }

                    BatteryWidget {
                        id: batteryBtn
                        size: 36
                        customRadius: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: ConfigService.showBattery !== false
                        onClicked: {
                            if (typeof batteryPanel !== "undefined" && batteryPanel) {
                                batteryPanel.toggle();
                            }
                        }
                    }
                }

                // CENTRAL WORKSPACE APPS TASKBAR (Center Region)
                Column {
                    id: workspaceAppsGroup
                    anchors.centerIn: parent
                    width: 36
                    spacing: 10
                    visible: barWindow.isBarVisible && barWindow.currentWorkspaceWindows.length > 0

                    Repeater {
                        model: barWindow.currentWorkspaceWindows

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            readonly property string appClass: modelData.class_name ? modelData.class_name : (modelData.class ? modelData.class : "")
                            readonly property bool isMinimizedWin: !!modelData.is_minimized
                            readonly property bool isFocusedWin: !isMinimizedWin && (!!modelData.is_active || ConfigService.activeWindowTitle === modelData.title)

                            implicitWidth: 36
                            implicitHeight: 36
                            radius: 8
                            opacity: isMinimizedWin ? 0.45 : 1.0

                            color: isFocusedWin 
                                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22)
                                : (appMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14) : "transparent")

                            border.color: isFocusedWin ? Theme.primary : (isMinimizedWin ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.3) : (appMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent"))
                            border.width: isFocusedWin ? 1.5 : (isMinimizedWin ? 1 : (appMouse.containsMouse ? 1 : 0))

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            // Focused Active Pill Indicator
                            Rectangle {
                                visible: isFocusedWin
                                width: 3
                                height: 16
                                radius: 1.5
                                color: Theme.primary
                                anchors.left: parent.left
                                anchors.leftMargin: -4
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Minimized Dot Indicator
                            Rectangle {
                                visible: isMinimizedWin
                                width: 4
                                height: 4
                                radius: 2
                                color: Theme.on_surface
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            // Centralized App Icon
                            AppIcon {
                                anchors.centerIn: parent
                                icon: modelData.icon || ""
                                appClass: appClass
                                appTitle: modelData.title || modelData.initialTitle || ""
                                iconSize: 22
                                isHovered: appMouse.containsMouse
                                isCurrent: isFocusedWin
                            }

                            MouseArea {
                                id: appMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onEntered: {
                                    var mappedPos = appMouse.mapToItem(null, 0, 0);
                                    if (typeof windowPreviewTooltip !== "undefined" && windowPreviewTooltip) {
                                        windowPreviewTooltip.showTooltip(modelData, mappedPos.y);
                                    }
                                }

                                onExited: {
                                    if (typeof windowPreviewTooltip !== "undefined" && windowPreviewTooltip) {
                                        windowPreviewTooltip.hideTooltip();
                                    }
                                }

                                onClicked: {
                                    if (modelData.is_minimized) {
                                        ConfigService.toggleMinimize(modelData.address);
                                    } else if (isFocusedWin) {
                                        ConfigService.toggleMinimize(modelData.address);
                                    } else if (modelData.address) {
                                        ConfigService.executeAction("focus_address_" + modelData.address);
                                    } else if (modelData.class_name || modelData.class) {
                                        ConfigService.executeAction("focus_app_" + (modelData.class_name || modelData.class));
                                    }
                                }
                            }
                        }
                    }
                }

                // QUICK CONTROLS GROUP (Bluetooth, Wi-Fi, Mic, Volume)
                Column {
                    id: quickControlsGroup
                    visible: ConfigService.leftBarShowControls && barWindow.isBarVisible
                    width: 36
                    spacing: 10

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14

                    SquareButton {
                        id: btnBluetooth
                        size: 36
                        customRadius: 8
                        iconName: {
                            if (!ConfigService.bluetoothPowered) return "bluetooth_off";
                            if (ConfigService.bluetoothConnected) return "bluetooth_connected";
                            return "bluetooth";
                        }
                        iconSize: 18
                        customIconColor: {
                            if (!ConfigService.bluetoothPowered) return Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.38);
                            if (ConfigService.bluetoothConnected) return Theme.primary;
                            return Theme.on_surface;
                        }
                        hasIndicatorDot: ConfigService.bluetoothConnected
                        indicatorDotColor: Theme.primary
                        anchors.horizontalCenter: parent.horizontalCenter
                        isActive: typeof bluetoothPanel !== "undefined" && bluetoothPanel && bluetoothPanel.isOpen

                        onHoverEntered: {
                            var mappedPos = btnBluetooth.mapToItem(null, 0, 0);
                            var tooltip = "Bluetooth: Off";
                            if (ConfigService.bluetoothPowered) {
                                if (ConfigService.bluetoothConnected) {
                                    tooltip = "Bluetooth: " + (ConfigService.bluetoothDeviceName || "Connected") + (ConfigService.bluetoothBattery >= 0 ? " (" + ConfigService.bluetoothBattery + "%)" : "");
                                } else {
                                    tooltip = "Bluetooth: On (Disconnected)";
                                }
                            }
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) {
                                simpleTooltip.showTooltip(tooltip, mappedPos.y);
                            }
                        }
                        onHoverExited: {
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) {
                                simpleTooltip.hideTooltip();
                            }
                        }

                        onClicked: {
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) simpleTooltip.hideTooltip();
                            if (typeof bluetoothPanel !== "undefined" && bluetoothPanel) InputService.togglePanel(bluetoothPanel);
                        }
                    }

                    SquareButton {
                        id: btnWifi
                        size: 36
                        customRadius: 8
                        iconName: {
                            if (!ConfigService.wifiEnabled) return "wifi_off";
                            if (!ConfigService.wifiConnected) return "wifi_disconnected";
                            if (ConfigService.wifiSignal >= 70) return "wifi_full";
                            if (ConfigService.wifiSignal >= 35) return "wifi_medium";
                            return "wifi_low";
                        }
                        iconSize: 20
                        customIconColor: {
                            if (!ConfigService.wifiEnabled) return Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.38);
                            if (ConfigService.wifiConnected) return Theme.primary;
                            return Theme.on_surface;
                        }
                        hasIndicatorDot: ConfigService.wifiConnected
                        indicatorDotColor: Theme.primary
                        anchors.horizontalCenter: parent.horizontalCenter
                        isActive: typeof wifiPanel !== "undefined" && wifiPanel && wifiPanel.isOpen

                        onHoverEntered: {
                            var mappedPos = btnWifi.mapToItem(null, 0, 0);
                            var tooltip = "Wi-Fi: Disabled";
                            if (ConfigService.wifiEnabled) {
                                if (ConfigService.wifiConnected) {
                                    tooltip = "Wi-Fi: " + (ConfigService.wifiSsid || "Connected") + (ConfigService.wifiSignal > 0 ? " (" + ConfigService.wifiSignal + "%)" : "");
                                } else {
                                    tooltip = "Wi-Fi: Disconnected";
                                }
                            }
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) {
                                simpleTooltip.showTooltip(tooltip, mappedPos.y);
                            }
                        }
                        onHoverExited: {
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) {
                                simpleTooltip.hideTooltip();
                            }
                        }

                        onClicked: {
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) simpleTooltip.hideTooltip();
                            if (typeof wifiPanel !== "undefined" && wifiPanel) InputService.togglePanel(wifiPanel);
                        }
                    }

                    SquareButton {
                        id: btnMic
                        size: 36
                        customRadius: 8
                        iconName: (ConfigService.micMuted || ConfigService.micVolume === 0) ? "mic_off" : "mic"
                        iconSize: 18
                        customIconColor: {
                            if (ConfigService.micMuted || ConfigService.micVolume === 0) return Theme.error;
                            return Theme.on_surface;
                        }
                        hasIndicatorDot: ConfigService.micMuted
                        indicatorDotColor: Theme.error
                        anchors.horizontalCenter: parent.horizontalCenter
                        isActive: typeof microphonePanel !== "undefined" && microphonePanel && microphonePanel.isOpen

                        onHoverEntered: {
                            var mappedPos = btnMic.mapToItem(null, 0, 0);
                            var tooltip = ConfigService.micMuted ? "Microphone: Muted" : ("Microphone: " + ConfigService.micVolume + "%" + (ConfigService.micSourceName ? " (" + ConfigService.micSourceName + ")" : ""));
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) {
                                simpleTooltip.showTooltip(tooltip, mappedPos.y);
                            }
                        }
                        onHoverExited: {
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) {
                                simpleTooltip.hideTooltip();
                            }
                        }

                        onClicked: {
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) simpleTooltip.hideTooltip();
                            if (typeof microphonePanel !== "undefined" && microphonePanel) InputService.togglePanel(microphonePanel);
                        }
                    }

                    SquareButton {
                        id: btnVolume
                        size: 36
                        customRadius: 8
                        iconName: {
                            if (ConfigService.audioIsHeadphones) {
                                return (ConfigService.audioMuted || ConfigService.audioVolume === 0) ? "headphones_off" : "headphones";
                            }
                            if (ConfigService.audioMuted || ConfigService.audioVolume === 0) return "volume_mute";
                            if (ConfigService.audioVolume >= 67) return "volume_high";
                            if (ConfigService.audioVolume >= 34) return "volume_medium";
                            return "volume_low";
                        }
                        iconSize: 19
                        customIconColor: {
                            if (ConfigService.audioMuted || ConfigService.audioVolume === 0) return Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.38);
                            return ConfigService.audioVolume > 0 ? Theme.primary : Theme.on_surface;
                        }
                        hasIndicatorDot: ConfigService.audioMuted
                        indicatorDotColor: Theme.error
                        anchors.horizontalCenter: parent.horizontalCenter
                        isActive: typeof volumePanel !== "undefined" && volumePanel && volumePanel.isOpen

                        onHoverEntered: {
                            var mappedPos = btnVolume.mapToItem(null, 0, 0);
                            var tooltip = ConfigService.audioMuted ? "Audio: Muted" : ("Volume: " + ConfigService.audioVolume + "%" + (ConfigService.audioSinkName ? " (" + ConfigService.audioSinkName + ")" : ""));
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) {
                                simpleTooltip.showTooltip(tooltip, mappedPos.y);
                            }
                        }
                        onHoverExited: {
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) {
                                simpleTooltip.hideTooltip();
                            }
                        }

                        onClicked: {
                            if (typeof simpleTooltip !== "undefined" && simpleTooltip) simpleTooltip.hideTooltip();
                            if (typeof volumePanel !== "undefined" && volumePanel) InputService.togglePanel(volumePanel);
                        }
                    }
                }
            }
        }
    }
}
