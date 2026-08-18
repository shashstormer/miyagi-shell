import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../components"

ColumnLayout {
    id: root

    property string notifSearchQuery: ""
    property string notifFilter: "All" // "All" | "Rules" | "Silent" | "Blocked"
    property string notifTimeframe: "all_time" // "today" | "week" | "month" | "all_time"
    property int focusIndex: -1
    property int actionIndex: 0

    readonly property var timeframeOptions: ["today", "week", "month", "all_time"]
    readonly property var filterOptions: ["All", "Rules", "Silent", "Blocked"]

    function getItemCount() {
        var apps = getNotificationAppsList();
        return 2 + apps.length;
    }

    function handleHorizontal(delta) {
        if (focusIndex === 0) {
            // Timeframe cycling
            var curIdx = timeframeOptions.indexOf(notifTimeframe);
            if (curIdx === -1) curIdx = 3;
            var nextIdx = Math.max(0, Math.min(timeframeOptions.length - 1, curIdx + delta));
            notifTimeframe = timeframeOptions[nextIdx];
        } else if (focusIndex === 1) {
            // Filter cycling
            var fIdx = filterOptions.indexOf(notifFilter);
            if (fIdx === -1) fIdx = 0;
            var nextF = Math.max(0, Math.min(filterOptions.length - 1, fIdx + delta));
            notifFilter = filterOptions[nextF];
        } else if (focusIndex >= 2) {
            // App row: switch between Silent (0) and Block (1)
            actionIndex = Math.max(0, Math.min(1, actionIndex + delta));
        }
    }

    function triggerItem() {
        if (focusIndex === 0) {
            var curIdx = timeframeOptions.indexOf(notifTimeframe);
            notifTimeframe = timeframeOptions[(curIdx + 1) % timeframeOptions.length];
        } else if (focusIndex === 1) {
            var fIdx = filterOptions.indexOf(notifFilter);
            notifFilter = filterOptions[(fIdx + 1) % filterOptions.length];
        } else if (focusIndex >= 2) {
            var apps = getNotificationAppsList();
            var appIdx = focusIndex - 2;
            if (appIdx >= 0 && appIdx < apps.length) {
                var app = apps[appIdx];
                if (actionIndex === 0) {
                    ConfigService.toggleAppSilent(app.name, !app.isSilent);
                } else {
                    ConfigService.toggleAppBlocked(app.name, !app.isBlocked);
                }
            }
        }
    }

    Layout.fillWidth: true
    spacing: 14

    function getSelectedReceivedCount() {
        if (notifTimeframe === "today") return (ConfigService.notificationStatsToday && ConfigService.notificationStatsToday.received !== undefined) ? ConfigService.notificationStatsToday.received : 0;
        if (notifTimeframe === "week") return (ConfigService.notificationStatsWeek && ConfigService.notificationStatsWeek.received !== undefined) ? ConfigService.notificationStatsWeek.received : 0;
        if (notifTimeframe === "month") return (ConfigService.notificationStatsMonth && ConfigService.notificationStatsMonth.received !== undefined) ? ConfigService.notificationStatsMonth.received : 0;
        return ConfigService.totalNotificationsReceived;
    }

    function getSelectedBlockedCount() {
        if (notifTimeframe === "today") return (ConfigService.notificationStatsToday && ConfigService.notificationStatsToday.blocked !== undefined) ? ConfigService.notificationStatsToday.blocked : 0;
        if (notifTimeframe === "week") return (ConfigService.notificationStatsWeek && ConfigService.notificationStatsWeek.blocked !== undefined) ? ConfigService.notificationStatsWeek.blocked : 0;
        if (notifTimeframe === "month") return (ConfigService.notificationStatsMonth && ConfigService.notificationStatsMonth.blocked !== undefined) ? ConfigService.notificationStatsMonth.blocked : 0;
        return ConfigService.totalNotificationsBlocked;
    }

    function getSenderCategory(appName) {
        var n = (appName || "").toLowerCase();
        if (n === "notify-send" || n === "curl" || n === "wget" || n === "bash" || n === "zsh" || n === "sh" || n === "python" || n === "node" || n === "script") {
            return "CLI / Script";
        }
        if (n.includes("systemd") || n.includes("kernel") || n.includes("system") || n.includes("cron") || n.includes("bluetooth") || n.includes("network") || n.includes("wireplumber") || n.includes("pipewire") || n.includes("udev") || n.includes("power") || n.includes("upower")) {
            return "System Service";
        }
        return "Notification Sender";
    }

    function getNotificationAppsList() {
        var map = {};
        // 1. Add apps from system applications list
        var apps = ConfigService.applicationsList || [];
        for (var i = 0; i < apps.length; i++) {
            var a = apps[i];
            if (!a || !a.name) continue;
            var key = a.name.trim().toUpperCase();
            map[key] = {
                id: a.id || key,
                name: a.name,
                icon: a.icon || "",
                category: a.category || "Application",
                received_count: 0,
                blocked_count: 0,
                today_count: 0,
                week_count: 0,
                month_count: 0,
                last_received_at: 0
            };
        }

        // 2. Add / update stats from notificationAppStats
        var stats = ConfigService.notificationAppStats || [];
        for (var j = 0; j < stats.length; j++) {
            var s = stats[j];
            if (!s || !s.app_name) continue;
            var k = s.app_name.trim().toUpperCase();
            if (!map[k]) {
                map[k] = {
                    id: k,
                    name: s.app_name,
                    icon: s.app_icon || "",
                    category: root.getSenderCategory(s.app_name),
                    received_count: s.received_count || 0,
                    blocked_count: s.blocked_count || 0,
                    today_count: s.today_count || 0,
                    week_count: s.week_count || 0,
                    month_count: s.month_count || 0,
                    last_received_at: s.last_received_at || 0
                };
            } else {
                if (s.app_icon && !map[k].icon) map[k].icon = s.app_icon;
                map[k].received_count = s.received_count || 0;
                map[k].blocked_count = s.blocked_count || 0;
                map[k].today_count = s.today_count || 0;
                map[k].week_count = s.week_count || 0;
                map[k].month_count = s.month_count || 0;
                map[k].last_received_at = s.last_received_at || 0;
            }
        }

        // 3. Add custom configured rules
        var silent = ConfigService.silentNotificationApps || [];
        for (var k1 = 0; k1 < silent.length; k1++) {
            var sName = (silent[k1] || "").trim().toUpperCase();
            if (sName && !map[sName]) {
                map[sName] = { id: sName, name: sName, icon: "", category: root.getSenderCategory(sName), received_count: 0, blocked_count: 0, today_count: 0, week_count: 0, month_count: 0, last_received_at: 0 };
            }
        }
        var blocked = ConfigService.blockedNotificationApps || [];
        for (var k2 = 0; k2 < blocked.length; k2++) {
            var bName = (blocked[k2] || "").trim().toUpperCase();
            if (bName && !map[bName]) {
                map[bName] = { id: bName, name: bName, icon: "", category: root.getSenderCategory(bName), received_count: 0, blocked_count: 0, today_count: 0, week_count: 0, month_count: 0, last_received_at: 0 };
            }
        }

        var list = [];
        var q = notifSearchQuery.trim().toLowerCase();
        for (var appKey in map) {
            var item = map[appKey];
            var isSilent = ConfigService.isAppSilent(item.name);
            var isBlocked = ConfigService.isAppBlocked(item.name);
            item.isSilent = isSilent;
            item.isBlocked = isBlocked;

            // Search query filter
            if (q.length > 0 && item.name.toLowerCase().indexOf(q) === -1 && item.category.toLowerCase().indexOf(q) === -1) {
                continue;
            }

            // Tab filter
            if (notifFilter === "Silent" && !isSilent) continue;
            if (notifFilter === "Blocked" && !isBlocked) continue;
            if (notifFilter === "Rules" && !isSilent && !isBlocked) continue;

            list.push(item);
        }

        // Sort: blocked/silent and high activity first, then alphabetical
        list.sort(function(a, b) {
            var scoreA = (a.isBlocked ? 2000 : 0) + (a.isSilent ? 1000 : 0) + (a.received_count * 10) + (a.last_received_at > 0 ? 500 : 0);
            var scoreB = (b.isBlocked ? 2000 : 0) + (b.isSilent ? 1000 : 0) + (b.received_count * 10) + (b.last_received_at > 0 ? 500 : 0);
            if (scoreA !== scoreB) return scoreB - scoreA;
            return a.name.localeCompare(b.name);
        });

        return list;
    }

    // 1. Timeframe Selector Filter Bar
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: 8
        color: (root.focusIndex === 0 && InputService.isNonMouse)
            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            : "transparent"
        border.color: (root.focusIndex === 0 && InputService.isNonMouse) ? Theme.primary : "transparent"
        border.width: (root.focusIndex === 0 && InputService.isNonMouse) ? 1.5 : 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 8

            Text {
                text: "INSIGHTS TIMEFRAME"
                color: (root.focusIndex === 0 && InputService.isNonMouse) ? Theme.primary : Theme.on_surface_variant
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.2
                font.family: Theme.fontFamilyDisplay
            }

            Item { Layout.fillWidth: true }

            FilterPillRow {
                model: [
                    { id: "today", label: "Today" },
                    { id: "week", label: "7 Days" },
                    { id: "month", label: "30 Days" },
                    { id: "all_time", label: "All Time" }
                ]
                selected: root.notifTimeframe
                onOptionSelected: optId => root.notifTimeframe = optId
            }
        }
    }

    // 2. Summary Statistics Dashboard (4 Modular Stat Cards)
    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 10
        rowSpacing: 10

        SettingStatCard {
            iconName: "bell"
            value: root.getSelectedReceivedCount() + ""
            label: "Received"
            accentColor: Theme.primary
            containerColor: Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 0.3)
            borderColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
        }

        SettingStatCard {
            iconName: "ban"
            value: root.getSelectedBlockedCount() + ""
            label: "Blocked"
            accentColor: Theme.error
            containerColor: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15)
            borderColor: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.25)
        }

        SettingStatCard {
            iconName: "bell-off"
            value: ((ConfigService.silentNotificationApps || []).length) + ""
            label: "Silenced Apps"
            accentColor: Theme.secondary
            containerColor: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.15)
            borderColor: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.25)
        }

        SettingStatCard {
            iconName: "ban"
            value: ((ConfigService.blockedNotificationApps || []).length) + ""
            label: "Blocked Apps"
            accentColor: Theme.error
            containerColor: Qt.rgba(Theme.error_container.r, Theme.error_container.g, Theme.error_container.b, 0.2)
            borderColor: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.25)
        }
    }

    // 3. Per-App Rules & Statistics Management Card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: notifCardInnerCol.implicitHeight + 36
        radius: 18
        color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 0.70)

        ColumnLayout {
            id: notifCardInnerCol
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16

            // Header Row: Title on Left, Filter Chips on Right
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 8
                color: (root.focusIndex === 1 && InputService.isNonMouse)
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                    : "transparent"
                border.color: (root.focusIndex === 1 && InputService.isNonMouse) ? Theme.primary : "transparent"
                border.width: (root.focusIndex === 1 && InputService.isNonMouse) ? 1.5 : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 12

                    RowLayout {
                        spacing: 10
                        VectorIcon {
                            name: "bell"
                            color: Theme.on_surface
                            iconSize: 18
                        }
                        Text {
                            text: "Rules & History"
                            color: Theme.on_surface
                            font.pixelSize: 15
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                        }
                    }

                    Item { Layout.fillWidth: true }

                    FilterPillRow {
                        model: ["All", "Rules", "Silent", "Blocked"]
                        selected: root.notifFilter
                        onOptionSelected: optId => root.notifFilter = optId
                    }
                }
            }

            // Search Input Bar
            SearchInput {
                Layout.fillWidth: true
                placeholder: "Search applications or notification senders..."
                onTextEdited: query => root.notifSearchQuery = query
            }

            // Modular Application Rows
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.getNotificationAppsList()

                    delegate: SettingAppRow {
                        id: appRowItem
                        required property int index
                        required property var modelData

                        appName: modelData.name
                        appIcon: modelData.icon || ""
                        category: modelData.category || "Application"
                        isSilent: modelData.isSilent
                        isBlocked: modelData.isBlocked
                        isFocused: (root.focusIndex === (appRowItem.index + 2))
                        focusedActionIndex: root.actionIndex

                        subtitle: {
                            var countStr = "";
                            if (root.notifTimeframe === "today") {
                                countStr = (modelData.today_count || 0) + " today";
                            } else if (root.notifTimeframe === "week") {
                                countStr = (modelData.week_count || 0) + " this week";
                            } else if (root.notifTimeframe === "month") {
                                countStr = (modelData.month_count || 0) + " this month";
                            } else {
                                countStr = (modelData.received_count || 0) + " received";
                            }
                            var blk = modelData.blocked_count || 0;
                            if (blk > 0) countStr += "  •  " + blk + " blocked";
                            return modelData.category + "  •  " + countStr;
                        }

                        onToggleSilent: ConfigService.toggleAppSilent(modelData.name, !modelData.isSilent)
                        onToggleBlock: ConfigService.toggleAppBlocked(modelData.name, !modelData.isBlocked)
                    }
                }
            }
        }
    }
}
