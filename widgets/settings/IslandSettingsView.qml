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
        titleText: "Dynamic Island Options"
        iconName: "island"

        SettingToggleRow {
            id: item0
            labelText: "Enable Dynamic Island"
            descriptionText: "Toggle floating top-center island widget"
            iconName: "island"
            checked: ConfigService.enableDynamicIsland
            isFocused: root.focusIndex === 0
            onToggled: newValue => ConfigService.enableDynamicIsland = newValue
        }

        GridLayout {
            columns: 2
            columnSpacing: 24
            rowSpacing: 12
            Layout.fillWidth: true

            SettingInlineItem {
                id: item1
                labelText: "Static Size Mode"
                iconName: "sliders"
                checked: ConfigService.islandStaticSize
                isFocused: root.focusIndex === 1
                onToggled: newValue => ConfigService.islandStaticSize = newValue
            }

            SettingInlineItem {
                id: item2
                labelText: "Click Pass-Through Input"
                iconName: "settings"
                checked: ConfigService.islandPassThrough
                isFocused: root.focusIndex === 2
                onToggled: newValue => ConfigService.islandPassThrough = newValue
            }
        }

        SettingToggleRow {
            id: item3
            labelText: "Auto-Hide on Fullscreen"
            descriptionText: "Automatically hide island when active app is in fullscreen"
            iconName: "grid"
            checked: ConfigService.islandFullscreenAutoHide
            isFocused: root.focusIndex === 3
            onToggled: newValue => ConfigService.islandFullscreenAutoHide = newValue
        }
    }
}
