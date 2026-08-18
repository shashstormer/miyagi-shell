import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../components"

PanelWindow {
    id: flyoutWindow
    visible: false

    property string title: "Panel"
    property string iconName: "settings"
    property string side: "left" // "left" or "right"
    property int cardWidth: 380
    property int cardHeight: 520
    property bool isOpen: false

    property bool showRefresh: true
    property bool isRefreshing: false
    property bool showSwitch: true
    property bool switchChecked: false
    property bool isSwitchFocused: false
    property var openedFrom: null

    signal refreshClicked()
    signal switchToggled(bool checked)
    signal panelClosed()

    default property alias content: contentContainer.data

    property bool panelEntered: false

    Timer {
        id: flyoutCloseTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (flyoutWindow.isOpen) {
                flyoutWindow.close();
            }
        }
    }

    property bool requiresKeyboardFocus: true

    Timer {
        id: focusGrabTimer
        interval: 60
        repeat: false
        onTriggered: {
            if (flyoutWindow.isOpen && flyoutWindow.requiresKeyboardFocus) {
                keyFocusReceiver.forceActiveFocus();
            }
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
        Keys.onMenuPressed: event => {
            if (!InputService.useKeyboard()) { event.accepted = true; return; }
            InputService.triggerContextMenu();
            event.accepted = true;
        }
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Alt || event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) {
                if (!InputService.useKeyboard()) { event.accepted = true; return; }
                InputService.triggerContextMenu();
                event.accepted = true;
            }
        }
    }

    function open() {
        InputService.closeOtherPanels(flyoutWindow);
        InputService.lockModality(InputService.mode);
        visible = true;
        isOpen = true;
        panelEntered = false;
        flyoutCloseTimer.stop();
        focusGrabTimer.restart();
    }

    function close() {
        flyoutCloseTimer.stop();
        panelEntered = false;
        isOpen = false;
    }

    function toggle() {
        if (isOpen) {
            close();
        } else {
            open();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: flyoutWindow.isOpen
        onActivated: {
            InputService.useKeyboard();
            InputService.triggerBack();
        }
    }

    Shortcut {
        sequence: "Menu"
        enabled: flyoutWindow.isOpen
        onActivated: {
            InputService.useKeyboard();
            InputService.triggerContextMenu();
        }
    }

    Shortcut {
        sequence: "Shift+F10"
        enabled: flyoutWindow.isOpen
        onActivated: {
            InputService.useKeyboard();
            InputService.triggerContextMenu();
        }
    }

    Connections {
        target: InputService
        enabled: flyoutWindow.isOpen

        function onClosePanelsExcept(exceptPanel) {
            if (exceptPanel !== flyoutWindow) {
                flyoutWindow.close();
            }
        }
    }

    WlrLayershell.namespace: "quickshell-flyout-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (flyoutWindow.isOpen && flyoutWindow.requiresKeyboardFocus) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors {
        left: flyoutWindow.side === "left"
        right: flyoutWindow.side === "right"
        top: true
        bottom: true
    }

    margins {
        left: flyoutWindow.side === "left" ? (flyoutWindow.leftBarWidth > 0 ? Math.max(0, flyoutWindow.leftBarWidth - 2) : 0) : 0
        right: flyoutWindow.side === "right" ? 0 : 0
        top: flyoutWindow.topBarHeight > 0 ? Math.max(0, flyoutWindow.topBarHeight - 2) : 0
        bottom: flyoutWindow.bottomBarHeight > 0 ? Math.max(0, flyoutWindow.bottomBarHeight - 2) : -2
    }

    implicitWidth: flyoutWindow.cardWidth

    // Dynamic bar margins so panel is physically attached to LeftBar and TopBar
    readonly property real leftBarWidth: ConfigService.enableLeftBar ? 54 : 0
    readonly property real topBarHeight: (ConfigService.enableTopBar && ConfigService.barPosition !== "bottom") ? 48 : 0
    readonly property real bottomBarHeight: (ConfigService.enableTopBar && ConfigService.barPosition === "bottom") ? 48 : 0

    Rectangle {
        id: mainCard
        anchors.fill: parent

        color: Theme.surface_container_lowest
        border.width: 0

        // Non-blocking HoverHandler tracking mouse exit to trigger 500ms auto-close delay
        HoverHandler {
            id: flyoutHoverHandler
            onHoveredChanged: {
                if (hovered) {
                    flyoutWindow.panelEntered = true;
                    flyoutCloseTimer.stop();
                } else if (flyoutWindow.isOpen && flyoutWindow.panelEntered) {
                    flyoutCloseTimer.restart();
                }
            }
        }

        // Corner filler squares to un-round corners based on side
        Rectangle {
            visible: flyoutWindow.side === "left"
            width: 24
            height: 24
            anchors.top: parent.top
            anchors.left: parent.left
            color: Theme.surface_container_lowest
        }

        Rectangle {
            visible: flyoutWindow.side === "right"
            width: 24
            height: 24
            anchors.top: parent.top
            anchors.right: parent.right
            color: Theme.surface_container_lowest
        }

        Rectangle {
            width: 24
            height: 24
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            color: Theme.surface_container_lowest
        }

        Rectangle {
            width: 24
            height: 24
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            color: Theme.surface_container_lowest
        }

        property real slideY: flyoutWindow.isOpen ? 0 : mainCard.height + 20

        transform: Translate {
            y: mainCard.slideY
        }

        Behavior on slideY {
            NumberAnimation {
                id: slideAnim
                duration: 260
                easing.type: Easing.OutCubic
                onRunningChanged: {
                    if (!running && !flyoutWindow.isOpen) {
                        flyoutWindow.visible = false;
                        flyoutWindow.panelClosed();
                    }
                }
            }
        }

        opacity: flyoutWindow.isOpen ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        // Prevent inner clicks from closing the panel
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // Header Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                VectorIcon {
                    name: flyoutWindow.iconName
                    color: Theme.primary
                    iconSize: 22
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: flyoutWindow.title
                    color: Theme.on_surface
                    font.bold: true
                    font.pixelSize: 16
                    font.family: Theme.fontFamilyDisplay
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                // Refresh Button
                Rectangle {
                    visible: flyoutWindow.showRefresh
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 16
                    Layout.alignment: Qt.AlignVCenter
                    color: scanMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent"

                    VectorIcon {
                        anchors.centerIn: parent
                        name: "refresh"
                        color: flyoutWindow.isRefreshing ? Theme.primary : Theme.on_surface_variant
                        iconSize: 17
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: flyoutWindow.refreshClicked()
                    }
                }

                // Power Switch
                Rectangle {
                    id: headerSwitch
                    visible: flyoutWindow.showSwitch
                    implicitWidth: 38
                    implicitHeight: 22
                    radius: 11
                    Layout.alignment: Qt.AlignVCenter
                    color: flyoutWindow.switchChecked ? Theme.primary : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.4)
                    border.color: flyoutWindow.isSwitchFocused ? Theme.primary : "transparent"
                    border.width: flyoutWindow.isSwitchFocused ? 2 : 0
                    scale: flyoutWindow.isSwitchFocused ? 1.15 : 1.0

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Rectangle {
                        x: flyoutWindow.switchChecked ? (headerSwitch.width - width - (flyoutWindow.isSwitchFocused ? 5 : 3)) : (flyoutWindow.isSwitchFocused ? 5 : 3)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 8
                        color: flyoutWindow.switchChecked ? Theme.on_primary : Theme.outline

                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: flyoutWindow.switchToggled(!flyoutWindow.switchChecked)
                    }
                }

                // Close Button
                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    Layout.alignment: Qt.AlignVCenter
                    color: closeMouse.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15) : "transparent"

                    VectorIcon {
                        anchors.centerIn: parent
                        name: "close"
                        color: closeMouse.containsMouse ? Theme.error : Theme.on_surface_variant
                        iconSize: 15
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: flyoutWindow.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.25)
            }

            // Body Content Container
            Item {
                id: contentContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}

