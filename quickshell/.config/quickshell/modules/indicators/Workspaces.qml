import QtQuick
import Quickshell.Hyprland
import "../"

// Hyprland workspace indicator dots (content only — no background;
// meant to be placed inside an Island).
//
// States:
// - normal   (empty, not focused):        outlined circle
// - active   (currently focused ws):       filled circle (pine)
// - occupied (has windows, not focused):   filled circle (subtle/muted)
// - urgent   (window requesting attention): filled circle (love/red)
Row {
    id: root
    spacing: 10

    // Sorted list of real (non-special) workspaces, reactive to Hyprland IPC updates.
    readonly property var sortedWorkspaces: {
        let arr = Hyprland.workspaces.values.filter(ws => ws.id > 0);
        arr.sort((a, b) => a.id - b.id);
        return arr;
    }

    Repeater {
        model: root.sortedWorkspaces

        delegate: Rectangle {
            id: dot
            required property var modelData

            readonly property bool active: modelData.active
            readonly property bool urgent: modelData.urgent
            readonly property bool occupied: modelData.toplevels.values.length > 0

            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: width / 2

            color: urgent ? Theme.love
                 : active ? Theme.pine
                 : occupied ? Theme.subtle
                 : "transparent"

            border.width: (active || urgent || occupied) ? 0 : 2
            border.color: Theme.subtle

            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: dot.modelData.activate()
            }
        }
    }
}
