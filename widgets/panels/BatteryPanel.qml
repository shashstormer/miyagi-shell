import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../components"

Scope {
    id: batteryPanelScope

    readonly property var batResp: ConfigService.batteryStatus
    readonly property var primaryBat: batResp ? (batResp.primary || batResp) : null
    readonly property var allDevices: (batResp && batResp.all_devices) ? batResp.all_devices : []

    property bool isOpen: batteryWindow.isOpen
    property alias openedFrom: batteryWindow.openedFrom

    function toggle() {
        if (batteryWindow.visible) {
            close();
        } else {
            open();
        }
    }

    function open() {
        ConfigService.fetchBatteryStatus();
        batteryWindow.open();
    }

    function close() {
        batteryWindow.close();
    }

    Connections {
        target: InputService
        enabled: batteryWindow.isOpen

        function onNavBack() {
            InputService.closeOrReturn(batteryWindow);
        }
        function onNavNextTab() {
            ConfigService.fetchBatteryStatus();
        }
        function onNavPrevTab() {
            ConfigService.fetchBatteryStatus();
        }
    }

    BaseFlyoutPanel {
        id: batteryWindow

        title: "Battery & Power"
        iconName: "battery"
        side: "left"
        cardWidth: 380
        cardHeight: 520
        showSwitch: false
        showRefresh: true

        onRefreshClicked: {
            ConfigService.fetchBatteryStatus();
        }

        ScrollView {
            id: batteryScrollView
            anchors.fill: parent
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: batteryScrollView.availableWidth > 0 ? batteryScrollView.availableWidth : 348
                spacing: 16

                // ==========================================
                // 1. PRIMARY BATTERY HERO CARD
                // ==========================================
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 146
                    radius: 14
                    color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.6)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.18)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16

                        // Left Column: Big Percentage, Status Pill & Life
                        ColumnLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true

                            RowLayout {
                                spacing: 10

                                Text {
                                    text: (primaryBat ? (primaryBat.percentage !== undefined ? primaryBat.percentage : 100) : 100) + "%"
                                    color: (primaryBat && primaryBat.is_low) ? Theme.error : Theme.on_surface
                                    font.pixelSize: 34
                                    font.bold: true
                                    font.family: Theme.fontFamilyDisplay
                                }

                                Rectangle {
                                    implicitWidth: statusText.implicitWidth + 14
                                    implicitHeight: 22
                                    radius: 11
                                    color: (primaryBat && primaryBat.is_charging) ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.8)
                                    border.color: (primaryBat && primaryBat.is_charging) ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                                    border.width: 1

                                    Text {
                                        id: statusText
                                        anchors.centerIn: parent
                                        text: {
                                            if (!primaryBat) return "Discharging";
                                            if (primaryBat.is_charging) return "Charging";
                                            if (primaryBat.is_plugged_in) return "Plugged In";
                                            if (primaryBat.state) return primaryBat.state.charAt(0).toUpperCase() + primaryBat.state.slice(1);
                                            return "Discharging";
                                        }
                                        color: (primaryBat && primaryBat.is_charging) ? Theme.primary : Theme.on_surface_variant
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }

                            Text {
                                text: {
                                    if (!primaryBat) return "";
                                    return primaryBat.eta || (primaryBat.is_plugged_in ? "AC Power Connected" : "On Battery Power");
                                }
                                color: Theme.on_surface_variant
                                font.pixelSize: 12
                            }

                            Text {
                                text: primaryBat ? (primaryBat.name || primaryBat.model || primaryBat.native_path || "") : ""
                                visible: text !== ""
                                color: Theme.outline
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.maximumWidth: 170
                            }
                        }

                        // Right Column: Battery Telemetry Grid (Rate, Health, Cycles)
                        ColumnLayout {
                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                implicitWidth: 124
                                implicitHeight: 28
                                radius: 8
                                color: Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.75)
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    Text { text: "Rate"; color: Theme.outline; font.pixelSize: 11; Layout.fillWidth: true }
                                    Text { text: (primaryBat && primaryBat.energy_rate) ? primaryBat.energy_rate : "0 W"; color: Theme.on_surface; font.pixelSize: 11; font.bold: true }
                                }
                            }

                            Rectangle {
                                implicitWidth: 124
                                implicitHeight: 28
                                radius: 8
                                color: Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.75)
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    Text { text: "Health"; color: Theme.outline; font.pixelSize: 11; Layout.fillWidth: true }
                                    Text { text: (primaryBat && primaryBat.health_capacity) ? primaryBat.health_capacity : "100%"; color: Theme.on_surface; font.pixelSize: 11; font.bold: true }
                                }
                            }

                            Rectangle {
                                implicitWidth: 124
                                implicitHeight: 28
                                radius: 8
                                color: Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.75)
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    Text { text: "Cycles"; color: Theme.outline; font.pixelSize: 11; Layout.fillWidth: true }
                                    Text { text: primaryBat ? primaryBat.cycles.toString() : "0"; color: Theme.on_surface; font.pixelSize: 11; font.bold: true }
                                }
                            }
                        }
                    }
                }

                // ==========================================
                // 2. POWER SUPPLIES & CONNECTED DEVICES LIST
                // ==========================================
                Text {
                    text: "POWER DEVICES & ACCESSORIES (" + allDevices.length + ")"
                    color: Theme.primary
                    font.bold: true
                    font.pixelSize: 11
                    font.family: Theme.fontFamilyDisplay
                    visible: allDevices.length > 0
                }

                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    Repeater {
                        model: allDevices

                        delegate: Rectangle {
                            id: devDelegate
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 56
                            radius: 14
                            color: devMouseArea.containsMouse ? Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.6) : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.45)
                            border.color: devMouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 12

                                // Device Category Icon
                                Rectangle {
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    radius: 16
                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)

                                    VectorIcon {
                                        anchors.centerIn: parent
                                        name: {
                                            if (modelData.device_type === "line-power" || modelData.online) return "power";
                                            if (modelData.device_type === "headset") return "headphones";
                                            if (modelData.device_type === "mouse") return "mouse";
                                            if (modelData.device_type === "keyboard") return "keyboard";
                                            return "battery";
                                        }
                                        color: modelData.online ? Theme.primary : Theme.on_surface_variant
                                        iconSize: 17
                                    }
                                }

                                // Device Title & Subtitle Info
                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true

                                    Text {
                                        text: modelData.name || modelData.model || modelData.native_path || modelData.device
                                        color: Theme.on_surface
                                        font.pixelSize: 13
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        spacing: 6

                                        Text {
                                            text: {
                                                if (modelData.device_type === "line-power") {
                                                    return modelData.online ? "AC Power Connected" : "Disconnected";
                                                }
                                                if (modelData.state) {
                                                    return modelData.state.charAt(0).toUpperCase() + modelData.state.slice(1);
                                                }
                                                return modelData.native_path || "Connected";
                                            }
                                            color: Theme.on_surface_variant
                                            font.pixelSize: 11
                                        }

                                        Text {
                                            visible: modelData.voltage !== "" && modelData.voltage !== "N/A"
                                            text: "•  " + modelData.voltage
                                            color: Theme.outline
                                            font.pixelSize: 10
                                        }

                                        Text {
                                            visible: modelData.energy_rate !== "" && modelData.energy_rate !== "0 W" && modelData.energy_rate !== "N/A"
                                            text: "•  " + modelData.energy_rate
                                            color: Theme.outline
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // Status Badge / Percentage
                                Rectangle {
                                    implicitWidth: statusBadgeText.implicitWidth + 14
                                    implicitHeight: 24
                                    radius: 12
                                    color: (modelData.online || (modelData.percentage !== undefined && modelData.percentage > 20)) ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.6)

                                    Text {
                                        id: statusBadgeText
                                        anchors.centerIn: parent
                                        text: {
                                            if (modelData.device_type === "line-power") return modelData.online ? "Online" : "Offline";
                                            if (modelData.percentage_str) return modelData.percentage_str;
                                            if (modelData.percentage !== undefined && modelData.percentage > 0) return modelData.percentage + "%";
                                            return "Active";
                                        }
                                        color: modelData.online ? Theme.primary : Theme.on_surface
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }

                            MouseArea {
                                id: devMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }
        }
    }
}
