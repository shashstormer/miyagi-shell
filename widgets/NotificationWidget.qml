import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import "../theme"

Item {
    id: notifWidgetRoot

    property var notifServer: null

    // Decoupled JS array model for active toast popups
    property var activePopups: []

    readonly property alias contentHeight: popupList.contentHeight

    Connections {
        target: notifWidgetRoot.notifServer
        ignoreUnknownSignals: true

        function onNotification(notification) {
            if (!notification) return;

            var rawAppName = notification.appName ? notification.appName.trim().toUpperCase() : "SYSTEM";
            var isBlocked = ConfigService.isAppBlocked(rawAppName);
            var isSilent = ConfigService.isAppSilent(rawAppName);

            // Both Silent and Blocked notifications must NOT show popup toasts
            if (isBlocked || isSilent) {
                return;
            }

            notification.tracked = true;

            var notifId = notification.id || Math.floor(Math.random() * 100000);

            // Close notification when sending app requests close via D-Bus
            try {
                if (notification.closed) {
                    notification.closed.connect(function() {
                        notifWidgetRoot.dismissById(notifId);
                    });
                }
            } catch (e) {}

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

            var currentPopups = notifWidgetRoot.activePopups.slice();
            var timeoutVal = notification.expireTimeout === 0 ? 0 : (notification.expireTimeout > 0 ? notification.expireTimeout : 5000);

            // Add new notification popup item to array model
            currentPopups.unshift({
                id: notifId,
                appName: notification.appName ? notification.appName.toUpperCase() : "SYSTEM",
                summary: notification.summary ? notification.summary : "Notification",
                body: notification.body ? notification.body : "",
                image: (notification.image || notification.appIcon) ? (notification.image || notification.appIcon) : "",
                urgency: notification.urgency,
                timeout: timeoutVal,
                actions: extractedActions,
                notifObj: notification
            });

            notifWidgetRoot.activePopups = currentPopups;
        }
    }

    function focusApp(appName) {
        ConfigService.focusApp(appName);
    }

    // Safely remove popup card from UI stack by unique ID
    function dismissById(targetId) {
        if (!targetId) return;
        activePopups = activePopups.filter(function(item) {
            return item && item.id !== targetId;
        });
    }

    function dismissPopup(idx) {
        if (idx >= 0 && idx < activePopups.length && activePopups[idx]) {
            dismissById(activePopups[idx].id);
        }
    }

    ListView {
        id: popupList
        anchors.fill: parent
        model: notifWidgetRoot.activePopups
        spacing: 10
        interactive: false
        clip: false

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 300; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x"; from: 100; to: 0; duration: 300; easing.type: Easing.OutCubic }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0.0; duration: 250; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x"; to: 100; duration: 250; easing.type: Easing.OutCubic }
            }
        }

        displaced: Transition {
            NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutCubic }
        }

        delegate: Rectangle {
            id: toastCard
            required property var modelData
            required property int index

            width: ListView.view.width
            implicitHeight: cardContent.implicitHeight + 20
            radius: 10
            color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 0.94)
            border.color: (modelData && modelData.urgency === NotificationUrgency.Critical) ? Theme.error : Theme.primary
            border.width: 1.5
            clip: true

            // Auto-dismiss timer (respecting expireTimeout === 0)
            Timer {
                interval: (modelData && modelData.timeout > 0) ? modelData.timeout : 5000
                running: modelData && modelData.timeout > 0
                repeat: false
                onTriggered: {
                    if (toastCard.modelData && toastCard.modelData.id) {
                        notifWidgetRoot.dismissById(toastCard.modelData.id);
                    }
                }
            }

            RowLayout {
                id: cardContent
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // Left Notification Icon Badge
                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 6
                    color: Theme.primary_container
                    clip: true
                    Layout.alignment: Qt.AlignTop

                    Image {
                        id: iconImage
                        anchors.fill: parent
                        source: {
                            if (!modelData || !modelData.image) return "";
                            var img = modelData.image;
                            if (img.startsWith("/") || img.startsWith("file://") || img.startsWith("http://") || img.startsWith("https://")) {
                                return img;
                            }
                            return "image://icon/" + img;
                        }
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                        asynchronous: true
                    }

                    // Vector Canvas Bell Icon (matching Launcher vector style)
                    Canvas {
                        id: bellCanvas
                        anchors.centerIn: parent
                        implicitWidth: 18
                        implicitHeight: 18
                        visible: iconImage.status !== Image.Ready
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = Theme.primary;
                            ctx.lineWidth = 1.6;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";

                            // Bell body dome
                            ctx.beginPath();
                            ctx.moveTo(9, 2);
                            ctx.arcTo(14, 2, 14, 11, 5);
                            ctx.lineTo(16, 13);
                            ctx.lineTo(2, 13);
                            ctx.lineTo(4, 11);
                            ctx.arcTo(4, 2, 9, 2, 5);
                            ctx.stroke();

                            // Bell clapper arc
                            ctx.beginPath();
                            ctx.arc(9, 14.5, 2, 0, Math.PI);
                            ctx.stroke();
                        }
                    }
                }

                // Text Content & Action Buttons Stack
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        Layout.fillWidth: true
                        text: modelData ? modelData.appName : ""
                        color: Theme.secondary
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1
                        font.family: Theme.fontFamilyMono
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData ? modelData.summary : ""
                        color: (modelData && modelData.urgency === NotificationUrgency.Critical) ? Theme.error : Theme.primary
                        font.pixelSize: 13
                        font.bold: true
                        font.family: Theme.fontFamilyMono
                        wrapMode: Text.Wrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData ? modelData.body : ""
                        color: Theme.on_surface_variant
                        font.pixelSize: 10
                        font.family: Theme.fontFamilyMono
                        wrapMode: Text.Wrap
                        visible: text.length > 0
                    }

                    // Interactive Action Buttons
                    RowLayout {
                        spacing: 6
                        visible: modelData && modelData.actions && modelData.actions.length > 0

                        Repeater {
                            model: modelData ? modelData.actions : []

                            delegate: Rectangle {
                                id: actionBtn
                                required property var modelData

                                implicitWidth: actionText.implicitWidth + 12
                                implicitHeight: 22
                                radius: 4
                                color: actionArea.containsMouse ? Theme.primary_fixed : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.8)
                                border.color: Theme.primary
                                border.width: 1

                                Text {
                                    id: actionText
                                    anchors.centerIn: parent
                                    text: modelData.text
                                    color: actionArea.containsMouse ? Theme.on_primary_fixed : Theme.primary
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.family: Theme.fontFamilyMono
                                }

                                MouseArea {
                                    id: actionArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var actionData = modelData;
                                        var notifItem = toastCard.modelData;

                                        if (notifItem && notifItem.notifObj) {
                                            try {
                                                var actionsList = notifItem.notifObj.actions;
                                                if (actionsList) {
                                                    for (var k = 0; k < actionsList.length; k++) {
                                                        if (actionsList[k] && actionsList[k].identifier === actionData.id) {
                                                            actionsList[k].invoke();
                                                            break;
                                                        }
                                                    }
                                                }
                                            } catch (e) {}
                                        }
                                        if (typeof notifWidgetRoot !== "undefined" && notifWidgetRoot && notifItem) {
                                            if (notifItem.appName) notifWidgetRoot.focusApp(notifItem.appName);
                                            if (notifItem.id) notifWidgetRoot.dismissById(notifItem.id);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Dismiss Button
                Rectangle {
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 10
                    color: closeArea.containsMouse ? Theme.error : Qt.rgba(Theme.surface_container_lowest.r, Theme.surface_container_lowest.g, Theme.surface_container_lowest.b, 0.5)
                    Layout.alignment: Qt.AlignTop
                    z: 10

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeArea.containsMouse ? Theme.on_error : Theme.on_surface_variant
                        font.pixelSize: 9
                        font.bold: true
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (toastCard.modelData && toastCard.modelData.id) {
                                notifWidgetRoot.dismissById(toastCard.modelData.id);
                            }
                        }
                    }
                }
            }

            // Clickable Toast Card Body
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                z: -1
                onClicked: {
                    var notifItem = toastCard.modelData;
                    if (notifItem) {
                        if (notifItem.notifObj) {
                            try {
                                var actionsList = notifItem.notifObj.actions;
                                if (actionsList && actionsList.length > 0) {
                                    actionsList[0].invoke();
                                }
                            } catch (e) {}
                        }
                        if (typeof notifWidgetRoot !== "undefined" && notifWidgetRoot) {
                            if (notifItem.appName) notifWidgetRoot.focusApp(notifItem.appName);
                            if (notifItem.id) notifWidgetRoot.dismissById(notifItem.id);
                        }
                    }
                }
            }
        }
    }
}
