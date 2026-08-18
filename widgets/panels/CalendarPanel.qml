import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../components"
import "../components/ModelUtils.js" as ModelUtils

Scope {
    id: calendarPanelScope

    property bool isOpen: calendarWindow.isOpen
    property alias openedFrom: calendarWindow.openedFrom
    property int calendarView: 0 // 0 = Days View, 1 = Months View, 2 = Years View
    property var selectedDate: new Date()
    property var viewDate: new Date()
    property var gridData: []

    readonly property var monthNames: ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
    readonly property var monthShortNames: ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
    readonly property var weekDayNames: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

    readonly property int decadeStart: Math.floor(viewDate.getFullYear() / 12) * 12

    function toggle() {
        if (calendarWindow.isOpen) {
            close();
        } else {
            open();
        }
    }

    function open() {
        calendarView = 0;
        selectedDate = new Date();
        viewDate = new Date();
        updateGrid();
        calendarWindow.open();
    }

    function close() {
        calendarWindow.close();
    }

    function prevPeriod() {
        if (calendarView === 0) {
            var y0 = viewDate.getFullYear();
            var m0 = viewDate.getMonth() - 1;
            viewDate = new Date(y0, m0, 1);
            updateGrid();
        } else if (calendarView === 1) {
            viewDate = new Date(viewDate.getFullYear() - 1, viewDate.getMonth(), 1);
        } else if (calendarView === 2) {
            viewDate = new Date(viewDate.getFullYear() - 12, viewDate.getMonth(), 1);
        }
    }

    function nextPeriod() {
        if (calendarView === 0) {
            var y0 = viewDate.getFullYear();
            var m0 = viewDate.getMonth() + 1;
            viewDate = new Date(y0, m0, 1);
            updateGrid();
        } else if (calendarView === 1) {
            viewDate = new Date(viewDate.getFullYear() + 1, viewDate.getMonth(), 1);
        } else if (calendarView === 2) {
            viewDate = new Date(viewDate.getFullYear() + 12, viewDate.getMonth(), 1);
        }
    }

    function resetToday() {
        calendarView = 0;
        selectedDate = new Date();
        viewDate = new Date();
        updateGrid();
    }

    function updateGrid() {
        var year = viewDate.getFullYear();
        var month = viewDate.getMonth();

        var daysInPrev = new Date(year, month, 0).getDate();
        var daysInCurr = new Date(year, month + 1, 0).getDate();

        var firstDayIndex = new Date(year, month, 1).getDay(); // 0 = Sun
        var startOffset = (firstDayIndex === 0) ? 6 : (firstDayIndex - 1); // 0 = Mon

        var grid = [];
        var today = new Date();

        // 1. Previous Month Days
        for (var i = startOffset - 1; i >= 0; i--) {
            var pDay = daysInPrev - i;
            var pDate = new Date(year, month - 1, pDay);
            grid.push({
                day: pDay,
                dateObj: pDate,
                isCurrentMonth: false,
                isToday: isSameDate(pDate, today),
                isSelected: isSameDate(pDate, selectedDate)
            });
        }

        // 2. Current Month Days
        for (var d = 1; d <= daysInCurr; d++) {
            var cDate = new Date(year, month, d);
            grid.push({
                day: d,
                dateObj: cDate,
                isCurrentMonth: true,
                isToday: isSameDate(cDate, today),
                isSelected: isSameDate(cDate, selectedDate)
            });
        }

        // 3. Next Month Days
        var nextDay = 1;
        while (grid.length < 42) {
            var nDate = new Date(year, month + 1, nextDay);
            grid.push({
                day: nextDay,
                dateObj: nDate,
                isCurrentMonth: false,
                isToday: isSameDate(nDate, today),
                isSelected: isSameDate(nDate, selectedDate)
            });
            nextDay++;
        }

        gridData = grid;
    }

    function isSameDate(d1, d2) {
        if (!d1 || !d2) return false;
        return d1.getDate() === d2.getDate() &&
               d1.getMonth() === d2.getMonth() &&
               d1.getFullYear() === d2.getFullYear();
    }

    property int selectedGridIndex: 0

    function navigateGrid(rowDelta, colDelta) {
        InputService.useKeyboard();
        if (calendarView === 0) {
            var newIdx = Math.max(0, Math.min(selectedGridIndex + (rowDelta * 7) + colDelta, 41));
            selectedGridIndex = newIdx;
            if (gridData && gridData[newIdx]) {
                selectedDate = gridData[newIdx].dateObj;
            }
        }
    }

    Connections {
        target: InputService
        enabled: calendarWindow.isOpen

        function onNavUp() {
            calendarPanelScope.navigateGrid(-1, 0);
        }
        function onNavDown() {
            calendarPanelScope.navigateGrid(1, 0);
        }
        function onNavLeft() {
            calendarPanelScope.navigateGrid(0, -1);
        }
        function onNavRight() {
            calendarPanelScope.navigateGrid(0, 1);
        }
        function onNavNextTab() {
            calendarPanelScope.nextPeriod();
        }
        function onNavPrevTab() {
            calendarPanelScope.prevPeriod();
        }
        function onNavSelect() {
            calendarPanelScope.resetToday();
        }
        function onNavBack() {
            if (calendarPanelScope.calendarView > 0) {
                calendarPanelScope.calendarView = 0;
            } else {
                InputService.closeOrReturn(calendarWindow);
            }
        }
    }

    BaseFlyoutPanel {
        id: calendarWindow
        title: "Calendar"
        iconName: "clock"
        side: "right"
        cardWidth: 380
        cardHeight: 500
        showRefresh: false
        showSwitch: false

        property var now: new Date()
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: calendarWindow.now = new Date()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 14

            // Live Digital Time & Date Banner Header Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 74
                radius: 12
                color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.7)
                border.color: Theme.outline_variant
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    VectorIcon {
                        name: "clock"
                        color: Theme.primary
                        iconSize: 24
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        Text {
                            text: Qt.formatDateTime(calendarWindow.now, "hh:mm:ss A")
                            color: Theme.primary
                            font.pixelSize: 18
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                        }

                        Text {
                            text: Qt.formatDate(calendarPanelScope.selectedDate, "dddd, MMMM d, yyyy").toUpperCase()
                            color: Theme.on_surface
                            font.pixelSize: 10
                            font.bold: true
                            font.family: Theme.fontFamilyMono
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // Month Navigation Bar with Clickable Multi-View Title
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 8
                    color: titleMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            text: calendarPanelScope.calendarView === 0
                                ? (calendarPanelScope.monthNames[calendarPanelScope.viewDate.getMonth()] + " " + calendarPanelScope.viewDate.getFullYear())
                                : (calendarPanelScope.calendarView === 1
                                    ? calendarPanelScope.viewDate.getFullYear().toString()
                                    : (calendarPanelScope.decadeStart + " - " + (calendarPanelScope.decadeStart + 11)))

                            color: titleMouse.containsMouse ? Theme.primary : Theme.on_surface
                            font.pixelSize: 13
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                        }

                        Item { Layout.fillWidth: true }
                    }

                    MouseArea {
                        id: titleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            calendarPanelScope.calendarView = (calendarPanelScope.calendarView + 1) % 3;
                        }
                    }
                }

                ActionButton {
                    text: "Today"
                    variant: "surface"
                    onClicked: calendarPanelScope.resetToday()
                }

                ActionButton {
                    iconName: "left"
                    variant: "outline"
                    onClicked: calendarPanelScope.prevPeriod()
                }

                ActionButton {
                    iconName: "right"
                    variant: "outline"
                    onClicked: calendarPanelScope.nextPeriod()
                }
            }

            // Days of Week Header Row (Only in Days View)
            RowLayout {
                visible: calendarPanelScope.calendarView === 0
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: calendarPanelScope.weekDayNames

                    delegate: Text {
                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: (index === 5 || index === 6) ? Theme.primary : Theme.secondary
                        font.pixelSize: 10
                        font.bold: true
                        font.family: Theme.fontFamilyMono
                    }
                }
            }

            // VIEW 0: 6x7 Month Calendar Grid
            GridLayout {
                visible: calendarPanelScope.calendarView === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                rows: 6
                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: calendarPanelScope.gridData

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8

                        color: modelData.isToday
                            ? Theme.primary
                            : (modelData.isSelected
                                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                                : (dayMouse.containsMouse ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.6) : "transparent"))

                        border.color: modelData.isSelected && !modelData.isToday ? Theme.primary : "transparent"
                        border.width: modelData.isSelected && !modelData.isToday ? 1.5 : 0

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day.toString()
                            color: modelData.isToday
                                ? Theme.on_primary
                                : (modelData.isCurrentMonth
                                    ? (modelData.isSelected ? Theme.primary : Theme.on_surface)
                                    : Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.4))
                            font.pixelSize: 11
                            font.bold: modelData.isToday || modelData.isSelected
                            font.family: Theme.fontFamilyDisplay
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                calendarPanelScope.selectedDate = modelData.dateObj;
                                calendarPanelScope.updateGrid();
                            }
                        }
                    }
                }
            }

            // VIEW 1: 3x4 Months Selector Grid
            GridLayout {
                visible: calendarPanelScope.calendarView === 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 4
                rows: 3
                rowSpacing: 8
                columnSpacing: 8

                Repeater {
                    model: calendarPanelScope.monthShortNames

                    delegate: Rectangle {
                        required property string modelData
                        required property int index

                        readonly property bool isCurrentMonth: index === (new Date()).getMonth() && calendarPanelScope.viewDate.getFullYear() === (new Date()).getFullYear()
                        readonly property bool isSelectedMonth: index === calendarPanelScope.viewDate.getMonth()

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10

                        color: isCurrentMonth
                            ? Theme.primary
                            : (isSelectedMonth
                                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                                : (monthMouse.containsMouse ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.6) : Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g, Theme.surface_container_low.b, 0.5)))

                        border.color: isSelectedMonth && !isCurrentMonth ? Theme.primary : Theme.outline_variant
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: isCurrentMonth ? Theme.on_primary : (isSelectedMonth ? Theme.primary : Theme.on_surface)
                            font.pixelSize: 13
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                        }

                        MouseArea {
                            id: monthMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                calendarPanelScope.viewDate = new Date(calendarPanelScope.viewDate.getFullYear(), index, 1);
                                calendarPanelScope.calendarView = 0;
                                calendarPanelScope.updateGrid();
                            }
                        }
                    }
                }
            }

            // VIEW 2: 3x4 Years Selector Grid (Decade View)
            GridLayout {
                visible: calendarPanelScope.calendarView === 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 4
                rows: 3
                rowSpacing: 8
                columnSpacing: 8

                Repeater {
                    model: 12

                    delegate: Rectangle {
                        required property int index
                        readonly property int yearVal: calendarPanelScope.decadeStart + index
                        readonly property bool isCurrentYear: yearVal === (new Date()).getFullYear()
                        readonly property bool isSelectedYear: yearVal === calendarPanelScope.viewDate.getFullYear()

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10

                        color: isCurrentYear
                            ? Theme.primary
                            : (isSelectedYear
                                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                                : (yearMouse.containsMouse ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.6) : Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g, Theme.surface_container_low.b, 0.5)))

                        border.color: isSelectedYear && !isCurrentYear ? Theme.primary : Theme.outline_variant
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: yearVal.toString()
                            color: isCurrentYear ? Theme.on_primary : (isSelectedYear ? Theme.primary : Theme.on_surface)
                            font.pixelSize: 13
                            font.bold: true
                            font.family: Theme.fontFamilyDisplay
                        }

                        MouseArea {
                            id: yearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                calendarPanelScope.viewDate = new Date(yearVal, calendarPanelScope.viewDate.getMonth(), 1);
                                calendarPanelScope.calendarView = 1;
                            }
                        }
                    }
                }
            }
        }
    }
}
