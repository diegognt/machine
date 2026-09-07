import QtQuick
import "../../"

// Small pill-style switch bound to adapter.enabled, mirrors WifiToggle.qml.
// Disabled/dimmed when there's no adapter available at all.
Row {
    id: root
    width: parent ? parent.width : implicitWidth
    spacing: 8

    property var adapter: null
    readonly property bool available: !!adapter

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.subtle
        text: "Bluetooth"
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 18
        radius: 9
        color: (root.available && root.adapter.enabled) ? Theme.pine : Theme.surface
        opacity: root.available ? 1.0 : 0.4

        Rectangle {
            width: 14
            height: 14
            radius: 7
            color: Theme.text
            anchors.verticalCenter: parent.verticalCenter
            x: (root.available && root.adapter.enabled) ? parent.width - width - 2 : 2
            Behavior on x { NumberAnimation { duration: 120 } }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.available
            cursorShape: Qt.PointingHandCursor
            onClicked: root.adapter.enabled = !root.adapter.enabled
        }
    }
}
