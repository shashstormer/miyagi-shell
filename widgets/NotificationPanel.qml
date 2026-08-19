import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import "../theme"
import "./panels"
import "./components"

Item {
    id: root

    property bool isOpen: notifFlyout.isOpen
    property var notifServer: null

    function toggle() {
        if (notifFlyout.isOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        notifFlyout.open();
        markAllAsRead();
    }

    function close() {
        notifFlyout.close();
    }

    // In-memory persistent history array (pure data, NO raw QObject pointers)
    property var historyList: []
    // Private dictionary holding Notification QObject handles safely outside QML var model
    property var _historyHandles: ({})
    property alias openedFrom: notifFlyout.openedFrom

    readonly property int unreadCount: {
        var count = 0;
        for (var i = 0; i < historyList.length; i++) {
            if (historyList[i] && !historyList[i].read) count++;
        }
        return count;
    }

    function markAllAsRead() {
        var copy = historyList.slice();
        for (var i = 0; i < copy.length; i++) {
            if (copy[i]) copy[i].read = true;
        }
        historyList = copy;
    }

    function clearAll() {
        _historyHandles = {};
        historyList = [];
    }

    function removeNotification(index) {
        if (index >= 0 && index < historyList.length) {
            var item = historyList[index];
            if (item && item.id) {
                delete root._historyHandles[item.id];
            }
            var copy = historyList.slice();
            copy.splice(index, 1);
            historyList = copy;
        }
    }

    function removeNotificationById(targetId) {
        delete root._historyHandles[targetId];
        var copy = historyList.slice();
        for (var i = 0; i < copy.length; i++) {
            if (copy[i] && copy[i].id === targetId) {
                copy.splice(i, 1);
                break;
            }
        }
        historyList = copy;
    }

    function focusApp(appName) {
        ConfigService.focusApp(appName);
    }

    // Direct D-Bus notification tracking connection to notifServer
    Connections {
        target: root.notifServer
        ignoreUnknownSignals: true
        
        function onNotification(notification) {
            if (!notification) return;
            
            var rawAppName = notification.appName ? notification.appName.trim().toUpperCase() : (notification.desktopEntry ? notification.desktopEntry.trim().toUpperCase() : "SYSTEM");
            var notifIcon = (notification.image || notification.appIcon) ? (notification.image || notification.appIcon) : "";
            var isBlocked = ConfigService.isAppBlocked(rawAppName);

            // Record per-app notification tracking stats with icon
            ConfigService.recordNotification(rawAppName, isBlocked, notifIcon);

            // Blocked = no popup AND no drawer history
            if (isBlocked) {
                return;
            }

            var notifId = notification.id || Math.floor(Math.random() * 1000000);
            root._historyHandles[notifId] = notification;

            try {
                if (notification.closed) {
                    notification.closed.connect(function() {
                        root.removeNotificationById(notifId);
                    });
                }
            } catch (e) {}

            var isTemporary = (notification.expireTimeout > 0);
            var timeoutMs = isTemporary ? notification.expireTimeout : 0;
            var expiresTimestamp = isTemporary ? (Date.now() + Math.max(100, Math.round(timeoutMs))) : 0;

            var extractedActions = [];
            if (notification.actions) {
                for (var i = 0; i < notification.actions.length; i++) {
                    var act = notification.actions[i];
                    if (act) {
                        extractedActions.push({
                            id: act.identifier || "",
                            text: act.text || act.identifier || "Action"
                        });
                    }
                }
            }

            var currentHistory = root.historyList.slice();
            var timeStr = Qt.formatDateTime(new Date(), "hh:mm AP");

            var historyItem = {
                id: notifId,
                appName: rawAppName,
                summary: notification.summary ? notification.summary : "Notification",
                body: notification.body ? notification.body : "",
                icon: (notification.image || notification.appIcon) ? (notification.image || notification.appIcon) : "",
                urgency: notification.urgency,
                actions: extractedActions,
                time: timeStr,
                read: false,
                expiresAt: expiresTimestamp
            };

            currentHistory.unshift(historyItem);
            root.historyList = currentHistory;
        }
    }

    // Single static expiration check timer (replaces dynamic Qt.createQmlObject timer creation)
    Timer {
        id: notifCleanupTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = Date.now();
            var hasExpired = false;
            for (var i = 0; i < root.historyList.length; i++) {
                if (root.historyList[i] && root.historyList[i].expiresAt > 0 && root.historyList[i].expiresAt <= now) {
                    hasExpired = true;
                    break;
                }
            }
            if (hasExpired) {
                var copy = [];
                for (var j = 0; j < root.historyList.length; j++) {
                    var item = root.historyList[j];
                    if (item && item.expiresAt > 0 && item.expiresAt <= now) {
                        delete root._historyHandles[item.id];
                    } else {
                        copy.push(item);
                    }
                }
                root.historyList = copy;
            }
        }
    }

    property int selectedIndex: 0
    property int selectedSubIndex: 0 // -1 = CLEAR ALL, 0 = Card Body, 1..N = Action Buttons, N+1 = Dismiss Button

    function navigate(delta) {
        InputService.useKeyboard();
        if (historyList.length === 0) return;
        if (delta < 0) {
            if (selectedIndex === 0 && selectedSubIndex <= 0) {
                selectedSubIndex = -1;
            } else {
                selectedIndex = Math.max(0, selectedIndex - 1);
                selectedSubIndex = 0;
            }
        } else if (delta > 0) {
            if (selectedSubIndex === -1) {
                selectedSubIndex = 0;
                selectedIndex = 0;
            } else {
                selectedIndex = Math.min(historyList.length - 1, selectedIndex + 1);
                selectedSubIndex = 0;
            }
        }
        if (listView && selectedIndex >= 0) {
            var curItem = historyList[selectedIndex];
            var actCount = (curItem && curItem.actions) ? curItem.actions.length : 0;
            if (selectedSubIndex === (actCount + 1)) {
                listView.positionViewAtIndex(selectedIndex, ListView.Beginning);
            } else if (selectedSubIndex > 0) {
                listView.positionViewAtIndex(selectedIndex, ListView.End);
            } else {
                listView.positionViewAtIndex(selectedIndex, ListView.Contain);
            }
        }
    }

    function openContextMenuForSelected() {
        if (selectedIndex >= 0 && selectedIndex < historyList.length) {
            var item = historyList[selectedIndex];
            if (item) {
                openContextMenuForNotif(item, selectedIndex);
            }
        }
    }

    function getAppSubtitle(appName, summary) {
        var clean = (appName || "").trim().toUpperCase();
        var stats = ConfigService.notificationAppStats || [];
        for (var i = 0; i < stats.length; i++) {
            if (stats[i] && stats[i].app_name === clean) {
                var rx = stats[i].received_count || 1;
                var blk = stats[i].blocked_count || 0;
                var info = rx + " received" + (blk > 0 ? (" • " + blk + " blocked") : "");
                return summary ? (summary + "  [" + info + "]") : info;
            }
        }
        return summary || "";
    }

    function openContextMenuForNotif(item, notifIdx) {
        if (!item) return;
        var appName = item.appName ? item.appName.trim().toUpperCase() : "SYSTEM";
        var isSilent = ConfigService.isAppSilent(appName);
        var isBlocked = ConfigService.isAppBlocked(appName);

        var menuItems = [
            {
                text: isSilent ? ("Unsilence " + item.appName) : ("Silence " + item.appName),
                icon: isSilent ? "bell" : "bell-off",
                destructive: false,
                action: function() {
                    ConfigService.toggleAppSilent(appName, !isSilent);
                }
            },
            {
                text: isBlocked ? ("Unblock " + item.appName) : ("Block " + item.appName),
                icon: isBlocked ? "check" : "ban",
                destructive: !isBlocked,
                action: function() {
                    ConfigService.toggleAppBlocked(appName, !isBlocked);
                    if (!isBlocked) {
                        var copy = [];
                        for (var i = 0; i < root.historyList.length; i++) {
                            if (root.historyList[i] && (root.historyList[i].appName || "").toUpperCase() !== appName) {
                                copy.push(root.historyList[i]);
                            }
                        }
                        root.historyList = copy;
                    }
                }
            },
            {
                text: "Copy Notification Text",
                icon: "clipboard",
                destructive: false,
                action: function() {
                    var fullText = (item.summary || "") + (item.body ? ("\n" + item.body) : "");
                    ConfigService.executeAction("copy_text_" + fullText);
                }
            },
            {
                text: "Dismiss Notification",
                icon: "trash",
                destructive: true,
                action: function() {
                    root.removeNotification(notifIdx);
                }
            }
        ];

        notifContextMenu.openForTarget(menuItems, item, item.appName || "Notification", root.getAppSubtitle(appName, item.summary));
    }

    function openContextMenuForNotifAt(x, y, item, notifIdx) {
        if (!item) return;
        var appName = item.appName ? item.appName.trim().toUpperCase() : "SYSTEM";
        var isSilent = ConfigService.isAppSilent(appName);
        var isBlocked = ConfigService.isAppBlocked(appName);

        var menuItems = [
            {
                text: isSilent ? ("Unsilence " + item.appName) : ("Silence " + item.appName),
                icon: isSilent ? "bell" : "bell-off",
                destructive: false,
                action: function() {
                    ConfigService.toggleAppSilent(appName, !isSilent);
                }
            },
            {
                text: isBlocked ? ("Unblock " + item.appName) : ("Block " + item.appName),
                icon: isBlocked ? "check" : "ban",
                destructive: !isBlocked,
                action: function() {
                    ConfigService.toggleAppBlocked(appName, !isBlocked);
                    if (!isBlocked) {
                        var copy = [];
                        for (var i = 0; i < root.historyList.length; i++) {
                            if (root.historyList[i] && (root.historyList[i].appName || "").toUpperCase() !== appName) {
                                copy.push(root.historyList[i]);
                            }
                        }
                        root.historyList = copy;
                    }
                }
            },
            {
                text: "Copy Notification Text",
                icon: "clipboard",
                destructive: false,
                action: function() {
                    var fullText = (item.summary || "") + (item.body ? ("\n" + item.body) : "");
                    ConfigService.executeAction("copy_text_" + fullText);
                }
            },
            {
                text: "Dismiss Notification",
                icon: "trash",
                destructive: true,
                action: function() {
                    root.removeNotification(notifIdx);
                }
            }
        ];

        notifContextMenu.openAt(x, y, menuItems, item, item.appName || "Notification", root.getAppSubtitle(appName, item.summary));
    }

    function navigateHorizontal(delta) {
        InputService.useKeyboard();
        if (historyList.length === 0 || selectedIndex < 0 || selectedIndex >= historyList.length) return;
        if (selectedSubIndex === -1) return;
        var item = historyList[selectedIndex];
        var actionCount = (item && item.actions) ? item.actions.length : 0;
        var maxSub = actionCount + 2;

        if (selectedSubIndex === 0 && delta > 0) {
            selectedSubIndex = 1;
        } else if (selectedSubIndex === 0 && delta < 0) {
            selectedSubIndex = maxSub;
        } else {
            selectedSubIndex = Math.max(0, Math.min(selectedSubIndex + delta, maxSub));
        }

        if (listView && selectedIndex >= 0) {
            if (selectedSubIndex === maxSub) {
                listView.positionViewAtIndex(selectedIndex, ListView.Beginning);
            } else if (selectedSubIndex > 0) {
                listView.positionViewAtIndex(selectedIndex, ListView.End);
            } else {
                listView.positionViewAtIndex(selectedIndex, ListView.Contain);
            }
        }
    }

    function activateSelected() {
        if (selectedSubIndex === -1) {
            clearAll();
            selectedSubIndex = 0;
            return;
        }
        if (selectedIndex >= 0 && selectedIndex < historyList.length) {
            var item = historyList[selectedIndex];
            if (!item) return;
            var actionCount = (item.actions) ? item.actions.length : 0;

            if (selectedSubIndex === 0) {
                if (item.appName) focusApp(item.appName);
            } else if (selectedSubIndex > 0 && selectedSubIndex <= actionCount) {
                var act = item.actions[selectedSubIndex - 1];
                if (act && item.id) {
                    var handle = root._historyHandles[item.id];
                    if (handle && handle.actions) {
                        var actionsList = handle.actions;
                        for (var k = 0; k < actionsList.length; k++) {
                            if (actionsList[k] && actionsList[k].identifier === act.id) {
                                try { actionsList[k].invoke(); } catch (e) {}
                                break;
                            }
                        }
                    }
                }
            } else if (selectedSubIndex === actionCount + 1) {
                openContextMenuForSelected();
            } else if (selectedSubIndex === actionCount + 2) {
                removeNotification(selectedIndex);
                if (selectedIndex >= historyList.length) {
                    selectedIndex = Math.max(0, historyList.length - 1);
                }
                selectedSubIndex = 0;
            }
        }
    }

    Connections {
        target: InputService
        enabled: notifFlyout.isOpen

        function onNavUp() {
            if (notifContextMenu.isOpen) {
                notifContextMenu.navigate(-1);
            } else {
                root.navigate(-1);
            }
        }
        function onNavDown() {
            if (notifContextMenu.isOpen) {
                notifContextMenu.navigate(1);
            } else {
                root.navigate(1);
            }
        }
        function onNavLeft() {
            if (!notifContextMenu.isOpen) {
                root.navigateHorizontal(-1);
            }
        }
        function onNavRight() {
            if (!notifContextMenu.isOpen) {
                root.navigateHorizontal(1);
            }
        }
        function onNavContextMenu() {
            root.openContextMenuForSelected();
        }
        function onNavSelect() {
            if (notifContextMenu.isOpen) {
                notifContextMenu.selectCurrent();
            } else {
                root.activateSelected();
            }
        }
        function onNavBack() {
            if (notifContextMenu.isOpen) {
                notifContextMenu.close();
            } else if (selectedSubIndex !== 0) {
                selectedSubIndex = 0;
            } else if (selectedIndex > 0) {
                selectedIndex = 0;
            } else {
                InputService.closeOrReturn(notifFlyout);
            }
        }
        function onNavNextTab() {
            if (!notifContextMenu.isOpen) {
                root.clearAll();
            }
        }
        function onNavPrevTab() {
            if (!notifContextMenu.isOpen) {
                root.removeNotification(root.selectedIndex);
            }
        }
    }

    onIsOpenChanged: {
        if (isOpen) {
            selectedIndex = 0;
            selectedSubIndex = 0;
            markAllAsRead();
        }
    }

    BaseFlyoutPanel {
        id: notifFlyout
        title: "Notifications"
        iconName: "bell"
        side: "right"
        cardWidth: 380
        cardHeight: 560
        showRefresh: false
        showSwitch: false
        requiresKeyboardFocus: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            // Subtitle & Clear All Row
            RowLayout {
                Layout.fillWidth: true
                visible: root.historyList.length > 0

                Text {
                    text: root.historyList.length + (root.historyList.length === 1 ? " MESSAGE IN HISTORY" : " MESSAGES IN HISTORY")
                    color: Theme.secondary
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.2
                    font.family: Theme.fontFamilyMono
                }

                Item { Layout.fillWidth: true }

                // Clear All Button with Vector Trash Can Canvas
                Rectangle {
                    visible: root.historyList.length > 0
                    implicitWidth: clearRow.implicitWidth + 12
                    implicitHeight: 26
                    radius: 6
                    readonly property bool isClearFocused: root.selectedSubIndex === -1 || clearArea.containsMouse
                    color: isClearFocused ? Theme.error_container : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.8)
                    border.color: isClearFocused ? Theme.error : Theme.outline_variant
                    border.width: isClearFocused ? 2 : 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: clearRow
                        anchors.centerIn: parent
                        spacing: 4

                        Canvas {
                            id: trashCanvas
                            implicitWidth: 14
                            implicitHeight: 14
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = clearArea.containsMouse ? Theme.on_error_container : Theme.on_surface_variant;
                                ctx.lineWidth = 1.4;
                                ctx.lineCap = "round";

                                // Lid
                                ctx.beginPath();
                                ctx.moveTo(2, 4);
                                ctx.lineTo(12, 4);
                                ctx.moveTo(5, 4);
                                ctx.lineTo(5, 2);
                                ctx.lineTo(9, 2);
                                ctx.lineTo(9, 4);
                                ctx.stroke();

                                // Body
                                ctx.beginPath();
                                ctx.moveTo(3.5, 4);
                                ctx.lineTo(4.5, 12);
                                ctx.lineTo(9.5, 12);
                                ctx.lineTo(10.5, 4);
                                ctx.stroke();
                            }
                            Connections {
                                target: clearArea
                                function onContainsMouseChanged() { trashCanvas.requestPaint(); }
                            }
                        }

                        Text {
                            text: "CLEAR"
                            color: clearArea.containsMouse ? Theme.on_error_container : Theme.on_surface_variant
                            font.pixelSize: 9
                            font.bold: true
                            font.family: Theme.fontFamilyMono
                        }
                    }

                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearAll()
                    }
                }

                // Quick Settings Button
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 6
                    color: settingsArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.8)
                    border.color: settingsArea.containsMouse ? Theme.primary : Theme.outline_variant
                    border.width: 1

                    VectorIcon {
                        anchors.centerIn: parent
                        name: "gear"
                        iconSize: 13
                        color: settingsArea.containsMouse ? Theme.primary : Theme.on_surface_variant
                    }

                    MouseArea {
                        id: settingsArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.close();
                            if (typeof settingsPanel !== "undefined" && settingsPanel) {
                                settingsPanel.open();
                            } else {
                                ConfigService.executeAction("open_settings");
                            }
                        }
                    }
                }
            }

            // Horizontal Separator Line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                visible: root.historyList.length > 0
                color: Theme.outline_variant
            }

        // Notification History Scrollable ListView
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.historyList.length > 0
            clip: true
            spacing: 10

            model: root.historyList
            currentIndex: root.selectedIndex

            onCurrentIndexChanged: {
                root.selectedIndex = currentIndex;
            }

            delegate: Rectangle {
                id: notifCard
                required property var modelData
                required property int index

                readonly property bool isCurrent: root.selectedIndex === index
                readonly property bool isHovered: notifMouseArea.containsMouse
                readonly property bool isHighlighted: (InputService.isMouse && isHovered) || (InputService.isNonMouse && isCurrent)

                width: listView.width
                implicitHeight: cardCol.implicitHeight + 20
                radius: 8

                color: isHighlighted
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                    : (modelData.read 
                        ? Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g, Theme.surface_container_low.b, 0.7)
                        : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.9))

                border.color: isHighlighted 
                    ? Theme.primary 
                    : ((modelData && modelData.urgency === NotificationUrgency.Critical) 
                        ? Theme.error 
                        : (modelData.read ? Theme.outline_variant : Theme.primary))
                border.width: 1

                MouseArea {
                    id: notifMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    property real lastMoveX: -1
                    property real lastMoveY: -1

                    onPositionChanged: mouse => {
                        if (lastMoveX >= 0 && lastMoveY >= 0) {
                            var dx = Math.abs(mouse.x - lastMoveX);
                            var dy = Math.abs(mouse.y - lastMoveY);
                            if (dx > 2 || dy > 2) {
                                if (InputService.useMouse()) {
                                    root.selectedIndex = index;
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
                        if (mouse) mouse.accepted = true;
                        if (!InputService.useMouse()) return;
                        root.selectedIndex = index;
                        if (mouse.button === Qt.RightButton) {
                            var item = modelData;
                            var idx = index;
                            var pos = notifCard.mapToItem(notifContextMenu, mouse.x, mouse.y);
                            Qt.callLater(function() {
                                root.openContextMenuForNotifAt(pos.x, pos.y, item, idx);
                            });
                        } else {
                            root.activateSelected();
                        }
                    }
                }

                RowLayout {
                    id: cardCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    // Notification Icon / Image Badge
                    Rectangle {
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 6
                        color: Theme.primary_container
                        clip: true
                        Layout.alignment: Qt.AlignTop

                        Image {
                            id: iconImage
                            anchors.fill: parent
                            source: {
                                if (!modelData || !modelData.icon) return "";
                                var img = modelData.icon;
                                if (img.startsWith("/") || img.startsWith("file://") || img.startsWith("http://") || img.startsWith("https://")) {
                                    return img;
                                }
                                return "image://icon/" + img;
                            }
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                            asynchronous: true
                        }

                        // Vector Bell Icon Canvas
                        Canvas {
                            anchors.centerIn: parent
                            implicitWidth: 16
                            implicitHeight: 16
                            visible: iconImage.status !== Image.Ready
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = Theme.primary;
                                ctx.lineWidth = 1.6;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";

                                ctx.beginPath();
                                ctx.moveTo(8, 2);
                                ctx.arcTo(13, 2, 13, 10, 4);
                                ctx.lineTo(15, 12);
                                ctx.lineTo(1, 12);
                                ctx.lineTo(3, 10);
                                ctx.arcTo(3, 2, 8, 2, 4);
                                ctx.stroke();

                                ctx.beginPath();
                                ctx.arc(8, 13.5, 1.8, 0, Math.PI);
                                ctx.stroke();
                            }
                        }
                    }

                    // Content Column
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: modelData.appName
                                color: Theme.secondary
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 1
                                font.family: Theme.fontFamilyMono
                            }

                            Rectangle {
                                visible: ConfigService.isAppSilent(modelData.appName)
                                implicitWidth: silentBadgeText.implicitWidth + 8
                                implicitHeight: 15
                                radius: 3
                                color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.2)
                                border.color: Theme.secondary
                                border.width: 1

                                Text {
                                    id: silentBadgeText
                                    anchors.centerIn: parent
                                    text: "SILENT"
                                    color: Theme.secondary
                                    font.pixelSize: 8
                                    font.bold: true
                                    font.family: Theme.fontFamilyMono
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: modelData.time
                                color: Theme.outline
                                font.pixelSize: 9
                                font.family: Theme.fontFamilyMono
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.summary
                            color: (modelData && modelData.urgency === NotificationUrgency.Critical) ? Theme.error : Theme.primary
                            font.pixelSize: 12
                            font.bold: true
                            font.family: Theme.fontFamilyMono
                            wrapMode: Text.Wrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.body
                            color: Theme.on_surface_variant
                            font.pixelSize: 10
                            font.family: Theme.fontFamilyMono
                            wrapMode: Text.Wrap
                            visible: text.length > 0
                        }

                        // Interactive Action Buttons inside History Drawer
                        RowLayout {
                            spacing: 6
                            visible: modelData && modelData.actions && modelData.actions.length > 0

                            Repeater {
                                model: modelData ? modelData.actions : []

                                delegate: Rectangle {
                                    id: actionBtn
                                    required property var modelData
                                    required property int index

                                    readonly property bool isActionFocused: notifCard.isCurrent && (root.selectedSubIndex === (index + 1))

                                    implicitWidth: actionText.implicitWidth + 16
                                    implicitHeight: 24
                                    radius: 6
                                    scale: isActionFocused ? 1.15 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                    color: isActionFocused ? Theme.primary : (actionArea.containsMouse ? Theme.primary_fixed : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.85))
                                    border.color: isActionFocused ? Theme.on_primary : Theme.primary
                                    border.width: isActionFocused ? 2.5 : 1

                                    Text {
                                        id: actionText
                                        anchors.centerIn: parent
                                        text: modelData.text
                                        color: isActionFocused ? Theme.on_primary : (actionArea.containsMouse ? Theme.on_primary_fixed : Theme.primary)
                                        font.pixelSize: 10
                                        font.bold: true
                                        font.family: Theme.fontFamilyMono
                                    }

                                    MouseArea {
                                        id: actionArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: mouse => {
                                            if (mouse) mouse.accepted = true;
                                            var actionData = modelData;
                                            var parentCard = notifCard.modelData;

                                            if (parentCard && parentCard.id) {
                                                var handle = root._historyHandles[parentCard.id];
                                                if (handle && handle.actions) {
                                                    var actionsList = handle.actions;
                                                    for (var k = 0; k < actionsList.length; k++) {
                                                        if (actionsList[k] && actionsList[k].identifier === actionData.id) {
                                                            try {
                                                                actionsList[k].invoke();
                                                            } catch (e) {}
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Action / Menu & Dismiss Buttons
                    RowLayout {
                        spacing: 4
                        Layout.alignment: Qt.AlignTop

                        // 3-Dots More Options Button
                        Rectangle {
                            id: moreBtn
                            readonly property int actionCount: (notifCard.modelData && notifCard.modelData.actions) ? notifCard.modelData.actions.length : 0
                            readonly property bool isMoreFocused: notifCard.isCurrent && (root.selectedSubIndex === (actionCount + 1))

                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 12
                            scale: (isMoreFocused && InputService.isNonMouse) ? 1.25 : (moreArea.containsMouse ? 1.1 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            color: (isMoreFocused && InputService.isNonMouse)
                                ? Theme.primary
                                : (moreArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.6))
                            border.color: (isMoreFocused && InputService.isNonMouse) ? Theme.on_primary : (moreArea.containsMouse ? Theme.primary : "transparent")
                            border.width: (isMoreFocused && InputService.isNonMouse) ? 2 : 0

                            VectorIcon {
                                anchors.centerIn: parent
                                name: "dots-vertical"
                                iconSize: 13
                                color: (moreBtn.isMoreFocused && InputService.isNonMouse)
                                    ? Theme.on_primary
                                    : (moreArea.containsMouse ? Theme.primary : Theme.on_surface_variant)
                            }

                            MouseArea {
                                id: moreArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    InputService.useMouse();
                                    root.selectedIndex = index;
                                    root.selectedSubIndex = moreBtn.actionCount + 1;
                                }
                                onClicked: mouse => {
                                    if (mouse) mouse.accepted = true;
                                    InputService.useMouse();
                                    var item = notifCard.modelData;
                                    var idx = index;
                                    var pos = moreBtn.mapToItem(notifContextMenu, 0, moreBtn.height);
                                    Qt.callLater(function() {
                                        root.openContextMenuForNotifAt(pos.x, pos.y, item, idx);
                                    });
                                }
                            }
                        }

                        // Single Item Dismiss Button (X)
                        Rectangle {
                            id: dismissBtn
                            readonly property int actionCount: (notifCard.modelData && notifCard.modelData.actions) ? notifCard.modelData.actions.length : 0
                            readonly property bool isDismissFocused: notifCard.isCurrent && (root.selectedSubIndex === (actionCount + 2))

                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 12
                            scale: dismissBtn.isDismissFocused ? 1.25 : (itemDismissArea.containsMouse ? 1.1 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            color: dismissBtn.isDismissFocused ? Theme.error : (itemDismissArea.containsMouse ? Theme.error : Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.5))
                            border.color: dismissBtn.isDismissFocused ? Theme.on_error : "transparent"
                            border.width: dismissBtn.isDismissFocused ? 2.5 : 0

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: (itemDismissArea.containsMouse || dismissBtn.isDismissFocused) ? Theme.on_error : Theme.on_surface_variant
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea {
                                id: itemDismissArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    InputService.useMouse();
                                    root.selectedIndex = index;
                                    root.selectedSubIndex = dismissBtn.actionCount + 2;
                                }
                                onClicked: root.removeNotification(index)
                            }
                        }
                    }
                }
            }
        }

            // Empty State Vector Illustration
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.historyList.length === 0
                spacing: 12

                Canvas {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 44
                    implicitHeight: 44
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = Theme.outline;
                        ctx.lineWidth = 2.2;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";

                        ctx.beginPath();
                        ctx.moveTo(22, 5);
                        ctx.arcTo(34, 5, 34, 28, 12);
                        ctx.lineTo(38, 33);
                        ctx.lineTo(6, 33);
                        ctx.lineTo(10, 28);
                        ctx.arcTo(10, 5, 22, 5, 12);
                        ctx.stroke();

                        ctx.beginPath();
                        ctx.arc(22, 37, 4.5, 0, Math.PI);
                        ctx.stroke();
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "NO NOTIFICATIONS"
                    color: Theme.primary
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 2
                    font.family: Theme.fontFamilyDisplay
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "System is clear and quiet"
                    color: Theme.on_surface_variant
                    font.pixelSize: 10
                    font.family: Theme.fontFamilyMono
                }
            }
        }

        // Modular Common Context Menu for Notifications inside Flyout Window
        ContextMenu {
            id: notifContextMenu
        }
    }
}
