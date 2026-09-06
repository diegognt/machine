import QtQuick
import "../"
import "../indicators"

// Center island — Hyprland workspace indicator.
Island {
    id: root
    anchors.horizontalCenter: parent.horizontalCenter

    ModulePill {
        spacing: Theme.spacingMedium
        Workspaces {}
    }
}
