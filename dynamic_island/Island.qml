import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

import "../theme"
import "../widgets/components"
import "../widgets/components/ModelUtils.js" as ModelUtils

Variants {
    id: islandVariants
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: islandWindow

            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "quickshell-dynamic-island"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: ConfigService.islandPassThrough ? WlrKeyboardFocus.None : WlrKeyboardFocus.OnDemand
            exclusionMode: ExclusionMode.Ignore
            Region { id: emptyRegion }
            mask: ConfigService.islandPassThrough ? emptyRegion : null
            color: "transparent"

            anchors {
                top: true
            }

            // Fixed maximum surface bounding box prevents Wayland protocol surface reallocation jitter
            implicitWidth: 380
            implicitHeight: 95

            // Bind central CavaService active state to music playback
            Binding {
                target: CavaService
                property: "active"
                value: MediaHelper.isPlaying
            }

            readonly property real cavaBar0: (CavaService.audioSpectrum && CavaService.audioSpectrum.length > 0) ? CavaService.audioSpectrum[0] : 0
            readonly property real cavaBar1: (CavaService.audioSpectrum && CavaService.audioSpectrum.length > 1) ? CavaService.audioSpectrum[1] : 0
            readonly property real cavaBar2: (CavaService.audioSpectrum && CavaService.audioSpectrum.length > 2) ? CavaService.audioSpectrum[2] : 0
            readonly property real cavaBar3: (CavaService.audioSpectrum && CavaService.audioSpectrum.length > 3) ? CavaService.audioSpectrum[3] : 0

            // Startup Guard: Ignore initial D-Bus / UPower property settlements during first 2 seconds
            property bool isSystemInitialized: false
            Timer {
                interval: 2000
                running: true
                repeat: false
                onTriggered: islandWindow.isSystemInitialized = true
            }

            // Clock Timer for Idle Time Display
            property var now: new Date()
            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: islandWindow.now = new Date()
            }

            // ==========================================
            // 1. DATA SOURCES & TRACKING
            // ==========================================
            readonly property bool isMusicPlaying: MediaHelper.isPlaying

            // --- REACTIVE PIPEWIRE VOLUME BINDINGS ---
            readonly property real pipewireVolume: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio.volume : 0
            readonly property bool pipewireMuted: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio.muted : false

            property real currentVolume: pipewireVolume
            property bool isMuted: pipewireMuted

            PwObjectTracker {
                objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
            }

            onPipewireVolumeChanged: {
                if (!isSystemInitialized) return;
                if (Math.abs(currentVolume - pipewireVolume) > 0.005) {
                    currentVolume = pipewireVolume;
                    triggerOverride("volume");
                }
            }

            onPipewireMutedChanged: {
                if (!isSystemInitialized) return;
                if (isMuted !== pipewireMuted) {
                    isMuted = pipewireMuted;
                    triggerOverride("volume");
                }
            }

            // --- HARDWARE BRIGHTNESS TRACKING (Via BrightnessService Singleton) ---
            readonly property real currentBrightness: BrightnessService.currentBrightness

            Connections {
                target: BrightnessService
                function onBrightnessChanged(val) {
                    if (isSystemInitialized) {
                        triggerOverride("brightness");
                    }
                }
            }

            // --- BATTERY & CHARGING TRACKING (UPower) ---
            readonly property var batteryDevice: UPower.displayDevice
            readonly property real batteryPercentage: (batteryDevice && batteryDevice.percentage !== undefined) ? batteryDevice.percentage : 1.0
            readonly property var batteryState: batteryDevice ? batteryDevice.state : null
            readonly property bool isCharging: batteryState === UPowerDeviceState.Charging
            readonly property bool isPluggedIn: isCharging || batteryState === UPowerDeviceState.PendingCharge || batteryState === UPowerDeviceState.FullyCharged
            readonly property bool isDischarging: batteryState === UPowerDeviceState.Discharging

            property var lastBatteryState: null
            property real lastBatteryPercentage: -1.0

            onBatteryStateChanged: {
                if (lastBatteryState !== null && lastBatteryState !== batteryState) {
                    triggerOverride("battery");
                }
                lastBatteryState = batteryState;
            }

            onBatteryPercentageChanged: {
                if (lastBatteryPercentage >= 0 && Math.abs(lastBatteryPercentage - batteryPercentage) >= 0.01) {
                    triggerOverride("battery");
                }
                lastBatteryPercentage = batteryPercentage;
            }

            // ==========================================
            // 2. OVERRIDE & PRIORITY CONTROLLER
            // ==========================================
            property string activeOverride: "" // "volume", "brightness", "battery", or ""

            Timer {
                id: overrideTimer
                interval: 5000
                repeat: false
                onTriggered: {
                    islandWindow.activeOverride = "";
                }
            }

            function triggerOverride(type) {
                if (!isSystemInitialized) return;
                activeOverride = type;
                overrideTimer.restart();
            }

            visible: ConfigService.isLoaded && ConfigService.enableDynamicIsland && (!ConfigService.islandFullscreenAutoHide || !ConfigService.isHyprlandFullscreen)

            readonly property bool isFullscreenActive: {
                if (!ConfigService.autoHideFullscreen) return false;
                return ConfigService.isHyprlandFullscreen;
            }

            // Solid Hover state based on card bounds containsMouse
            readonly property bool isHovered: !ConfigService.islandPassThrough && cardHoverArea.containsMouse

            // State Resolution
            readonly property string currentState: {
                if (overrideTimer.running && activeOverride !== "") {
                    return activeOverride;
                }
                if (isMusicPlaying || isHovered) {
                    return "music";
                }
                return "idle";
            }

            // ==========================================
            // 3. DYNAMIC ISLAND CARD CONTAINER
            // ==========================================
            Rectangle {
                id: islandCard
                visible: islandWindow.visible
                anchors.top: parent.top
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true

                // Dynamic dimensions based on state, hover, and ConfigService settings
                width: {
                    if (ConfigService.islandStaticSize) {
                        return ConfigService.islandWidthCollapsed;
                    }
                    if (islandWindow.currentState === "volume" || islandWindow.currentState === "brightness") {
                        return 260;
                    } else if (islandWindow.currentState === "battery") {
                        return 230;
                    } else if (islandWindow.currentState === "music") {
                        return islandWindow.isHovered ? ConfigService.islandWidthExpanded : ConfigService.islandWidthCollapsed;
                    } else {
                        return 150; // Idle clock state
                    }
                }

                height: {
                    if (ConfigService.islandStaticSize) {
                        return ConfigService.islandHeightCollapsed;
                    }
                    if (islandWindow.currentState === "music" && islandWindow.isHovered) {
                        return ConfigService.islandHeightExpanded;
                    } else {
                        return ConfigService.islandHeightCollapsed;
                    }
                }

                radius: (islandWindow.currentState === "music" && islandWindow.isHovered && !ConfigService.islandStaticSize) ? ConfigService.islandRadiusExpanded : ConfigService.islandRadiusCollapsed

                color: Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.96)

                border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.4)
                border.width: 1

                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                        onRunningChanged: if (!running) songProgressBorderCanvas.requestPaint()
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                        onRunningChanged: if (!running) songProgressBorderCanvas.requestPaint()
                    }
                }
                Behavior on radius {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                        onRunningChanged: if (!running) songProgressBorderCanvas.requestPaint()
                    }
                }

                MouseArea {
                    id: cardHoverArea
                    anchors.fill: parent
                    hoverEnabled: !ConfigService.islandPassThrough
                    enabled: !ConfigService.islandPassThrough
                }

                // --- DUAL-PROGRESS BORDER OVERLAY (REALTIME ANIMATION REPAINT & EXACT FINISH SYNC) ---
                Canvas {
                    id: songProgressBorderCanvas
                    anchors.fill: parent
                    antialiasing: true
                    visible: islandWindow.currentState === "music" && MediaHelper.hasPlayer && MediaHelper.length > 0

                    property real currentRatio: {
                        if (!MediaHelper.hasPlayer || MediaHelper.length <= 0) return 0;
                        var pos = MediaHelper.position || 0;
                        var len = MediaHelper.length;
                        return Math.max(0, Math.min(1, pos / len));
                    }

                    onCurrentRatioChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    Connections {
                        target: islandCard
                        function onRadiusChanged() { songProgressBorderCanvas.requestPaint(); }
                    }

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.clearRect(0, 0, width, height);

                        if (!MediaHelper.hasPlayer || MediaHelper.length <= 0 || currentRatio <= 0.001) return;

                        var w = width;
                        var h = height;
                        var r = Math.max(2, islandCard.radius);

                        var inset = 1.5;
                        var innerR = Math.max(1, r - inset);

                        var straightW = Math.max(0, w - 2 * r);
                        var L = Math.PI * innerR + straightW; // Length of top or bottom branch path

                        // Dual branch scaling: dashLength is (currentRatio / 2.0) * L so both branches meet at far right edge at currentRatio == 1.0
                        var dashLength = (currentRatio / 2.0) * L;

                        ctx.lineWidth = 1.8;
                        ctx.strokeStyle = Theme.primary;
                        ctx.lineCap = "round";

                        var cx_tr = w - r;
                        var cy_tr = r;
                        var cx_br = w - r;
                        var cy_br = h - r;
                        var cx_bl = r;
                        var cy_bl = h - r;
                        var cx_tl = r;
                        var cy_tl = r;

                        // TOP BRANCH: Starts at left apex (inset, h/2) -> travels across top edge to right edge (w - inset, h/2)
                        ctx.beginPath();
                        ctx.moveTo(inset, h / 2);
                        ctx.arc(cx_tl, cy_tl, innerR, Math.PI, (3 * Math.PI) / 2, false);
                        ctx.lineTo(cx_tr, inset);
                        ctx.arc(cx_tr, cy_tr, innerR, -Math.PI / 2, 0, false);
                        ctx.setLineDash([dashLength, L]);
                        ctx.stroke();

                        // BOTTOM BRANCH: Starts at left apex (inset, h/2) -> travels across bottom edge to right edge (w - inset, h/2)
                        ctx.beginPath();
                        ctx.moveTo(inset, h / 2);
                        ctx.arc(cx_bl, cy_bl, innerR, Math.PI, Math.PI / 2, true);
                        ctx.lineTo(cx_br, h - inset);
                        ctx.arc(cx_br, cy_br, innerR, Math.PI / 2, 0, true);
                        ctx.setLineDash([dashLength, L]);
                        ctx.stroke();
                    }

                    Connections {
                        target: MediaHelper
                        function onPositionChanged() { songProgressBorderCanvas.requestPaint(); }
                    }
                }

                // ==========================================
                // 4. CONTENT SECTIONS
                // ==========================================

                // --- A. VOLUME OVERRIDE CONTENT ---
                Item {
                    id: volumeContent
                    anchors.fill: parent
                    visible: islandWindow.currentState === "volume"
                    opacity: visible ? 1.0 : 0.0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 10

                        VectorIcon {
                            iconSize: 18
                            color: Theme.primary
                            name: {
                                if (islandWindow.isMuted || islandWindow.currentVolume === 0) return "volume_mute";
                                if (islandWindow.currentVolume > 0.5) return "volume_high";
                                return "volume_low";
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 6
                            radius: 3
                            color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.4)

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, islandWindow.currentVolume))
                                height: parent.height
                                radius: 3
                                color: islandWindow.isMuted ? Theme.error : Theme.primary
                            }
                        }

                        Text {
                            text: islandWindow.isMuted ? "MUTED" : Math.round(islandWindow.currentVolume * 100) + "%"
                            color: Theme.on_surface
                            font.bold: true
                            font.pixelSize: 11
                            font.family: Theme.fontFamilyMono
                        }
                    }
                }

                // --- B. BRIGHTNESS OVERRIDE CONTENT ---
                Item {
                    id: brightnessContent
                    anchors.fill: parent
                    visible: islandWindow.currentState === "brightness"
                    opacity: visible ? 1.0 : 0.0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 10

                        VectorIcon {
                            iconSize: 18
                            color: Theme.primary
                            name: "sun"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 6
                            radius: 3
                            color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.4)

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, islandWindow.currentBrightness))
                                height: parent.height
                                radius: 3
                                color: Theme.primary
                            }
                        }

                        Text {
                            text: Math.round(islandWindow.currentBrightness * 100) + "%"
                            color: Theme.on_surface
                            font.bold: true
                            font.pixelSize: 11
                            font.family: Theme.fontFamilyMono
                        }
                    }
                }

                // --- C. BATTERY STATUS OVERRIDE CONTENT ---
                Item {
                    id: batteryContent
                    anchors.fill: parent
                    visible: islandWindow.currentState === "battery"
                    opacity: visible ? 1.0 : 0.0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 10

                        Canvas {
                            id: batteryCanvas
                            implicitWidth: 24; implicitHeight: 14
                            antialiasing: true

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.clearRect(0, 0, width, height);
                                var isLow = islandWindow.batteryPercentage <= 0.2;
                                var fillColor = islandWindow.isCharging ? Theme.primary : (isLow ? Theme.error : Theme.on_surface);

                                ctx.strokeStyle = Theme.outline;
                                ctx.lineWidth = 1.4;

                                ModelUtils.drawRRect(ctx, 1, 1, 18, 12, 2);
                                ctx.stroke();

                                ctx.fillStyle = Theme.outline;
                                ModelUtils.drawRRect(ctx, 20, 4, 2, 6, 1);
                                ctx.fill();

                                var levelWidth = Math.max(1, Math.min(14, (islandWindow.batteryPercentage * 14)));
                                ctx.fillStyle = fillColor;
                                ModelUtils.drawRRect(ctx, 3, 3, levelWidth, 8, 1);
                                ctx.fill();

                                if (islandWindow.isPluggedIn) {
                                    ctx.fillStyle = Theme.primary;
                                    ctx.strokeStyle = Theme.surface;
                                    ctx.lineWidth = 0.8;
                                    ctx.beginPath();
                                    ctx.moveTo(11, 0);
                                    ctx.lineTo(6, 7);
                                    ctx.lineTo(9, 7);
                                    ctx.lineTo(8, 14);
                                    ctx.lineTo(13, 7);
                                    ctx.lineTo(10, 7);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();
                                }
                            }

                            Connections {
                                target: islandWindow
                                function onBatteryPercentageChanged() { batteryCanvas.requestPaint(); }
                                function onBatteryStateChanged() { batteryCanvas.requestPaint(); }
                            }
                        }

                        Text {
                            text: Math.round(islandWindow.batteryPercentage * 100) + "% " +
                                  (islandWindow.isCharging ? "Charging" : (islandWindow.isPluggedIn ? "Plugged" : "Discharging"))
                            color: Theme.on_surface
                            font.bold: true
                            font.pixelSize: 11
                            font.family: Theme.fontFamilyMono
                        }
                    }
                }

                // --- D. MUSIC PLAYBACK CONTENT ---
                Item {
                    id: musicContent
                    anchors.fill: parent
                    visible: islandWindow.currentState === "music"
                    opacity: visible ? 1.0 : 0.0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        anchors.topMargin: 6
                        anchors.bottomMargin: 6
                        spacing: 10

                        // 1. LEFT: Album Cover Artwork
                        Rectangle {
                            implicitWidth: islandWindow.isHovered ? 52 : 26
                            implicitHeight: islandWindow.isHovered ? 52 : 26
                            radius: islandWindow.isHovered ? 12 : 13
                            color: Theme.surface_container_high
                            border.color: islandWindow.isMusicPlaying ? Theme.primary : Theme.outline_variant
                            border.width: 1
                            clip: true
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                            Image {
                                anchors.fill: parent
                                source: MediaHelper.trackArtUrl
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready
                            }

                            VectorIcon {
                                anchors.centerIn: parent
                                iconSize: islandWindow.isHovered ? 20 : 14
                                color: Theme.primary
                                name: "music"
                                visible: !MediaHelper.trackArtUrl || MediaHelper.trackArtUrl.length === 0
                            }
                        }

                        // 2. CENTER: Perfectly centered Track Title & Artist
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: islandWindow.isHovered ? 2 : 0

                            Text {
                                Layout.fillWidth: true
                                text: MediaHelper.trackTitle
                                color: Theme.on_surface
                                font.bold: true
                                font.pixelSize: islandWindow.isHovered ? 12 : 11
                                font.family: Theme.fontFamilySans
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: MediaHelper.trackArtist
                                color: Theme.on_surface_variant
                                font.pixelSize: islandWindow.isHovered ? 10 : 9
                                font.family: Theme.fontFamilySans
                                elide: Text.ElideRight
                            }

                            // Scrub Bar & Timestamps (only loaded when expanded)
                            Loader {
                                Layout.fillWidth: true
                                active: islandWindow.isHovered
                                visible: islandWindow.isHovered

                                sourceComponent: ColumnLayout {
                                    spacing: 2

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 3
                                        radius: 1.5
                                        color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.4)

                                        Rectangle {
                                            width: parent.width * Math.max(0, Math.min(1, (MediaHelper.length > 0) ? (MediaHelper.position / MediaHelper.length) : 0))
                                            height: parent.height
                                            radius: 1.5
                                            color: Theme.primary
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: MediaHelper.formatTime(MediaHelper.position)
                                            color: Theme.on_surface_variant
                                            font.pixelSize: 8
                                            font.family: Theme.fontFamilyMono
                                        }

                                        Item { Layout.fillWidth: true }

                                        Text {
                                            text: MediaHelper.formatTime(MediaHelper.length)
                                            color: Theme.on_surface_variant
                                            font.pixelSize: 8
                                            font.family: Theme.fontFamilyMono
                                        }
                                    }
                                }
                            }
                        }

                        // 3. RIGHT: Controls & Equalizer Bars
                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 8

                            Loader {
                                active: islandWindow.isHovered
                                visible: islandWindow.isHovered

                                sourceComponent: RowLayout {
                                    spacing: 6

                                    Item {
                                        implicitWidth: 24; implicitHeight: 24
                                        Rectangle {
                                            anchors.fill: parent; radius: 12
                                            color: prevArea.pressed ? Qt.rgba(Theme.primary_fixed.r, Theme.primary_fixed.g, Theme.primary_fixed.b, 0.25) : "transparent"
                                            VectorIcon {
                                                anchors.centerIn: parent
                                                iconSize: 12
                                                color: Theme.on_surface
                                                name: "prev"
                                            }
                                        }
                                        MouseArea {
                                            id: prevArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: MediaHelper.previous()
                                        }
                                    }

                                    Item {
                                        implicitWidth: 26; implicitHeight: 26
                                        Rectangle {
                                            anchors.fill: parent; radius: 13
                                            color: playPauseArea.pressed ? Theme.primary_fixed_dim : Theme.primary
                                            VectorIcon {
                                                anchors.centerIn: parent
                                                iconSize: 12
                                                color: Theme.on_primary
                                                name: islandWindow.isMusicPlaying ? "pause" : "play"
                                            }
                                        }
                                        MouseArea {
                                            id: playPauseArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: MediaHelper.togglePlaying()
                                        }
                                    }

                                    Item {
                                        implicitWidth: 24; implicitHeight: 24
                                        Rectangle {
                                            anchors.fill: parent; radius: 12
                                            color: nextArea.pressed ? Qt.rgba(Theme.primary_fixed.r, Theme.primary_fixed.g, Theme.primary_fixed.b, 0.25) : "transparent"
                                            VectorIcon {
                                                anchors.centerIn: parent
                                                iconSize: 12
                                                color: Theme.on_surface
                                                name: "next"
                                            }
                                        }
                                        MouseArea {
                                            id: nextArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: MediaHelper.next()
                                        }
                                    }
                                }
                            }

                            // EQUALIZER BARS (Direct Property Access to Avoid Array Evaluation Overhead)
                            Item {
                                implicitWidth: 16; implicitHeight: islandWindow.isHovered ? 24 : 14
                                Layout.alignment: Qt.AlignVCenter

                                Row {
                                    anchors.bottom: parent.bottom
                                    spacing: 2

                                    Repeater {
                                        model: 4
                                        delegate: Rectangle {
                                            required property int index
                                            width: 2.5
                                            height: {
                                                var maxH = islandWindow.isHovered ? 24 : 14;
                                                if (!islandWindow.isMusicPlaying) return 3;
                                                var val = 0;
                                                if (index === 0) val = islandWindow.cavaBar0;
                                                else if (index === 1) val = islandWindow.cavaBar1;
                                                else if (index === 2) val = islandWindow.cavaBar2;
                                                else if (index === 3) val = islandWindow.cavaBar3;
                                                return Math.max(3, Math.min(maxH, (val / 100.0) * maxH));
                                            }
                                            radius: 1.2
                                            color: Theme.primary
                                            anchors.bottom: parent.bottom
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // --- E. IDLE CONTENT (Clock Display) ---
                Item {
                    id: idleContent
                    anchors.fill: parent
                    visible: islandWindow.currentState === "idle"
                    opacity: visible ? 1.0 : 0.0

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        VectorIcon {
                            iconSize: 14
                            color: Theme.primary
                            name: "clock"
                        }

                        Text {
                            text: Qt.formatDateTime(islandWindow.now, "hh:mm:ss")
                            color: Theme.on_surface
                            font.bold: true
                            font.pixelSize: 11
                            font.family: Theme.fontFamilyMono
                        }
                    }
                }
            }
        }
    }
}
