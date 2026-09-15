pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../"

// Session/power-management row, directly below UserHeader: Lock, Logout,
// Suspend, Reboot, Shutdown. Fire-and-forget via Quickshell.execDetached
// (no need to track process state/output, unlike e.g. brightnessctl writes
// in BrightnessSection.qml which debounce rapid slider drags) — mirrors
// the commands already used by hypridle.conf/keybindings.lua so behavior
// stays consistent with the rest of this Hyprland config.
Row {
    id: root
    width: parent ? parent.width : implicitWidth
    spacing: 8

    readonly property var actions: [
        { icon: "\ue897", label: "Lock",     command: ["loginctl", "lock-session"] },
        { icon: "\ue9ba", label: "Logout",   command: ["hyprctl", "dispatch", "exit"] },
        { icon: "\uf6b3", label: "Suspend",  command: ["systemctl", "suspend"] },
        { icon: "\ue042", label: "Reboot",   command: ["systemctl", "reboot"] },
        { icon: "\ue8ac", label: "Shutdown", command: ["systemctl", "poweroff"] },
    ]

    readonly property real buttonSize: (width - spacing * (actions.length - 1)) / actions.length

    Repeater {
        model: root.actions

        delegate: Rectangle {
            id: button
            required property var modelData

            width: root.buttonSize
            height: root.buttonSize
            radius: 12
            color: buttonArea.containsMouse ? Theme.highlightMed : Theme.surface

            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }

            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 18
                    color: Theme.text
                    text: button.modelData.icon
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 10
                    color: Theme.subtle
                    text: button.modelData.label
                }
            }

            MouseArea {
                id: buttonArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(button.modelData.command)
            }
        }
    }
}
