import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Bluetooth
import "../../"

// Native, macOS-style "Pair new device" modal — mirrors
// WifiConnectDialog.qml's full-screen, centered top-level surface instead
// of an inline expand-in-popup list, so scanning results get a proper
// scrollable/pop-out home rather than growing the hover popup. Drives
// `adapter.discovering` for as long as it's open, and closes it again on
// close so the radio doesn't keep scanning in the background.
//
// Quickshell.Bluetooth doesn't register a BlueZ pairing agent of its own
// (see quickshell-mirror/quickshell#138, closed/unmerged), so device.pair()
// has nothing to answer BlueZ's RequestConfirmation/RequestPasskey/
// Authorize callbacks — pairing silently fails for any device that needs
// one. Fix: spawn `bt-agent` (from bluez-tools) as a NoInputNoOutput agent
// for the lifetime of this dialog only, so "Just Works"-style pairing (the
// vast majority of headphones/mice/keyboards) succeeds without a PIN
// prompt, and the agent goes away again as soon as the dialog closes.
PanelWindow {
    id: dialog

    property var adapter: null

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: false
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Registered/unregistered by simply toggling `running`, tied 1:1 to
    // the dialog's own open()/close() below.
    Process {
        id: pairingAgent
        command: ["bt-agent", "--capability=NoInputNoOutput"]
    }

    readonly property var allDevices: adapter ? adapter.devices.values : []
    // Only devices that (a) aren't already paired/bonded and (b) advertise
    // an actual human-readable name — i.e. not blank, and not merely their
    // own MAC address parroted back (some BlueZ backends fall back to
    // that when no name/alias is set). Filters out the usual clutter of
    // anonymous nearby devices (random BLE beacons, etc.) that are useless
    // to pair with anyway since they can't be told apart.
    readonly property var pairableDevices: allDevices.filter(d => {
        if (d.paired || d.bonded) return false;
        return dialog.hasHumanReadableName(d);
    })

    function hasHumanReadableName(device) {
        const raw = (device.name || device.deviceName || "").trim();
        if (raw.length === 0) return false;
        // BlueZ/hardware MAC-as-name fallback, e.g. "CF:0B:0D:70:2D:D9" or
        // "CF-0B-0D-70-2D-D9" or "CF0B0D702DD9".
        if (/^[0-9A-Fa-f]{2}([:\-]?[0-9A-Fa-f]{2}){5}$/.test(raw)) return false;
        return true;
    }

    function displayName(device) {
        let raw = device.name || device.deviceName || "";
        raw = raw.trim().replace(/_/g, " ").replace(/\s+/g, " ");
        return raw;
    }

    function iconGlyph(device) {
        const icon = device.icon || "";
        if (icon.indexOf("headset") >= 0 || icon.indexOf("headphone") >= 0) return "\ue60f"; // headset
        if (icon.indexOf("audio") >= 0 || icon.indexOf("speaker") >= 0) return "\ue050";      // speaker
        if (icon.indexOf("input-mouse") >= 0) return "\ue323";                                // mouse
        if (icon.indexOf("input-keyboard") >= 0) return "\ue312";                             // keyboard
        if (icon.indexOf("phone") >= 0) return "\ue0cd";                                      // smartphone
        return "\ue1a7"; // generic bluetooth
    }

    function open() {
        visible = true;
        pairingAgent.running = true;
        if (adapter) adapter.discovering = true;
    }

    function close() {
        visible = false;
        pairingAgent.running = false;
        if (adapter) adapter.discovering = false;
    }

    // Dimmed backdrop — click outside the card to close.
    Rectangle {
        anchors.fill: parent
        color: "#B0000000"

        MouseArea {
            anchors.fill: parent
            onClicked: dialog.close()
        }
    }

    // Card
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 360
        implicitHeight: content.implicitHeight + 32
        radius: 12
        color: Theme.base
        border.width: 2
        border.color: Theme.overlay

        // Swallow clicks so they don't fall through to the backdrop.
        MouseArea { anchors.fill: parent }

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.iconFontFamily
                font.pixelSize: 40
                color: Theme.foam
                text: "\ue1aa" // bluetooth_searching
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Theme.text
                font.pixelSize: 14
                font.bold: true
                text: "Pair a new device"
            }

            Text {
                visible: dialog.adapter && dialog.adapter.discovering
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: Theme.subtle
                font.pixelSize: 12
                text: "Scanning…"
            }

            ListView {
                id: deviceListView
                width: parent.width
                height: Math.min(Math.max(contentHeight, 40), 260)
                clip: true
                interactive: contentHeight > height
                spacing: 6
                model: dialog.pairableDevices

                delegate: Rectangle {
                    id: delegateRoot
                    required property var modelData

                    width: deviceListView.width
                    height: rowContent.implicitHeight + 8
                    radius: 6
                    color: "transparent"

                    Row {
                        id: rowContent
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: pairAction.left
                        anchors.margins: 4
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.iconFontFamily
                            color: Theme.subtle
                            text: dialog.iconGlyph(delegateRoot.modelData)
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.text
                            text: dialog.displayName(delegateRoot.modelData)
                            elide: Text.ElideRight
                            width: 180
                        }
                    }

                    // Auto-connect once pairing finishes successfully. Pairing
                    // and connecting are two separate BlueZ operations, but from
                    // the user's perspective clicking "Pair" should be the only
                    // step needed to start using the device. Also marks it
                    // trusted so it reconnects automatically in the future
                    // (e.g. on power-on) without going through this dialog again.
                    Connections {
                        target: delegateRoot.modelData
                        function onPairingChanged() {
                            const device = delegateRoot.modelData;
                            if (!device.pairing && device.paired && !device.connected) {
                                device.trusted = true;
                                device.connect();
                            }
                        }
                    }

                    Rectangle {
                        id: pairAction
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.margins: 4
                        width: pairLabel.implicitWidth + 12
                        height: pairLabel.implicitHeight + 6
                        radius: 6
                        color: pairMouse.containsMouse ? Theme.highlightHigh : Theme.surface

                        Text {
                            id: pairLabel
                            anchors.centerIn: parent
                            color: Theme.text
                            text: {
                                const d = delegateRoot.modelData;
                                if (d.pairing) return "Pairing…";
                                if (d.paired && d.state === BluetoothDeviceState.Connecting) return "Connecting…";
                                return "Pair";
                            }
                        }

                        MouseArea {
                            id: pairMouse
                            anchors.fill: parent
                            enabled: !delegateRoot.modelData.pairing && delegateRoot.modelData.state !== BluetoothDeviceState.Connecting
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: delegateRoot.modelData.pair()
                        }
                    }
                }
            }

            Text {
                visible: dialog.pairableDevices.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Theme.muted
                font.pixelSize: 12
                text: (dialog.adapter && dialog.adapter.discovering)
                    ? "No nameable devices found yet…"
                    : "No devices found"
            }

            Row {
                width: parent.width
                layoutDirection: Qt.RightToLeft

                Rectangle {
                    width: 72
                    height: 28
                    radius: 6
                    color: Theme.surface

                    Text {
                        anchors.centerIn: parent
                        color: Theme.text
                        text: "Close"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dialog.close()
                    }
                }
            }
        }
    }
}
