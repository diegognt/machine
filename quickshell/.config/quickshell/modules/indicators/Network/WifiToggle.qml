import QtQuick
import Quickshell.Networking
import "../../"

// Small pill-style switch bound to Networking.wifiEnabled. Disabled/dimmed
// when the hardware radio is off (rfkill), matching the wifi hardware state
// reported by NetworkManager.
Row {
    id: root
    width: parent ? parent.width : implicitWidth
    spacing: 8

    Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.subtle
        text: "Wi-Fi"
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 18
        radius: 9
        color: Networking.wifiEnabled ? Theme.pine : Theme.surface
        opacity: Networking.wifiHardwareEnabled ? 1.0 : 0.4

        Rectangle {
            width: 14
            height: 14
            radius: 7
            color: Theme.text
            anchors.verticalCenter: parent.verticalCenter
            x: Networking.wifiEnabled ? parent.width - width - 2 : 2
            Behavior on x { NumberAnimation { duration: 120 } }
        }

        MouseArea {
            anchors.fill: parent
            enabled: Networking.wifiHardwareEnabled
            cursorShape: Qt.PointingHandCursor
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }
}
