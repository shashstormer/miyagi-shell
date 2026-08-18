import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../components"
import "../components/ModelUtils.js" as ModelUtils

Scope {
    id: volumePanelScope

    property bool isOpen: volumeWindow.isOpen
    property alias openedFrom: volumeWindow.openedFrom
    property int currentView: 0 // 0 = Sinks & Streams List, 1 = Device Details Page
    property var selectedSink: null

    property int currentVolume: 100
    property bool isMuted: false
    property string activeSinkName: "Default Output"
    property var sinksList: []
    property var streamsList: []

    function toggle() {
        if (volumeWindow.isOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        currentView = 0;
        selectedSink = null;
        volumeWindow.open();
        refresh();
    }

    function close() {
        volumeWindow.close();
    }

    function refresh() {
        ConfigService.fetchAudioStatus(function(data) {
            if (!data) return;
            volumePanelScope.currentVolume = data.volume !== undefined ? data.volume : 100;
            volumePanelScope.isMuted = !!data.muted;
            volumePanelScope.activeSinkName = data.active_sink_name || "Default Output";
            volumeWindow.switchChecked = !volumePanelScope.isMuted;

            if (data.sinks) {
                volumePanelScope.sinksList = data.sinks;
                if (volumePanelScope.selectedSink) {
                    for (var i = 0; i < data.sinks.length; i++) {
                        if (data.sinks[i].id === volumePanelScope.selectedSink.id) {
                            volumePanelScope.selectedSink = data.sinks[i];
                            break;
                        }
                    }
                }
            }
            if (data.streams) {
                volumePanelScope.streamsList = data.streams;
            }
        });
    }

    property int selectedIndex: 0
    readonly property int totalItemCount: 1 + (sinksList ? sinksList.length : 0) + (streamsList ? streamsList.length : 0)

    function navigate(delta) {
        InputService.useKeyboard();
        if (totalItemCount > 0) {
            selectedIndex = Math.max(-1, Math.min(selectedIndex + delta, totalItemCount - 1));
            volumeWindow.isSwitchFocused = (selectedIndex === -1);
        } else {
            selectedIndex = -1;
            volumeWindow.isSwitchFocused = true;
        }
    }

    function adjustVolume(delta) {
        InputService.useKeyboard();
        if (selectedIndex <= 0) {
            var newVol = Math.max(0, Math.min(currentVolume + delta, 150));
            ConfigService.setAudioVolume(newVol, function() { refresh(); });
        } else if (sinksList && selectedIndex > 0 && selectedIndex <= sinksList.length) {
            var sink = sinksList[selectedIndex - 1];
            if (sink) {
                var sVol = Math.max(0, Math.min((sink.volume || 100) + delta, 150));
                ConfigService.setSinkVolume(sink.id, sVol, function() { refresh(); });
            }
        } else if (streamsList && sinksList && selectedIndex > sinksList.length) {
            var stream = streamsList[selectedIndex - 1 - sinksList.length];
            if (stream) {
                var stVol = Math.max(0, Math.min((stream.volume || 100) + delta, 150));
                ConfigService.setStreamVolume(stream.id, stVol, function() { refresh(); });
            }
        }
    }

    function activateSelected() {
        if (selectedIndex <= 0) {
            ConfigService.toggleAudioMute(!isMuted, function() { refresh(); });
        } else if (sinksList && selectedIndex > 0 && selectedIndex <= sinksList.length) {
            var sink = sinksList[selectedIndex - 1];
            if (sink) {
                ConfigService.setActiveSink(sink.id, function() { refresh(); });
            }
        }
    }

    Connections {
        target: InputService
        enabled: volumeWindow.isOpen

        function onNavUp() {
            volumePanelScope.navigate(-1);
        }
        function onNavDown() {
            volumePanelScope.navigate(1);
        }
        function onNavLeft() {
            volumePanelScope.adjustVolume(-5);
        }
        function onNavRight() {
            volumePanelScope.adjustVolume(5);
        }
        function onNavSelect() {
            volumePanelScope.activateSelected();
        }
        function onNavBack() {
            if (volumePanelScope.currentView === 1) {
                volumePanelScope.currentView = 0;
            } else if (selectedIndex !== 0) {
                selectedIndex = 0;
                volumeWindow.isSwitchFocused = false;
            } else {
                InputService.closeOrReturn(volumeWindow);
            }
        }
    }

    BaseFlyoutPanel {
        id: volumeWindow
        title: volumePanelScope.currentView === 0 ? "Volume" : "Device Settings"
        iconName: "volume"
        side: "left"
        cardWidth: 380
        cardHeight: 540
        showRefresh: true
        showSwitch: volumePanelScope.currentView === 0

        onRefreshClicked: volumePanelScope.refresh()
        onSwitchToggled: function(checked) {
            ConfigService.toggleAudioMute(!checked, function() {
                volumePanelScope.refresh();
            });
        }

        // VIEW 0: MAIN OUTPUT DEVICES & PER-APP VOLUME LIST
        ScrollView {
            id: mainScroll
            visible: volumePanelScope.currentView === 0
            anchors.fill: parent
            clip: true

            ColumnLayout {
                width: mainScroll.availableWidth
                spacing: 14

                // Unified Master Volume & Active Output Card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 96
                    radius: 12
                    color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.7)
                    border.color: (InputService.isNonMouse && volumePanelScope.selectedIndex === 0) ? Theme.primary : Theme.outline_variant
                    border.width: (InputService.isNonMouse && volumePanelScope.selectedIndex === 0) ? 2 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        // Top Header Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            VectorIcon {
                                name: "volume"
                                color: volumePanelScope.isMuted ? Theme.error : Theme.primary
                                iconSize: 18
                            }

                            Text {
                                text: volumePanelScope.activeSinkName.toUpperCase()
                                color: Theme.on_surface
                                font.pixelSize: 11
                                font.bold: true
                                font.family: Theme.fontFamilyDisplay
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: volumePanelScope.isMuted ? "MUTED" : (volumePanelScope.currentVolume + "%")
                                color: volumePanelScope.isMuted ? Theme.error : Theme.primary
                                font.pixelSize: 11
                                font.bold: true
                                font.family: Theme.fontFamilyMono
                            }
                        }

                        // Master Volume Slider
                        SmoothSlider {
                            id: volSlider
                            Layout.fillWidth: true
                            from: 0
                            to: ConfigService.enableOverAmplify ? 150 : 100
                            externalValue: volumePanelScope.currentVolume
                            stepSize: 1

                            onValueMoved: function(newVal) {
                                volumePanelScope.currentVolume = newVal;
                                ConfigService.setAudioVolume(newVal, function() {});
                            }

                            onValueCommitted: function(finalVal) {
                                volumePanelScope.currentVolume = finalVal;
                                ConfigService.setAudioVolume(finalVal, function() {});
                            }
                        }
                    }
                }

                // Section Header: Output Devices
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "OUTPUT DEVICES"
                        color: Theme.secondary
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.2
                        font.family: Theme.fontFamilyMono
                    }

                    Item { Layout.fillWidth: true }
                }

                // Output Devices Repeater List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: volumePanelScope.sinksList

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: 46
                            radius: 10
                            color: modelData.is_default 
                                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)
                                : (sinkMouse.containsMouse ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.8) : Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g, Theme.surface_container_low.b, 0.5))

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
                                            name: modelData.icon || "volume"
                                            color: modelData.is_default ? Theme.primary : Theme.on_surface_variant
                                            iconSize: 18
                                        }

                                        Text {
                                            text: modelData.name || modelData.description || "Audio Output"
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
                                        id: sinkMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            ConfigService.setDefaultAudioSink(modelData.id, function() {
                                                volumePanelScope.refresh();
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
                                            volumePanelScope.selectedSink = modelData;
                                            volumePanelScope.currentView = 1;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Section Header: Playing Applications (Active Audio Streams)
                RowLayout {
                    visible: volumePanelScope.streamsList && volumePanelScope.streamsList.length > 0
                    Layout.fillWidth: true

                    Text {
                        text: "PLAYING APPLICATIONS"
                        color: Theme.secondary
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.2
                        font.family: Theme.fontFamilyMono
                    }

                    Item { Layout.fillWidth: true }
                }

                // Per-Application Stream Volume Controls Repeater List
                ColumnLayout {
                    visible: volumePanelScope.streamsList && volumePanelScope.streamsList.length > 0
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: volumePanelScope.streamsList

                        delegate: Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: 52
                            radius: 10
                            color: Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g, Theme.surface_container_low.b, 0.6)
                            border.color: Theme.outline_variant
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    VectorIcon {
                                        name: "volume"
                                        color: Theme.primary
                                        iconSize: 14
                                    }

                                    Text {
                                        text: (modelData.app_name || modelData.name || "Application").toUpperCase()
                                        color: Theme.on_surface
                                        font.pixelSize: 10
                                        font.bold: true
                                        font.family: Theme.fontFamilyDisplay
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: Math.round(appSlider.value) + "%"
                                        color: Theme.primary
                                        font.pixelSize: 10
                                        font.bold: true
                                        font.family: Theme.fontFamilyMono
                                    }
                                }

                                SmoothSlider {
                                    id: appSlider
                                    Layout.fillWidth: true
                                    from: 0
                                    to: ConfigService.enableOverAmplify ? 150 : 100
                                    externalValue: modelData.volume !== undefined ? modelData.volume : 100
                                    stepSize: 1

                                    onValueMoved: function(newVal) {
                                        if (modelData) modelData.volume = newVal;
                                        ConfigService.setStreamVolume(modelData.id, newVal, function() {});
                                    }

                                    onValueCommitted: function(finalVal) {
                                        if (modelData) modelData.volume = finalVal;
                                        ConfigService.setStreamVolume(modelData.id, finalVal, function() {});
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // VIEW 1: PER-DEVICE SETTINGS PAGE
        ColumnLayout {
            visible: volumePanelScope.currentView === 1
            anchors.fill: parent
            spacing: 14

            // Navigation Header (Back Button)
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ActionButton {
                    text: "Back to Devices"
                    iconName: "left"
                    variant: "outline"
                    onClicked: volumePanelScope.currentView = 0
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
                        name: "volume"
                        color: Theme.primary
                        iconSize: 24
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true

                        Text {
                            text: volumePanelScope.selectedSink ? (volumePanelScope.selectedSink.name || volumePanelScope.selectedSink.description) : "Audio Output"
                            color: Theme.on_surface
                            font.pixelSize: 13
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "ID: " + (volumePanelScope.selectedSink ? volumePanelScope.selectedSink.id : "")
                            color: Theme.secondary
                            font.pixelSize: 10
                            font.family: Theme.fontFamilyMono
                        }
                    }

                    Rectangle {
                        visible: volumePanelScope.selectedSink && volumePanelScope.selectedSink.is_default
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

            // Per-Device Volume Control Card
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
                            text: "DEVICE VOLUME"
                            color: Theme.primary
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.2
                            font.family: Theme.fontFamilyMono
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: Math.round(deviceVolSlider.value) + "%"
                            color: Theme.primary
                            font.pixelSize: 11
                            font.bold: true
                            font.family: Theme.fontFamilyMono
                        }
                    }

                    SmoothSlider {
                        id: deviceVolSlider
                        Layout.fillWidth: true
                        from: 0
                        to: ConfigService.enableOverAmplify ? 150 : 100
                        externalValue: volumePanelScope.selectedSink ? volumePanelScope.selectedSink.volume : 100
                        stepSize: 1

                        onValueMoved: function(newVal) {
                            if (volumePanelScope.selectedSink) {
                                ConfigService.setSinkVolume(volumePanelScope.selectedSink.id, newVal, function() {});
                            }
                        }

                        onValueCommitted: function(finalVal) {
                            if (volumePanelScope.selectedSink) {
                                ConfigService.setSinkVolume(volumePanelScope.selectedSink.id, finalVal, function() {
                                    volumePanelScope.refresh();
                                });
                            }
                        }
                    }
                }
            }

            // Device Actions (Set Default, Mute & Test Sound)
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ActionButton {
                    Layout.fillWidth: true
                    text: volumePanelScope.selectedSink && volumePanelScope.selectedSink.is_default ? "Default" : "Set Default"
                    iconName: "volume"
                    variant: volumePanelScope.selectedSink && volumePanelScope.selectedSink.is_default ? "secondary" : "primary"
                    disabled: volumePanelScope.selectedSink && volumePanelScope.selectedSink.is_default
                    onClicked: {
                        if (volumePanelScope.selectedSink) {
                            ConfigService.setDefaultAudioSink(volumePanelScope.selectedSink.id, function() {
                                volumePanelScope.refresh();
                            });
                        }
                    }
                }

                ActionButton {
                    Layout.fillWidth: true
                    text: volumePanelScope.selectedSink && volumePanelScope.selectedSink.muted ? "Unmute" : "Mute"
                    iconName: "volume"
                    variant: volumePanelScope.selectedSink && volumePanelScope.selectedSink.muted ? "danger" : "outline"
                    onClicked: {
                        if (volumePanelScope.selectedSink) {
                            var newMuteState = !volumePanelScope.selectedSink.muted;
                            ConfigService.toggleSinkMute(volumePanelScope.selectedSink.id, newMuteState, function() {
                                volumePanelScope.refresh();
                            });
                        }
                    }
                }

                ActionButton {
                    Layout.fillWidth: true
                    text: "Test"
                    iconName: "bell"
                    variant: "outline"
                    onClicked: {
                        if (volumePanelScope.selectedSink) {
                            ConfigService.playTestSound(volumePanelScope.selectedSink.id, function() {});
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
