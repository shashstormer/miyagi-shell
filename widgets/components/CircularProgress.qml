import QtQuick
import "../../theme"

Canvas {
    id: progressCanvas

    property real value: 0      // 0 to 100
    property color color: Theme.primary
    property alias progressColor: progressCanvas.color
    property color trackColor: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.25)
    property real ringWidth: 2.2
    property alias lineWidth: progressCanvas.ringWidth
    property real size: 16

    implicitWidth: size
    implicitHeight: size

    onValueChanged: requestPaint()
    onColorChanged: requestPaint()
    onTrackColorChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();

        var w = width;
        var h = height;
        var cx = w / 2;
        var cy = h / 2;
        var radius = Math.min(w, h) / 2 - ringWidth;

        // Draw track ring
        ctx.beginPath();
        ctx.arc(cx, cy, radius, 0, Math.PI * 2);
        ctx.strokeStyle = trackColor;
        ctx.lineWidth = ringWidth;
        ctx.stroke();

        // Draw progress arc (anti-clockwise starting from top center)
        var pct = Math.max(0, Math.min(100, value)) / 100;
        if (pct > 0) {
            var startAngle = -Math.PI / 2;
            var endAngle = startAngle - pct * (Math.PI * 2);
            ctx.beginPath();
            ctx.arc(cx, cy, radius, startAngle, endAngle, true);
            ctx.strokeStyle = progressCanvas.color;
            ctx.lineWidth = ringWidth;
            ctx.lineCap = "round";
            ctx.stroke();
        }
    }
}
