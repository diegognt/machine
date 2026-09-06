import Quickshell
import QtQuick
import "./islands"

// Top bar shell: transparent panel hosting three islands (left, center,
// right), each a floating pill of indicator modules.
PanelWindow {
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: Theme.barBackground

    LeftIsland {}
    CenterIsland {}
    RightIsland {}
}
