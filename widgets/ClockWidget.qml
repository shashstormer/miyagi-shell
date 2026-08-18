import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"

Rectangle {
    id: root

    implicitWidth: clockLayout.implicitWidth + 36
    implicitHeight: 68
    visible: ConfigService.showClock

    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 0.88)
    border.color: Theme.outline_variant
    border.width: 1.5
    radius: 8

    // Toggle 24-hour mode (true) vs 12-hour AM/PM mode (false)
    property bool use24Hour: true

    property var now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    readonly property string currentTime: Qt.formatDateTime(now, use24Hour ? "hh:mm:ss" : "hh:mm:ss AP")
    readonly property string currentDateString: Qt.formatDateTime(now, "dddd  /  MMM d, yyyy").toUpperCase()

    ColumnLayout {
        id: clockLayout
        anchors.centerIn: parent
        spacing: 2

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.currentTime
            color: Theme.primary
            font.pixelSize: 32
            font.bold: true
            font.family: Theme.fontFamilyDisplay
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.currentDateString
            color: Theme.tertiary
            font.pixelSize: 12
            font.bold: true
            font.family: Theme.fontFamilyDisplay
        }
    }
}
