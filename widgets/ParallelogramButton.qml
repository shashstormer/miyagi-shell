import QtQuick
import QtQuick.Controls
import "../theme"

Item {
    id: root

    property string indexText: "01"
    property string titleText: "FILES"
    property string iconType: "folder" // folder, terminal, settings, launcher, steam
    property color bannerColor: Theme.primary
    property color darkColor: Theme.background
    property color accentCyan: Theme.secondary
    
    signal clicked()

    implicitWidth: 380
    implicitHeight: 52

    property bool hovered: mouseArea.containsMouse
    property bool pressed: mouseArea.pressed

    // Hover animation translation
    Item {
        id: container
        anchors.fill: parent
        
        x: root.hovered ? 14 : 0
        Behavior on x {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Canvas {
            id: canvas
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();

                var w = width;
                var h = height;
                var skew = 18; // Horizontal offset for skewing

                // Main Banner Parallelogram path
                ctx.beginPath();
                ctx.moveTo(skew, 0);
                ctx.lineTo(w, 0);
                ctx.lineTo(w - skew, h);
                ctx.lineTo(0, h);
                ctx.closePath();

                // Fill main banner color
                ctx.fillStyle = root.hovered ? Theme.primary_fixed : root.bannerColor;
                ctx.fill();

                // If hovered, draw glowing outer stroke
                if (root.hovered) {
                    ctx.lineWidth = 2;
                    ctx.strokeStyle = root.accentCyan;
                    ctx.stroke();
                }

                // Left Dark Index Cutout Section
                var indexWidth = 62;
                ctx.beginPath();
                ctx.moveTo(skew, 0);
                ctx.lineTo(skew + indexWidth, 0);
                ctx.lineTo(indexWidth, h);
                ctx.lineTo(0, h);
                ctx.closePath();

                ctx.fillStyle = root.darkColor;
                ctx.fill();

                // Right Icon Container Box
                var iconBoxW = 38;
                var iconBoxH = 36;
                var iconRightOffset = 18;
                var iconX = w - iconRightOffset - iconBoxW - (skew * 0.4);
                var iconY = (h - iconBoxH) / 2;

                ctx.beginPath();
                ctx.rect(iconX, iconY, iconBoxW, iconBoxH);
                ctx.fillStyle = root.darkColor;
                ctx.fill();

                if (root.hovered) {
                    ctx.lineWidth = 1;
                    ctx.strokeStyle = root.accentCyan;
                    ctx.stroke();
                }

                // Draw Vector Icons inside right box
                ctx.fillStyle = root.hovered ? root.accentCyan : root.bannerColor;
                ctx.strokeStyle = root.hovered ? root.accentCyan : root.bannerColor;
                ctx.lineWidth = 2.5;

                var cx = iconX + iconBoxW / 2;
                var cy = iconY + iconBoxH / 2;

                if (root.iconType === "folder") {
                    var fw = 18, fh = 14;
                    var fx = cx - fw / 2;
                    var fy = cy - fh / 2 + 1;
                    ctx.beginPath();
                    ctx.rect(fx, fy, fw, fh);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.moveTo(fx, fy);
                    ctx.lineTo(fx + 6, fy - 4);
                    ctx.lineTo(fx + 10, fy - 4);
                    ctx.lineTo(fx + 12, fy);
                    ctx.stroke();
                } else if (root.iconType === "terminal") {
                    ctx.beginPath();
                    ctx.moveTo(cx - 7, cy - 6);
                    ctx.lineTo(cx - 1, cy);
                    ctx.lineTo(cx - 7, cy + 6);
                    ctx.stroke();

                    ctx.beginPath();
                    ctx.moveTo(cx + 1, cy + 6);
                    ctx.lineTo(cx + 7, cy + 6);
                    ctx.stroke();
                } else if (root.iconType === "settings") {
                    ctx.beginPath();
                    ctx.arc(cx, cy, 6, 0, Math.PI * 2);
                    ctx.stroke();
                    for (var a = 0; a < 6; a++) {
                        var angle = (a * Math.PI / 3);
                        var x1 = cx + Math.cos(angle) * 7;
                        var y1 = cy + Math.sin(angle) * 7;
                        var x2 = cx + Math.cos(angle) * 10;
                        var y2 = cy + Math.sin(angle) * 10;
                        ctx.beginPath();
                        ctx.moveTo(x1, y1);
                        ctx.lineTo(x2, y2);
                        ctx.stroke();
                    }
                } else if (root.iconType === "launcher") {
                    var sq = 6;
                    var gap = 3;
                    ctx.fillRect(cx - sq - gap/2, cy - sq - gap/2, sq, sq);
                    ctx.fillRect(cx + gap/2, cy - sq - gap/2, sq, sq);
                    ctx.fillRect(cx - sq - gap/2, cy + gap/2, sq, sq);
                    ctx.fillRect(cx + gap/2, cy + gap/2, sq, sq);
                } else if (root.iconType === "steam") {
                    ctx.beginPath();
                    ctx.arc(cx - 3, cy + 2, 4, 0, Math.PI * 2);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.arc(cx + 4, cy - 3, 3, 0, Math.PI * 2);
                    ctx.fill();
                    ctx.beginPath();
                    ctx.moveTo(cx - 3, cy + 2);
                    ctx.lineTo(cx + 4, cy - 3);
                    ctx.stroke();
                }
            }

            Connections {
                target: root
                function onHoveredChanged() { canvas.requestPaint(); }
                function onBannerColorChanged() { canvas.requestPaint(); }
                function onDarkColorChanged() { canvas.requestPaint(); }
                function onAccentCyanChanged() { canvas.requestPaint(); }
            }

            Connections {
                target: Theme
                function onPrimaryChanged() { canvas.requestPaint(); }
                function onSecondaryChanged() { canvas.requestPaint(); }
                function onBackgroundChanged() { canvas.requestPaint(); }
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: root.indexText
            color: root.hovered ? root.accentCyan : root.bannerColor
            font.pixelSize: 20
            font.bold: true
            font.italic: true
            font.family: Theme.fontFamilyMono
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 92
            anchors.verticalCenter: parent.verticalCenter
            text: root.titleText
            color: root.darkColor
            font.pixelSize: 24
            font.bold: true
            font.family: Theme.fontFamilyDisplay
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
