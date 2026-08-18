import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../components"

Item {
    id: root

    property int focusIndex: -1
    property int actionIndex: 0

    readonly property var batResp: ConfigService.batteryStatus
    readonly property var primaryBat: batResp ? (batResp.primary || batResp) : null
    readonly property var allDevices: (batResp && batResp.all_devices) ? batResp.all_devices : []

    function getItemCount() {
        return 2; // Power Profile, Refresh button
    }

    function handleHorizontal(delta) {
        if (focusIndex === 0) {
            profileSelector.cycle(delta);
        }
    }

    function triggerItem() {
        if (focusIndex === 0) {
            profileSelector.cycle(1);
        } else if (focusIndex === 1) {
            ConfigService.fetchBatteryStatus();
        }
    }

    implicitHeight: mainLayout.implicitHeight
    Layout.fillWidth: true

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 12

        // ==========================================
        // 1. BATTERY & CHARGING HERO GAUGE
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 110
            radius: 14
            color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.55)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 18

                // Circular Battery Ring
                Item {
                    width: 78
                    height: 78
                    Layout.alignment: Qt.AlignVCenter

                    CircularProgress {
                        anchors.fill: parent
                        value: (primaryBat && primaryBat.percentage !== undefined) ? primaryBat.percentage : 100
                        ringWidth: 6
                        trackColor: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.25)
                        color: {
                            var p = primaryBat ? (primaryBat.percentage || 100) : 100;
                            if (primaryBat && primaryBat.is_charging) return "#55E080";
                            if (p <= 20) return Theme.error;
                            if (p <= 40) return "#FFB366";
                            return Theme.primary;
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 0

                        Text {
                            text: (primaryBat && primaryBat.percentage !== undefined) ? (primaryBat.percentage + "%") : "100%"
                            color: Theme.on_surface
                            font.bold: true
                            font.pixelSize: 16
                            font.family: Theme.fontFamilyDisplay
                            Layout.alignment: Qt.AlignHCenter
                        }

                        VectorIcon {
                            name: (primaryBat && primaryBat.is_charging) ? "sparkle" : "battery"
                            iconSize: 12
                            color: (primaryBat && primaryBat.is_charging) ? "#55E080" : Theme.primary
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 3

                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true

                        Text {
                            text: (primaryBat && primaryBat.is_charging) 
                                ? "Charging on AC Power" 
                                : ((primaryBat && primaryBat.is_plugged_in) ? "AC Connected (Full)" : "Running on Battery")
                            color: Theme.on_surface
                            font.pixelSize: 16
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                        }

                        PillBadge {
                            text: (primaryBat && primaryBat.is_charging) ? "Charging" : ((primaryBat && primaryBat.state) ? primaryBat.state : "Active")
                            isInteractive: false
                            defaultColor: (primaryBat && primaryBat.is_charging) 
                                ? Qt.rgba(85/255, 224/255, 128/255, 0.18) 
                                : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            defaultTextColor: (primaryBat && primaryBat.is_charging) ? "#55E080" : Theme.primary
                        }
                    }

                    Text {
                        text: (primaryBat && primaryBat.time_remaining) 
                            ? ("Estimated: " + primaryBat.time_remaining)
                            : ((primaryBat && primaryBat.is_plugged_in) ? "AC Adapter Connected" : "Battery Level: " + (primaryBat ? primaryBat.percentage : 100) + "%")
                        color: Theme.on_surface_variant
                        font.pixelSize: 11
                        font.family: Theme.fontFamilyDisplay
                    }

                    Text {
                        text: "Power Rate: " + ((primaryBat && primaryBat.wattage) ? (primaryBat.wattage + " W") : "Normal") + "  •  Health: " + ((primaryBat && primaryBat.health) ? (primaryBat.health + "%") : "100%")
                        color: Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.7)
                        font.pixelSize: 10
                        font.family: Theme.fontFamilyDisplay
                    }
                }

                SquareButton {
                    text: "Refresh"
                    iconName: "arrow_clockwise"
                    size: 32
                    customRadius: 16
                    isActive: root.focusIndex === 1
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: ConfigService.fetchBatteryStatus()
                }
            }
        }

        // ==========================================
        // 2. SYSTEM POWER PROFILES
        // ==========================================
        SettingCardGroup {
            titleText: "System Energy & Performance Profiles"

            SettingPillSelector {
                id: profileSelector
                labelText: "Active Profile"
                options: ["Performance", "Balanced", "Power Saver"]
                readonly property var profileKeys: ["performance", "balanced", "power-saver"]
                selectedIndex: Math.max(0, profileKeys.indexOf(ConfigService.activePowerProfile))
                isFocused: root.focusIndex === 0
                onOptionSelected: (idx, opt) => {
                    var p = profileKeys[idx] || "balanced";
                    ConfigService.setPowerProfile(p);
                }
            }

            Text {
                text: ConfigService.activePowerProfile === "performance" 
                    ? "Maximum CPU/GPU clocks for intensive gaming and development workloads."
                    : (ConfigService.activePowerProfile === "power-saver" 
                        ? "Optimized for extended battery runtime, limits clock speeds and background power draw."
                        : "Balanced dynamic power management for responsive system performance.")
                color: Theme.on_surface_variant
                font.pixelSize: 11
                font.family: Theme.fontFamilyDisplay
                Layout.fillWidth: true
                Layout.leftMargin: 4
            }
        }

        // ==========================================
        // 3. BATTERY DIAGNOSTICS & TELEMETRY
        // ==========================================
        SettingCardGroup {
            titleText: "Battery Telemetry & Health"

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                SettingStatCard {
                    Layout.fillWidth: true
                    value: (primaryBat && primaryBat.health) ? (primaryBat.health + "%") : "100%"
                    label: "Health Capacity"
                    iconName: "battery"
                    accentColor: Theme.primary
                }

                SettingStatCard {
                    Layout.fillWidth: true
                    value: (primaryBat && primaryBat.cycles !== undefined) ? String(primaryBat.cycles) : "N/A"
                    label: "Charge Cycles"
                    iconName: "refresh"
                    accentColor: "#55E080"
                }

                SettingStatCard {
                    Layout.fillWidth: true
                    value: (primaryBat && primaryBat.technology) ? primaryBat.technology : "Li-Poly"
                    label: "Chemistry"
                    iconName: "sparkle"
                    accentColor: Theme.tertiary
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 56
                radius: 10
                color: Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.35)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Current Capacity"
                            color: Theme.on_surface_variant
                            font.pixelSize: 10
                            font.family: Theme.fontFamilyDisplay
                        }
                        Text {
                            text: ((primaryBat && primaryBat.energy) ? (primaryBat.energy + " Wh") : "Full") + " / " + ((primaryBat && primaryBat.energy_full) ? (primaryBat.energy_full + " Wh") : "Design")
                            color: Theme.on_surface
                            font.bold: true
                            font.pixelSize: 11
                            font.family: Theme.fontFamilyMono
                        }
                    }

                    Rectangle {
                        implicitWidth: 1
                        Layout.fillHeight: true
                        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Voltage & Power Rate"
                            color: Theme.on_surface_variant
                            font.pixelSize: 10
                            font.family: Theme.fontFamilyDisplay
                        }
                        Text {
                            text: ((primaryBat && primaryBat.voltage) ? (primaryBat.voltage + " V") : "11.4 V") + "  •  " + ((primaryBat && primaryBat.wattage) ? (primaryBat.wattage + " W") : "Normal")
                            color: Theme.primary
                            font.bold: true
                            font.pixelSize: 11
                            font.family: Theme.fontFamilyMono
                        }
                    }
                }
            }
        }

        // ==========================================
        // 4. CONNECTED POWER PERIPHERALS
        // ==========================================
        SettingCardGroup {
            titleText: "Connected Power Devices (" + root.allDevices.length + ")"

            EmptyState {
                visible: root.allDevices.length === 0
                iconName: "battery"
                title: "No other power devices"
                description: "Connected Bluetooth mice, keyboards, and accessories will appear here."
            }

            Repeater {
                model: root.allDevices
                delegate: Rectangle {
                    id: deviceRow
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: 10
                    color: Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.35)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        VectorIcon {
                            name: modelData.device_type === "line-power" ? "sparkle" : (modelData.device_type === "mouse" ? "mouse" : (modelData.device_type === "keyboard" ? "keyboard" : "battery"))
                            iconSize: 16
                            color: Theme.primary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.model || modelData.name || (modelData.device_type === "line-power" ? "AC Power Adapter" : "Peripheral Device")
                                color: Theme.on_surface
                                font.bold: true
                                font.pixelSize: 12
                                font.family: Theme.fontFamilyDisplay
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.device_type === "line-power" ? (modelData.online ? "Online Supplying Power" : "Offline") : ((modelData.percentage !== undefined ? (modelData.percentage + "% Battery") : "Connected"))
                                color: Theme.on_surface_variant
                                font.pixelSize: 10
                                font.family: Theme.fontFamilyDisplay
                            }
                        }

                        PillBadge {
                            text: modelData.percentage !== undefined ? (modelData.percentage + "%") : (modelData.online ? "Connected" : "Active")
                            isInteractive: false
                        }
                    }
                }
            }
        }
    }
}
