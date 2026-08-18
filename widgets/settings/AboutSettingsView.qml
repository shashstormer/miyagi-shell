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
        return 2;
    }

    function handleHorizontal(delta) {
    }

    function triggerItem() {
        if (focusIndex === 0) {
            ConfigService.saveConfig();
        } else if (focusIndex === 1) {
            ConfigService.refreshApplications();
        }
    }

    Layout.fillWidth: true
    spacing: 12

    // ==========================================
    // 1. HERO SYSTEM CARD
    // ==========================================
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 88
        radius: 14
        color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.55)
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Rectangle {
                width: 48
                height: 48
                radius: 12
                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)
                Layout.alignment: Qt.AlignVCenter

                VectorIcon {
                    anchors.centerIn: parent
                    name: "sparkle"
                    iconSize: 24
                    color: Theme.primary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    Text {
                        text: "Miyagi Rice"
                        color: Theme.on_surface
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Theme.fontFamilyDisplay
                    }

                    PillBadge {
                        text: "v2.5 Release"
                        isInteractive: false
                    }
                }

                Text {
                    text: "QtQuick & Wayland Desktop Shell"
                    color: Theme.on_surface_variant
                    font.pixelSize: 11
                    font.family: Theme.fontFamilyDisplay
                }
            }
        }
    }

    // ==========================================
    // 2. SYSTEM SPECIFICATIONS
    // ==========================================
    SettingCardGroup {
        titleText: "System & Desktop Specifications"

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            SettingStatCard {
                Layout.fillWidth: true
                value: "Hyprland"
                label: "Compositor"
                iconName: "layout"
                accentColor: Theme.primary
            }

            SettingStatCard {
                Layout.fillWidth: true
                value: "Quickshell"
                label: "Engine"
                iconName: "sparkle"
                accentColor: "#55E080"
            }

            SettingStatCard {
                Layout.fillWidth: true
                value: String(ConfigService.windowsList ? ConfigService.windowsList.length : 0)
                label: "Windows"
                iconName: "grid"
                accentColor: Theme.tertiary
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 56
            radius: 10
            color: Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.35)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Session:"
                        color: Theme.on_surface_variant
                        font.pixelSize: 11
                        font.family: Theme.fontFamilyDisplay
                    }
                    Text {
                        text: "Linux (x86_64)  •  Wayland"
                        color: Theme.on_surface
                        font.bold: true
                        font.pixelSize: 11
                        font.family: Theme.fontFamilyDisplay
                    }
                    Item { Layout.fillWidth: true }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Workspace:"
                        color: Theme.on_surface_variant
                        font.pixelSize: 11
                        font.family: Theme.fontFamilyDisplay
                    }
                    Text {
                        text: "Workspace " + (ConfigService.activeWorkspaceId || 1) + " (" + (ConfigService.activeWindowTitle || "Empty") + ")"
                        color: Theme.primary
                        font.bold: true
                        font.pixelSize: 11
                        font.family: Theme.fontFamilyDisplay
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    // ==========================================
    // 3. SYSTEM ACTIONS & MAINTENANCE
    // ==========================================
    SettingCardGroup {
        titleText: "Maintenance Actions"

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ActionButton {
                Layout.fillWidth: true
                text: "Save & Sync Config"
                iconName: "save"
                isFocused: root.focusIndex === 0
                onClicked: ConfigService.saveConfig()
            }

            ActionButton {
                Layout.fillWidth: true
                text: "Reload App Database"
                iconName: "refresh"
                variant: "surface"
                isFocused: root.focusIndex === 1
                onClicked: ConfigService.refreshApplications()
            }
        }
    }
}
