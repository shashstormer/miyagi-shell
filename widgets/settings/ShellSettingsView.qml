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
        return 5;
    }

    function handleHorizontal(delta) {
        if (focusIndex === 3) {
            cavaFpsItem.cycle(delta);
        }
    }

    function triggerItem() {
        if (focusIndex === 0) item0.triggerToggle();
        else if (focusIndex === 1) item1.triggerToggle();
        else if (focusIndex === 2) item2.triggerToggle();
        else if (focusIndex === 3) cavaFpsItem.cycle(1);
        else if (focusIndex === 4) item4.triggerToggle();
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
    // 2. DESKTOP WIDGETS
    // ==========================================
    SettingCardGroup {
        titleText: "Desktop Widgets & Visualizer"

        SettingPillSelector {
            id: cavaFpsItem
            labelText: "Cava Framerate"
            options: ["30 FPS", "60 FPS", "120 FPS"]
            readonly property var fpsValues: [30, 60, 120]
            selectedIndex: Math.max(0, fpsValues.indexOf(ConfigService.cavaFramerate))
            isFocused: root.focusIndex === 3
            onOptionSelected: (idx, opt) => ConfigService.cavaFramerate = fpsValues[idx] || 60
        }

        SettingToggleRow {
            id: item4
            labelText: "Desktop Media Player"
            descriptionText: "Interactive music widget on the desktop surface"
            checked: ConfigService.showMediaPlayer
            isFocused: root.focusIndex === 4
            onToggled: newValue => ConfigService.showMediaPlayer = newValue
        }
    }
}
