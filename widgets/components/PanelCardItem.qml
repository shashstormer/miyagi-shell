import QtQuick
import QtQuick.Layouts
import "../../theme"

Rectangle {
    id: root

    property bool isSelected: false
    property bool isHovered: mouseArea.containsMouse && InputService.isMouse
    property bool isCurrent: false
    property bool showActiveIndicator: true
    property int cardRadius: 10
    property int itemHeight: 52

    // Tri-Modal Input Highlighting: Keyboard & Gamepad use selection/current; Mouse uses active hover
    readonly property bool isHighlighted: (InputService.isMouse && isHovered) || (InputService.isNonMouse && (isSelected || isCurrent))

    property color selectedBorderColor: Theme.primary
    property color defaultBorderColor: (InputService.isMouse && isHovered) ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : Theme.outline_variant
    property color selectedBgColor: Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 0.5)
    property color defaultBgColor: (InputService.isMouse && isHovered) ? Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.7) : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.4)

    signal clicked()
    signal doubleClicked()
    signal rightClicked()
    signal rightClickedWithPos(real mouseX, real mouseY)
    signal itemHovered()

    Layout.fillWidth: true
    implicitHeight: itemHeight
    radius: cardRadius
    clip: true

    color: isHighlighted ? selectedBgColor : defaultBgColor
    border.color: isHighlighted ? selectedBorderColor : defaultBorderColor
    border.width: isHighlighted ? 1.5 : 1.0

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }
    Behavior on border.width { NumberAnimation { duration: 150 } }

    // Left Active Indicator Accent Bar
    Rectangle {
        visible: root.showActiveIndicator && root.isHighlighted
        width: 3
        height: root.height - 18
        radius: 2
        color: Theme.primary
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property real lastMoveX: -1
        property real lastMoveY: -1

        onPositionChanged: mouse => {
            if (lastMoveX >= 0 && lastMoveY >= 0) {
                var dx = Math.abs(mouse.x - lastMoveX);
                var dy = Math.abs(mouse.y - lastMoveY);
                if (dx > 2 || dy > 2) {
                    if (InputService.useMouse()) {
                        root.itemHovered();
                    }
                }
            }
            lastMoveX = mouse.x;
            lastMoveY = mouse.y;
        }

        onExited: {
            lastMoveX = -1;
            lastMoveY = -1;
        }

        onClicked: mouse => {
            if (!InputService.useMouse()) return;
            if (mouse.button === Qt.RightButton) {
                root.rightClicked();
                root.rightClickedWithPos(mouse.x, mouse.y);
            } else {
                root.clicked();
            }
        }

        onDoubleClicked: mouse => {
            if (!InputService.useMouse()) return;
            if (mouse.button === Qt.LeftButton) {
                root.doubleClicked();
            }
        }
    }
}
