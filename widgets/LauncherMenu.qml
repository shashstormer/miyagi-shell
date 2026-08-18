import QtQuick
import QtQuick.Layouts
import "../theme"

ColumnLayout {
    id: root

    spacing: 12
    property real staircaseStep: 62 // Width of the left dark index tab

    ParallelogramButton {
        indexText: "01"
        titleText: "FILES"
        iconType: "folder"
        Layout.leftMargin: 0
        onClicked: ConfigService.executeAction("launch_files")
    }

    ParallelogramButton {
        indexText: "02"
        titleText: "TERMINAL"
        iconType: "terminal"
        Layout.leftMargin: root.staircaseStep * 0.5
        onClicked: ConfigService.executeAction("launch_terminal")
    }

    ParallelogramButton {
        indexText: "03"
        titleText: "SETTINGS"
        iconType: "settings"
        Layout.leftMargin: root.staircaseStep * 1
        onClicked: {
            InputService.toggleSettings();
        }
    }

    ParallelogramButton {
        indexText: "04"
        titleText: "STEAM"
        iconType: "steam"
        Layout.leftMargin: root.staircaseStep * 1.5
        onClicked: ConfigService.executeAction("launch_steam")
    }
}

