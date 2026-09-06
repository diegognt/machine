import QtQuick
import "../"

// Base "island": a pure layout container that lays out indicator pills in a
// row along the bar. Carries no look & feel of its own — background,
// border, and hover behavior belong to ModulePill, applied per-indicator by
// LeftIsland/CenterIsland/RightIsland.
Row {
    id: root
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.islandSpacing
}
