import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"

// Control Center: a right-edge panel that slides in over 25% of the
// screen width, opened/closed via ControlCenterState (driven by
// ControlCenterToggle's pill in RightIsland). Content is organized into
// per-indicator SectionCard sections — see the individual Section files
// in this folder for how each one derives its state.
//
// Sliding technique: the window is always anchored top+bottom+right (full
// height, flush right) and always `visible` while animating, so it can
// actually animate; margins.right is tweened between 0 (fully on-screen)
// and -implicitWidth (fully off-screen, parked past the right edge).
// exclusionMode is Ignore since this is an overlay, not a permanently
// docked panel — it shouldn't reserve screen space like the bar does.
PanelWindow {
    id: root

    readonly property real screenWidth: screen ? screen.width : 1920
    readonly property real screenHeight: screen ? screen.height : 1080
    readonly property int panelWidth: Math.round(screenWidth * Theme.controlCenterWidthRatio)

    anchors {
        top: true
        bottom: true
        right: true
    }

    implicitWidth: panelWidth
    color: "transparent"
    // Always kept visible (not tied directly to ControlCenterState.visible)
    // so the margins.right Behavior below can actually animate the slide
    // in/out — a window that gets hidden immediately never gets to render
    // the transition. Off-screen (closed) state is achieved purely via the
    // negative right margin parking the panel past the screen edge; input
    // is also disabled while closed so it doesn't intercept clicks meant
    // for whatever's beneath the reserved strip.
    visible: true
    focusable: ControlCenterState.visible
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ControlCenterState.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "control-center"

    margins.right: ControlCenterState.visible ? 0 : -panelWidth

    Behavior on margins.right {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // Click-outside-to-close: a full-screen transparent catcher living
    // behind the panel's own content would require a second window under
    // typical layer-shell stacking; instead, closing on losing keyboard
    // focus (below) plus an Escape handler covers the common cases
    // without needing input-region trickery.
    Keys.onEscapePressed: ControlCenterState.close()

    Rectangle {
        anchors.fill: parent
        color: Theme.base
        border.width: 1
        border.color: Theme.overlay

        MouseArea {
            // Swallow clicks so they don't pass through to whatever is
            // beneath the panel.
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
        }

        Column {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Theme.controlCenterPadding
            spacing: Theme.controlCenterHeaderSpacing

            Item {
                width: parent.width
                height: Math.max(userHeader.implicitHeight, closeIcon.implicitHeight)

                UserHeader {
                    id: userHeader
                    anchors.left: parent.left
                    anchors.right: closeIcon.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: closeIcon
                    anchors.right: parent.right
                    anchors.top: parent.top
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 18
                    color: Theme.subtle
                    text: "\ue5cd" // close

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ControlCenterState.close()
                    }
                }
            }

            SessionControls { width: parent.width }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.overlay
            }
        }

        Flickable {
            id: scrollArea
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.controlCenterPadding
            anchors.topMargin: Theme.controlCenterHeaderSpacing
            clip: true
            contentWidth: width
            contentHeight: sections.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: sections
                width: parent.width
                spacing: Theme.controlCenterSectionSpacing

                ConnectivitySection { width: parent.width }
                VolumeSection { width: parent.width }
                BrightnessSection { width: parent.width }
                HardwareSection { width: parent.width }
            }
        }
    }
}
