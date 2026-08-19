//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_SVG_DEFAULT_OPTIONS=2

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications

import "./theme"
import "./widgets"
import "./widgets/panels"
import "./dynamic_island"

ShellRoot {
    id: root

    // Shared Global D-Bus Notification Server Instance
    NotificationServer {
        id: globalNotifServer
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => {
            if (notification) {
                notification.tracked = true;
            }
        }
    }

    // 1. Bottom Layer Desktop Window (Workspaces, Launcher, Clock, Media Player, System Tray, Notification Drawer)
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: desktopWindow
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "quickshell:miyagi-desktop"
            WlrLayershell.layer: WlrLayer.Bottom
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Item {
                id: desktopWidgetsContainer
                anchors.fill: parent
                opacity: !ConfigService.hasActiveWindow ? 1.0 : 0.0
                scale: !ConfigService.hasActiveWindow ? 1.0 : 0.98
                visible: opacity > 0.005

                readonly property real topOffset: 72
                readonly property real bottomOffset: 60
                readonly property real leftOffset: (ConfigService.enableLeftBar && !ConfigService.leftBarAutoHide) ? 72 : 40
                readonly property real rightOffset: 40

                Behavior on opacity {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                Behavior on scale {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                // Top Left Workspaces Widget
                WorkspacesWidget {
                    id: workspacesWidget
                    visible: ConfigService.showWorkspaces
                    anchors.top: parent.top
                    anchors.topMargin: desktopWidgetsContainer.topOffset
                    anchors.left: parent.left
                    anchors.leftMargin: desktopWidgetsContainer.leftOffset

                    Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.leftMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                // Left Action Launcher Menu (Staircase Parallelogram Banners)
                LauncherMenu {
                    id: launcherMenu
                    anchors.left: parent.left
                    anchors.leftMargin: desktopWidgetsContainer.leftOffset
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: desktopWidgetsContainer.bottomOffset

                    Behavior on anchors.leftMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on anchors.bottomMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                // Top Right Clock Widget
                ClockWidget {
                    id: clockWidget
                    visible: ConfigService.showClock
                    anchors.top: parent.top
                    anchors.topMargin: desktopWidgetsContainer.topOffset
                    anchors.right: parent.right
                    anchors.rightMargin: desktopWidgetsContainer.rightOffset

                    Behavior on anchors.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                // Bottom Right Stack: System Tray & Media Player Card
                ColumnLayout {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: desktopWidgetsContainer.bottomOffset
                    anchors.right: parent.right
                    anchors.rightMargin: desktopWidgetsContainer.rightOffset
                    spacing: 12

                    Behavior on anchors.bottomMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    SystemTrayWidget {
                        id: systemTray
                        visible: ConfigService.showSystemTray
                        parentWindow: desktopWindow
                        notifPanel: notificationPanel
                        Layout.alignment: Qt.AlignRight
                    }

                    MediaPlayer {
                        id: mediaPlayer
                        visible: ConfigService.showMediaPlayer
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }
        }
    }

    // 2. Overlay Layer Window for Toast Popups (Height binds dynamically to popup contentHeight)
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popupWindow
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "quickshell:miyagi-popups"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors {
                top: true
                right: true
            }

            margins {
                top: 60
                right: 40
            }

            implicitWidth: 360
            implicitHeight: Math.min(popupWidget.contentHeight, 600)

            Behavior on implicitHeight {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }

            NotificationWidget {
                id: popupWidget
                anchors.fill: parent
                notifServer: globalNotifServer
            }
        }
    }

    // 3. Floating Top-Center Dynamic Island Window
    Island {}

    // 4. Vertical Left Bar Window
    LeftBar {}

    // 5. Vantage Styled Top-Attached Bar Window
    TopBar {}

    // 6. Interactive Bluetooth Management Panel
    BluetoothPanel {
        id: bluetoothPanel
    }

    // 7. Interactive Wi-Fi Management Panel
    WifiPanel {
        id: wifiPanel
    }

    // 8. Interactive Notification Management Panel
    NotificationPanel {
        id: notificationPanel
        notifServer: globalNotifServer
    }

    // 9. Interactive Audio Output Volume Panel
    VolumePanel {
        id: volumePanel
    }

    // 10. Interactive Microphone Input Panel
    MicrophonePanel {
        id: microphonePanel
    }

    // 11. Interactive Calendar Panel
    CalendarPanel {
        id: calendarPanel
    }

    // 12. Interactive Battery & Power Panel
    BatteryPanel {
        id: batteryPanel
    }

    // 13. Interactive Application Launcher Panel
    AppLauncherPanel {
        id: appLauncherPanel
    }

    // 14. Interactive System Settings Dialog Panel
    SettingsPanel {
        id: settingsPanel
    }

    // 12. Floating Screencopy Window Preview Tooltip Module
    WindowPreviewTooltip {
        id: windowPreviewTooltip
    }

    // 13. Alt-Tab Window Switcher Overlay Panel
    AltTabPanel {
        id: altTabPanel
    }

    // 14. Floating Workspace Live Preview Tooltip Module
    WorkspacePreviewTooltip {
        id: workspacePreviewTooltip
    }

    // 15. Fullscreen Workspaces Overview Grid Panel
    WorkspacesOverviewPanel {
        id: workspacesOverviewPanel
    }

    // 16. Floating Simple Label Tooltip Module
    SimpleTooltip {
        id: simpleTooltip
    }

    // 17. Interactive Quick Menu Selector Panel
    MenuSelectorPanel {
        id: menuSelectorPanel
    }

    // 18. Focus Application Window Switcher Panel
    WindowSwitcherPanel {
        id: windowSwitcherPanel
    }

    // IPC Handler for Alt-Tab Switcher
    IpcHandler {
        target: "alttab"

        function next() {
            altTabPanel.openAndNext();
        }

        function prev() {
            altTabPanel.openAndPrev();
        }

        function close() {
            altTabPanel.confirmSelection();
        }

        function cancel() {
            altTabPanel.cancelSelection();
        }
    }

    // IPC Handler for Workspaces Overview
    IpcHandler {
        target: "overview"

        function toggle() {
            workspacesOverviewPanel.toggleOverview();
        }

        function next() {
            workspacesOverviewPanel.cycleNext();
        }

        function prev() {
            workspacesOverviewPanel.cyclePrev();
        }

        function open() {
            workspacesOverviewPanel.openOverview();
        }

        function close() {
            workspacesOverviewPanel.confirmSelection();
        }

        function cancel() {
            workspacesOverviewPanel.closeOverview();
        }
    }

    // IPC Handler for Application Launcher
    IpcHandler {
        target: "launcher"

        function toggle() {
            if (typeof appLauncherPanel !== "undefined" && appLauncherPanel) {
                appLauncherPanel.toggle();
            }
        }

        function open() {
            if (typeof appLauncherPanel !== "undefined" && appLauncherPanel) {
                appLauncherPanel.open();
            }
        }

        function close() {
            if (typeof appLauncherPanel !== "undefined" && appLauncherPanel) {
                appLauncherPanel.close();
            }
        }
    }

    // IPC Handler for Quick Menu Selector
    IpcHandler {
        target: "selector"

        function toggle() {
            if (typeof menuSelectorPanel !== "undefined" && menuSelectorPanel) {
                menuSelectorPanel.toggle();
            }
        }

        function open() {
            if (typeof menuSelectorPanel !== "undefined" && menuSelectorPanel) {
                menuSelectorPanel.open();
            }
        }

        function close() {
            if (typeof menuSelectorPanel !== "undefined" && menuSelectorPanel) {
                menuSelectorPanel.close();
            }
        }
    }

    // IPC Handler for Bluetooth Panel
    IpcHandler {
        target: "bluetooth"

        function toggle() {
            if (typeof bluetoothPanel !== "undefined" && bluetoothPanel) {
                bluetoothPanel.toggle();
            }
        }

        function open() {
            if (typeof bluetoothPanel !== "undefined" && bluetoothPanel) {
                bluetoothPanel.open();
            }
        }

        function close() {
            if (typeof bluetoothPanel !== "undefined" && bluetoothPanel) {
                bluetoothPanel.close();
            }
        }
    }

    // IPC Handler for Wi-Fi Panel
    IpcHandler {
        target: "wifi"

        function toggle() {
            if (typeof wifiPanel !== "undefined" && wifiPanel) {
                wifiPanel.toggle();
            }
        }

        function open() {
            if (typeof wifiPanel !== "undefined" && wifiPanel) {
                wifiPanel.open();
            }
        }

        function close() {
            if (typeof wifiPanel !== "undefined" && wifiPanel) {
                wifiPanel.close();
            }
        }
    }

    // IPC Handler for Notifications Panel
    IpcHandler {
        target: "notifications"

        function toggle() {
            if (typeof notificationPanel !== "undefined" && notificationPanel) {
                notificationPanel.toggle();
            }
        }

        function open() {
            if (typeof notificationPanel !== "undefined" && notificationPanel) {
                notificationPanel.open();
            }
        }

        function close() {
            if (typeof notificationPanel !== "undefined" && notificationPanel) {
                notificationPanel.close();
            }
        }
    }

    // Unified Generic Panel IPC Handler
    IpcHandler {
        target: "panel"

        function bluetooth() {
            if (typeof bluetoothPanel !== "undefined" && bluetoothPanel) bluetoothPanel.toggle();
        }
        function wifi() {
            if (typeof wifiPanel !== "undefined" && wifiPanel) wifiPanel.toggle();
        }
        function microphone() {
            if (typeof microphonePanel !== "undefined" && microphonePanel) microphonePanel.toggle();
        }
        function volume() {
            if (typeof volumePanel !== "undefined" && volumePanel) volumePanel.toggle();
        }
        function launcher() {
            if (typeof appLauncherPanel !== "undefined" && appLauncherPanel) appLauncherPanel.toggle();
        }
        function notifications() {
            if (typeof notificationPanel !== "undefined" && notificationPanel) notificationPanel.toggle();
        }
        function battery() {
            if (typeof batteryPanel !== "undefined" && batteryPanel) batteryPanel.toggle();
        }
        function calendar() {
            if (typeof calendarPanel !== "undefined" && calendarPanel) calendarPanel.toggle();
        }
        function selector() {
            if (typeof menuSelectorPanel !== "undefined" && menuSelectorPanel) menuSelectorPanel.toggle();
        }
        function menu() {
            if (typeof menuSelectorPanel !== "undefined" && menuSelectorPanel) menuSelectorPanel.toggle();
        }
        function settings() {
            if (typeof settingsPanel !== "undefined" && settingsPanel) settingsPanel.toggle();
        }
    }

    // IPC Handler for Settings Panel
    IpcHandler {
        target: "settings"

        function toggle() {
            if (typeof settingsPanel !== "undefined" && settingsPanel) settingsPanel.toggle();
        }
        function open() {
            if (typeof settingsPanel !== "undefined" && settingsPanel) settingsPanel.open();
        }
        function close() {
            if (typeof settingsPanel !== "undefined" && settingsPanel) settingsPanel.close();
        }
    }

    // IPC Handler for Input Service (Gamepad / Keyboard IPC Navigation)
    IpcHandler {
        target: "input"

        function inputOpenCount(): int {
            var count = 0;
            var panels = [
                typeof bluetoothPanel !== "undefined" ? bluetoothPanel : null,
                typeof wifiPanel !== "undefined" ? wifiPanel : null,
                typeof notificationPanel !== "undefined" ? notificationPanel : null,
                typeof volumePanel !== "undefined" ? volumePanel : null,
                typeof microphonePanel !== "undefined" ? microphonePanel : null,
                typeof calendarPanel !== "undefined" ? calendarPanel : null,
                typeof batteryPanel !== "undefined" ? batteryPanel : null,
                typeof appLauncherPanel !== "undefined" ? appLauncherPanel : null,
                typeof altTabPanel !== "undefined" ? altTabPanel : null,
                typeof workspacesOverviewPanel !== "undefined" ? workspacesOverviewPanel : null,
                typeof menuSelectorPanel !== "undefined" ? menuSelectorPanel : null,
                typeof windowSwitcherPanel !== "undefined" ? windowSwitcherPanel : null,
                typeof settingsPanel !== "undefined" ? settingsPanel : null
            ];
            for (var i = 0; i < panels.length; i++) {
                if (panels[i] && panels[i].isOpen) {
                    count++;
                }
            }
            return count;
        }

        function inputA() { InputService.buttonA(); }
        function inputB() { InputService.buttonB(); }
        function inputX() { InputService.buttonX(); }
        function inputY() { InputService.buttonY(); }
        function inputLB() { InputService.lb(); }
        function inputRB() { InputService.rb(); }
        function inputUp() { InputService.dpadUp(); }
        function inputDown() { InputService.dpadDown(); }
        function inputLeft() { InputService.dpadLeft(); }
        function inputRight() { InputService.dpadRight(); }
        function inputStart() { InputService.buttonStart(); }
        function inputMenu() { InputService.buttonMenu(); }
        function inputOptions() { InputService.buttonOptions(); }
        function inputContextMenu() { InputService.triggerContextMenu(); }
    }
}


