pragma Singleton
import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: mediaHelper

    // 1. Raw & Deduplicated MPRIS Player Management
    property int manualPlayerIndex: -1
    readonly property var rawPlayerList: Mpris.players ? Mpris.players.values : []
    readonly property var playerList: deduplicatePlayers(rawPlayerList)
    readonly property int playerCount: playerList ? playerList.length : 0
    readonly property bool hasMultiplePlayers: playerCount > 1

    // 2. Active Player Dynamic Resolution
    readonly property MprisPlayer activePlayer: selectActivePlayer(playerList, manualPlayerIndex)
    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: hasPlayer ? (activePlayer.playbackState === MprisPlaybackState.Playing) : false

    // 3. Track Metadata
    readonly property string trackTitle: {
        if (!hasPlayer) return "NO MEDIA PLAYING";
        if (activePlayer.trackTitle && activePlayer.trackTitle.trim() !== "") return activePlayer.trackTitle;
        return "Media Paused / Ready";
    }

    readonly property string trackArtist: {
        if (!hasPlayer) return "System Audio Idle";
        if (activePlayer.trackArtist && activePlayer.trackArtist.trim() !== "") return activePlayer.trackArtist;
        if (activePlayer.trackArtists && activePlayer.trackArtists.length > 0) return activePlayer.trackArtists.join(", ");
        if (activePlayer.identity) return activePlayer.identity;
        return "Unknown Artist";
    }

    readonly property string trackArtUrl: (hasPlayer && activePlayer.trackArtUrl) ? activePlayer.trackArtUrl.toString() : ""
    readonly property real length: hasPlayer ? (activePlayer.length || 0) : 0

    // 4. Real-Time Position Tracking & Polling
    property real trackPosition: 0
    readonly property real position: trackPosition

    property Timer positionTimer: Timer {
        interval: 1000
        running: mediaHelper.isPlaying
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (mediaHelper.hasPlayer && mediaHelper.isPlaying) {
                var bus = mediaHelper.activePlayer.busName || "";
                var id = mediaHelper.activePlayer.identity || "";
                if (!bus.includes("playerctld") && !id.includes("playerctld")) {
                    try {
                        mediaHelper.activePlayer.positionChanged();
                    } catch (e) {}
                }
                mediaHelper.trackPosition += 1;
            }
        }
    }

    // Direct listener for position changes from active player
    property var activePlayerTracker: Connections {
        target: mediaHelper.hasPlayer ? mediaHelper.activePlayer : null
        function onPositionChanged() {
            if (mediaHelper.activePlayer && mediaHelper.activePlayer.position !== undefined) {
                mediaHelper.trackPosition = mediaHelper.activePlayer.position;
            }
        }
    }

    onActivePlayerChanged: {
        if (activePlayer && activePlayer.position !== undefined) {
            trackPosition = activePlayer.position;
        } else {
            trackPosition = 0;
        }
    }

    // 5. Playback Transport & Cycling Actions
    function cyclePlayer() {
        if (!playerList || playerList.length <= 1) return;
        var currentIdx = 0;
        for (var i = 0; i < playerList.length; i++) {
            if (playerList[i] === activePlayer) {
                currentIdx = i;
                break;
            }
        }
        manualPlayerIndex = (currentIdx + 1) % playerList.length;
    }

    function togglePlaying() {
        if (hasPlayer && activePlayer) {
            activePlayer.togglePlaying();
        }
    }

    function next() {
        if (hasPlayer && activePlayer) {
            activePlayer.next();
        }
    }

    function previous() {
        if (hasPlayer && activePlayer) {
            activePlayer.previous();
        }
    }

    function seek(newPos) {
        if (hasPlayer && activePlayer && length > 0) {
            trackPosition = newPos;
            activePlayer.position = newPos;
        }
    }

    // 6. Utility Functions
    function deduplicatePlayers(rawList) {
        if (!rawList || rawList.length === 0) return [];
        var result = [];
        for (var i = 0; i < rawList.length; i++) {
            var p = rawList[i];
            if (!p) continue;
            var name = (p.identity || p.busName || ("player_" + i)).toLowerCase();
            var existingIdx = -1;
            for (var j = 0; j < result.length; j++) {
                var existingName = (result[j].identity || result[j].busName || "").toLowerCase();
                if (existingName === name) {
                    existingIdx = j;
                    break;
                }
            }
            if (existingIdx >= 0) {
                if (p.playbackState === MprisPlaybackState.Playing && result[existingIdx].playbackState !== MprisPlaybackState.Playing) {
                    result[existingIdx] = p;
                }
            } else {
                result.push(p);
            }
        }
        return result;
    }

    function selectActivePlayer(playerList, manualIndex) {
        if (!playerList || playerList.length === 0) return null;
        if (manualIndex >= 0 && manualIndex < playerList.length) {
            return playerList[manualIndex];
        }
        for (var i = 0; i < playerList.length; i++) {
            if (playerList[i] && playerList[i].playbackState === MprisPlaybackState.Playing) {
                return playerList[i];
            }
        }
        for (var j = 0; j < playerList.length; j++) {
            if (playerList[j] && (playerList[j].trackTitle || playerList[j].trackArtist)) {
                return playerList[j];
            }
        }
        return playerList[0];
    }

    function formatTime(seconds) {
        if (!seconds || isNaN(seconds) || seconds <= 0) return "0:00";
        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
}
