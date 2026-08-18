pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: cavaService

    property bool active: false
    property var audioSpectrum: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    readonly property real audioIntensity: {
        if (!audioSpectrum || audioSpectrum.length === 0) return 0;
        var sum = 0;
        for (var i = 0; i < audioSpectrum.length; i++) sum += audioSpectrum[i];
        return (sum / audioSpectrum.length) / 100.0;
    }

    readonly property string dynamicConfigPath: "/tmp/quickshell_cava.conf"

    property Process configWriter: Process {
        id: writerProc
    }

    function updateCavaConfig() {
        var bars = (typeof ConfigService !== "undefined" && ConfigService.cavaBarsCount) ? ConfigService.cavaBarsCount : 14;
        var fps = (typeof ConfigService !== "undefined" && ConfigService.cavaFramerate) ? ConfigService.cavaFramerate : 60;

        var content = "[general]\nbars = " + bars + "\nframerate = " + fps + "\n\n[output]\nmethod = raw\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 100\nbar_delimiter = 59\n";

        writerProc.command = ["sh", "-c", "printf '%s' '" + content + "' > " + dynamicConfigPath];
        writerProc.running = true;
    }

    onActiveChanged: {
        if (active) {
            updateCavaConfig();
        }
    }

    property Process cavaProc: Process {
        id: cavaProc
        command: ["cava", "-p", cavaService.dynamicConfigPath]
        running: cavaService.active

        stdout: SplitParser {
            onRead: data => {
                if (!cavaService.active || !data) return;
                var parts = data.trim().split(";");
                var result = [];
                for (var i = 0; i < parts.length; i++) {
                    var val = parseInt(parts[i]);
                    if (!isNaN(val)) {
                        result.push(Math.max(0, Math.min(100, val)));
                    }
                }
                if (result.length > 0) {
                    cavaService.audioSpectrum = result;
                }
            }
        }
    }
}
