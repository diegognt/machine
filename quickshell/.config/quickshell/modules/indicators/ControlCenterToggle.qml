import QtQuick
import "../"

// Bar entry point for the Control Center: a single icon-only indicator,
// last in RightIsland, that toggles ControlCenterState (which the
// ControlCenter PanelWindow itself, instantiated separately in shell.qml,
// reacts to). Unlike the other indicators this opens on click rather than
// hover, and has no hover-popup of its own — the "popup" is the full
// slide-in side panel.
IndicatorIcon {
    id: root
    text: "\ue8b8" // settings
    color: ControlCenterState.visible ? Theme.iris : Theme.text

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ControlCenterState.toggle()
    }
}
