import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.UPower
import "../../theme"
import "./ModelUtils.js" as ModelUtils

Rectangle {
    id: root

    property real size: 36
    property real customRadius: 8

    implicitWidth: size
    implicitHeight: size
    radius: customRadius

    signal clicked()

    // Server status bindings with UPower fallbacks
    readonly property var serverBat: ConfigService.batteryStatus
    readonly property var effectiveBat: serverBat ? (serverBat.primary || serverBat) : null
    readonly property var batteryDevice: UPower.displayDevice

    readonly property real batteryPercentage: (effectiveBat && effectiveBat.percentage !== undefined)
        ? (effectiveBat.percentage / 100.0) 
        : (batteryDevice?.percentage ?? 1.0)

    readonly property var batteryState: batteryDevice?.state ?? null

    readonly property bool isCharging: (effectiveBat && effectiveBat.is_charging !== undefined)
        ? effectiveBat.is_charging 
        : (batteryState === UPowerDeviceState.Charging)

    readonly property bool isPluggedIn: (effectiveBat && effectiveBat.is_plugged_in !== undefined)
        ? effectiveBat.is_plugged_in 
        : (isCharging || batteryState === UPowerDeviceState.PendingCharge || batteryState === UPowerDeviceState.FullyCharged)

    readonly property bool isLow: batteryPercentage <= 0.2 && !isPluggedIn
    readonly property int percentInt: Math.round(batteryPercentage * 100)

    function formatSeconds(secs) {
        if (!secs || secs <= 0 || secs > 86400 * 2) return "";
        var hrs = Math.floor(secs / 3600);
        var mins = Math.floor((secs % 3600) / 60);
        if (hrs > 0) return hrs + "h " + mins + "m";
        return mins + "m";
    }

    color: mouseArea.containsMouse 
        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) 
        : "transparent"

    border.color: mouseArea.containsMouse 
        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) 
        : "transparent"
    border.width: mouseArea.containsMouse ? 1 : 0

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    Canvas {
        id: batteryCanvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var w = width;
            var h = height;

            var mainColor = root.isLow ? Theme.error : (mouseArea.containsMouse ? Theme.primary : Theme.on_surface_variant);
            ctx.fillStyle = mainColor;
            ctx.strokeStyle = mainColor;

            // 1. Draw Horizontal Battery Body (20x11px)
            var bw = 20;
            var bh = 11;
            var bx = Math.round((w - (bw + 3)) / 2);
            var by = Math.round((h - bh) / 2);
            var br = 2.5;

            ctx.lineWidth = 1.3;
            ModelUtils.drawRRect(ctx, bx + 0.65, by + 0.65, bw - 1.3, bh - 1.3, br);
            ctx.stroke();

            // 2. Draw Positive Terminal Cap on the Right (2x5px)
            var capX = bx + bw + 0.5;
            var capH = 5;
            var capY = by + Math.round((bh - capH) / 2);
            var capW = 2;
            ModelUtils.drawRRect(ctx, capX, capY, capW, capH, 1);
            ctx.fill();

            // 3. Draw Battery Fill Level (Horizontal Left-to-Right)
            var pad = 2;
            var fillMaxW = bw - (pad * 2) - 1;
            var fillMaxH = bh - (pad * 2);
            var fillW = Math.max(1, Math.min(fillMaxW, Math.round(fillMaxW * root.batteryPercentage)));
            var fillX = bx + pad + 0.5;
            var fillY = by + pad;

            if (fillW > 0) {
                var fillR = Math.min(1.5, fillW / 2);
                ModelUtils.drawRRect(ctx, fillX, fillY, fillW, fillMaxH, fillR);
                ctx.fill();
            }

            // 4. Draw Charging Lightning Bolt Overlay (Centered inside battery)
            if (root.isCharging) {
                ctx.fillStyle = Theme.surface_container_highest;
                ctx.strokeStyle = Theme.surface_container_highest;
                ctx.lineWidth = 0.8;

                var cx = bx + Math.round(bw / 2);
                var cy = by + Math.round(bh / 2);

                ctx.beginPath();
                ctx.moveTo(cx + 1, cy - 3.5);
                ctx.lineTo(cx - 2.5, cy + 0.5);
                ctx.lineTo(cx - 0.5, cy + 0.5);
                ctx.lineTo(cx - 1.5, cy + 3.5);
                ctx.lineTo(cx + 2.5, cy - 0.5);
                ctx.lineTo(cx + 0.5, cy - 0.5);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();
            }
        }

        Connections {
            target: root
            function onBatteryPercentageChanged() { batteryCanvas.requestPaint(); }
            function onBatteryStateChanged() { batteryCanvas.requestPaint(); }
            function onServerBatChanged() { batteryCanvas.requestPaint(); }
            function onEffectiveBatChanged() { batteryCanvas.requestPaint(); }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onContainsMouseChanged: batteryCanvas.requestPaint()
        onClicked: root.clicked()

        onEntered: {
            var bat = root.effectiveBat;
            var statusStr = root.isCharging ? "Charging" : (root.isPluggedIn ? "Fully Charged" : "Discharging");
            var etaText = (bat && bat.eta) ? bat.eta : statusStr;

            var label = "Battery: " + root.percentInt + "% (" + etaText + ")";
            var mappedPos = root.mapToItem(null, 0, 0);
            if (typeof simpleTooltip !== "undefined" && simpleTooltip) {
                simpleTooltip.showTooltip(label, mappedPos.y + (root.height / 2));
            }
        }

        onExited: {
            if (typeof simpleTooltip !== "undefined" && simpleTooltip) {
                simpleTooltip.hideTooltip();
            }
        }
    }
}
