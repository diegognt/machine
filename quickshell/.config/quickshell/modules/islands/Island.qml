import QtQuick
import "../"

// Base "island": a pure layout container that lays out indicator pills in a
// row along the bar. Manages only the horizontal spacing between the pills
// it contains; vertical sizing/positioning (spacing from the screen/bar
// edges) is the bar's job, and each pill's own internal padding is the
// indicator's job. Carries no look & feel of its own — background and
// hover behavior belong to ModulePill, applied per-indicator by
// LeftIsland/CenterIsland/RightIsland.
Item {
    id: root
    default property alias content: row.children
    property alias spacing: row.spacing

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.islandSpacing
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: "red"
    }
}
