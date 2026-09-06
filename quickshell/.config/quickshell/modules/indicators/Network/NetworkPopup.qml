import QtQuick
import Quickshell.Networking
import "../../"

// Hover-popup content: header (icon + name + connectivity state), wifi/wired
// detail lines, the Wi-Fi radio toggle, and the nmcli-backed network list.
// Kept separate from Network.qml so the PopupWindow's content can be
// iterated on independently of the bar-label/hover-open mechanics.
Column {
    id: root
    spacing: 8

    // --- Inputs, supplied by Network.qml ---
    property string icon: ""
    property color stateColor: Theme.text
    property string connectionName: ""
    property string connectivityLabel: ""
    property bool wifiConnected: false
    property bool wiredConnected: false
    property real signalStrength: 0
    property bool secured: false
    property var wifiDevice: null
    property var wiredDevice: null
    property bool showDetails: false

    // Network list is opt-in: collapsed by default, expanded via the
    // "Available networks" row below. Collapses again whenever the popup
    // itself closes, so it always starts fresh next time.
    property bool networksExpanded: false
    onShowDetailsChanged: if (!showDetails) networksExpanded = false

    // Item {} instead of Row so the icon can span the full two-line height,
    // vertically centered next to the connection name + status text.
    Item {
        width: parent.width
        height: nameText.height + stateText.height

        Text {
            id: headerIcon
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.iconFontFamily
            font.pixelSize: 32
            color: root.stateColor
            text: root.icon
        }

        Text {
            id: nameText
            anchors.left: headerIcon.right
            anchors.leftMargin: 8
            anchors.top: parent.top
            color: Theme.text
            font.pixelSize: 16
            font.bold: true
            text: root.connectionName || "Not connected"
        }
        Text {
            id: stateText
            anchors.left: nameText.left
            anchors.top: nameText.bottom
            color: Theme.subtle
            text: root.connectivityLabel
        }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.surface }

    // Wifi details
    Text {
        visible: root.wifiConnected
        color: Theme.text
        text: "Signal: " + Math.round(root.signalStrength) + "%"
    }
    Text {
        visible: root.wifiConnected
        color: Theme.text
        text: "Security: " + (root.secured ? "Secured" : "Open")
    }

    // Wired details
    Text {
        visible: root.wiredConnected
        color: Theme.text
        text: "Link speed: " + (root.wiredDevice ? root.wiredDevice.linkSpeed : 0) + " Mbps"
    }

    Rectangle {
        visible: !!root.wifiDevice
        width: parent.width
        height: 1
        color: Theme.surface
    }

    WifiToggle {
        visible: !!root.wifiDevice
        width: parent.width
    }

    // Full-width click-to-reveal button instead of always showing the
    // scanned network list at a glance.
    Rectangle {
        id: expandButton
        visible: !!root.wifiDevice && Networking.wifiEnabled
        width: parent.width
        height: expandButtonRow.implicitHeight + 12
        radius: 6
        color: expandButtonArea.containsMouse ? Theme.highlightMed : Theme.surface

        Behavior on color { ColorAnimation { duration: 100 } }

        Row {
            id: expandButtonRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.iconFontFamily
                font.pixelSize: 16
                color: Theme.text
                text: root.networksExpanded ? "\ue313" : "\ue315" // keyboard_arrow_down/right
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                text: "Available networks"
            }
        }

        MouseArea {
            id: expandButtonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.networksExpanded = !root.networksExpanded
        }
    }

    // Native nmcli-backed Wi-Fi network browser (scan, list, connect,
    // password modal), independent of Quickshell.Networking's own network
    // list. Only mounted/scanning once the user opts in above.
    WifiNetworkList {
        visible: root.networksExpanded && !!root.wifiDevice && Networking.wifiEnabled
        width: parent.width
        active: root.showDetails && root.networksExpanded && !!root.wifiDevice && Networking.wifiEnabled
    }
}
