import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../theme"
import "../components"

PanelWindow {
    id: altTabWindow

    property bool isOpen: false
    property int selectedIndex: 0

    visible: isOpen
    color: "transparent"

    WlrLayershell.namespace: "quickshell-alttab-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Auto-confirm selection timer after inactivity
    property Timer dismissTimer: Timer {
        interval: 600
        repeat: false
        onTriggered: altTabWindow.confirmSelection()
    }

    // Shortcut for ESC key to cancel Alt-Tab switcher
    Shortcut {
        sequence: "Escape"
        enabled: altTabWindow.isOpen
        onActivated: altTabWindow.cancelSelection()
    }

    Connections {
        target: InputService
        enabled: altTabWindow.isOpen

        function onNavLeft() {
            InputService.useKeyboard();
            altTabWindow.previousWindow();
        }
        function onNavRight() {
            InputService.useKeyboard();
            altTabWindow.nextWindow();
        }
        function onNavSelect() {
            altTabWindow.confirmSelection();
        }
        function onNavBack() {
            altTabWindow.cancelSelection();
        }
    }

    // Workspace Windows List (Both Open & Minimized) via ConfigService
    readonly property var workspaceWindows: ConfigService.getWorkspaceWindows()

    onWorkspaceWindowsChanged: {
        if (!workspaceWindows || workspaceWindows.length === 0) {
            selectedIndex = 0;
        } else if (selectedIndex >= workspaceWindows.length) {
            selectedIndex = Math.max(0, workspaceWindows.length - 1);
        }
    }

    function openAndNext() {
        ConfigService.fetchWindows();
        var wins = workspaceWindows;
        if (!wins || wins.length === 0) return;

        if (!isOpen) {
            InputService.closeOtherPanels(altTabWindow);
            isOpen = true;
            var activeIdx = -1;
            for (var i = 0; i < wins.length; i++) {
                if (wins[i].is_active && !wins[i].is_minimized) {
                    activeIdx = i;
                    break;
                }
            }
            selectedIndex = (activeIdx + 1) % wins.length;
        } else {
            selectedIndex = (selectedIndex + 1) % wins.length;
        }
        Qt.callLater(scrollActiveIntoView);
        dismissTimer.restart();
    }

    function openAndPrev() {
        ConfigService.fetchWindows();
        var wins = workspaceWindows;
        if (!wins || wins.length === 0) return;

        if (!isOpen) {
            InputService.closeOtherPanels(altTabWindow);
            isOpen = true;
            var activeIdx = -1;
            for (var i = 0; i < wins.length; i++) {
                if (wins[i].is_active && !wins[i].is_minimized) {
                    activeIdx = i;
                    break;
                }
            }
            selectedIndex = (activeIdx - 1 + wins.length) % wins.length;
        } else {
            selectedIndex = (selectedIndex - 1 + wins.length) % wins.length;
        }
        Qt.callLater(scrollActiveIntoView);
        dismissTimer.restart();
    }

    function scrollActiveIntoView() {
        if (!cardsFlickable || cardsFlickable.width <= 0) return;
        var maxScroll = cardsFlickable.contentWidth - cardsFlickable.width;
        if (maxScroll <= 0) {
            scrollAnimation.stop();
            cardsFlickable.contentX = 0;
            return;
        }
        var cardW = 240 + 16; // width + spacing
        var targetX = selectedIndex * cardW - (cardsFlickable.width / 2) + (240 / 2);
        targetX = Math.max(0, Math.min(targetX, maxScroll));
        scrollAnimation.to = targetX;
        scrollAnimation.restart();
    }

    onIsOpenChanged: {
        if (isOpen) {
            Qt.callLater(scrollActiveIntoView);
        } else if (cardsFlickable) {
            cardsFlickable.contentX = 0;
        }
    }

    function confirmSelection() {
        dismissTimer.stop();
        if (!isOpen) return;
        var wins = workspaceWindows;
        if (wins && wins.length > 0 && selectedIndex >= 0 && selectedIndex < wins.length) {
            var target = wins[selectedIndex];
            if (target) {
                if (target.is_minimized) {
                    ConfigService.toggleMinimize(target.address);
                } else if (target.address) {
                    ConfigService.executeAction("focus_address_" + target.address);
                }
            }
        }
        isOpen = false;
    }

    function cancelSelection() {
        dismissTimer.stop();
        isOpen = false;
    }

    // Smooth Scroll Animation for Cards Flickable
    NumberAnimation {
        id: scrollAnimation
        target: cardsFlickable
        property: "contentX"
        duration: 220
        easing.type: Easing.OutCubic
    }

    // Modal Dark Backdrop Overlay
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        opacity: altTabWindow.isOpen ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: altTabWindow.confirmSelection()
        }

        // Center HUD Switcher Window Frame
        Rectangle {
            id: hudContainer
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, Math.max(420, cardRow.implicitWidth + 48))
            height: 310
            radius: 22
            scale: altTabWindow.isOpen ? 1.0 : 0.94
            opacity: altTabWindow.isOpen ? 1.0 : 0.0

            color: Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.92)
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
            border.width: 1.5

            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                // Skewed Header Banner Matching Miyagi Aesthetic
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Skewed Workspace Banner Title
                    Rectangle {
                        implicitWidth: wsTitleRow.implicitWidth + 24
                        implicitHeight: 30
                        radius: 8
                        color: Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 0.75)
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.5)
                        border.width: 1

                        RowLayout {
                            id: wsTitleRow
                            anchors.centerIn: parent
                            spacing: 8

                            VectorIcon {
                                name: "layers"
                                color: Theme.primary
                                iconSize: 16
                            }

                            Text {
                                text: "WORKSPACE " + (ConfigService.activeWorkspaceId < 10 ? "0" : "") + ConfigService.activeWorkspaceId
                                color: Theme.primary
                                font.pixelSize: 11
                                font.bold: true
                                font.family: Theme.fontFamilyDisplay
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Counter Pill Tag
                    Rectangle {
                        implicitWidth: countText.implicitWidth + 20
                        implicitHeight: 26
                        radius: 13
                        color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.85)
                        border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.3)
                        border.width: 1

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: altTabWindow.workspaceWindows ? ((altTabWindow.selectedIndex + 1 < 10 ? "0" : "") + (altTabWindow.selectedIndex + 1) + " / " + (altTabWindow.workspaceWindows.length < 10 ? "0" : "") + altTabWindow.workspaceWindows.length) : "00 / 00"
                            color: Theme.on_surface_variant
                            font.pixelSize: 11
                            font.bold: true
                            font.family: Theme.fontFamilyMono
                        }
                    }
                }

                // Cards Scrollable Horizontal Carousel
                Flickable {
                    id: cardsFlickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: cardRow.implicitWidth
                    contentHeight: cardsFlickable.height
                    clip: true

                    onWidthChanged: Qt.callLater(altTabWindow.scrollActiveIntoView)

                    Row {
                        id: cardRow
                        spacing: 16
                        x: cardsFlickable.contentWidth < cardsFlickable.width 
                           ? Math.max(0, Math.round((cardsFlickable.width - implicitWidth) / 2)) 
                           : 0
                        y: Math.max(0, Math.round((cardsFlickable.height - implicitHeight) / 2))

                        Repeater {
                            model: altTabWindow.workspaceWindows

                            delegate: Rectangle {
                                id: cardItem
                                required property var modelData
                                required property int index

                                readonly property bool isSelected: index === altTabWindow.selectedIndex
                                readonly property string appClass: modelData.class_name ? modelData.class_name : (modelData.class ? modelData.class : "")
                                readonly property bool isMin: !!modelData.is_minimized
                                readonly property bool isActiveWin: !isMin && !!modelData.is_active

                                // Screencopy Toplevel Lookup
                                readonly property var targetToplevel: ConfigService.getToplevelForWin(modelData)

                                width: 240
                                height: 168
                                radius: 16
                                scale: isSelected ? 1.04 : 0.98
                                opacity: isSelected ? 1.0 : 0.75

                                color: isSelected 
                                    ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 0.40)
                                    : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.55)

                                border.color: isSelected 
                                    ? Theme.primary 
                                    : (isMin ? Qt.rgba(Theme.tertiary.r, Theme.tertiary.g, Theme.tertiary.b, 0.4) : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.3))
                                border.width: isSelected ? 2.0 : 1.0

                                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 160 } }
                                Behavior on border.color { ColorAnimation { duration: 160 } }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    // Card Title & Icon Header
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        AppIcon {
                                            icon: modelData.icon || ""
                                            appClass: appClass
                                            appTitle: modelData.title || modelData.initialTitle || ""
                                            iconSize: 20
                                            isCurrent: isSelected
                                        }

                                        Text {
                                            text: modelData.title || appClass || "Window"
                                            color: isSelected ? Theme.primary : Theme.on_surface
                                            font.pixelSize: 12
                                            font.bold: true
                                            font.family: Theme.fontFamilyDisplay
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        // Status Pill Tag (MINIMIZED or FOCUSED)
                                        PillBadge {
                                            visible: isMin || isActiveWin
                                            text: isMin ? "MINIMIZED" : "FOCUSED"
                                            pillHeight: 20
                                            fontSize: 9
                                            horizontalPadding: 7
                                            isSelected: true
                                            selectedColor: isMin 
                                                ? Qt.rgba(Theme.tertiary_container.r, Theme.tertiary_container.g, Theme.tertiary_container.b, 0.8)
                                                : Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 0.8)
                                            selectedTextColor: isMin ? Theme.tertiary : Theme.primary
                                            selectedBorderColor: isMin ? Theme.tertiary : Theme.primary
                                            isInteractive: false
                                        }
                                    }

                                    // Thumbnail Screencopy Preview Frame
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 10
                                        color: Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.90)
                                        border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.25)
                                        border.width: 1
                                        clip: true

                                        ScreencopyView {
                                            id: previewView
                                            anchors.fill: parent
                                            captureSource: cardItem.targetToplevel
                                            live: true
                                        }

                                        // Fallback View if no live frame available
                                        Item {
                                            anchors.centerIn: parent
                                            visible: !previewView.hasFrame || !cardItem.targetToplevel
                                            width: 32
                                            height: 32

                                            VectorIcon {
                                                anchors.centerIn: parent
                                                name: "grid"
                                                color: isSelected ? Theme.primary : Theme.on_surface_variant
                                                iconSize: 32
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: {
                                        InputService.useMouse();
                                        altTabWindow.selectedIndex = index;
                                    }
                                    onClicked: {
                                        InputService.useMouse();
                                        altTabWindow.selectedIndex = index;
                                        altTabWindow.confirmSelection();
                                    }
                                }
                            }
                        }
                    }
                }

                // Footer Keyboard Navigation Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Item { Layout.fillWidth: true }

                    Row {
                        spacing: 6
                        Rectangle {
                            implicitWidth: k1.implicitWidth + 12
                            implicitHeight: 20
                            radius: 6
                            color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.9)
                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.35)
                            border.width: 1
                            Text { id: k1; anchors.centerIn: parent; text: "ALT + TAB"; color: Theme.primary; font.pixelSize: 9; font.bold: true; font.family: Theme.fontFamilyMono }
                        }
                        Text { text: "Next"; color: Theme.on_surface_variant; font.pixelSize: 10; font.family: Theme.fontFamilySans; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 6
                        Rectangle {
                            implicitWidth: k2.implicitWidth + 12
                            implicitHeight: 20
                            radius: 6
                            color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.9)
                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.35)
                            border.width: 1
                            Text { id: k2; anchors.centerIn: parent; text: "SHIFT + TAB"; color: Theme.secondary; font.pixelSize: 9; font.bold: true; font.family: Theme.fontFamilyMono }
                        }
                        Text { text: "Prev"; color: Theme.on_surface_variant; font.pixelSize: 10; font.family: Theme.fontFamilySans; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 6
                        Rectangle {
                            implicitWidth: k3.implicitWidth + 12
                            implicitHeight: 20
                            radius: 6
                            color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.9)
                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.35)
                            border.width: 1
                            Text { id: k3; anchors.centerIn: parent; text: "ESC"; color: Theme.error; font.pixelSize: 9; font.bold: true; font.family: Theme.fontFamilyMono }
                        }
                        Text { text: "Cancel"; color: Theme.on_surface_variant; font.pixelSize: 10; font.family: Theme.fontFamilySans; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
