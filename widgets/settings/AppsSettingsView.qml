import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../components"

ColumnLayout {
    id: root

    property int focusIndex: -1
    property int actionIndex: 0
    property string searchQuery: ""
    property string selectedCategory: "All"

    readonly property var allApps: ConfigService.applicationsList || []
    readonly property var filteredApps: {
        var list = allApps;
        var q = searchQuery.toLowerCase().trim();
        var cat = selectedCategory;

        return list.filter(function(app) {
            if (!app) return false;
            var matchCat = (cat === "All") || (app.category && app.category.toLowerCase().indexOf(cat.toLowerCase()) !== -1);
            if (!matchCat) return false;
            if (!q) return true;
            var name = (app.name || "").toLowerCase();
            var desc = (app.description || "").toLowerCase();
            var id = (app.id || "").toLowerCase();
            var exec = (app.exec || "").toLowerCase();
            return name.indexOf(q) !== -1 || desc.indexOf(q) !== -1 || id.indexOf(q) !== -1 || exec.indexOf(q) !== -1;
        });
    }

    readonly property var pinnedApps: {
        return allApps.filter(function(a) { return !!a.pinned; });
    }

    function getItemCount() {
        return filteredApps.length;
    }

    function handleHorizontal(delta) {
    }

    function triggerItem() {
        if (focusIndex >= 0 && focusIndex < filteredApps.length) {
            var app = filteredApps[focusIndex];
            if (app) ConfigService.launchApplication(app.id, app.exec, app.desktop_file);
        }
    }

    Layout.fillWidth: true
    spacing: 12

    // ==========================================
    // 1. APPLICATIONS HERO STATUS CARD
    // ==========================================
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 88
        radius: 14
        color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.55)
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Rectangle {
                width: 48
                height: 48
                radius: 12
                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)
                Layout.alignment: Qt.AlignVCenter

                VectorIcon {
                    anchors.centerIn: parent
                    name: "grid9"
                    iconSize: 22
                    color: Theme.primary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    Text {
                        text: "Applications"
                        color: Theme.on_surface
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Theme.fontFamilyDisplay
                    }

                    PillBadge {
                        text: allApps.length + " Apps Installed"
                        isInteractive: false
                    }
                }

                Text {
                    text: root.pinnedApps.length + " Pinned to Quick Launcher  •  System Indexed"
                    color: Theme.on_surface_variant
                    font.pixelSize: 11
                    font.family: Theme.fontFamilyDisplay
                }
            }

            SquareButton {
                text: "Refresh"
                iconName: "arrow_clockwise"
                size: 32
                customRadius: 16
                Layout.alignment: Qt.AlignVCenter
                onClicked: ConfigService.refreshApplications()
            }
        }
    }

    // ==========================================
    // 2. SEARCH & CATEGORY FILTER
    // ==========================================
    SettingCardGroup {
        titleText: "Search & Filter"

        SearchInput {
            Layout.fillWidth: true
            placeholder: "Search applications by name or command..."
            onTextEdited: query => {
                root.searchQuery = query;
            }
        }

        Flickable {
            Layout.fillWidth: true
            implicitHeight: 28
            contentWidth: categoryRow.implicitWidth
            flickableDirection: Flickable.HorizontalFlick
            clip: true

            FilterPillRow {
                id: categoryRow
                model: ["All", "AudioVideo", "Development", "Game", "Graphics", "Network", "Office", "System", "Utility"]
                selected: root.selectedCategory
                onOptionSelected: cat => {
                    root.selectedCategory = cat;
                }
            }
        }
    }

    // ==========================================
    // 3. APPLICATIONS LIST
    // ==========================================
    SettingCardGroup {
        titleText: "Installed Applications (" + root.filteredApps.length + ")"

        EmptyState {
            visible: root.filteredApps.length === 0
            iconName: "search"
            title: "No applications found"
            description: "No installed application matches \"" + root.searchQuery + "\""
        }

        Repeater {
            model: root.filteredApps
            delegate: Rectangle {
                id: appRow
                required property var modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: 48
                radius: 10
                color: (root.focusIndex === index)
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                    : (appMouse.containsMouse ? Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.35) : "transparent")

                border.color: (root.focusIndex === index) ? Theme.primary : "transparent"
                border.width: (root.focusIndex === index) ? 1.5 : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    AppIcon {
                        icon: modelData.icon || ""
                        appClass: modelData.id || ""
                        appTitle: modelData.name || ""
                        iconSize: 26
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        RowLayout {
                            spacing: 6
                            Layout.fillWidth: true

                            Text {
                                text: modelData.name || "App"
                                color: Theme.on_surface
                                font.bold: true
                                font.pixelSize: 12
                                font.family: Theme.fontFamilyDisplay
                                elide: Text.ElideRight
                            }

                            PillBadge {
                                visible: !!modelData.pinned
                                text: "Pinned"
                                isInteractive: false
                                pillHeight: 18
                                fontSize: 10
                            }
                        }

                        Text {
                            text: modelData.description || modelData.exec || ""
                            color: Theme.on_surface_variant
                            font.pixelSize: 10
                            font.family: Theme.fontFamilyDisplay
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Pin Favorite Button
                    SquareButton {
                        size: 28
                        customRadius: 7
                        iconName: "star"
                        isActive: !!modelData.pinned
                        customIconColor: modelData.pinned ? Theme.primary : Theme.on_surface_variant
                        onClicked: ConfigService.togglePinApp(modelData.id, !modelData.pinned)
                    }

                    // Launch Button
                    SquareButton {
                        text: "Launch"
                        iconName: "play"
                        size: 28
                        customRadius: 14
                        onClicked: ConfigService.launchApplication(modelData.id, modelData.exec, modelData.desktop_file)
                    }
                }

                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ConfigService.launchApplication(modelData.id, modelData.exec, modelData.desktop_file)
                }
            }
        }
    }
}
