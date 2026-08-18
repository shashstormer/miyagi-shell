import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../components"

Rectangle {
    id: root

    property string labelText: ""
    property string descriptionText: ""
    property string iconName: ""
    property var options: []
    property int selectedIndex: 0
    property bool isFocused: false
    property bool flowLayout: (options && options.length > 4)
    signal optionSelected(int index, var option)

    function cycle(delta) {
        if (!options || options.length === 0) return;
        var next = (selectedIndex + delta + options.length) % options.length;
        if (next !== selectedIndex) {
            selectedIndex = next;
            optionSelected(selectedIndex, options[selectedIndex]);
        }
    }

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 16
    radius: 10

    color: (isFocused && InputService.isNonMouse)
        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
        : "transparent"

    border.color: (isFocused && InputService.isNonMouse) ? Theme.primary : "transparent"
    border.width: (isFocused && InputService.isNonMouse) ? 1.5 : 0

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 10
        spacing: root.flowLayout ? 8 : 0

        // Single line inline mode: RowLayout contains Label on left, Pills on right
        RowLayout {
            visible: !root.flowLayout
            Layout.fillWidth: true
            spacing: 12

            VectorIcon {
                visible: root.iconName !== ""
                name: root.iconName
                color: root.isFocused ? Theme.primary : Theme.on_surface_variant
                iconSize: 15
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: root.labelText
                    color: (root.isFocused && InputService.isNonMouse) ? Theme.primary : Theme.on_surface
                    font.pixelSize: 13
                    font.bold: true
                    font.family: Theme.fontFamilyDisplay
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    visible: root.descriptionText !== ""
                    text: root.descriptionText
                    color: Theme.on_surface_variant
                    font.pixelSize: 11
                    font.family: Theme.fontFamilyDisplay
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            Row {
                spacing: 6

                Repeater {
                    model: root.flowLayout ? [] : root.options
                    delegate: Rectangle {
                        required property int index
                        required property var modelData

                        implicitWidth: inlinePillText.implicitWidth + 20
                        implicitHeight: 28
                        radius: 14

                        color: index === root.selectedIndex 
                            ? Theme.primary 
                            : (inlinePillMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.50))
                        border.color: index === root.selectedIndex ? Theme.primary : Theme.outline_variant
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: inlinePillText
                            anchors.centerIn: parent
                            text: typeof modelData === "object" ? modelData.label : String(modelData)
                            color: index === root.selectedIndex ? Theme.on_primary : Theme.on_surface
                            font.pixelSize: 11
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                        }

                        MouseArea {
                            id: inlinePillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                InputService.useMouse();
                                root.selectedIndex = index;
                                root.optionSelected(index, modelData);
                            }
                        }
                    }
                }
            }
        }

        // Multi-line Flow mode: Header with Label & Description on top, Wrapping Flow below
        ColumnLayout {
            visible: root.flowLayout
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                VectorIcon {
                    visible: root.iconName !== ""
                    name: root.iconName
                    color: root.isFocused ? Theme.primary : Theme.on_surface_variant
                    iconSize: 15
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Text {
                        text: root.labelText
                        color: (root.isFocused && InputService.isNonMouse) ? Theme.primary : Theme.on_surface
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Theme.fontFamilyDisplay
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.descriptionText !== ""
                        text: root.descriptionText
                        color: Theme.on_surface_variant
                        font.pixelSize: 11
                        font.family: Theme.fontFamilyDisplay
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: root.flowLayout ? root.options : []
                    delegate: Rectangle {
                        required property int index
                        required property var modelData

                        implicitWidth: flowPillText.implicitWidth + 22
                        implicitHeight: 30
                        radius: 15

                        color: index === root.selectedIndex 
                            ? Theme.primary 
                            : (flowPillMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.40))
                        border.color: index === root.selectedIndex ? Theme.primary : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.4)
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: flowPillText
                            anchors.centerIn: parent
                            text: typeof modelData === "object" ? modelData.label : String(modelData)
                            color: index === root.selectedIndex ? Theme.on_primary : Theme.on_surface
                            font.pixelSize: 11
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                        }

                        MouseArea {
                            id: flowPillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                InputService.useMouse();
                                root.selectedIndex = index;
                                root.optionSelected(index, modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
