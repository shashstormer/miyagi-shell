import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../components"

Item {
    id: root

    property int focusIndex: -1
    property int actionIndex: 0

    property var audioData: ConfigService.audioStatus
    property var sinksList: ConfigService.audioSinks || []
    property var streamsList: ConfigService.audioStreams || []

    function refreshAudio() {
        ConfigService.fetchAudioStatus(function(data) {
            if (!data) return;
            root.audioData = data;
            if (data.sinks) root.sinksList = data.sinks;
            if (data.streams) root.streamsList = data.streams;
        });
        ConfigService.fetchMicStatus();
    }

    Component.onCompleted: refreshAudio()

    function getItemCount() {
        var count = 3; // Master volume, Master Mute, Over-Amplify
        count += root.sinksList.length; // Sinks
        count += 2; // Mic gain, Mic mute
        count += root.streamsList.length; // App streams
        return count;
    }

    function handleHorizontal(delta) {
        if (focusIndex === 0) {
            var newVol = Math.max(0, Math.min(ConfigService.audioVolume + delta * 5, ConfigService.enableOverAmplify ? 150 : 100));
            ConfigService.setAudioVolume(newVol);
        } else if (focusIndex > 2 && focusIndex <= 2 + root.sinksList.length) {
            var sIdx = focusIndex - 3;
            if (sIdx >= 0 && sIdx < root.sinksList.length) {
                var sink = root.sinksList[sIdx];
                var sVol = Math.max(0, Math.min((sink.volume !== undefined ? sink.volume : 100) + delta * 5, ConfigService.enableOverAmplify ? 150 : 100));
                var updatedSinks = root.sinksList.map(function(s, idx) {
                    if (idx === sIdx) {
                        var copy = Object.assign({}, s);
                        copy.volume = sVol;
                        return copy;
                    }
                    return s;
                });
                root.sinksList = updatedSinks;
                ConfigService.setSinkVolume(sink.id, sVol);
            }
        } else if (focusIndex === 3 + root.sinksList.length) {
            var mVol = Math.max(0, Math.min(ConfigService.micVolume + delta * 5, 100));
            ConfigService.setMicVolume(mVol);
        } else if (focusIndex > 4 + root.sinksList.length) {
            var stIdx = focusIndex - (5 + root.sinksList.length);
            if (stIdx >= 0 && stIdx < root.streamsList.length) {
                var stream = root.streamsList[stIdx];
                var stVol = Math.max(0, Math.min((stream.volume !== undefined ? stream.volume : 100) + delta * 5, ConfigService.enableOverAmplify ? 150 : 100));
                var updatedStreams = root.streamsList.map(function(st, idx) {
                    if (idx === stIdx) {
                        var copy = Object.assign({}, st);
                        copy.volume = stVol;
                        return copy;
                    }
                    return st;
                });
                root.streamsList = updatedStreams;
                ConfigService.setStreamVolume(stream.id, stVol);
            }
        }
    }

    function triggerItem() {
        if (focusIndex === 1) {
            masterMuteToggle.triggerToggle();
        } else if (focusIndex === 2) {
            overAmplifyToggle.triggerToggle();
        } else if (focusIndex > 2 && focusIndex <= 2 + root.sinksList.length) {
            var sIdx = focusIndex - 3;
            if (sIdx >= 0 && sIdx < root.sinksList.length) {
                var sink = root.sinksList[sIdx];
                if (sink) ConfigService.setDefaultSink(sink.id, refreshAudio);
            }
        } else if (focusIndex === 4 + root.sinksList.length) {
            micMuteToggle.triggerToggle();
        } else if (focusIndex > 4 + root.sinksList.length) {
            var stIdx = focusIndex - (5 + root.sinksList.length);
            if (stIdx >= 0 && stIdx < root.streamsList.length) {
                var stream = root.streamsList[stIdx];
                var nVol = (stream.volume === 0 || stream.muted) ? 100 : 0;
                var updatedStreams = root.streamsList.map(function(st, idx) {
                    if (idx === stIdx) {
                        var copy = Object.assign({}, st);
                        copy.volume = nVol;
                        copy.muted = (nVol === 0);
                        return copy;
                    }
                    return st;
                });
                root.streamsList = updatedStreams;
                ConfigService.setStreamVolume(stream.id, nVol, refreshAudio);
            }
        }
    }

    implicitHeight: mainLayout.implicitHeight
    Layout.fillWidth: true

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 12

        // ==========================================
        // 1. SOUND HERO STATUS CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 90
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
                    color: ConfigService.audioMuted 
                        ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.18) 
                        : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)
                    Layout.alignment: Qt.AlignVCenter

                    VectorIcon {
                        anchors.centerIn: parent
                        name: ConfigService.audioMuted ? "volume_muted" : "volume"
                        iconSize: 22
                        color: ConfigService.audioMuted ? Theme.error : Theme.primary
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
                            text: "Audio Output"
                            color: Theme.on_surface
                            font.pixelSize: 16
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                        }

                        PillBadge {
                            text: ConfigService.audioMuted ? "Muted" : ((ConfigService.audioVolume > 100) ? (ConfigService.audioVolume + "% Boost") : (ConfigService.audioVolume + "%"))
                            isInteractive: false
                            defaultColor: ConfigService.audioMuted 
                                ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.18) 
                                : ((ConfigService.audioVolume > 100) ? Qt.rgba(255/255, 179/255, 102/255, 0.22) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12))
                            defaultTextColor: ConfigService.audioMuted ? Theme.error : ((ConfigService.audioVolume > 100) ? "#FFB366" : Theme.primary)
                        }
                    }

                    Text {
                        text: ConfigService.audioMuted ? "Audio output is muted" : ("Active Sink: " + (ConfigService.defaultSinkName || "Default Audio Device"))
                        color: Theme.on_surface_variant
                        font.pixelSize: 11
                        font.family: Theme.fontFamilyDisplay
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                SquareButton {
                    text: "Test Sound"
                    iconName: "play"
                    size: 32
                    customRadius: 16
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: ConfigService.playTestSound()
                }
            }
        }

        // ==========================================
        // 2. MASTER OUTPUT VOLUME
        // ==========================================
        SettingCardGroup {
            titleText: "Master Playback"

            SettingSliderRow {
                id: masterVolumeSlider
                labelText: "Master Output Volume"
                descriptionText: "Adjust overall system audio playback level"
                value: ConfigService.audioVolume
                fromValue: 0
                toValue: ConfigService.enableOverAmplify ? 150 : 100
                unitText: "%"
                isFocused: root.focusIndex === 0
                onValueModified: newValue => ConfigService.setAudioVolume(Math.round(newValue), null, true)
                onValueCommitted: finalValue => ConfigService.setAudioVolume(Math.round(finalValue))
            }

            SettingToggleRow {
                id: masterMuteToggle
                labelText: "Mute Master Audio"
                descriptionText: "Silence all output streams"
                checked: ConfigService.audioMuted
                isFocused: root.focusIndex === 1
                onToggled: newValue => ConfigService.toggleAudioMute(newValue)
            }

            SettingToggleRow {
                id: overAmplifyToggle
                labelText: "Volume Boost (Over-Amplify to 150%)"
                descriptionText: "Allow audio level amplification beyond standard 100% threshold"
                checked: ConfigService.enableOverAmplify
                isFocused: root.focusIndex === 2
                onToggled: newValue => {
                    ConfigService.enableOverAmplify = newValue;
                    if (!newValue && ConfigService.audioVolume > 100) {
                        ConfigService.setAudioVolume(100);
                    }
                }
            }
        }

        // ==========================================
        // 3. OUTPUT SINKS & DEVICES (WITH PER-SINK VOLUME)
        // ==========================================
        SettingCardGroup {
            titleText: "Output Devices (" + root.sinksList.length + ")"

            Repeater {
                model: root.sinksList
                delegate: Rectangle {
                    id: sinkRow
                    required property var modelData
                    required property int index

                    readonly property int itemFocusIndex: 3 + index
                    readonly property bool isRowFocused: root.focusIndex === itemFocusIndex

                    Layout.fillWidth: true
                    implicitHeight: 70
                    radius: 10
                    color: isRowFocused
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        : (modelData.is_default ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.35))

                    border.color: isRowFocused ? Theme.primary : (modelData.is_default ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent")
                    border.width: isRowFocused ? 1.5 : (modelData.is_default ? 1 : 0)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        // Clickable Header Area for setting Default Sink
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 22

                            RowLayout {
                                anchors.fill: parent
                                spacing: 10

                                VectorIcon {
                                    name: modelData.is_headphones ? "headphones" : "audio"
                                    iconSize: 16
                                    color: modelData.is_default ? Theme.primary : Theme.on_surface_variant
                                }

                                Text {
                                    text: modelData.description || modelData.name || "Output Device"
                                    color: modelData.is_default ? Theme.primary : Theme.on_surface
                                    font.bold: true
                                    font.pixelSize: 12
                                    font.family: Theme.fontFamilyDisplay
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                PillBadge {
                                    visible: !!modelData.is_default
                                    text: "Default"
                                    isInteractive: false
                                    pillHeight: 18
                                    fontSize: 10
                                }

                                RadioButton {
                                    checked: !!modelData.is_default
                                    onClicked: ConfigService.setDefaultSink(modelData.id, root.refreshAudio)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ConfigService.setDefaultSink(modelData.id, root.refreshAudio)
                            }
                        }

                        // Per-Sink Volume Slider
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            SmoothSlider {
                                id: sinkSlider
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                from: 0
                                to: ConfigService.enableOverAmplify ? 150 : 100
                                externalValue: modelData.volume !== undefined ? modelData.volume : 100
                                stepSize: 1
                                onValueMoved: val => {
                                    if (modelData) modelData.volume = Math.round(val);
                                    ConfigService.setSinkVolume(modelData.id, Math.round(val), null, true);
                                }
                                onValueCommitted: val => {
                                    if (modelData) modelData.volume = Math.round(val);
                                    ConfigService.setSinkVolume(modelData.id, Math.round(val), root.refreshAudio);
                                }
                            }

                            Text {
                                text: Math.round(sinkSlider.value) + "%"
                                color: Theme.primary
                                font.bold: true
                                font.pixelSize: 11
                                font.family: Theme.fontFamilyMono
                                Layout.preferredWidth: 38
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 4. MICROPHONE & AUDIO INPUT
        // ==========================================
        SettingCardGroup {
            titleText: "Microphone & Input"

            SettingSliderRow {
                id: micVolumeSlider
                labelText: "Microphone Input Sensitivity"
                descriptionText: "Adjust input gain for voice and microphone recording"
                value: ConfigService.micVolume
                fromValue: 0
                toValue: 100
                unitText: "%"
                isFocused: root.focusIndex === (3 + root.sinksList.length)
                onValueModified: newValue => ConfigService.setMicVolume(Math.round(newValue), null, true)
                onValueCommitted: finalValue => ConfigService.setMicVolume(Math.round(finalValue))
            }

            SettingToggleRow {
                id: micMuteToggle
                labelText: "Mute Microphone"
                descriptionText: "Disable audio input hardware"
                checked: ConfigService.micMuted
                isFocused: root.focusIndex === (4 + root.sinksList.length)
                onToggled: newValue => ConfigService.toggleMicMute(newValue)
            }
        }

        // ==========================================
        // 5. APPLICATION AUDIO STREAM MIXER
        // ==========================================
        SettingCardGroup {
            titleText: "Application Audio Mixer (" + root.streamsList.length + ")"

            EmptyState {
                visible: root.streamsList.length === 0
                iconName: "audio"
                title: "No active audio streams"
                description: "Applications currently playing sound will appear here."
            }

            Repeater {
                model: root.streamsList
                delegate: Rectangle {
                    id: streamRow
                    required property var modelData
                    required property int index

                    readonly property int itemFocusIndex: (5 + root.sinksList.length) + index
                    readonly property bool isRowFocused: root.focusIndex === itemFocusIndex

                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 10
                    color: isRowFocused
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.35)

                    border.color: isRowFocused ? Theme.primary : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        AppIcon {
                            icon: modelData.icon || modelData.name || ""
                            appClass: modelData.name || ""
                            appTitle: modelData.description || ""
                            iconSize: 24
                        }

                        ColumnLayout {
                            Layout.preferredWidth: 150
                            spacing: 1

                            Text {
                                text: modelData.name || modelData.description || "Application"
                                color: Theme.on_surface
                                font.bold: true
                                font.pixelSize: 12
                                font.family: Theme.fontFamilyDisplay
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.description || "Active Playback"
                                color: Theme.on_surface_variant
                                font.pixelSize: 10
                                font.family: Theme.fontFamilyDisplay
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        SmoothSlider {
                            id: streamSlider
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            from: 0
                            to: ConfigService.enableOverAmplify ? 150 : 100
                            externalValue: modelData.volume !== undefined ? modelData.volume : 100
                            stepSize: 1
                            onValueMoved: val => {
                                if (modelData) modelData.volume = Math.round(val);
                                ConfigService.setStreamVolume(modelData.id, Math.round(val), null, true);
                            }
                            onValueCommitted: val => {
                                if (modelData) modelData.volume = Math.round(val);
                                ConfigService.setStreamVolume(modelData.id, Math.round(val), root.refreshAudio);
                            }
                        }

                        Text {
                            text: Math.round(streamSlider.value) + "%"
                            color: Theme.primary
                            font.bold: true
                            font.pixelSize: 11
                            font.family: Theme.fontFamilyMono
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }

                        SquareButton {
                            size: 28
                            customRadius: 8
                            iconName: (modelData.volume === 0 || modelData.muted) ? "volume_muted" : "volume"
                            customIconColor: (modelData.volume === 0 || modelData.muted) ? Theme.error : Theme.on_surface
                            isActive: (modelData.volume === 0 || modelData.muted)
                            activeColor: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.20)
                            onClicked: {
                                var newVol = (modelData.volume === 0 || modelData.muted) ? 100 : 0;
                                if (modelData) modelData.volume = newVol;
                                ConfigService.setStreamVolume(modelData.id, newVol, root.refreshAudio);
                            }
                        }
                    }
                }
            }
        }
    }
}
