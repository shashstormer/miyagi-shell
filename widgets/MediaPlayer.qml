import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../theme"
import "./components"

Rectangle {
    id: root

    visible: ConfigService.showMediaPlayer

    // Dynamic Config Path Resolution
    readonly property string cavaConfigPath: Quickshell.shellDir ? (Quickshell.shellDir + "/resources/cava.conf") : (Quickshell.env("HOME") + "/.config/quickshell/miyagi/resources/cava.conf")

    implicitWidth: 412
    // Compact height when idle/no media player present, full height when player is active
    implicitHeight: MediaHelper.hasPlayer ? 142 : 72
    Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 0.88)
    border.color: MediaHelper.isPlaying ? Theme.secondary : Theme.outline_variant
    border.width: 1.5
    radius: 10
    clip: true

    Behavior on color { ColorAnimation { duration: 250 } }

    // 1. Full-Bleed Ambient Album Cover Artwork Spread with Dynamic Zoom & Opacity Beat Pulse
    Image {
        id: bgArt
        anchors.fill: parent
        source: MediaHelper.trackArtUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: MediaHelper.hasPlayer && MediaHelper.trackArtUrl.length > 0
        
        // Dynamic Opacity & Scale Pulsing in Sync with Cava Audio Beats
        opacity: MediaHelper.isPlaying ? (0.22 + root.audioIntensity * 0.38) : 0.14
        scale: MediaHelper.isPlaying ? (1.0 + root.audioIntensity * 0.06) : 1.0
        
        Behavior on opacity { NumberAnimation { duration: 70; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 70; easing.type: Easing.OutQuad } }
    }

    // 2. Internal Radial Ambient Beat Color Pulse Layer
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.18)
        opacity: MediaHelper.isPlaying ? (0.08 + root.audioIntensity * 0.32) : 0.0
        Behavior on opacity { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
    }

    // 3. Dark Gradient Vignette for High Contrast Text Readability
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.60) }
            GradientStop { position: 1.0; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.85) }
        }
    }

    // 4. Dynamic Audio Intensity Beat Ring Border
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: Theme.secondary
        border.width: 1.5
        opacity: MediaHelper.isPlaying ? (0.20 + root.audioIntensity * 0.50) : 0.0
        Behavior on opacity { NumberAnimation { duration: 60 } }
    }

    // Bind central CavaService active state to music playing on desktop only
    Binding {
        target: CavaService
        property: "active"
        value: MediaHelper.isPlaying && !ConfigService.hasActiveWindow
    }

    // Real-time audio intensity from central CavaService
    readonly property real audioIntensity: CavaService.audioIntensity
    readonly property var audioSpectrum: CavaService.audioSpectrum

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14

        // Left Side: Cover Art Box
        Rectangle {
            id: artBox
            implicitWidth: MediaHelper.hasPlayer ? 96 : 48
            implicitHeight: MediaHelper.hasPlayer ? 96 : 48
            Layout.alignment: Qt.AlignVCenter
            color: Theme.surface_container_lowest
            border.color: MediaHelper.isPlaying ? Theme.secondary : Theme.outline_variant
            border.width: 1.5
            radius: 8
            clip: true

            Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            // Album Artwork Image
            Image {
                anchors.fill: parent
                source: MediaHelper.trackArtUrl
                fillMode: Image.PreserveAspectCrop
                visible: MediaHelper.trackArtUrl.length > 0
                asynchronous: true
                opacity: status === Image.Ready ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }

            // Fallback Cover Graphic
            Rectangle {
                anchors.fill: parent
                color: Theme.surface_container_low
                visible: MediaHelper.trackArtUrl.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    VectorIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        iconSize: MediaHelper.hasPlayer ? 24 : 18
                        color: MediaHelper.isPlaying ? Theme.secondary : Theme.on_surface_variant
                        name: "music"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            if (!MediaHelper.hasPlayer) return "IDLE";
                            if (MediaHelper.isPlaying) return "PLAYING";
                            return "PAUSED";
                        }
                        color: Theme.secondary
                        font.pixelSize: 8
                        font.bold: true
                        font.letterSpacing: 1
                        font.family: Theme.fontFamilyMono
                    }
                }
            }
        }

        // Right Side: Header, Track Metadata, Scrub Bar & Controls
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 3

            // Top Header: App Name, Identity & Player Switcher
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: {
                        if (!MediaHelper.hasPlayer) return "MEDIA PLAYER // IDLE";
                        var name = MediaHelper.activePlayer.identity ? MediaHelper.activePlayer.identity.toUpperCase() : "MPRIS MEDIA";
                        if (MediaHelper.hasMultiplePlayers) {
                            var idx = (MediaHelper.playerList.indexOf(MediaHelper.activePlayer) + 1);
                            return name + "  [" + idx + "/" + MediaHelper.playerCount + "]";
                        }
                        return name;
                    }
                    color: Theme.secondary
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.5
                    font.family: Theme.fontFamilyMono
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Interactive Player Switcher Button (Visible when multiple players are present)
                Rectangle {
                    visible: MediaHelper.hasMultiplePlayers
                    implicitWidth: switcherRow.implicitWidth + 12
                    implicitHeight: 18
                    radius: 9
                    color: switcherArea.containsMouse ? Theme.secondary_container : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.8)
                    border.color: Theme.outline_variant
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: switcherRow
                        anchors.centerIn: parent
                        spacing: 3

                        VectorIcon {
                            iconSize: 12
                            color: switcherArea.containsMouse ? Theme.on_secondary_container : Theme.secondary
                            name: "switch_arrows"
                        }

                        Text {
                            text: "SWITCH"
                            color: switcherArea.containsMouse ? Theme.on_secondary_container : Theme.secondary
                            font.pixelSize: 8
                            font.bold: true
                            font.letterSpacing: 1
                            font.family: Theme.fontFamilyMono
                        }
                    }

                    MouseArea {
                        id: switcherArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaHelper.cyclePlayer()
                    }
                }
            }

            // Track Title & Artist Text Stack
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: MediaHelper.trackTitle
                    color: Theme.on_surface
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    font.family: Theme.fontFamilyMono
                }

                Text {
                    Layout.fillWidth: true
                    text: MediaHelper.trackArtist
                    color: Theme.on_surface_variant
                    font.pixelSize: 10
                    font.bold: true
                    elide: Text.ElideRight
                    font.family: Theme.fontFamilyMono
                }
            }

            // Interactive Track Scrub Bar & Timestamps (Visible when media player is active)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                visible: MediaHelper.hasPlayer

                Rectangle {
                    id: progressBar
                    Layout.fillWidth: true
                    height: progressArea.containsMouse ? 6 : 4
                    color: Theme.surface_container_high
                    radius: 3
                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                    // Adaptive Progress Fill Bar
                    Rectangle {
                        width: parent.width * (MediaHelper.length > 0 ? Math.min(1.0, Math.max(0.0, MediaHelper.position / MediaHelper.length)) : 0.0)
                        height: parent.height
                        color: Theme.secondary
                        radius: 3
                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    }

                    // Scrub Handle Knob on Hover
                    Rectangle {
                        visible: progressArea.containsMouse && MediaHelper.length > 0
                        x: Math.max(0, Math.min(progressBar.width - width, progressBar.width * (MediaHelper.position / MediaHelper.length) - width / 2))
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10; height: 10; radius: 5
                        color: Theme.secondary_container
                        border.color: Theme.secondary
                        border.width: 1.5
                    }

                    MouseArea {
                        id: progressArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: MediaHelper.hasPlayer && MediaHelper.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: mouse => {
                            if (MediaHelper.hasPlayer && MediaHelper.length > 0) {
                                var clickRatio = mouse.x / width;
                                MediaHelper.seek(clickRatio * MediaHelper.length);
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: MediaHelper.formatTime(MediaHelper.position)
                        color: Theme.secondary
                        font.pixelSize: 9
                        font.family: Theme.fontFamilyMono
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: MediaHelper.formatTime(MediaHelper.length)
                        color: Theme.on_surface_variant
                        font.pixelSize: 9
                        font.family: Theme.fontFamilyMono
                    }
                }
            }

            // Bottom Control Bar + Real Cava Spectrum Visualizer
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: MediaHelper.hasPlayer

                // Real Cava Audio Spectrum Bars (Anchored at bottom, growing UPWARDS)
                Item {
                    implicitWidth: 68
                    implicitHeight: 18
                    visible: MediaHelper.isPlaying
                    Layout.alignment: Qt.AlignVCenter

                    Row {
                        anchors.bottom: parent.bottom
                        spacing: 2.5

                        Repeater {
                            model: 14
                            delegate: Rectangle {
                                required property int index
                                anchors.bottom: parent.bottom
                                width: 2.5
                                height: Math.max(2, Math.min(18, (root.audioSpectrum[index] || 0) / 100 * 18))
                                color: Theme.secondary
                                radius: 1
                                Behavior on height { NumberAnimation { duration: 40; easing.type: Easing.OutQuad } }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Media Control Buttons (Previous, Play/Pause, Next)
                RowLayout {
                    spacing: 12

                    // Previous Button
                    Rectangle {
                        implicitWidth: 26; implicitHeight: 26; radius: 13
                        color: prevArea.containsMouse ? Theme.secondary : Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.7)
                        border.color: prevArea.containsMouse ? Theme.secondary : Theme.outline_variant
                        border.width: 1
                        opacity: MediaHelper.hasPlayer && (MediaHelper.activePlayer.canGoPrevious ?? true) ? 1.0 : 0.4

                        Behavior on color { ColorAnimation { duration: 150 } }

                        VectorIcon {
                            anchors.centerIn: parent
                            iconSize: 10
                            color: prevArea.containsMouse ? Theme.on_secondary : Theme.secondary
                            name: "prev"
                        }

                        MouseArea {
                            id: prevArea; anchors.fill: parent; hoverEnabled: true
                            enabled: MediaHelper.hasPlayer && (MediaHelper.activePlayer.canGoPrevious ?? true)
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MediaHelper.previous()
                        }
                    }

                    // Play / Pause Main Button
                    Rectangle {
                        implicitWidth: 32; implicitHeight: 32; radius: 16
                        color: playArea.containsMouse ? Theme.secondary_container : Theme.secondary
                        opacity: MediaHelper.hasPlayer && (MediaHelper.activePlayer.canControl ?? true) ? 1.0 : 0.5

                        Behavior on color { ColorAnimation { duration: 150 } }

                        VectorIcon {
                            anchors.centerIn: parent
                            iconSize: 12
                            color: playArea.containsMouse ? Theme.on_secondary_container : Theme.on_secondary
                            name: MediaHelper.isPlaying ? "pause" : "play"
                        }

                        MouseArea {
                            id: playArea; anchors.fill: parent; hoverEnabled: true
                            enabled: MediaHelper.hasPlayer && (MediaHelper.activePlayer.canControl ?? true)
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MediaHelper.togglePlaying()
                        }
                    }

                    // Next Button
                    Rectangle {
                        implicitWidth: 26; implicitHeight: 26; radius: 13
                        color: nextArea.containsMouse ? Theme.secondary : Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.7)
                        border.color: nextArea.containsMouse ? Theme.secondary : Theme.outline_variant
                        border.width: 1
                        opacity: MediaHelper.hasPlayer && (MediaHelper.activePlayer.canGoNext ?? true) ? 1.0 : 0.4

                        Behavior on color { ColorAnimation { duration: 150 } }

                        VectorIcon {
                            anchors.centerIn: parent
                            iconSize: 10
                            color: nextArea.containsMouse ? Theme.on_secondary : Theme.secondary
                            name: "next"
                        }

                        MouseArea {
                            id: nextArea; anchors.fill: parent; hoverEnabled: true
                            enabled: MediaHelper.hasPlayer && (MediaHelper.activePlayer.canGoNext ?? true)
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MediaHelper.next()
                        }
                    }
                }
            }
        }
    }
}
