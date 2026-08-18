import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../components"

ColumnLayout {
    id: root

    property int focusIndex: -1
    property int actionIndex: 0

    function getItemCount() {
        return 9;
    }

    function handleHorizontal(delta) {
        if (focusIndex === 1) {
            posItem.cycle(delta);
        }
    }

    function triggerItem() {
        if (focusIndex === 0) item0.triggerToggle();
        else if (focusIndex === 1) posItem.cycle(1);
        else if (focusIndex === 2) item2.triggerToggle();
        else if (focusIndex === 3) item3.triggerToggle();
        else if (focusIndex === 4) item4.triggerToggle();
        else if (focusIndex === 5) item5.triggerToggle();
        else if (focusIndex === 6) item6.triggerToggle();
        else if (focusIndex === 7) item7.triggerToggle();
        else if (focusIndex === 8) item8.triggerToggle();
    }

    Layout.fillWidth: true
    spacing: 14

    SettingCardGroup {
        titleText: "Top Bar Layout & Alignment"
        iconName: "bar"

        SettingToggleRow {
            id: item0
            labelText: "Enable Top Bar"
            descriptionText: "Show or hide top bar on desktop"
            iconName: "sparkle"
            checked: ConfigService.enableTopBar
            isFocused: root.focusIndex === 0
            onToggled: newValue => ConfigService.enableTopBar = newValue
        }

        SettingPillSelector {
            id: posItem
            labelText: "Bar Position"
            iconName: "arrows"
            options: ["Top", "Bottom"]
            selectedIndex: ConfigService.barPosition === "bottom" ? 1 : 0
            isFocused: root.focusIndex === 1
            onOptionSelected: (idx, opt) => ConfigService.barPosition = idx === 1 ? "bottom" : "top"
        }

        SettingToggleRow {
            id: item2
            labelText: "Auto-Hide Top Bar"
            descriptionText: "Automatically hide top bar when cursor leaves top edge"
            iconName: "eye"
            checked: ConfigService.topBarAutoHide
            isFocused: root.focusIndex === 2
            onToggled: newValue => ConfigService.topBarAutoHide = newValue
        }

        SettingToggleRow {
            id: item3
            labelText: "Auto-Hide on Fullscreen"
            descriptionText: "Hide top bar when an application enters fullscreen mode"
            iconName: "eye"
            checked: ConfigService.topBarFullscreenAutoHide
            isFocused: root.focusIndex === 3
            onToggled: newValue => ConfigService.topBarFullscreenAutoHide = newValue
        }

        SettingToggleRow {
            id: item4
            labelText: "Auto-Hide on Desktop"
            descriptionText: "Hide top bar when viewing empty desktop with no active windows"
            iconName: "eye"
            checked: ConfigService.topBarDesktopAutoHide
            isFocused: root.focusIndex === 4
            onToggled: newValue => ConfigService.topBarDesktopAutoHide = newValue
        }
    }

    SettingCardGroup {
        titleText: "Top Bar Modules & Widgets"
        iconName: "widgets"

        SettingToggleRow {
            id: item5
            labelText: "Workspaces Pager"
            descriptionText: "Show dynamic workspaces indicator"
            iconName: "grid9"
            checked: ConfigService.topBarShowWorkspaces
            isFocused: root.focusIndex === 5
            onToggled: newValue => ConfigService.topBarShowWorkspaces = newValue
        }

        SettingToggleRow {
            id: item6
            labelText: "Media Player Module"
            descriptionText: "Show interactive media playback controls"
            iconName: "audio"
            checked: ConfigService.topBarShowMediaPlayer
            isFocused: root.focusIndex === 6
            onToggled: newValue => ConfigService.topBarShowMediaPlayer = newValue
        }

        SettingToggleRow {
            id: item7
            labelText: "System Tray Area"
            descriptionText: "Show active system tray status icons"
            iconName: "grid"
            checked: ConfigService.topBarShowSystemTray
            isFocused: root.focusIndex === 7
            onToggled: newValue => ConfigService.topBarShowSystemTray = newValue
        }

        SettingToggleRow {
            id: item8
            labelText: "Clock & Date Module"
            descriptionText: "Show centered clock and date module"
            iconName: "clock"
            checked: ConfigService.topBarShowClock
            isFocused: root.focusIndex === 8
            onToggled: newValue => ConfigService.topBarShowClock = newValue
        }
    }
}
