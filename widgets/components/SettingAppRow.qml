import QtQuick
import QtQuick.Layouts
import "../../theme"

Rectangle {
    id: root

    property string appName: ""
    property string appIcon: ""
    property string category: ""
    property string subtitle: ""
    property bool isSilent: false
    property bool isBlocked: false
    property bool isFocused: false
    property int focusedActionIndex: 0 // 0 = Silent, 1 = Block

    signal toggleSilent()
    signal toggleBlock()

    function triggerAction() {
        if (focusedActionIndex === 0) {
            root.toggleSilent();
        } else {
            root.toggleBlock();
        }
    }

    Layout.fillWidth: true
    implicitHeight: 56
    radius: 10
    color: (isFocused && InputService.isNonMouse)
        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
        : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.4)

    border.color: (isFocused && InputService.isNonMouse)
        ? Theme.primary
        : ((root.isBlocked || root.isSilent)
            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
            : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2))
    border.width: (isFocused && InputService.isNonMouse) ? 2 : 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        // App Icon Container
        Rectangle {
            implicitWidth: 34
            implicitHeight: 34
            radius: 8
            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)

            AppIcon {
                anchors.centerIn: parent
                icon: root.appIcon
                appTitle: root.appName
                iconSize: 22
            }
        }

        // App Name & Statistics Metadata
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                spacing: 6
                Text {
                    text: root.appName
                    color: (root.isFocused && InputService.isNonMouse) ? Theme.primary : Theme.on_surface
                    font.pixelSize: 13
                    font.bold: true
                    font.family: Theme.fontFamilyDisplay
                }

                // Silent Badge
                Rectangle {
                    visible: root.isSilent
                    implicitWidth: silentText.implicitWidth + 8
                    implicitHeight: 15
                    radius: 3
                    color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.2)
                    border.color: Theme.secondary
                    border.width: 1

                    Text {
                        id: silentText
                        anchors.centerIn: parent
                        text: "SILENT"
                        color: Theme.secondary
                        font.pixelSize: 8
                        font.bold: true
                        font.family: Theme.fontFamilyMono
                    }
                }

                // Blocked Badge
                Rectangle {
                    visible: root.isBlocked
                    implicitWidth: blockedText.implicitWidth + 8
                    implicitHeight: 15
                    radius: 3
                    color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2)
                    border.color: Theme.error
                    border.width: 1

                    Text {
                        id: blockedText
                        anchors.centerIn: parent
                        text: "BLOCKED"
                        color: Theme.error
                        font.pixelSize: 8
                        font.bold: true
                        font.family: Theme.fontFamilyMono
                    }
                }
            }

            // Subtitle with stats
            Text {
                text: root.subtitle !== "" ? root.subtitle : (root.category)
                color: Theme.on_surface_variant
                font.pixelSize: 10
                font.family: Theme.fontFamilyMono
            }
        }

        // Action Buttons: Silent Toggle & Block Toggle
        RowLayout {
            spacing: 8

            // Silence Toggle Button
            Rectangle {
                implicitWidth: 80
                implicitHeight: 30
                radius: 15
                color: root.isSilent
                    ? Theme.secondary
                    : (silentBtnMouse.containsMouse ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.2) : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.6))
                
                border.color: (root.isFocused && root.focusedActionIndex === 0 && InputService.isNonMouse)
                    ? Theme.primary
                    : (root.isSilent ? Theme.secondary : Theme.outline_variant)
                border.width: (root.isFocused && root.focusedActionIndex === 0 && InputService.isNonMouse) ? 2 : 1

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    VectorIcon {
                        name: root.isSilent ? "bell" : "bell-off"
                        iconSize: 11
                        color: root.isSilent ? Theme.on_secondary : Theme.on_surface_variant
                    }

                    Text {
                        text: root.isSilent ? "Silent" : "Mute"
                        color: root.isSilent ? Theme.on_secondary : Theme.on_surface
                        font.pixelSize: 10
                        font.bold: true
                        font.family: Theme.fontFamilyDisplay
                    }
                }

                MouseArea {
                    id: silentBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleSilent()
                }
            }

            // Block Toggle Button
            Rectangle {
                implicitWidth: 80
                implicitHeight: 30
                radius: 15
                color: root.isBlocked
                    ? Theme.error
                    : (blockBtnMouse.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2) : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.6))
                
                border.color: (root.isFocused && root.focusedActionIndex === 1 && InputService.isNonMouse)
                    ? Theme.primary
                    : (root.isBlocked ? Theme.error : Theme.outline_variant)
                border.width: (root.isFocused && root.focusedActionIndex === 1 && InputService.isNonMouse) ? 2 : 1

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    VectorIcon {
                        name: root.isBlocked ? "check" : "ban"
                        iconSize: 11
                        color: root.isBlocked ? Theme.on_error : Theme.on_surface_variant
                    }

                    Text {
                        text: root.isBlocked ? "Blocked" : "Block"
                        color: root.isBlocked ? Theme.on_error : Theme.on_surface
                        font.pixelSize: 10
                        font.bold: true
                        font.family: Theme.fontFamilyDisplay
                    }
                }

                MouseArea {
                    id: blockBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleBlock()
                }
            }
        }
    }
}
