import QtQuick
import Quickshell.Bluetooth
import "../../"

// Paired/bonded device list — always visible whenever the adapter is on,
// independent of the scan-for-new-devices flow (DeviceList.qml). These are
// devices you've already paired with previously, so they're shown
// unconditionally rather than behind an expand-to-reveal button.
Column {
    id: root
    width: parent.width
    spacing: 6

    property var adapter: null

    readonly property var pairedDevices: {
        const devices = adapter ? adapter.devices.values : [];
        return devices.filter(d => d.paired || d.bonded);
    }

    // Prefer the user-facing alias (BlueZ "Alias", writable) over the raw
    // advertised hardware name (BlueZ "Name", read-only) since a custom
    // rename should always win. Falls back further to the address itself
    // only for devices that haven't reported any name yet. Also normalizes
    // common raw-name noise (stray underscores, doubled whitespace) so
    // hardware-provided names read more like a product name than a
    // firmware string.
    function displayName(device) {
        let raw = device.name || device.deviceName || "";
        raw = raw.trim().replace(/_/g, " ").replace(/\s+/g, " ");
        return raw.length > 0 ? raw : device.address;
    }

    function iconGlyph(device) {
        // Fallback glyph set keyed on BlueZ's own icon hint (freedesktop
        // icon naming spec, e.g. "audio-headset", "input-mouse").
        const icon = device.icon || "";
        if (icon.indexOf("headset") >= 0 || icon.indexOf("headphone") >= 0) return "\ue60f"; // headset
        if (icon.indexOf("audio") >= 0 || icon.indexOf("speaker") >= 0) return "\ue050";      // speaker
        if (icon.indexOf("input-mouse") >= 0) return "\ue323";                                // mouse
        if (icon.indexOf("input-keyboard") >= 0) return "\ue312";                             // keyboard
        if (icon.indexOf("phone") >= 0) return "\ue0cd";                                      // smartphone
        return "\ue1a7"; // generic bluetooth
    }

    function stateLabel(device) {
        switch (device.state) {
        case BluetoothDeviceState.Connected: return "Connected";
        case BluetoothDeviceState.Connecting: return "Connecting…";
        case BluetoothDeviceState.Disconnecting: return "Disconnecting…";
        default: return device.pairing ? "Pairing…" : "";
        }
    }

    Text {
        visible: root.pairedDevices.length > 0
        color: Theme.subtle
        text: "Paired devices"
    }

    // Capped height + scroll instead of letting the popup grow unbounded
    // with the device count (mirrors WifiNetworkList.qml's ListView).
    ListView {
        id: pairedList
        width: root.width
        height: Math.min(contentHeight, 180)
        clip: true
        interactive: contentHeight > height
        spacing: 6
        model: root.pairedDevices

        delegate: Rectangle {
            id: delegateRoot
            required property var modelData

            width: pairedList.width
            height: rowContent.implicitHeight + 8
            radius: 6
            color: modelData.connected ? Theme.highlightMed : "transparent"

            Row {
                id: rowContent
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: actionArea.left
                anchors.margins: 4
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.iconFontFamily
                    color: Theme.text
                    text: root.iconGlyph(delegateRoot.modelData)
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        color: Theme.text
                        text: root.displayName(delegateRoot.modelData)
                        elide: Text.ElideRight
                        width: 140
                    }
                    Text {
                        visible: root.stateLabel(delegateRoot.modelData).length > 0 || delegateRoot.modelData.batteryAvailable
                        color: Theme.subtle
                        text: {
                            const parts = [];
                            const s = root.stateLabel(delegateRoot.modelData);
                            if (s) parts.push(s);
                            if (delegateRoot.modelData.batteryAvailable)
                                parts.push(Math.round(delegateRoot.modelData.battery * 100) + "%");
                            return parts.join(" · ");
                        }
                    }
                }
            }

            Row {
                id: actionArea
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.margins: 4
                spacing: 4

                Rectangle {
                    width: connectLabel.implicitWidth + 12
                    height: connectLabel.implicitHeight + 6
                    radius: 6
                    color: connectMouse.containsMouse ? Theme.highlightHigh : Theme.surface

                    Text {
                        id: connectLabel
                        anchors.centerIn: parent
                        color: Theme.text
                        text: delegateRoot.modelData.connected ? "Disconnect" : "Connect"
                    }

                    MouseArea {
                        id: connectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (delegateRoot.modelData.connected)
                                delegateRoot.modelData.disconnect();
                            else
                                delegateRoot.modelData.connect();
                        }
                    }
                }

                Rectangle {
                    width: forgetLabel.implicitWidth + 12
                    height: forgetLabel.implicitHeight + 6
                    radius: 6
                    color: forgetMouse.containsMouse ? Theme.highlightHigh : Theme.surface

                    Text {
                        id: forgetLabel
                        anchors.centerIn: parent
                        color: Theme.love
                        text: "Forget"
                    }

                    MouseArea {
                        id: forgetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: delegateRoot.modelData.forget()
                    }
                }
            }
        }
    }

    Text {
        visible: root.adapter && root.pairedDevices.length === 0
        color: Theme.muted
        text: "No paired devices"
    }
}
