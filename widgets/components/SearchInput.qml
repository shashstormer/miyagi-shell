import QtQuick
import QtQuick.Layouts
import "../../theme"

Rectangle {
    id: root

    property string text: ""
    property string placeholder: "Search..."
    property int debounceMs: 40
    property bool autofocus: false
    property bool isSearching: text.length > 0

    signal textEdited(string query)
    signal returnPressed()
    signal downPressed()
    signal upPressed()
    signal leftPressed()
    signal rightPressed()
    signal escapePressed()

    implicitHeight: 38
    radius: 10
    color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.6)
    border.color: inputField.activeFocus ? Theme.primary : Theme.outline_variant
    border.width: inputField.activeFocus ? 1.5 : 1.0

    onActiveFocusChanged: {
        if (activeFocus) {
            inputField.forceActiveFocus();
        }
    }

    Behavior on border.color { ColorAnimation { duration: 150 } }
    Behavior on border.width { NumberAnimation { duration: 150 } }

    Timer {
        id: debounceTimer
        interval: root.debounceMs
        repeat: false
        onTriggered: {
            root.textEdited(root.text);
        }
    }

    function forceFocus() {
        inputField.forceActiveFocus();
        inputField.selectAll();
    }

    function clear() {
        inputField.text = "";
        root.text = "";
        root.textEdited("");
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 8

        VectorIcon {
            name: "search"
            iconSize: 17
            color: inputField.activeFocus ? Theme.primary : Theme.on_surface_variant
            Layout.alignment: Qt.AlignVCenter
        }

        TextInput {
            id: inputField
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            color: Theme.on_surface
            font.pixelSize: 13
            font.family: Theme.fontFamilyDisplay
            selectByMouse: true
            clip: true

            text: root.text

            Text {
                anchors.fill: parent
                text: root.placeholder
                color: Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.5)
                font.pixelSize: 13
                font.family: Theme.fontFamilyDisplay
                visible: inputField.text === "" && !inputField.activeFocus
            }

            onTextChanged: {
                if (root.text !== text) {
                    InputService.useKeyboard();
                    root.text = text;
                    debounceTimer.restart();
                }
            }

            Keys.onReturnPressed: {
                if (!InputService.useKeyboard()) return;
                root.returnPressed();
            }
            Keys.onDownPressed: {
                if (!InputService.useKeyboard()) return;
                root.downPressed();
            }
            Keys.onUpPressed: {
                if (!InputService.useKeyboard()) return;
                root.upPressed();
            }
            Keys.onLeftPressed: {
                if (!InputService.useKeyboard()) return;
                root.leftPressed();
            }
            Keys.onRightPressed: {
                if (!InputService.useKeyboard()) return;
                root.rightPressed();
            }
            Keys.onEscapePressed: {
                if (!InputService.useKeyboard()) return;
                root.escapePressed();
            }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Alt || event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) {
                    if (!InputService.useKeyboard()) { event.accepted = true; return; }
                    InputService.triggerContextMenu();
                    event.accepted = true;
                }
            }
        }

        // Clear button
        Rectangle {
            visible: inputField.text.length > 0
            implicitWidth: 20
            implicitHeight: 20
            radius: 10
            color: clearMouse.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.15) : "transparent"
            Layout.alignment: Qt.AlignVCenter

            VectorIcon {
                anchors.centerIn: parent
                name: "close"
                iconSize: 12
                color: Theme.on_surface_variant
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    InputService.useMouse();
                    root.clear();
                    inputField.forceActiveFocus();
                }
            }
        }
    }
}
