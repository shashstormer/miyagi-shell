import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../components"

ColumnLayout {
    id: root

    property int focusIndex: -1
    property int actionIndex: 0

    function getItemCount() {
        return 4;
    }

    function handleHorizontal(delta) {
        // No sub-actions in this view
    }

    function triggerItem() {
        if (focusIndex === 0) item0.triggerToggle();
        else if (focusIndex === 1) item1.triggerToggle();
        else if (focusIndex === 2) item2.triggerToggle();
        else if (focusIndex === 3) item3.triggerToggle();
    }

    Layout.fillWidth: true
    spacing: 14

    SettingCardGroup {
        titleText: "Desktop Widgets"
        iconName: "widgets"

        SettingToggleRow {
            id: item0
            labelText: "Show Media Player Card"
            descriptionText: "Display MPRIS music player card"
            iconName: "audio"
            checked: ConfigService.showMediaPlayer
            isFocused: root.focusIndex === 0
            onToggled: newValue => ConfigService.showMediaPlayer = newValue
        }

        SettingToggleRow {
            id: item1
            labelText: "Over-Amplify Volume (Up to 150%)"
            descriptionText: "Allow output volume slider to exceed 100%"
            iconName: "volume"
            checked: ConfigService.enableOverAmplify
            isFocused: root.focusIndex === 1
            onToggled: newValue => ConfigService.enableOverAmplify = newValue
        }

        SettingToggleRow {
            id: item2
            labelText: "Show Clock Widget"
            descriptionText: "Display desktop clock widget"
            iconName: "clock"
            checked: ConfigService.showClock
            isFocused: root.focusIndex === 2
            onToggled: newValue => ConfigService.showClock = newValue
        }

        SettingToggleRow {
            id: item3
            labelText: "Show Workspaces Widget"
            descriptionText: "Display floating desktop workspaces widget"
            iconName: "grid9"
            checked: ConfigService.showWorkspaces
            isFocused: root.focusIndex === 3
            onToggled: newValue => ConfigService.showWorkspaces = newValue
        }
    }
}
