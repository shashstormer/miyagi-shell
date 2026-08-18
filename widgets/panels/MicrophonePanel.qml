import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../components"
import "../components/ModelUtils.js" as ModelUtils

Scope {
    id: micPanelScope

    property bool isOpen: micWindow.isOpen
    property alias openedFrom: micWindow.openedFrom
    property int currentView: 0 // 0 = Sources List, 1 = Device Details Page
    property var selectedSource: null

    property int currentVolume: 100
    property bool isMuted: false
    property string activeSourceName: "Default Microphone"
    property var sourcesList: []

    function toggle() {
        if (micWindow.isOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        currentView = 0;
        selectedSource = null;
        micWindow.open();
        refresh();
    }

    function close() {
        micWindow.close();
    }

    function refresh() {
        ConfigService.fetchMicStatus(function(data) {
            if (!data) return;
            micPanelScope.currentVolume = data.volume !== undefined ? data.volume : 100;
            micPanelScope.isMuted = !!data.muted;
            micPanelScope.activeSourceName = data.active_source_name || "Default Microphone";
            micWindow.switchChecked = !micPanelScope.isMuted;

            if (data.sources) {
                micPanelScope.sourcesList = data.sources;
                if (micPanelScope.selectedSource) {
                    for (var i = 0; i < data.sources.length; i++) {
                        if (data.sources[i].id === micPanelScope.selectedSource.id) {
                            micPanelScope.selectedSource = data.sources[i];
                            break;
                        }
                    }
                }
            }
        });
    }

    property int selectedIndex: 0
    readonly property int totalItemCount: 1 + (sourcesList ? sourcesList.length : 0)

    function navigate(delta) {
        InputService.useKeyboard();
        if (totalItemCount > 0) {
            selectedIndex = Math.max(-1, Math.min(selectedIndex + delta, totalItemCount - 1));
            micWindow.isSwitchFocused = (selectedIndex === -1);
        } else {
            selectedIndex = -1;
            micWindow.isSwitchFocused = true;
        }
    }

    function adjustVolume(delta) {
        InputService.useKeyboard();
        if (selectedIndex <= 0) {
            var newVol = Math.max(0, Math.min(currentVolume + delta, 150));
            ConfigService.setMicVolume(newVol, function() { refresh(); });
        } else if (sourcesList && selectedIndex > 0 && selectedIndex <= sourcesList.length) {
            var source = sourcesList[selectedIndex - 1];
            if (source) {
                var sVol = Math.max(0, Math.min((source.volume || 100) + delta, 150));
                ConfigService.setSourceVolume(source.id, sVol, function() { refresh(); });
            }
        }
    }

    function activateSelected() {
        if (selectedIndex <= 0) {
            ConfigService.toggleMicMute(!isMuted, function() { refresh(); });
        } else if (sourcesList && selectedIndex > 0 && selectedIndex <= sourcesList.length) {
            var source = sourcesList[selectedIndex - 1];
            if (source) {
                ConfigService.setActiveSource(source.id, function() { refresh(); });
            }
        }
    }

    Connections {
        target: InputService
        enabled: micWindow.isOpen

        function onNavUp() {
            micPanelScope.navigate(-1);
        }
        function onNavDown() {
            micPanelScope.navigate(1);
        }
        function onNavLeft() {
            micPanelScope.adjustVolume(-5);
        }
        function onNavRight() {
            micPanelScope.adjustVolume(5);
        }
        function onNavSelect() {
            micPanelScope.activateSelected();
        }
        function onNavBack() {
            if (micPanelScope.currentView === 1) {
                micPanelScope.currentView = 0;
            } else if (selectedIndex !== 0) {
                selectedIndex = 0;
                micWindow.isSwitchFocused = false;
            } else {
                InputService.closeOrReturn(micWindow);
            }
        }
    }

    BaseFlyoutPanel {
        id: micWindow
        title: micPanelScope.currentView === 0 ? "Microphone" : "Microphone Settings"
        iconName: "mic"
        side: "left"
        cardWidth: 380
        cardHeight: 520
        showRefresh: true
        showSwitch: micPanelScope.currentView === 0

        onRefreshClicked: micPanelScope.refresh()
        onSwitchToggled: function(checked) {
            ConfigService.toggleMicMute(!checked, function() {
                micPanelScope.refresh();
            });
        }

        // VIEW 0: MAIN INPUT DEVICES & MASTER GAIN LIST
        ScrollView {
            id: mainScroll
            visible: micPanelScope.currentView === 0
            anchors.fill: parent
            clip: true

            ColumnLayout {
                width: mainScroll.availableWidth
                spacing: 14

                // Unified Master Mic Gain & Active Input Card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 96
                    radius: 12
                    color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.7)
                    border.color: (InputService.isNonMouse && micPanelScope.selectedIndex === 0) ? Theme.primary : Theme.outline_variant
                    border.width: (InputService.isNonMouse && micPanelScope.selectedIndex === 0) ? 2 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        // Top Header Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            VectorIcon {
                                name: "mic"
                                color: micPanelScope.isMuted ? Theme.error : Theme.primary
                                iconSize: 18
                            }

                            Text {
                                text: micPanelScope.activeSourceName.toUpperCase()
                                color: Theme.on_surface
                                font.pixelSize: 11
                                font.bold: true
                                font.family: Theme.fontFamilyDisplay
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: micPanelScope.isMuted ? "MIC MUTED" : (micPanelScope.currentVolume + "%")
                                color: micPanelScope.isMuted ? Theme.error : Theme.primary
                                font.pixelSize: 11
                                font.bold: true
                                font.family: Theme.fontFamilyMono
                            }
                        }

                        // Master Mic Gain Slider
                        SmoothSlider {
                            id: micSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            externalValue: micPanelScope.currentVolume
                            stepSize: 1

                            onValueMoved: function(newVal) {
                                micPanelScope.currentVolume = newVal;
                                ConfigService.setMicVolume(newVal, function() {});
                            }

                            onValueCommitted: function(finalVal) {
                                micPanelScope.currentVolume = finalVal;
                                ConfigService.setMicVolume(finalVal, function() {});
                            }
                        }
                    }
                }

                // Section Header: Input Devices
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "INPUT DEVICES"
                        color: Theme.secondary
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.2
                        font.family: Theme.fontFamilyMono
                    }

                    Item { Layout.fillWidth: true }
                }

                // Input Devices Repeater List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: micPanelScope.sourcesList

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: 46
                            radius: 10
                            color: modelData.is_default 
                                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)
                                : (sourceMouse.containsMouse ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.8) : Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g, Theme.surface_container_low.b, 0.5))

                            border.color: modelData.is_default ? Theme.primary : Theme.outline_variant
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 10

                                        VectorIcon {
                                            name: modelData.icon || "mic"
                                            color: modelData.is_default ? Theme.primary : Theme.on_surface_variant
                                            iconSize: 18
                                        }

                                        Text {
                                            text: modelData.name || modelData.description || "Microphone Input"
                                            color: modelData.is_default ? Theme.primary : Theme.on_surface
                                            font.pixelSize: 12
                                            font.bold: modelData.is_default
                                            font.family: Theme.fontFamilyDisplay
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        // Active Indicator Badge
                                        Rectangle {
                                            visible: modelData.is_default
                                            implicitWidth: 54
                                            implicitHeight: 22
                                            radius: 11
                                            color: Theme.primary

                                            Text {
                                                anchors.centerIn: parent
                                                text: "ACTIVE"
                                                color: Theme.on_primary
                                                font.pixelSize: 9
                                                font.bold: true
                                                font.family: Theme.fontFamilyMono
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: sourceMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            ConfigService.setDefaultAudioSource(modelData.id, function() {
                                                micPanelScope.refresh();
                                            });
                                        }
                                    }
                                }

                                // Gear Settings Button for View 1
                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 14
                                    color: gearMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : "transparent"

                                    VectorIcon {
                                        anchors.centerIn: parent
                                        name: "sliders"
                                        color: Theme.primary
                                        iconSize: 14
                                    }

                                    MouseArea {
                                        id: gearMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            micPanelScope.selectedSource = modelData;
                                            micPanelScope.currentView = 1;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // VIEW 1: PER-DEVICE INPUT SETTINGS PAGE
        ColumnLayout {
            visible: micPanelScope.currentView === 1
            anchors.fill: parent
            spacing: 14

            // Navigation Header (Back Button)
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ActionButton {
                    text: "Back to Microphones"
                    iconName: "left"
                    variant: "outline"
                    onClicked: micPanelScope.currentView = 0
                }

                Item { Layout.fillWidth: true }
            }

            // Selected Device Card Summary
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 74
                radius: 12
                color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.8)
                border.color: Theme.outline_variant
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    VectorIcon {
                        name: micPanelScope.selectedSource ? (micPanelScope.selectedSource.icon || "mic") : "mic"
                        color: Theme.primary
                        iconSize: 24
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true

                        Text {
                            text: micPanelScope.selectedSource ? (micPanelScope.selectedSource.name || micPanelScope.selectedSource.description) : "Microphone Input"
                            color: Theme.on_surface
                            font.pixelSize: 13
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "ID: " + (micPanelScope.selectedSource ? micPanelScope.selectedSource.id : "")
                            color: Theme.secondary
                            font.pixelSize: 10
                            font.family: Theme.fontFamilyMono
                        }
                    }

                    Rectangle {
                        visible: micPanelScope.selectedSource && micPanelScope.selectedSource.is_default
                        implicitWidth: 54
                        implicitHeight: 22
                        radius: 11
                        color: Theme.primary

                        Text {
                            anchors.centerIn: parent
                            text: "ACTIVE"
                            color: Theme.on_primary
                            font.pixelSize: 9
                            font.bold: true
                            font.family: Theme.fontFamilyMono
                        }
                    }
                }
            }

            // Per-Device Mic Gain Control Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                radius: 10
                color: Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g, Theme.surface_container_low.b, 0.7)
                border.color: Theme.outline_variant
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "MIC GAIN"
                            color: Theme.primary
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.2
                            font.family: Theme.fontFamilyMono
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: Math.round(deviceMicSlider.value) + "%"
                            color: Theme.primary
                            font.pixelSize: 11
                            font.bold: true
                            font.family: Theme.fontFamilyMono
                        }
                    }

                    SmoothSlider {
                        id: deviceMicSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        externalValue: micPanelScope.selectedSource ? micPanelScope.selectedSource.volume : 100
                        stepSize: 1

                        onValueMoved: function(newVal) {
                            if (micPanelScope.selectedSource) {
                                ConfigService.setSourceVolume(micPanelScope.selectedSource.id, newVal, function() {});
                            }
                        }

                        onValueCommitted: function(finalVal) {
                            if (micPanelScope.selectedSource) {
                                ConfigService.setSourceVolume(micPanelScope.selectedSource.id, finalVal, function() {
                                    micPanelScope.refresh();
                                });
                            }
                        }
                    }
                }
            }

            // Per-Device Actions (Set Default & Mute / Unmute)
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ActionButton {
                    Layout.fillWidth: true
                    text: micPanelScope.selectedSource && micPanelScope.selectedSource.is_default ? "Default Input" : "Set Default"
                    iconName: "mic"
                    variant: micPanelScope.selectedSource && micPanelScope.selectedSource.is_default ? "secondary" : "primary"
                    disabled: micPanelScope.selectedSource && micPanelScope.selectedSource.is_default
                    onClicked: {
                        if (micPanelScope.selectedSource) {
                            ConfigService.setDefaultAudioSource(micPanelScope.selectedSource.id, function() {
                                micPanelScope.refresh();
                            });
                        }
                    }
                }

                ActionButton {
                    Layout.fillWidth: true
                    text: micPanelScope.selectedSource && micPanelScope.selectedSource.muted ? "Unmute Mic" : "Mute Mic"
                    iconName: micPanelScope.selectedSource && micPanelScope.selectedSource.muted ? "mic-off" : "mic"
                    variant: micPanelScope.selectedSource && micPanelScope.selectedSource.muted ? "danger" : "outline"
                    onClicked: {
                        if (micPanelScope.selectedSource) {
                            var newMuteState = !micPanelScope.selectedSource.muted;
                            ConfigService.toggleSourceMute(micPanelScope.selectedSource.id, newMuteState, function() {
                                micPanelScope.refresh();
                            });
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
