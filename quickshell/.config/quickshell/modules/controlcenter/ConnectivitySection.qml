import QtQuick
import Quickshell.Networking
import Quickshell.Bluetooth

// First Control Center section: quick on/off toggle tiles for Wi-Fi and
// Bluetooth radios, side by side, mirroring GNOME/macOS quick-settings
// tiles. Full connection detail (signal strength, paired devices, Wi-Fi
// scan) intentionally stays in the bar's own Network/Bluetooth hover
// popups rather than being duplicated here.
SectionCard {
    id: root
    title: "Connectivity"
    icon: "\ue1b1" // settings_input_antenna

    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btAvailable: !!btAdapter
    readonly property bool btEnabled: btAvailable && btAdapter.enabled

    // Tiles are half as tall as they are wide: width is half the available
    // width minus the gap between them (so the pair spans the section's
    // full width edge-to-edge - SectionCard's own padding already
    // separates that width from the Control Center's outer border), and
    // height is 50% shorter than that width.
    Row {
        width: parent.width
        spacing: 10

        readonly property real tileWidth: (width - spacing) / 2
        readonly property real tileHeight: tileWidth * 0.5

        ToggleTile {
            width: parent.tileWidth
            height: parent.tileHeight
            icon: Networking.wifiEnabled ? "\ue63e" : "\ue648" // wifi / wifi_off
            label: "Wi-Fi"
            active: Networking.wifiEnabled
            available: Networking.wifiHardwareEnabled
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }

        ToggleTile {
            width: parent.tileWidth
            height: parent.tileHeight
            icon: root.btEnabled ? "\ue1a7" : "\ue1a9" // bluetooth / bluetooth_disabled
            label: "Bluetooth"
            active: root.btEnabled
            available: root.btAvailable
            onClicked: root.btAdapter.enabled = !root.btAdapter.enabled
        }
    }
}
