import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../components"

ColumnLayout {
    id: root

    property int focusIndex: -1
    property int actionIndex: 0

    function getItemCount() {
        return 7;
    }

    function handleHorizontal(delta) {
        if (focusIndex === 4) {
            menuPosItem.cycle(delta);
        }
    }

    function triggerItem() {
        if (focusIndex === 0) item0.triggerToggle();
        else if (focusIndex === 1) item1.triggerToggle();
        else if (focusIndex === 2) item2.triggerToggle();
        else if (focusIndex === 3) item3.triggerToggle();
        else if (focusIndex === 4) menuPosItem.cycle(1);
        else if (focusIndex === 5) item5.triggerToggle();
        else if (focusIndex === 6) item6.triggerToggle();
    }

    Layout.fillWidth: true
    spacing: 14

    SettingCardGroup {
        titleText: "Left Bar Options"
        iconName: "sliders"

        SettingToggleRow {
            id: item0
            labelText: "Enable Left Bar"
            descriptionText: "Show or hide left bar on desktop"
            iconName: "sparkle"
            checked: ConfigService.enableLeftBar
            isFocused: root.focusIndex === 0
            onToggled: newValue => ConfigService.enableLeftBar = newValue
        }

        SettingToggleRow {
            id: item1
            labelText: "Auto-Hide Left Bar"
            descriptionText: "Automatically hide left bar when cursor leaves left edge"
            iconName: "eye"
            checked: ConfigService.leftBarAutoHide
            isFocused: root.focusIndex === 1
            onToggled: newValue => ConfigService.leftBarAutoHide = newValue
        }

        SettingToggleRow {
            id: item2
            labelText: "Auto-Hide on Fullscreen"
            descriptionText: "Hide left bar when an application enters fullscreen mode"
            iconName: "eye"
            checked: ConfigService.leftBarFullscreenAutoHide
            isFocused: root.focusIndex === 2
            onToggled: newValue => ConfigService.leftBarFullscreenAutoHide = newValue
        }

        SettingToggleRow {
            id: item3
            labelText: "Auto-Hide on Desktop"
            descriptionText: "Hide left bar when viewing empty desktop with no active windows"
            iconName: "eye"
            checked: ConfigService.leftBarDesktopAutoHide
            isFocused: root.focusIndex === 3
            onToggled: newValue => ConfigService.leftBarDesktopAutoHide = newValue
        }
    }

    SettingCardGroup {
        titleText: "Left Bar Modules & Positioning"
        iconName: "grid9"

        SettingPillSelector {
            id: menuPosItem
            labelText: "Menu Button Position"
            iconName: "arrows"
            options: ["Top", "Bottom"]
            selectedIndex: ConfigService.leftBarMenuPosition === "bottom" ? 1 : 0
            isFocused: root.focusIndex === 4
            onOptionSelected: (idx, opt) => ConfigService.leftBarMenuPosition = idx === 1 ? "bottom" : "top"
        }

        SettingToggleRow {
            id: item5
            labelText: "App Launcher Menu Button"
            descriptionText: "Show 9-cubes launcher menu button"
            iconName: "grid9"
            checked: ConfigService.leftBarShowMenu
            isFocused: root.focusIndex === 5
            onToggled: newValue => ConfigService.leftBarShowMenu = newValue
        }

        SettingToggleRow {
            id: item6
            labelText: "Quick Controls Module"
            descriptionText: "Show Bluetooth, Wi-Fi, Mic, and Volume controls"
            iconName: "sliders"
            checked: ConfigService.leftBarShowControls
            isFocused: root.focusIndex === 6
            onToggled: newValue => ConfigService.leftBarShowControls = newValue
        }
    }
}
