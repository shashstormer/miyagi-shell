import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../theme"

PanelWindow {
    id: dialogWindow
    visible: false

    property string title: "Settings"
    property int dialogWidth: 860
    property int dialogHeight: 560
    property bool isOpen: false
    property bool showCloseButton: true
    property bool showFooter: true
    property string saveButtonText: "SAVE & SYNC"
    property bool isSaveFocused: false
    property bool requiresKeyboardFocus: true
    property var openedFrom: null

    default property alias content: contentSlot.data

    signal panelClosed()
    signal saved()

    WlrLayershell.namespace: "quickshell-dialog-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (dialogWindow.isOpen && dialogWindow.requiresKeyboardFocus) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Timer {
        id: focusGrabTimer
        interval: 60
        repeat: false
        onTriggered: {
            if (dialogWindow.isOpen && dialogWindow.requiresKeyboardFocus) {
                keyFocusReceiver.forceActiveFocus();
            }
        }
    }

    Timer {
        id: closeDelayTimer
        interval: 230
        repeat: false
        onTriggered: {
            if (!dialogWindow.isOpen) {
                dialogWindow.visible = false;
            }
        }
    }

    function open() {
        InputService.closeOtherPanels(dialogWindow);
        InputService.lockModality(InputService.mode);
        visible = true;
        isOpen = true;
        focusGrabTimer.restart();
    }

    function close() {
        isOpen = false;
        dialogWindow.panelClosed();
    }

    function toggle() {
        if (isOpen) close();
        else open();
    }

    onIsOpenChanged: {
        if (isOpen) {
            visible = true;
            focusGrabTimer.restart();
        } else {
            closeDelayTimer.restart();
        }
    }

    Connections {
        target: InputService
        enabled: dialogWindow.isOpen

        function onClosePanelsExcept(exceptPanel) {
            if (exceptPanel !== dialogWindow) {
                dialogWindow.close();
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: dialogWindow.isOpen
        onActivated: {
            InputService.useKeyboard();
            InputService.triggerBack();
        }
    }

    Item {
        id: keyFocusReceiver
        anchors.fill: parent
        focus: true

        Keys.onUpPressed: event => {
            if (!InputService.useKeyboard()) { event.accepted = true; return; }
            InputService.triggerUp();
            event.accepted = true;
        }
        Keys.onDownPressed: event => {
            if (!InputService.useKeyboard()) { event.accepted = true; return; }
            InputService.triggerDown();
            event.accepted = true;
        }
        Keys.onLeftPressed: event => {
            if (!InputService.useKeyboard()) { event.accepted = true; return; }
            InputService.triggerLeft();
            event.accepted = true;
        }
        Keys.onRightPressed: event => {
            if (!InputService.useKeyboard()) { event.accepted = true; return; }
            InputService.triggerRight();
            event.accepted = true;
        }
        Keys.onReturnPressed: event => {
            if (!InputService.useKeyboard()) { event.accepted = true; return; }
            InputService.triggerSelect();
            event.accepted = true;
        }
        Keys.onEnterPressed: event => {
            if (!InputService.useKeyboard()) { event.accepted = true; return; }
            InputService.triggerSelect();
            event.accepted = true;
        }
        Keys.onSpacePressed: event => {
            if (!InputService.useKeyboard()) { event.accepted = true; return; }
            InputService.triggerSelect();
            event.accepted = true;
        }
        Keys.onEscapePressed: event => {
            if (!InputService.useKeyboard()) { event.accepted = true; return; }
            InputService.triggerBack();
            event.accepted = true;
        }
        Keys.onTabPressed: event => {
            if (!InputService.useKeyboard()) { event.accepted = true; return; }
            if (event.modifiers & Qt.ShiftModifier) {
                InputService.triggerPrevTab();
            } else {
                InputService.triggerNextTab();
            }
            event.accepted = true;
        }
        Keys.onBacktabPressed: event => {
            if (!InputService.useKeyboard()) { event.accepted = true; return; }
            InputService.triggerPrevTab();
            event.accepted = true;
        }
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (!InputService.useKeyboard()) { event.accepted = true; return; }
                InputService.triggerBack();
                event.accepted = true;
            }
        }
    }

    // 1. Scrim Backdrop Overlay
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.scrim.r, Theme.scrim.g, Theme.scrim.b, 0.65)
        opacity: dialogWindow.isOpen ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: dialogWindow.close()
        }
    }

    // 2. Main Dialog Card Container
    Rectangle {
        id: dialogCard
        width: dialogWindow.dialogWidth
        height: dialogWindow.dialogHeight
        anchors.centerIn: parent
        clip: true

        color: Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.98)
        radius: 20
        border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.35)
        border.width: 1

        opacity: dialogWindow.isOpen ? 1.0 : 0.0
        scale: dialogWindow.isOpen ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: { /* Prevent click through to backdrop */ }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header Bar
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20

                    Item { Layout.fillWidth: true }

                    Text {
                        text: dialogWindow.title
                        color: Theme.on_surface
                        font.pixelSize: 17
                        font.bold: true
                        font.family: Theme.fontFamilyDisplay
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item { Layout.fillWidth: true }

                    // Top Right Close Button
                    Rectangle {
                        visible: dialogWindow.showCloseButton
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 14
                        color: closeBtnMouse.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.25) : "transparent"
                        border.color: closeBtnMouse.containsMouse ? Theme.error : Theme.outline_variant
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeBtnMouse.containsMouse ? Theme.error : Theme.on_surface_variant
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            id: closeBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dialogWindow.close()
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.25)
                }
            }

            // Content Area Slot
            Item {
                id: contentSlot
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Footer Bar
            Rectangle {
                visible: dialogWindow.showFooter
                Layout.fillWidth: true
                implicitHeight: 56
                color: "transparent"

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 1
                    color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.25)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: 160
                        implicitHeight: 36
                        radius: 18
                        color: (dialogWindow.isSaveFocused && InputService.isNonMouse)
                            ? Theme.primary_fixed
                            : (saveBtnMouse.containsMouse ? Theme.primary_fixed : Theme.primary)

                        border.color: (dialogWindow.isSaveFocused && InputService.isNonMouse) ? Theme.on_primary_fixed : "transparent"
                        border.width: (dialogWindow.isSaveFocused && InputService.isNonMouse) ? 2 : 0

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            VectorIcon {
                                name: "save"
                                color: Theme.on_primary_fixed
                                iconSize: 14
                            }

                            Text {
                                text: dialogWindow.saveButtonText
                                color: Theme.on_primary_fixed
                                font.pixelSize: 12
                                font.bold: true
                                font.family: Theme.fontFamilyDisplay
                            }
                        }

                        MouseArea {
                            id: saveBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dialogWindow.saved()
                        }
                    }
                }
            }
        }
    }
}
