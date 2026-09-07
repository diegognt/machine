import QtQuick
import Quickshell.Io
import "../../"

// Hover-popup content for the Calendar indicator: month header, a
// Mon-Sun week-day grid with today highlighted, and a couple of small
// "system" facts (week number, uptime) below. Kept separate from
// Calendar.qml so the popup's content can be iterated on independently
// of the bar-label/hover-open mechanics (mirrors NetworkPopup.qml).
Column {
    id: root
    spacing: 8

    // --- Inputs, supplied by Calendar.qml ---
    property date today: new Date()

    readonly property int viewYear: today.getFullYear()
    readonly property int viewMonth: today.getMonth() // 0-11

    readonly property var dayNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // ISO week number for `today`.
    function isoWeekNumber(date) {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        const dayNum = (d.getUTCDay() + 6) % 7; // Mon=0 .. Sun=6
        d.setUTCDate(d.getUTCDate() - dayNum + 3);
        const firstThursday = new Date(Date.UTC(d.getUTCFullYear(), 0, 4));
        const weekNum = 1 + Math.round(((d - firstThursday) / 86400000 - 3 + ((firstThursday.getUTCDay() + 6) % 7)) / 7);
        return weekNum;
    }

    // Flat list of 42 cells (6 weeks) covering the full month, padded with
    // the tail of the previous month and the head of the next so the grid
    // is always a full rectangle. Each entry: { day, inMonth, isToday }.
    readonly property var cells: {
        const firstOfMonth = new Date(viewYear, viewMonth, 1);
        // getDay(): 0=Sun..6=Sat -> convert to Mon=0..Sun=6
        const leadingBlanks = (firstOfMonth.getDay() + 6) % 7;
        const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
        const daysInPrevMonth = new Date(viewYear, viewMonth, 0).getDate();

        const list = [];
        for (let i = leadingBlanks - 1; i >= 0; i--) {
            list.push({ day: daysInPrevMonth - i, inMonth: false, isToday: false });
        }
        for (let d = 1; d <= daysInMonth; d++) {
            list.push({
                day: d,
                inMonth: true,
                isToday: d === today.getDate(),
            });
        }
        while (list.length < 42) {
            list.push({ day: list.length - (leadingBlanks + daysInMonth) + 1, inMonth: false, isToday: false });
        }
        return list;
    }

    // --- Header: month name + year ---
    Text {
        color: Theme.text
        font.pixelSize: 16
        font.bold: true
        text: Qt.formatDate(root.today, "MMMM yyyy")
    }

    Text {
        color: Theme.subtle
        text: "Week " + root.isoWeekNumber(root.today)
    }

    Rectangle { width: parent.width; height: 1; color: Theme.surface }

    // --- Day-of-week header row ---
    Grid {
        columns: 7
        rowSpacing: 4
        columnSpacing: 4
        width: parent.width

        Repeater {
            model: root.dayNames
            delegate: Text {
                required property string modelData
                width: (root.width - 6 * 4) / 7
                horizontalAlignment: Text.AlignHCenter
                color: Theme.muted
                font.pixelSize: 12
                text: modelData
            }
        }
    }

    // --- Month grid ---
    Grid {
        columns: 7
        rowSpacing: 4
        columnSpacing: 4
        width: parent.width

        Repeater {
            model: root.cells
            delegate: Rectangle {
                required property var modelData
                width: (root.width - 6 * 4) / 7
                height: width
                radius: width / 2
                color: modelData.isToday ? Theme.iris : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: modelData.day
                    font.pixelSize: 12
                    color: modelData.isToday
                        ? Theme.base
                        : (modelData.inMonth ? Theme.text : Theme.muted)
                }
            }
        }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.surface }

    // --- System facts ---
    Text {
        id: uptimeText
        color: Theme.subtle
        text: "Uptime: —"
    }

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: uptimeText.text = "Uptime: " + this.text.trim().replace(/^up /, "")
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimeProc.running = true
    }

    // --- Agenda stub ---
    // Placeholder for a future events feed (e.g. khal/gcalcli-backed
    // Process, mirroring WifiNetworkList.qml's opt-in expand pattern).
    // Text {
    //     color: Theme.subtle
    //     text: "No events today"
    // }
}
