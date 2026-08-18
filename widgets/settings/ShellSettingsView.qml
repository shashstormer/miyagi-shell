import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../components"

ColumnLayout {
    id: root

    property int focusIndex: -1
    property int actionIndex: 0

    function getItemCount() {
        return 12;
    }

    function handleHorizontal(delta) {
        if (focusIndex === 4) {
            topBarPosItem.cycle(delta);
        } else if (focusIndex === 8) {
            leftBarPosItem.cycle(delta);
        } else if (focusIndex === 10) {
            cavaFpsItem.cycle(delta);
        }
    }

    function triggerItem() {
        if (focusIndex === 0) item0.triggerToggle();
        else if (focusIndex === 1) item1.triggerToggle();
        else if (focusIndex === 2) item2.triggerToggle();
        else if (focusIndex === 3) item3.triggerToggle();
        else if (focusIndex === 4) topBarPosItem.cycle(1);
        else if (focusIndex === 5) item5.triggerToggle();
        else if (focusIndex === 6) item6.triggerToggle();
        else if (focusIndex === 7) item7.triggerToggle();
        else if (focusIndex === 8) leftBarPosItem.cycle(1);
        else if (focusIndex === 9) item9.triggerToggle();
        else if (focusIndex === 10) cavaFpsItem.cycle(1);
        else if (focusIndex === 11) item11.triggerToggle();
    }

    Layout.fillWidth: true
    spacing: 12

    // ==========================================
    // 1. DYNAMIC ISLAND
    // ==========================================
    SettingCardGroup {
        titleText: "Dynamic Island"

        SettingToggleRow {
            id: item0
            labelText: "Enable Dynamic Island"
            descriptionText: "Interactive top-center pill for notifications, media, and status"
            checked: ConfigService.enableDynamicIsland
            isFocused: root.focusIndex === 0
            onToggled: newValue => ConfigService.enableDynamicIsland = newValue
        }

        SettingToggleRow {
            id: item1
            labelText: "Auto-Hide on Fullscreen"
            descriptionText: "Tuck away island when active window is fullscreen"
            checked: ConfigService.islandFullscreenAutoHide
            isFocused: root.focusIndex === 1
            onToggled: newValue => ConfigService.islandFullscreenAutoHide = newValue
        }

        SettingToggleRow {
            id: item2
            labelText: "Mouse Click Pass-Through"
            descriptionText: "Allow clicks to pass through collapsed island"
            checked: ConfigService.islandPassThrough
            isFocused: root.focusIndex === 2
            onToggled: newValue => ConfigService.islandPassThrough = newValue
        }
    }

    // ==========================================
    // 2. TOP BAR
    // ==========================================
    SettingCardGroup {
        titleText: "Top Status Bar"

        SettingToggleRow {
            id: item3
            labelText: "Enable Top Bar"
            descriptionText: "Show desktop status bar with clock, workspaces, and tray"
            checked: ConfigService.enableTopBar
            isFocused: root.focusIndex === 3
            onToggled: newValue => ConfigService.enableTopBar = newValue
        }

        SettingPillSelector {
            id: topBarPosItem
            labelText: "Screen Position"
            options: ["Top", "Bottom"]
            selectedIndex: ConfigService.barPosition === "bottom" ? 1 : 0
            isFocused: root.focusIndex === 4
            onOptionSelected: (idx, opt) => ConfigService.barPosition = idx === 1 ? "bottom" : "top"
        }

        SettingToggleRow {
            id: item5
            labelText: "Auto-Hide Top Bar"
            descriptionText: "Slide bar off-screen when cursor leaves screen edge"
            checked: ConfigService.topBarAutoHide
            isFocused: root.focusIndex === 5
            onToggled: newValue => ConfigService.topBarAutoHide = newValue
        }

        SettingToggleRow {
            id: item6
            labelText: "Workspaces Pager"
            descriptionText: "Display virtual workspace indicators"
            checked: ConfigService.topBarShowWorkspaces
            isFocused: root.focusIndex === 6
            onToggled: newValue => ConfigService.topBarShowWorkspaces = newValue
        }
    }

    // ==========================================
    // 3. LEFT DOCK / BAR
    // ==========================================
    SettingCardGroup {
        titleText: "Left Dock & Action Bar"

        SettingToggleRow {
            id: item7
            labelText: "Enable Left Bar"
            descriptionText: "Vertical side dock with quick launchers and toggles"
            checked: ConfigService.enableLeftBar
            isFocused: root.focusIndex === 7
            onToggled: newValue => ConfigService.enableLeftBar = newValue
        }

        SettingPillSelector {
            id: leftBarPosItem
            labelText: "Menu Position"
            options: ["Top", "Bottom"]
            selectedIndex: ConfigService.leftBarMenuPosition === "bottom" ? 1 : 0
            isFocused: root.focusIndex === 8
            onOptionSelected: (idx, opt) => ConfigService.leftBarMenuPosition = idx === 1 ? "bottom" : "top"
        }

        SettingToggleRow {
            id: item9
            labelText: "Auto-Hide Left Bar"
            descriptionText: "Slide dock off-screen when not hovered"
            checked: ConfigService.leftBarAutoHide
            isFocused: root.focusIndex === 9
            onToggled: newValue => ConfigService.leftBarAutoHide = newValue
        }
    }

    // ==========================================
    // 4. DESKTOP WIDGETS
    // ==========================================
    SettingCardGroup {
        titleText: "Desktop Widgets & Visualizer"

        SettingPillSelector {
            id: cavaFpsItem
            labelText: "Cava Framerate"
            options: ["30 FPS", "60 FPS", "120 FPS"]
            readonly property var fpsValues: [30, 60, 120]
            selectedIndex: Math.max(0, fpsValues.indexOf(ConfigService.cavaFramerate))
            isFocused: root.focusIndex === 10
            onOptionSelected: (idx, opt) => ConfigService.cavaFramerate = fpsValues[idx] || 60
        }

        SettingToggleRow {
            id: item11
            labelText: "Desktop Media Player"
            descriptionText: "Interactive music widget on the desktop surface"
            checked: ConfigService.showMediaPlayer
            isFocused: root.focusIndex === 11
            onToggled: newValue => ConfigService.showMediaPlayer = newValue
        }
    }
}
