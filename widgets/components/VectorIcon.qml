import QtQuick
import "../../theme"

Canvas {
    id: root

    property string name: "settings"
    property color color: Theme.primary
    property real iconSize: 18

    implicitWidth: iconSize
    implicitHeight: iconSize

    onColorChanged: requestPaint()
    onNameChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = root.color;
        ctx.fillStyle = root.color;
        ctx.lineWidth = 1.8;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        var w = width;
        var h = height;

        if (name === "settings" || name === "gear") {
            // Inner Hole Circle
            ctx.beginPath();
            ctx.arc(w/2, h/2, w*0.16, 0, Math.PI * 2);
            ctx.stroke();

            // 6-Tooth Outer Gear Outline
            ctx.beginPath();
            var numTeeth = 6;
            var innerR = w * 0.28;
            var outerR = w * 0.43;
            var cx = w / 2;
            var cy = h / 2;

            for (var i = 0; i < numTeeth; i++) {
                var a0 = i * (Math.PI * 2 / numTeeth) - 0.22;
                var a1 = i * (Math.PI * 2 / numTeeth) - 0.10;
                var a2 = i * (Math.PI * 2 / numTeeth) + 0.10;
                var a3 = i * (Math.PI * 2 / numTeeth) + 0.22;

                var x0 = cx + Math.cos(a0) * innerR;
                var y0 = cy + Math.sin(a0) * innerR;
                var x1 = cx + Math.cos(a1) * outerR;
                var y1 = cy + Math.sin(a1) * outerR;
                var x2 = cx + Math.cos(a2) * outerR;
                var y2 = cy + Math.sin(a2) * outerR;
                var x3 = cx + Math.cos(a3) * innerR;
                var y3 = cy + Math.sin(a3) * innerR;

                if (i === 0) {
                    ctx.moveTo(x0, y0);
                } else {
                    ctx.lineTo(x0, y0);
                }
                ctx.lineTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.lineTo(x3, y3);
            }
            ctx.closePath();
            ctx.stroke();
        } else if (name === "island" || name === "bar") {
            ctx.beginPath();
            ctx.rect(w*0.1, h*0.3, w*0.8, h*0.4);
            ctx.stroke();
        } else if (name === "widgets" || name === "grid") {
            ctx.beginPath();
            ctx.rect(w*0.15, h*0.15, w*0.3, h*0.3);
            ctx.rect(w*0.55, h*0.15, w*0.3, h*0.3);
            ctx.rect(w*0.15, h*0.55, w*0.3, h*0.3);
            ctx.rect(w*0.55, h*0.55, w*0.3, h*0.3);
            ctx.stroke();
        } else if (name === "scrolling") {
            ctx.beginPath();
            ctx.rect(w*0.12, h*0.18, w*0.35, h*0.64);
            ctx.rect(w*0.53, h*0.18, w*0.35, h*0.64);
            ctx.stroke();
        } else if (name === "dwindle" || name === "layout" || name === "layers") {
            ctx.beginPath();
            ctx.rect(w*0.15, h*0.15, w*0.7, h*0.7);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(w*0.48, h*0.15); ctx.lineTo(w*0.48, h*0.85);
            ctx.moveTo(w*0.48, h*0.5); ctx.lineTo(w*0.85, h*0.5);
            ctx.stroke();
        } else if (name === "master") {
            ctx.beginPath();
            ctx.rect(w*0.12, h*0.15, w*0.42, h*0.7);
            ctx.rect(w*0.58, h*0.15, w*0.3, h*0.32);
            ctx.rect(w*0.58, h*0.53, w*0.3, h*0.32);
            ctx.stroke();
        } else if (name === "monocle") {
            ctx.beginPath();
            ctx.rect(w*0.15, h*0.15, w*0.7, h*0.7);
            ctx.stroke();
            ctx.beginPath();
            ctx.rect(w*0.28, h*0.28, w*0.44, h*0.44);
            ctx.stroke();
        } else if (name === "panel" || name === "sidebar" || name === "panel-left") {
            ctx.beginPath();
            ctx.rect(w*0.15, h*0.16, w*0.7, h*0.68);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(w*0.40, h*0.16); ctx.lineTo(w*0.40, h*0.84);
            ctx.stroke();
        } else if (name === "palette" || name === "appearance") {
            ctx.beginPath();
            ctx.arc(w/2, h/2, w*0.38, 0, Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(w*0.35, h*0.35, w*0.06, 0, Math.PI * 2);
            ctx.arc(w*0.65, h*0.35, w*0.06, 0, Math.PI * 2);
            ctx.arc(w*0.35, h*0.65, w*0.06, 0, Math.PI * 2);
            ctx.fill();
        } else if (name === "services" || name === "cpu") {
            ctx.beginPath();
            ctx.rect(w*0.25, h*0.25, w*0.5, h*0.5);
            ctx.stroke();
            ctx.moveTo(w*0.35, h*0.1); ctx.lineTo(w*0.35, h*0.25);
            ctx.moveTo(w*0.65, h*0.1); ctx.lineTo(w*0.65, h*0.25);
            ctx.moveTo(w*0.35, h*0.75); ctx.lineTo(w*0.35, h*0.9);
            ctx.moveTo(w*0.65, h*0.75); ctx.lineTo(w*0.65, h*0.9);
            ctx.moveTo(w*0.1, h*0.35); ctx.lineTo(w*0.25, h*0.35);
            ctx.moveTo(w*0.1, h*0.65); ctx.lineTo(w*0.25, h*0.65);
            ctx.moveTo(w*0.75, h*0.35); ctx.lineTo(w*0.9, h*0.35);
            ctx.moveTo(w*0.75, h*0.65); ctx.lineTo(w*0.9, h*0.65);
            ctx.stroke();
        } else if (name === "info" || name === "about") {
            ctx.beginPath();
            ctx.arc(w/2, h/2, w*0.38, 0, Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(w/2, h*0.32, w*0.05, 0, Math.PI * 2);
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(w/2, h*0.46);
            ctx.lineTo(w/2, h*0.72);
            ctx.stroke();
        } else if (name === "clock") {
            ctx.beginPath();
            ctx.arc(w/2, h/2, w*0.38, 0, Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(w/2, h/2);
            ctx.lineTo(w/2, h*0.26);
            ctx.moveTo(w/2, h/2);
            ctx.lineTo(w*0.68, h/2);
            ctx.stroke();
        } else if (name === "calendar" || name === "calendar-days") {
            ctx.beginPath();
            ctx.rect(w*0.15, h*0.22, w*0.7, h*0.65);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(w*0.15, h*0.42); ctx.lineTo(w*0.85, h*0.42);
            ctx.moveTo(w*0.34, h*0.12); ctx.lineTo(w*0.34, h*0.26);
            ctx.moveTo(w*0.66, h*0.12); ctx.lineTo(w*0.66, h*0.26);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(w*0.35, h*0.58, w*0.04, 0, Math.PI * 2);
            ctx.arc(w*0.65, h*0.58, w*0.04, 0, Math.PI * 2);
            ctx.arc(w*0.35, h*0.74, w*0.04, 0, Math.PI * 2);
            ctx.arc(w*0.65, h*0.74, w*0.04, 0, Math.PI * 2);
            ctx.fill();
        } else if (name === "parallax" || name === "arrows") {
            ctx.beginPath();
            ctx.moveTo(w*0.2, h*0.35); ctx.lineTo(w*0.8, h*0.35);
            ctx.moveTo(w*0.2, h*0.65); ctx.lineTo(w*0.8, h*0.65);
            ctx.moveTo(w*0.35, h*0.2); ctx.lineTo(w*0.2, h*0.35); ctx.lineTo(w*0.35, h*0.5);
            ctx.moveTo(w*0.65, h*0.5); ctx.lineTo(w*0.8, h*0.65); ctx.lineTo(w*0.65, h*0.8);
            ctx.stroke();
        } else if (name === "save") {
            ctx.beginPath();
            ctx.rect(w*0.15, h*0.15, w*0.7, h*0.7);
            ctx.stroke();
            ctx.beginPath();
            ctx.rect(w*0.3, h*0.15, w*0.4, h*0.25);
            ctx.stroke();
        } else if (name === "check") {
            ctx.beginPath();
            ctx.moveTo(w*0.2, h*0.5);
            ctx.lineTo(w*0.42, h*0.72);
            ctx.lineTo(w*0.82, h*0.28);
            ctx.stroke();
        } else if (name === "sliders" || name === "quick" || name === "file") {
            ctx.beginPath();
            ctx.moveTo(w*0.15, h*0.3); ctx.lineTo(w*0.85, h*0.3);
            ctx.moveTo(w*0.15, h*0.7); ctx.lineTo(w*0.85, h*0.7);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(w*0.4, h*0.3, w*0.1, 0, Math.PI * 2);
            ctx.arc(w*0.65, h*0.7, w*0.1, 0, Math.PI * 2);
            ctx.fill();
        } else if (name === "sparkle") {
            ctx.beginPath();
            ctx.moveTo(w*0.5, h*0.1);
            ctx.quadraticCurveTo(w*0.5, h*0.5, w*0.9, h*0.5);
            ctx.quadraticCurveTo(w*0.5, h*0.5, w*0.5, h*0.9);
            ctx.quadraticCurveTo(w*0.5, h*0.5, w*0.1, h*0.5);
            ctx.quadraticCurveTo(w*0.5, h*0.5, w*0.5, h*0.1);
            ctx.fill();
        } else if (name === "eye") {
            ctx.beginPath();
            ctx.arc(w*0.5, h*0.5, w*0.35, 0, Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(w*0.5, h*0.5, w*0.12, 0, Math.PI * 2);
            ctx.fill();
        } else if (name === "flip" || name === "swap") {
            ctx.beginPath();
            ctx.moveTo(w*0.2, h*0.35); ctx.lineTo(w*0.8, h*0.35);
            ctx.moveTo(w*0.65, h*0.2); ctx.lineTo(w*0.8, h*0.35); ctx.lineTo(w*0.65, h*0.5);
            ctx.moveTo(w*0.8, h*0.65); ctx.lineTo(w*0.2, h*0.65);
            ctx.moveTo(w*0.35, h*0.5); ctx.lineTo(w*0.2, h*0.65); ctx.lineTo(w*0.35, h*0.8);
            ctx.stroke();
        } else if (name === "book" || name === "sepia") {
            ctx.beginPath();
            ctx.moveTo(w*0.5, h*0.3); ctx.lineTo(w*0.15, h*0.2); ctx.lineTo(w*0.15, h*0.75); ctx.lineTo(w*0.5, h*0.85);
            ctx.lineTo(w*0.85, h*0.75); ctx.lineTo(w*0.85, h*0.2); ctx.closePath();
            ctx.moveTo(w*0.5, h*0.3); ctx.lineTo(w*0.5, h*0.85);
            ctx.stroke();
        } else if (name === "exposure" || name === "gamma" || name === "wb_sunny" || name === "brightness_high") {
            ctx.beginPath();
            ctx.arc(w*0.5, h*0.5, w*0.35, 0, Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(w*0.5, h*0.5, w*0.35, -Math.PI*0.5, Math.PI*0.5);
            ctx.fill();
        } else if (name === "undo" || name === "reset") {
            ctx.beginPath();
            ctx.arc(w*0.5, h*0.55, w*0.28, Math.PI*0.2, Math.PI*1.5);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(w*0.5, h*0.15); ctx.lineTo(w*0.5, h*0.35); ctx.lineTo(w*0.3, h*0.25); ctx.closePath();
            ctx.fill();
        } else if (name === "wave") {
            ctx.beginPath();
            ctx.moveTo(w*0.15, h*0.5);
            ctx.lineTo(w*0.35, h*0.25);
            ctx.lineTo(w*0.65, h*0.75);
            ctx.lineTo(w*0.85, h*0.5);
            ctx.stroke();
        } else if (name === "terminal") {
            ctx.beginPath();
            ctx.moveTo(w*0.2, h*0.3); ctx.lineTo(w*0.45, h*0.5); ctx.lineTo(w*0.2, h*0.7);
            ctx.moveTo(w*0.55, h*0.7); ctx.lineTo(w*0.8, h*0.7);
            ctx.stroke();
        } else if (name === "browser") {
            ctx.beginPath();
            ctx.arc(w*0.5, h*0.5, w*0.36, 0, Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(w*0.5, h*0.5, w*0.14, 0, Math.PI * 2);
            ctx.stroke();
        } else if (name === "github") {
            ctx.beginPath();
            ctx.arc(w*0.5, h*0.5, w*0.36, 0, Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(w*0.38, h*0.45, w*0.06, 0, Math.PI * 2);
            ctx.arc(w*0.62, h*0.45, w*0.06, 0, Math.PI * 2);
            ctx.fill();
        } else if (name === "battery") {
            ctx.beginPath();
            ctx.rect(w*0.2, h*0.15, w*0.6, h*0.7);
            ctx.stroke();
            ctx.beginPath();
            ctx.rect(w*0.38, h*0.05, w*0.24, h*0.1);
            ctx.fill();
        } else if (name === "mic" || name === "mic_on" || name === "microphone" || name === "mic_off" || name === "mic_muted" || name === "mic_slash" || name === "mic_disabled") {
            var isOff = (name === "mic_off" || name === "mic_muted" || name === "mic_slash" || name === "mic_disabled");
            var cx = w * 0.5;

            ctx.beginPath();
            ctx.arc(cx, h*0.28, w*0.14, Math.PI, 0);
            ctx.lineTo(cx + w*0.14, h*0.48);
            ctx.arc(cx, h*0.48, w*0.14, 0, Math.PI);
            ctx.closePath();
            ctx.stroke();

            ctx.beginPath();
            ctx.arc(cx, h*0.46, w*0.26, 0, Math.PI);
            ctx.stroke();

            ctx.beginPath();
            ctx.moveTo(cx, h*0.72); ctx.lineTo(cx, h*0.86);
            ctx.moveTo(cx - w*0.18, h*0.86); ctx.lineTo(cx + w*0.18, h*0.86);
            ctx.stroke();

            if (isOff) {
                ctx.beginPath();
                ctx.moveTo(w*0.18, h*0.18);
                ctx.lineTo(w*0.82, h*0.82);
                ctx.stroke();
            }
        } else if (name.indexOf("wifi") !== -1) {
            var cx = w * 0.5;
            var cy = h * 0.82;
            var isOff = (name === "wifi_off" || name === "wifi_slash" || name === "wifi_disabled");
            var isDisconnected = (name === "wifi_0" || name === "wifi_disconnected" || name === "wifi_none");
            var isLow = (name === "wifi_low" || name === "wifi_1");
            var isMedium = (name === "wifi_medium" || name === "wifi_2");
            var isFull = (name === "wifi" || name === "wifi_full" || name === "wifi_high" || name === "wifi_3" || name === "wifi_4");

            // Base broadcast dot
            ctx.beginPath();
            ctx.arc(cx, cy - w*0.02, w*0.065, 0, Math.PI * 2);
            ctx.fill();

            if (isDisconnected) {
                // Small disconnected mark above dot
                ctx.beginPath();
                ctx.moveTo(cx, h*0.28);
                ctx.lineTo(cx, h*0.56);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(cx, h*0.68, w*0.04, 0, Math.PI * 2);
                ctx.fill();
            } else {
                // Inner arc
                ctx.beginPath();
                ctx.arc(cx, cy, w*0.18, -Math.PI*0.75, -Math.PI*0.25);
                ctx.stroke();

                // Middle arc
                if (isMedium || isFull || isOff) {
                    ctx.beginPath();
                    ctx.arc(cx, cy, w*0.32, -Math.PI*0.75, -Math.PI*0.25);
                    ctx.stroke();
                }

                // Outer arc
                if (isFull || isOff) {
                    ctx.beginPath();
                    ctx.arc(cx, cy, w*0.46, -Math.PI*0.75, -Math.PI*0.25);
                    ctx.stroke();
                }
            }

            if (isOff) {
                ctx.beginPath();
                ctx.moveTo(w*0.18, h*0.18);
                ctx.lineTo(w*0.82, h*0.82);
                ctx.stroke();
            }
        } else if (name.indexOf("bluetooth") !== -1) {
            var isOff = (name === "bluetooth_off" || name === "bluetooth_slash" || name === "bluetooth_disabled");
            var isConnected = (name === "bluetooth_connected" || name === "bluetooth_active");
            var isScanning = (name === "bluetooth_scan" || name === "bluetooth_searching");

            // Bluetooth rune
            ctx.beginPath();
            ctx.moveTo(w*0.32, h*0.30);
            ctx.lineTo(w*0.68, h*0.68);
            ctx.lineTo(w*0.50, h*0.88);
            ctx.lineTo(w*0.50, h*0.12);
            ctx.lineTo(w*0.68, h*0.32);
            ctx.lineTo(w*0.32, h*0.70);
            ctx.stroke();

            if (isConnected) {
                ctx.beginPath();
                ctx.arc(w*0.20, h*0.50, w*0.075, 0, Math.PI * 2);
                ctx.arc(w*0.80, h*0.50, w*0.075, 0, Math.PI * 2);
                ctx.fill();
            } else if (isScanning) {
                ctx.beginPath();
                ctx.arc(w*0.68, h*0.50, w*0.20, -Math.PI*0.3, Math.PI*0.3);
                ctx.stroke();
            }

            if (isOff) {
                ctx.beginPath();
                ctx.moveTo(w*0.18, h*0.18);
                ctx.lineTo(w*0.82, h*0.82);
                ctx.stroke();
            }
        } else if (name === "grid9" || name === "menu9" || name === "appgrid") {
            var step = w * 0.28;
            var size = w * 0.18;
            for (var r = 0; r < 3; r++) {
                for (var c = 0; c < 3; c++) {
                    ctx.beginPath();
                    ctx.rect(w*0.13 + c * step, h*0.13 + r * step, size, size);
                    ctx.fill();
                }
            }
        } else if (name.indexOf("volume") !== -1 || name.indexOf("speaker") !== -1) {
            var isMute = (name === "volume_mute" || name === "volume_muted" || name === "volume_off" || name === "volume_slash" || name === "volume_zero" || name === "speaker_mute" || name === "speaker_off");
            var isLow = (name === "volume_low" || name === "volume_1" || name === "speaker_low");
            var isMed = (name === "volume_medium" || name === "volume_2" || name === "speaker_medium");
            var isHigh = (name === "volume" || name === "volume_high" || name === "volume_3" || name === "speaker" || name === "speaker_high");

            // Speaker cone body
            ctx.beginPath();
            ctx.moveTo(w*0.14, h*0.36);
            ctx.lineTo(w*0.30, h*0.36);
            ctx.lineTo(w*0.52, h*0.18);
            ctx.lineTo(w*0.52, h*0.82);
            ctx.lineTo(w*0.30, h*0.64);
            ctx.lineTo(w*0.14, h*0.64);
            ctx.closePath();
            ctx.stroke();

            if (isMute) {
                // Clean 'X' next to cone
                ctx.beginPath();
                ctx.moveTo(w*0.64, h*0.38);
                ctx.lineTo(w*0.84, h*0.62);
                ctx.moveTo(w*0.84, h*0.38);
                ctx.lineTo(w*0.64, h*0.62);
                ctx.stroke();
            } else {
                if (isLow || isMed || isHigh) {
                    ctx.beginPath();
                    ctx.arc(w*0.50, h*0.50, w*0.18, -Math.PI*0.28, Math.PI*0.28);
                    ctx.stroke();
                }
                if (isMed || isHigh) {
                    ctx.beginPath();
                    ctx.arc(w*0.50, h*0.50, w*0.30, -Math.PI*0.28, Math.PI*0.28);
                    ctx.stroke();
                }
                if (isHigh) {
                    ctx.beginPath();
                    ctx.arc(w*0.50, h*0.50, w*0.42, -Math.PI*0.28, Math.PI*0.28);
                    ctx.stroke();
                }
            }
        } else if (name === "trash" || name === "delete") {
            ctx.beginPath();
            ctx.rect(w*0.25, h*0.3, w*0.5, h*0.58);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(w*0.18, h*0.3); ctx.lineTo(w*0.82, h*0.3);
            ctx.moveTo(w*0.38, h*0.18); ctx.lineTo(w*0.62, h*0.18);
            ctx.stroke();
        } else if (name === "close" || name === "x" || name === "cross") {
            ctx.beginPath();
            ctx.moveTo(w*0.24, h*0.24); ctx.lineTo(w*0.76, h*0.76);
            ctx.moveTo(w*0.76, h*0.24); ctx.lineTo(w*0.24, h*0.76);
            ctx.stroke();
        } else if (name === "refresh" || name === "sync") {
            ctx.beginPath();
            ctx.arc(w*0.5, h*0.5, w*0.32, Math.PI*0.2, Math.PI*1.7);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(w*0.72, h*0.25); ctx.lineTo(w*0.85, h*0.42); ctx.lineTo(w*0.62, h*0.44);
            ctx.stroke();
        } else if (name === "audio" || name === "headphones" || name === "headphones_off" || name === "headphones_muted" || name === "headphones_slash") {
            var isOff = (name === "headphones_off" || name === "headphones_muted" || name === "headphones_slash");

            ctx.beginPath();
            ctx.arc(w*0.5, h*0.45, w*0.30, Math.PI, 0);
            ctx.stroke();

            ctx.beginPath();
            ctx.rect(w*0.15, h*0.45, w*0.14, h*0.32);
            ctx.rect(w*0.71, h*0.45, w*0.14, h*0.32);
            ctx.fill();

            if (isOff) {
                ctx.beginPath();
                ctx.moveTo(w*0.18, h*0.18);
                ctx.lineTo(w*0.82, h*0.82);
                ctx.stroke();
            }
        } else if (name === "keyboard") {
            ctx.beginPath();
            ctx.rect(w*0.15, h*0.3, w*0.7, h*0.42);
            ctx.stroke();
            ctx.beginPath();
            ctx.rect(w*0.28, h*0.4, w*0.12, h*0.08);
            ctx.rect(w*0.46, h*0.4, w*0.12, h*0.08);
            ctx.rect(w*0.64, h*0.4, w*0.12, h*0.08);
            ctx.rect(w*0.32, h*0.54, w*0.36, h*0.08);
            ctx.fill();
        } else if (name === "mouse") {
            ctx.beginPath();
            ctx.rect(w*0.3, h*0.2, w*0.4, h*0.6);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(w*0.5, h*0.2); ctx.lineTo(w*0.5, h*0.42);
            ctx.stroke();
        } else if (name === "phone") {
            ctx.beginPath();
            ctx.rect(w*0.28, h*0.15, w*0.44, h*0.7);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(w*0.5, h*0.75, w*0.04, 0, Math.PI * 2);
            ctx.fill();
        } else if (name === "battery") {
            ctx.beginPath();
            ctx.rect(w*0.15, h*0.3, w*0.65, h*0.4);
            ctx.stroke();
            ctx.beginPath();
            ctx.rect(w*0.82, h*0.4, w*0.08, h*0.2);
            ctx.fill();
            ctx.beginPath();
            ctx.rect(w*0.22, h*0.38, w*0.35, h*0.24);
            ctx.fill();
        } else if (name === "left" || name === "chevron_left" || name === "chevron-left" || name === "arrow_back" || name === "back") {
            ctx.beginPath();
            ctx.moveTo(w*0.62, h*0.25);
            ctx.lineTo(w*0.35, h*0.5);
            ctx.lineTo(w*0.62, h*0.75);
            ctx.stroke();
        } else if (name === "right" || name === "chevron_right" || name === "chevron-right" || name === "arrow_forward" || name === "forward") {
            ctx.beginPath();
            ctx.moveTo(w*0.38, h*0.25);
            ctx.lineTo(w*0.65, h*0.5);
            ctx.lineTo(w*0.38, h*0.75);
            ctx.stroke();
        } else if (name === "search" || name === "find" || name === "magnifier") {
            ctx.beginPath();
            ctx.arc(w * 0.42, h * 0.42, w * 0.24, 0, Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(w * 0.59, h * 0.59);
            ctx.lineTo(w * 0.82, h * 0.82);
            ctx.stroke();
        } else if (name === "pin" || name === "pinned") {
            ctx.beginPath();
            ctx.moveTo(w * 0.35, h * 0.20);
            ctx.lineTo(w * 0.65, h * 0.20);
            ctx.lineTo(w * 0.58, h * 0.45);
            ctx.lineTo(w * 0.70, h * 0.58);
            ctx.lineTo(w * 0.30, h * 0.58);
            ctx.lineTo(w * 0.42, h * 0.45);
            ctx.closePath();
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(w * 0.50, h * 0.58);
            ctx.lineTo(w * 0.50, h * 0.85);
            ctx.stroke();
        } else if (name === "star" || name === "favorite") {
            var cx = w * 0.5;
            var cy = h * 0.5;
            var spikes = 5;
            var outerRadius = w * 0.38;
            var innerRadius = w * 0.18;
            var rot = Math.PI / 2 * 3;
            var step = Math.PI / spikes;

            ctx.beginPath();
            ctx.moveTo(cx, cy - outerRadius);
            for (var s = 0; s < spikes; s++) {
                var x = cx + Math.cos(rot) * outerRadius;
                var y = cy + Math.sin(rot) * outerRadius;
                ctx.lineTo(x, y);
                rot += step;

                x = cx + Math.cos(rot) * innerRadius;
                y = cy + Math.sin(rot) * innerRadius;
                ctx.lineTo(x, y);
                rot += step;
            }
            ctx.lineTo(cx, cy - outerRadius);
            ctx.closePath();
            ctx.stroke();
        } else if (name === "fire" || name === "flame" || name === "trending" || name === "frequent") {
            ctx.beginPath();
            ctx.moveTo(w * 0.50, h * 0.15);
            ctx.quadraticCurveTo(w * 0.75, h * 0.35, w * 0.75, h * 0.60);
            ctx.arc(w * 0.50, h * 0.60, w * 0.25, 0, Math.PI);
            ctx.quadraticCurveTo(w * 0.25, h * 0.35, w * 0.50, h * 0.15);
            ctx.closePath();
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(w * 0.50, h * 0.65, w * 0.10, 0, Math.PI * 2);
            ctx.fill();
        } else if (name === "game" || name === "gamepad") {
            ctx.beginPath();
            ctx.rect(w * 0.18, h * 0.30, w * 0.64, h * 0.40);
            ctx.stroke();
            // D-Pad +
            ctx.beginPath();
            ctx.moveTo(w * 0.35, h * 0.42); ctx.lineTo(w * 0.35, h * 0.58);
            ctx.moveTo(w * 0.27, h * 0.50); ctx.lineTo(w * 0.43, h * 0.50);
            ctx.stroke();
            // Action buttons
            ctx.beginPath();
            ctx.arc(w * 0.65, h * 0.45, w * 0.04, 0, Math.PI * 2);
            ctx.arc(w * 0.73, h * 0.55, w * 0.04, 0, Math.PI * 2);
            ctx.fill();
        } else if (name === "folder" || name === "files") {
            ctx.beginPath();
            ctx.moveTo(w * 0.15, h * 0.30);
            ctx.lineTo(w * 0.40, h * 0.30);
            ctx.lineTo(w * 0.48, h * 0.38);
            ctx.lineTo(w * 0.85, h * 0.38);
            ctx.lineTo(w * 0.85, h * 0.75);
        } else if (name === "bell" || name === "notification" || name === "notifications") {
            // Bell dome & flare outline
            ctx.beginPath();
            ctx.moveTo(w * 0.5, h * 0.18);
            ctx.arcTo(w * 0.78, h * 0.18, w * 0.78, h * 0.65, w * 0.28);
            ctx.lineTo(w * 0.88, h * 0.72);
            ctx.lineTo(w * 0.12, h * 0.72);
            ctx.lineTo(w * 0.22, h * 0.65);
            ctx.arcTo(w * 0.22, h * 0.18, w * 0.5, h * 0.18, w * 0.28);
            ctx.closePath();
            ctx.stroke();

            // Bell clapper arc
            ctx.beginPath();
            ctx.arc(w * 0.5, h * 0.81, w * 0.1, 0, Math.PI);
            ctx.stroke();
        } else if (name === "dots-vertical" || name === "more-vertical" || name === "dots") {
            // 3 Vertical dots
            ctx.beginPath();
            ctx.arc(w * 0.5, h * 0.25, Math.max(1.5, w * 0.08), 0, Math.PI * 2);
            ctx.arc(w * 0.5, h * 0.50, Math.max(1.5, w * 0.08), 0, Math.PI * 2);
            ctx.arc(w * 0.5, h * 0.75, Math.max(1.5, w * 0.08), 0, Math.PI * 2);
            ctx.fill();
        } else if (name === "bell-off" || name === "mute-bell" || name === "silent") {
            // Full Bell outline
            ctx.beginPath();
            ctx.moveTo(w * 0.5, h * 0.18);
            ctx.arcTo(w * 0.78, h * 0.18, w * 0.78, h * 0.65, w * 0.28);
            ctx.lineTo(w * 0.88, h * 0.72);
            ctx.lineTo(w * 0.12, h * 0.72);
            ctx.lineTo(w * 0.22, h * 0.65);
            ctx.arcTo(w * 0.22, h * 0.18, w * 0.5, h * 0.18, w * 0.28);
            ctx.closePath();
            ctx.stroke();

            // Bell clapper arc
            ctx.beginPath();
            ctx.arc(w * 0.5, h * 0.81, w * 0.1, 0, Math.PI);
            ctx.stroke();

            // Diagonal slash
            ctx.beginPath();
            ctx.moveTo(w * 0.12, h * 0.12);
            ctx.lineTo(w * 0.88, h * 0.88);
            ctx.stroke();
        } else if (name === "ban" || name === "block") {
            // Prohibited circle with diagonal slash
            ctx.beginPath();
            ctx.arc(w * 0.5, h * 0.5, w * 0.36, 0, Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(w * 0.25, h * 0.25);
            ctx.lineTo(w * 0.75, h * 0.75);
            ctx.stroke();
        } else if (name === "clipboard" || name === "copy") {
            ctx.beginPath();
            ctx.rect(w * 0.25, h * 0.25, w * 0.5, h * 0.6);
            ctx.stroke();
            ctx.beginPath();
            ctx.rect(w * 0.38, h * 0.15, w * 0.24, h * 0.15);
            ctx.stroke();
        } else if (name === "sun" || name === "brightness" || name === "light") {
            var cx = w * 0.5;
            var cy = h * 0.5;
            ctx.beginPath();
            ctx.arc(cx, cy, w * 0.20, 0, Math.PI * 2);
            ctx.fill();
            for (var i = 0; i < 8; i++) {
                var angle = (i * Math.PI) / 4;
                var x1 = cx + Math.cos(angle) * (w * 0.30);
                var y1 = cy + Math.sin(angle) * (h * 0.30);
                var x2 = cx + Math.cos(angle) * (w * 0.44);
                var y2 = cy + Math.sin(angle) * (h * 0.44);
                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.stroke();
            }
        } else if (name === "moon" || name === "night" || name === "night_light") {
            ctx.beginPath();
            ctx.arc(w * 0.52, h * 0.50, w * 0.32, 0.55 * Math.PI, 1.85 * Math.PI, false);
            ctx.arc(w * 0.40, h * 0.42, w * 0.25, 1.85 * Math.PI, 0.55 * Math.PI, true);
            ctx.closePath();
            ctx.fill();
        } else if (name === "play") {
            ctx.beginPath();
            ctx.moveTo(w * 0.25, h * 0.15);
            ctx.lineTo(w * 0.85, h * 0.5);
            ctx.lineTo(w * 0.25, h * 0.85);
            ctx.closePath();
            ctx.fill();
        } else if (name === "pause") {
            ctx.beginPath();
            ctx.rect(w * 0.22, h * 0.15, w * 0.2, h * 0.7);
            ctx.rect(w * 0.58, h * 0.15, w * 0.2, h * 0.7);
            ctx.fill();
        } else if (name === "play_pause") {
            ctx.beginPath();
            ctx.moveTo(w * 0.15, h * 0.2);
            ctx.lineTo(w * 0.55, h * 0.5);
            ctx.lineTo(w * 0.15, h * 0.8);
            ctx.closePath();
            ctx.fill();
            ctx.beginPath();
            ctx.rect(w * 0.68, h * 0.2, w * 0.16, h * 0.6);
            ctx.fill();
        } else if (name === "prev" || name === "previous" || name === "skip_back") {
            ctx.beginPath();
            ctx.rect(w * 0.12, h * 0.15, w * 0.16, h * 0.7);
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(w * 0.85, h * 0.15);
            ctx.lineTo(w * 0.35, h * 0.5);
            ctx.lineTo(w * 0.85, h * 0.85);
            ctx.closePath();
            ctx.fill();
        } else if (name === "next" || name === "forward_media" || name === "skip_forward") {
            ctx.beginPath();
            ctx.moveTo(w * 0.15, h * 0.15);
            ctx.lineTo(w * 0.65, h * 0.5);
            ctx.lineTo(w * 0.15, h * 0.85);
            ctx.closePath();
            ctx.fill();
            ctx.beginPath();
            ctx.rect(w * 0.72, h * 0.15, w * 0.16, h * 0.7);
            ctx.fill();
        } else if (name === "music" || name === "note" || name === "audio_note") {
            ctx.beginPath();
            ctx.ellipse(w * 0.32, h * 0.72, w * 0.18, h * 0.14, -Math.PI / 6, 0, Math.PI * 2);
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(w * 0.44, h * 0.70);
            ctx.lineTo(w * 0.44, h * 0.18);
            ctx.lineTo(w * 0.78, h * 0.28);
            ctx.stroke();
        } else if (name === "switch_arrows" || name === "cycle" || name === "rotate") {
            ctx.beginPath();
            ctx.moveTo(w * 0.18, h * 0.35);
            ctx.lineTo(w * 0.78, h * 0.35);
            ctx.lineTo(w * 0.62, h * 0.20);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(w * 0.82, h * 0.65);
            ctx.lineTo(w * 0.22, h * 0.65);
            ctx.lineTo(w * 0.38, h * 0.80);
            ctx.stroke();
        } else {
            ctx.beginPath();
            ctx.arc(w/2, h/2, w*0.2, 0, Math.PI * 2);
            ctx.fill();
        }
    }
}
