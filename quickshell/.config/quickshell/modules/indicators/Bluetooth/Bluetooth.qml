import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../"
import "../"

// Bar entry point for the bluetooth indicator: mirrors Network.qml. Derives
// adapter/connection state from Quickshell.Bluetooth (backed by BlueZ over
// D-Bus, no bluedevil/qt6-connectivity involved), renders the bar icon, and
// hosts the hover-popup (BluetoothPopup.qml) which itself hosts the power
// toggle and device list (DeviceList.qml).
IndicatorIcon {
    id: root
    color: root.stateColor
    text: root.icon

    // --- Adapter ---
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: !!adapter
    readonly property bool enabled: available && adapter.enabled
    readonly property bool discovering: available && adapter.discovering

    // --- Devices ---
    readonly property var devices: available ? adapter.devices.values : []
    readonly property var connectedDevices: devices.filter(d => d.connected)
    readonly property var pairedDevices: devices.filter(d => d.paired || d.bonded)
    readonly property bool anyConnected: connectedDevices.length > 0

    // Same alias-preferring logic as DeviceList.qml's displayName(), kept
    // in sync here since the bar-level popup header also shows a device
    // name (single-connection case) independent of the device list.
    function displayName(device) {
        let raw = device.name || device.deviceName || "";
        raw = raw.trim().replace(/_/g, " ").replace(/\s+/g, " ");
        return raw.length > 0 ? raw : device.address;
    }

    readonly property string connectionLabel: {
        if (!available) return "No adapter";
        if (!enabled) return "Bluetooth off";
        if (anyConnected) {
            if (connectedDevices.length === 1) return root.displayName(connectedDevices[0]);
            return connectedDevices.length + " devices connected";
        }
        return "No device connected";
    }

    readonly property string icon: {
        if (!available || !enabled) return "\ue1a9"; // bluetooth_disabled
        if (anyConnected) return "\ue1a8";           // bluetooth_connected
        if (discovering) return "\ue1aa";            // bluetooth_searching
        return "\ue1a7";                             // bluetooth (idle, powered on)
    }

    // Matches Network.qml/Battery.qml's stateColor convention: Theme.text
    // for the "active/connected" state, Theme.muted otherwise (off,
    // unavailable, or on-but-idle) instead of a third in-between shade.
    readonly property color stateColor: {
        if (!available || !enabled) return Theme.muted;
        if (anyConnected) return Theme.text;
        return Theme.muted;
    }

    // Hover-popup mechanics (mirrors Battery.qml / Network.qml).
    property bool showDetails: false

    Timer {
        id: hideTimer
        interval: 150
        onTriggered: root.showDetails = false
    }

    function keepOpen() {
        hideTimer.stop();
        root.showDetails = true;
    }

    function scheduleClose() {
        hideTimer.restart();
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.keepOpen()
        onExited: root.scheduleClose()
    }

    readonly property var barWindow: QsWindow.window

    PopupWindow {
        id: popup

        // Centered horizontally under the indicator icon and flush below
        // the bar. A plain reactive binding on anchor.rect.x/y isn't
        // reliable here (see Quickshell's own Tooltip.qml) — the anchor
        // point must be (re)computed in onAnchoring, which fires whenever
        // the popup is (re)positioned, using the already-known
        // implicitWidth. With the default Top|Left edges and
        // Bottom|Right gravity, the popup grows down-right from that
        // computed point, so setting rect.x to the already-centered x
        // places the popup's left edge exactly there.
        anchor {
            window: root.barWindow
            gravity: Edges.Bottom | Edges.Right
            adjustment: PopupAdjustment.Slide

            onAnchoring: {
                if (!root.barWindow) return;
                // x centers under the icon; y uses Theme.barHeight (the
                // bar's own fixed height, in the bar window's own
                // coordinate space) instead of root.height, since the
                // icon itself is vertically centered inside its (shorter)
                // pill and doesn't span the bar's full height.
                const pos = root.mapToItem(root.barWindow.contentItem, root.width / 2 - popup.implicitWidth / 2, 0);
                anchor.rect.x = pos.x;
                anchor.rect.y = Theme.barHeight;
            }
        }
        implicitWidth: 280
        implicitHeight: popupContent.implicitHeight + 24
        visible: root.showDetails
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.pillBackground
            border.width: 2
            border.color: Theme.overlay

            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        root.keepOpen();
                    else
                        root.scheduleClose();
                }
            }

            BluetoothPopup {
                id: popupContent
                anchors.fill: parent
                anchors.margins: 12

                icon: root.icon
                stateColor: root.stateColor
                available: root.available
                enabled: root.enabled
                adapter: root.adapter
                connectionLabel: root.connectionLabel
                devices: root.devices
                showDetails: root.showDetails
            }
        }
    }
}
