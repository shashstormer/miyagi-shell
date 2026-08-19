import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris
import "../../theme"
import "../components"

BaseFlyoutPanel {
    id: mediaPanelWindow

    title: "Media Player"
    iconName: "music"
    side: "left"
    cardWidth: 460
    cardHeight: 620
    showSwitch: false
    showRefresh: true
    requiresKeyboardFocus: true

    // Focus Index: 0 = Play/Pause & Transport, 1 = Seek Bar, 2+ = Player List Items
    property int selectedIndex: 0
    readonly property int playerCount: MediaHelper.playerCount
    readonly property int totalFocusCount: 2 + playerCount

    onRefreshClicked: {
        // Force refresh active player & state
        if (MediaHelper.hasPlayer && MediaHelper.activePlayer) {
            try {
                MediaHelper.activePlayer.positionChanged();
            } catch(e) {}
        }
    }

    onIsOpenChanged: {
        if (isOpen) {
            selectedIndex = 0;
            InputService.useKeyboard();
        }
    }

    function formatTime(seconds) {
        if (isNaN(seconds) || seconds < 0) return "0:00";
        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function seekRelative(deltaSeconds) {
        if (!MediaHelper.hasPlayer || MediaHelper.length <= 0) return;
        var newPos = Math.max(0, Math.min(MediaHelper.length, MediaHelper.position + deltaSeconds));
        MediaHelper.seek(newPos);
    }

    function navigate(delta) {
        InputService.useKeyboard();
        if (totalFocusCount > 0) {
            selectedIndex = (selectedIndex + (delta % totalFocusCount) + totalFocusCount) % totalFocusCount;
            if (selectedIndex >= 2) {
                var playerIdx = selectedIndex - 2;
                playersListView.positionViewAtIndex(playerIdx, ListView.Contain);
            }
        }
    }

    function executeCurrentAction() {
        if (selectedIndex === 0) {
            MediaHelper.togglePlaying();
        } else if (selectedIndex === 1) {
            MediaHelper.togglePlaying();
        } else if (selectedIndex >= 2) {
            var pIdx = selectedIndex - 2;
            if (pIdx >= 0 && pIdx < MediaHelper.playerCount) {
                MediaHelper.selectPlayer(pIdx);
            }
        }
    }

    // Connect to global InputService navigation signals (Keyboard & Controller)
    Connections {
        target: InputService
        enabled: mediaPanelWindow.isOpen

        function onNavUp() {
            mediaPanelWindow.navigate(-1);
        }

        function onNavDown() {
            mediaPanelWindow.navigate(1);
        }

        function onNavLeft() {
            if (selectedIndex === 1) {
                mediaPanelWindow.seekRelative(-5);
            } else {
                MediaHelper.previous();
            }
        }

        function onNavRight() {
            if (selectedIndex === 1) {
                mediaPanelWindow.seekRelative(5);
            } else {
                MediaHelper.next();
            }
        }

        function onNavPrevTab() {
            MediaHelper.previous();
        }

        function onNavNextTab() {
            MediaHelper.next();
        }

        function onNavSelect() {
            mediaPanelWindow.executeCurrentAction();
        }

        function onNavBack() {
            InputService.closeOrReturn(mediaPanelWindow);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // ==========================================
        // 1. ACTIVE PLAYER HERO CARD
        // ==========================================
        Rectangle {
            id: heroCard
            Layout.fillWidth: true
            implicitHeight: 220
            radius: 14
            clip: true
            color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 0.90)
            border.color: (mediaPanelWindow.selectedIndex === 0 || mediaPanelWindow.selectedIndex === 1)
                ? Theme.secondary
                : (MediaHelper.isPlaying ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.4) : Theme.outline_variant)
            border.width: (mediaPanelWindow.selectedIndex === 0 || mediaPanelWindow.selectedIndex === 1) ? 2 : 1

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // Ambient Album Artwork Spread Background
            Image {
                anchors.fill: parent
                source: MediaHelper.trackArtUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: MediaHelper.hasPlayer && MediaHelper.trackArtUrl.length > 0
                opacity: MediaHelper.isPlaying ? 0.22 : 0.12
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // Dark Gradient Vignette for Readability
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.65) }
                    GradientStop { position: 1.0; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.88) }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Top Row: Album Cover Art & Track Metadata
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    // Album Cover Art Box
                    Rectangle {
                        width: 80
                        height: 80
                        radius: 10
                        color: Theme.surface_container_lowest
                        border.color: MediaHelper.isPlaying ? Theme.secondary : Theme.outline_variant
                        border.width: 1.5
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: MediaHelper.trackArtUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: MediaHelper.trackArtUrl.length > 0
                            opacity: status === Image.Ready ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                        // Fallback Music Note Icon
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surface_container_low
                            visible: MediaHelper.trackArtUrl.length === 0

                            VectorIcon {
                                anchors.centerIn: parent
                                name: "music"
                                iconSize: 32
                                color: MediaHelper.isPlaying ? Theme.secondary : Theme.on_surface_variant
                            }
                        }
                    }

                    // Metadata Column
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 3

                        // Player Tag & State Badge
                        RowLayout {
                            spacing: 6
                            Layout.fillWidth: true

                            Text {
                                text: {
                                    if (!MediaHelper.hasPlayer) return "NO ACTIVE PLAYER";
                                    var idName = MediaHelper.activePlayer.identity ? MediaHelper.activePlayer.identity.toUpperCase() : "MPRIS MEDIA";
                                    return idName;
                                }
                                color: Theme.secondary
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1.2
                                font.family: Theme.fontFamilyMono
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            PillBadge {
                                text: MediaHelper.isPlaying ? "PLAYING" : (MediaHelper.hasPlayer ? "PAUSED" : "IDLE")
                                isInteractive: false
                                pillHeight: 18
                                fontSize: 9
                                horizontalPadding: 6
                            }
                        }

                        // Track Title
                        Text {
                            text: MediaHelper.trackTitle
                            color: Theme.on_surface
                            font.bold: true
                            font.pixelSize: 14
                            font.family: Theme.fontFamilyDisplay
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Track Artist
                        Text {
                            text: MediaHelper.trackArtist
                            color: Theme.on_surface_variant
                            font.pixelSize: 11
                            font.family: Theme.fontFamilyDisplay
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                // Middle: Progress Seek Slider
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: mediaPanelWindow.formatTime(MediaHelper.position)
                            color: Theme.on_surface_variant
                            font.pixelSize: 10
                            font.family: Theme.fontFamilyMono
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: MediaHelper.length > 0 ? mediaPanelWindow.formatTime(MediaHelper.length) : "0:00"
                            color: Theme.on_surface_variant
                            font.pixelSize: 10
                            font.family: Theme.fontFamilyMono
                        }
                    }

                    // Interactive Scrub Bar
                    Rectangle {
                        id: scrubBar
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.7)
                        border.color: (mediaPanelWindow.selectedIndex === 1) ? Theme.secondary : "transparent"
                        border.width: (mediaPanelWindow.selectedIndex === 1) ? 1.5 : 0

                        // Progress Fill
                        Rectangle {
                            height: parent.height
                            radius: 4
                            width: MediaHelper.length > 0 
                                ? Math.max(0, Math.min(parent.width, (MediaHelper.position / MediaHelper.length) * parent.width))
                                : 0
                            color: Theme.secondary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                InputService.useMouse();
                                if (MediaHelper.length > 0) {
                                    var ratio = Math.max(0, Math.min(1, mouse.x / width));
                                    MediaHelper.seek(ratio * MediaHelper.length);
                                }
                            }
                        }
                    }
                }

                // Bottom: Tactile Transport Controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20

                    // Previous Track Button
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: prevMouse.containsMouse 
                            ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.20)
                            : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.6)
                        border.color: prevMouse.containsMouse ? Theme.secondary : Theme.outline_variant
                        border.width: 1

                        VectorIcon {
                            anchors.centerIn: parent
                            name: "prev"
                            iconSize: 16
                            color: Theme.on_surface
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                InputService.useMouse();
                                MediaHelper.previous();
                            }
                        }
                    }

                    // Play / Pause Prominent Circular Button
                    Rectangle {
                        width: 46
                        height: 46
                        radius: 23
                        color: (mediaPanelWindow.selectedIndex === 0 || playMouse.containsMouse)
                            ? Theme.secondary
                            : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.85)
                        border.color: (mediaPanelWindow.selectedIndex === 0) ? Theme.on_secondary : "transparent"
                        border.width: (mediaPanelWindow.selectedIndex === 0) ? 2 : 0
                        scale: playMouse.pressed ? 0.94 : 1.0

                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Behavior on color { ColorAnimation { duration: 120 } }

                        VectorIcon {
                            anchors.centerIn: parent
                            name: MediaHelper.isPlaying ? "pause" : "play"
                            iconSize: 22
                            color: Theme.on_secondary
                        }

                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                InputService.useMouse();
                                MediaHelper.togglePlaying();
                            }
                        }
                    }

                    // Next Track Button
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: nextMouse.containsMouse 
                            ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.20)
                            : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.6)
                        border.color: nextMouse.containsMouse ? Theme.secondary : Theme.outline_variant
                        border.width: 1

                        VectorIcon {
                            anchors.centerIn: parent
                            name: "next"
                            iconSize: 16
                            color: Theme.on_surface
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                InputService.useMouse();
                                MediaHelper.next();
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 2. AVAILABLE PLAYERS SECTION HEADER
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "AVAILABLE PLAYERS (" + MediaHelper.playerCount + ")"
                color: Theme.on_surface_variant
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.2
                font.family: Theme.fontFamilyMono
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            // Cycle Player Shortcut Button
            Rectangle {
                visible: MediaHelper.hasMultiplePlayers
                implicitWidth: cycleRow.implicitWidth + 14
                implicitHeight: 22
                radius: 6
                color: cycleMouse.containsMouse 
                    ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.20)
                    : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.6)
                border.color: Theme.outline_variant
                border.width: 1

                RowLayout {
                    id: cycleRow
                    anchors.centerIn: parent
                    spacing: 4

                    VectorIcon {
                        name: "refresh"
                        iconSize: 11
                        color: Theme.secondary
                    }

                    Text {
                        text: "Cycle Player (Tab)"
                        color: Theme.on_surface
                        font.pixelSize: 10
                        font.family: Theme.fontFamilyDisplay
                    }
                }

                MouseArea {
                    id: cycleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        InputService.useMouse();
                        MediaHelper.cyclePlayer();
                    }
                }
            }
        }

        // ==========================================
        // 3. PLAYERS LIST VIEW
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: playersListView
                anchors.fill: parent
                clip: true
                spacing: 6
                model: MediaHelper.playerList
                currentIndex: Math.max(0, mediaPanelWindow.selectedIndex - 2)
                highlightMoveDuration: 0

                delegate: PanelCardItem {
                    id: playerCard
                    required property var modelData
                    required property int index

                    readonly property bool isActiveThis: modelData === MediaHelper.activePlayer
                    readonly property bool isPlayingThis: modelData && modelData.playbackState === MprisPlaybackState.Playing
                    readonly property bool isSelectedThis: mediaPanelWindow.selectedIndex === (index + 2)

                    width: playersListView.width - 10
                    itemHeight: 52
                    isCurrent: isSelectedThis
                    isSelected: isActiveThis

                    onItemHovered: {
                        if (InputService.isMouse) {
                            mediaPanelWindow.selectedIndex = index + 2;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        // Left Player Icon
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 8
                            color: isActiveThis 
                                ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.20)
                                : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.8)
                            Layout.alignment: Qt.AlignVCenter

                            VectorIcon {
                                anchors.centerIn: parent
                                name: isPlayingThis ? "music" : "audio"
                                iconSize: 16
                                color: isActiveThis ? Theme.secondary : Theme.on_surface_variant
                            }
                        }

                        // Player Identity & Current Track Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            RowLayout {
                                spacing: 6
                                Layout.fillWidth: true

                                Text {
                                    text: modelData.identity || modelData.busName || ("Player " + (index + 1))
                                    color: isActiveThis ? Theme.secondary : Theme.on_surface
                                    font.bold: true
                                    font.pixelSize: 12
                                    font.family: Theme.fontFamilyDisplay
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                PillBadge {
                                    text: isPlayingThis ? "Playing" : (isActiveThis ? "Active" : "Ready")
                                    isInteractive: false
                                    pillHeight: 18
                                    fontSize: 9
                                    horizontalPadding: 6
                                }
                            }

                            Text {
                                text: {
                                    if (modelData.trackTitle && modelData.trackTitle.trim() !== "") {
                                        return modelData.trackTitle + (modelData.trackArtist ? (" • " + modelData.trackArtist) : "");
                                    }
                                    return "No track information";
                                }
                                color: Theme.on_surface_variant
                                font.pixelSize: 10
                                font.family: Theme.fontFamilyDisplay
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Quick Toggle Button on Item
                        SquareButton {
                            size: 28
                            customRadius: 7
                            iconName: isPlayingThis ? "pause" : "play"
                            iconSize: 12
                            onClicked: {
                                MediaHelper.selectPlayer(index);
                                if (modelData && modelData.togglePlaying) {
                                    modelData.togglePlaying();
                                }
                            }
                        }
                    }

                    onClicked: {
                        MediaHelper.selectPlayer(index);
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    id: pScrollBar
                    active: true
                    width: 5
                    policy: ScrollBar.AsNeeded
                    anchors.right: parent.right

                    contentItem: Rectangle {
                        implicitWidth: 5
                        radius: 2.5
                        color: pScrollBar.pressed 
                            ? Theme.secondary 
                            : (pScrollBar.hovered ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.7) : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.25))
                    }
                }
            }

            // Empty State when no players are discovered
            EmptyState {
                anchors.centerIn: parent
                visible: MediaHelper.playerCount === 0
                iconName: "music"
                title: "No Media Players"
                description: "Start Spotify, a web browser, or media player to stream audio."
            }
        }

        // ==========================================
        // 4. FOOTER STATUS BAR
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            height: 24
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Text {
                    text: MediaHelper.hasPlayer ? (MediaHelper.activePlayer.identity || "Media Active") : "Idle"
                    color: Theme.secondary
                    font.pixelSize: 10
                    font.bold: true
                    font.family: Theme.fontFamilyDisplay
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "↵ Select/Play  •  ←/→ Seek/Track  •  Esc Close"
                    color: Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.6)
                    font.pixelSize: 10
                    font.family: Theme.fontFamilyDisplay
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
