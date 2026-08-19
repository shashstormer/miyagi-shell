pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: brightnessService

    property real currentBrightness: 0.8
    readonly property int brightnessPercent: Math.round(currentBrightness * 100)
    property bool isLoaded: false

    signal brightnessChanged(real value)

    // Real-time brightness monitor process (listens to hardware brightness kernel events)
    property Process brightnessMonitorProc: Process {
        command: ["brightnessctl", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data && brightnessService.brightnessProc && !brightnessService.brightnessProc.running) {
                    brightnessService.brightnessProc.running = true;
                }
            }
        }
    }

    // Fast native brightness fetch (machine-readable brightnessctl -m)
    property Process brightnessProc: Process {
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return;
                var parts = data.trim().split(",");
                if (parts.length >= 5) {
                    var cur = parseFloat(parts[2]);
                    var max = parseFloat(parts[4]);
                    if (max > 0) {
                        var val = Math.max(0, Math.min(1, cur / max));
                        if (!brightnessService.isLoaded) {
                            brightnessService.currentBrightness = val;
                            brightnessService.isLoaded = true;
                        } else if (Math.abs(brightnessService.currentBrightness - val) > 0.005) {
                            brightnessService.currentBrightness = val;
                            brightnessService.brightnessChanged(val);
                        }
                    }
                }
            }
        }
    }

    property Timer pollTimer: Timer {
        interval: 150
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (brightnessService.brightnessProc && !brightnessService.brightnessProc.running) {
                brightnessService.brightnessProc.running = true;
            }
        }
    }

    property Process brightnessSetProc: Process {
        command: ["brightnessctl", "set", "100%"]
    }

    function setBrightness(percent) {
        var p = Math.max(1, Math.min(100, Math.round(percent)));
        brightnessService.currentBrightness = p / 100.0;
        brightnessSetProc.command = ["brightnessctl", "set", p + "%"];
        if (brightnessSetProc.running) {
            brightnessSetProc.running = false;
        }
        brightnessSetProc.running = true;
    }
}
