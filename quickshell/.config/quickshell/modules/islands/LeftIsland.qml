import QtQuick
import "../"
import "../indicators"

// Left island — empty for now, add indicators here as needed. Each
// indicator should be wrapped in its own ModulePill for background/border.
Island {
    id: root
    anchors.left: parent.left
    anchors.leftMargin: Theme.barEdgeMargin
}
