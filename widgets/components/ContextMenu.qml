import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

Item {
    id: root

    property bool isOpen: false
    property var menuItems: [] // Array of { text: string, icon: string, iconColor: color, destructive: bool, action: function(data) }
    property var targetData: null
    property string menuTitle: ""
    property string menuSubtitle: ""
    property int selectedIndex: 0
    property bool useFixedPosition: false
    property real popupX: 0
    property real popupY: 0

    signal closed()
    signal actionTriggered(int index, var item, var data)

    anchors.fill: parent
    visible: isOpen || menuContainer.opacity > 0
    z: 999

    function openForTarget(items, data, title, subtitle) {
        menuItems = items || [];
        targetData = data || null;
        menuTitle = title || "";
        menuSubtitle = subtitle || "";
        selectedIndex = 0;
        useFixedPosition = false;
        isOpen = true;
        InputService.useKeyboard();
    }

    function openAt(x, y, items, data, title, subtitle) {
        menuItems = items || [];
        targetData = data || null;
        menuTitle = title || "";
        menuSubtitle = subtitle || "";
        selectedIndex = 0;
        useFixedPosition = true;

        var availableW = root.width > 0 ? root.width : (parent ? parent.width : 460);
        var availableH = root.height > 0 ? root.height : (parent ? parent.height : 600);
        var menuW = 250;
        var estH = (items ? items.length : 2) * 42 + (title ? 50 : 0) + 24;

        popupX = Math.max(12, Math.min(x, availableW - menuW - 12));
        popupY = Math.max(12, Math.min(y, availableH - estH - 12));

        isOpen = true;
        InputService.useMouse();
    }

    function close() {
        if (isOpen) {
            isOpen = false;
            root.closed();
        }
    }

    function navigate(delta) {
        if (!isOpen || menuItems.length === 0) return;
        InputService.useKeyboard();
        var count = menuItems.length;
        selectedIndex = (selectedIndex + (delta % count) + count) % count;
    }

    function selectCurrent() {
        if (!isOpen || menuItems.length === 0) return;
        if (selectedIndex >= 0 && selectedIndex < menuItems.length) {
            var item = menuItems[selectedIndex];
            var data = targetData;
            close();
            if (item && typeof item.action === "function") {
                Qt.callLater(function() {
                    item.action(data);
                });
            }
            root.actionTriggered(selectedIndex, item, data);
        }
    }

    // Modal Backdrop Dimmer
    Rectangle {
        anchors.fill: parent
        color: root.useFixedPosition ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(0, 0, 0, 0.5)
        opacity: root.isOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.close()
        }
    }

    // Glassmorphic Popup Card (Positioned at mouse or centered for keyboard/gamepad)
    Rectangle {
        id: menuContainer
        width: Math.min((root.width > 0 ? root.width : (parent ? parent.width : 460)) - 24, 250)
        implicitHeight: menuColumn.implicitHeight + 20
        radius: 12
        color: Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.96)
        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
        border.width: 1.5

        x: root.useFixedPosition ? root.popupX : Math.round(((root.width > 0 ? root.width : (parent ? parent.width : 460)) - width) / 2)
        y: root.useFixedPosition ? root.popupY : Math.round(((root.height > 0 ? root.height : (parent ? parent.height : 600)) - height) / 2)

        scale: root.isOpen ? 1.0 : 0.92
        opacity: root.isOpen ? 1.0 : 0.0
        transformOrigin: root.useFixedPosition ? Item.TopLeft : Item.Center

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 120 } }

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            // Header (Title / Subtitle)
            ColumnLayout {
                visible: root.menuTitle !== ""
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.menuTitle
                    color: Theme.on_surface
                    font.bold: true
                    font.pixelSize: 12
                    font.family: Theme.fontFamilyDisplay
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    visible: root.menuSubtitle !== ""
                    text: root.menuSubtitle
                    color: Theme.on_surface_variant
                    font.pixelSize: 10
                    font.family: Theme.fontFamilySans
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Subtle Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.outline_variant
                    opacity: 0.4
                    Layout.topMargin: 3
                    Layout.bottomMargin: 3
                }
            }

            // Menu Items List
            Repeater {
                model: root.menuItems
                delegate: Rectangle {
                    id: itemCard
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 7

                    readonly property bool isCurrent: root.selectedIndex === index
                    readonly property bool isHovered: itemMouse.containsMouse

                    color: (isCurrent || isHovered)
                        ? (modelData.destructive
                            ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.18)
                            : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22))
                        : "transparent"

                    border.color: isCurrent
                        ? (modelData.destructive ? Theme.error : Theme.primary)
                        : (isHovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : "transparent")
                    border.width: isCurrent ? 1.5 : (isHovered ? 1.0 : 0)

                    scale: (isCurrent || isHovered) ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on border.color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        VectorIcon {
                            visible: modelData.icon !== undefined && modelData.icon !== ""
                            name: modelData.icon || "gear"
                            iconSize: 15
                            color: modelData.destructive
                                ? Theme.error
                                : (modelData.iconColor !== undefined && modelData.iconColor !== ""
                                    ? modelData.iconColor
                                    : (itemCard.isCurrent || itemCard.isHovered ? Theme.primary : Theme.on_surface_variant))
                        }

                        Text {
                            text: modelData.text || ""
                            color: modelData.destructive
                                ? Theme.error
                                : (itemCard.isCurrent || itemCard.isHovered ? Theme.primary : Theme.on_surface)
                            font.bold: itemCard.isCurrent
                            font.pixelSize: 12
                            font.family: Theme.fontFamilyDisplay
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        VectorIcon {
                            visible: itemCard.isCurrent
                            name: "chevron-right"
                            iconSize: 11
                            color: modelData.destructive ? Theme.error : Theme.primary
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: {
                            root.selectedIndex = index;
                            InputService.useMouse();
                        }
                        onClicked: {
                            root.selectedIndex = index;
                            root.selectCurrent();
                        }
                    }
                }
            }
        }
    }
}
