import QtQuick
import "../../"

// Hover-popup content: header (icon + connection label), the power toggle,
// the always-visible paired-device list (PairedDevices.qml), and a button
// to open the centered pairing dialog (PairDeviceDialog.qml) for scanning
// and pairing new devices.
Column {
    id: root
    spacing: 8

    // --- Inputs, supplied by Bluetooth.qml ---
    property string icon: ""
    property color stateColor: Theme.text
    property bool available: false
    property bool enabled: false
    property var adapter: null
    property string connectionLabel: ""
    property var devices: []
    property bool showDetails: false

    // Note: the pairing dialog (PairDeviceDialog) is intentionally NOT
    // tied to showDetails/this popup's own lifecycle. It's a separate
    // top-level surface with its own backdrop/close button; closing this
    // hover popup (e.g. by moving the mouse away right after clicking
    // "Pair new device") must not also close the dialog the user just
    // opened.

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
            text: "Bluetooth"
        }
        Text {
            id: stateText
            anchors.left: nameText.left
            anchors.top: nameText.bottom
            color: Theme.subtle
            text: root.connectionLabel
        }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.surface }

    Text {
        visible: !root.available
        color: Theme.muted
        text: "No Bluetooth adapter found"
    }

    BluetoothToggle {
        visible: root.available
        width: parent.width
        adapter: root.adapter
    }

    Rectangle {
        visible: root.available && root.enabled
        width: parent.width
        height: 1
        color: Theme.surface
    }

    // Paired devices are always shown (not behind the expand button) since
    // they don't require scanning and are the most common thing a user
    // wants to see/act on (connect/disconnect/forget).
    PairedDevices {
        visible: root.available && root.enabled
        width: parent.width
        adapter: root.adapter
    }

    // Full-width button that opens the centered pairing dialog — scanning
    // and the discovered-device list live entirely inside that dialog
    // (PairDeviceDialog.qml) instead of growing this hover popup, and
    // scanning only runs while the dialog itself is open.
    Rectangle {
        id: pairButton
        visible: root.available && root.enabled
        width: parent.width
        height: pairButtonRow.implicitHeight + 12
        radius: 6
        color: pairButtonArea.containsMouse ? Theme.highlightMed : Theme.surface

        Behavior on color { ColorAnimation { duration: 100 } }

        Row {
            id: pairButtonRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.iconFontFamily
                font.pixelSize: 16
                color: Theme.text
                text: "\ue1aa" // bluetooth_searching
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                text: "Pair new device"
            }
        }

        MouseArea {
            id: pairButtonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pairDialog.open()
        }
    }

    PairDeviceDialog {
        id: pairDialog
        adapter: root.adapter
    }
}
