import QtQuick
import QtQuick.Layouts
import "../../theme"

Item {
    id: root

    property bool isOpen: false
    property var targetPanel: null
    signal dismissed()

    anchors.fill: parent
    visible: isOpen || opacity > 0
    opacity: isOpen ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // Fullscreen backdrop overlay for click-outside dismissal
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.isOpen = false;
            if (root.targetPanel && root.targetPanel.close) {
                root.targetPanel.close();
            }
            root.dismissed();
        }
    }
}
