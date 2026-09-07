import QtQuick
import Quickshell
import Quickshell.Networking
import "../../"
import "../"

// Bar entry point for the network indicator: derives connection state from
// Quickshell.Networking, renders the bar label, and hosts the hover-popup
// (NetworkPopup.qml) which itself hosts the nmcli-backed Wi-Fi browser
// (WifiNetworkList.qml). See README.md in this folder for the full picture.
IndicatorIcon {
    id: root
    color: root.stateColor
    text: root.icon

    // --- Devices ---
    readonly property var devices: Networking.devices.values
    readonly property var wifiDevice: {
        for (const d of devices)
            if (d.type === DeviceType.Wifi)
                return d;
        return null;
    }
    readonly property var wiredDevice: {
        for (const d of devices)
            if (d.type === DeviceType.Wired)
                return d;
        return null;
    }

    // --- Active connection (prefer wired over wifi, matching typical priority) ---
    readonly property bool wiredConnected: !!(wiredDevice && wiredDevice.network && wiredDevice.network.connected)
    readonly property var activeWifiNetwork: {
        if (!wifiDevice)
            return null;
        for (const n of wifiDevice.networks.values)
            if (n.connected)
                return n;
        return null;
    }
    readonly property bool wifiConnected: !!activeWifiNetwork

    readonly property real signalStrength: activeWifiNetwork ? activeWifiNetwork.signalStrength : 0
    readonly property int security: activeWifiNetwork ? activeWifiNetwork.security : WifiSecurityType.Open
    readonly property bool secured: security !== WifiSecurityType.Open && security !== WifiSecurityType.Unknown

    readonly property string connectionName: {
        if (wiredConnected)
            return wiredDevice.network.name;
        if (wifiConnected)
            return activeWifiNetwork.name;
        return "";
    }

    readonly property string connectivityLabel: {
        switch (Networking.connectivity) {
        case NetworkConnectivity.Full:
            return "Connected";
        case NetworkConnectivity.Limited:
            return "Limited connectivity";
        case NetworkConnectivity.Portal:
            return "Login required";
        case NetworkConnectivity.None:
            return "No connectivity";
        default:
            return "Unknown";
        }
    }

    readonly property string icon: {
        if (wiredConnected)
            return "\ueb2f";        // lan (wired)
        if (wifiConnected) {
            if (signalStrength <= 25)
                return "\uebe4"; // network_wifi_1_bar
            if (signalStrength <= 50)
                return "\uebd6"; // network_wifi_2_bar
            if (signalStrength <= 75)
                return "\uebe1"; // network_wifi_3_bar
            return "\ue1ba";                            // network_wifi (full)
        }
        if (Networking.wifiEnabled)
            return "\uf0ef";  // signal_wifi_statusbar_not_connected
        return "\ue648";                                // wifi_off
    }

    readonly property color stateColor: {
        if (wiredConnected || wifiConnected) {
            if (Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.Portal)
                return Theme.gold;
            return Theme.text;
        }
        return Theme.muted;
    }

    // Hover-popup mechanics (mirrors Battery.qml).
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

    // Icon-only in the bar; connection name and full detail live in the
    // hover popup below. Icon rendering itself is handled by the shared
    // IndicatorIcon base (color/text bound above).
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.keepOpen()
        onExited: root.scheduleClose()
    }

    // Anchored to the Bar (PanelWindow) itself rather than this indicator
    // item, so its top edge always sits exactly at the bar's own bottom
    // edge - regardless of how this item is vertically centered inside
    // its (shorter) pill - instead of overlapping the indicator/pill.
    // Horizontally it still centers under this item via the mapped anchor
    // rect below.
    readonly property var barWindow: QsWindow.window

    PopupWindow {
        id: popup
        anchor.window: root.barWindow
        anchor.rect.x: root.barWindow ? root.mapToItem(root.barWindow.contentItem, 0, 0).x : 0
        anchor.rect.y: Theme.barHeight
        anchor.rect.width: root.width
        anchor.rect.height: 0
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.adjustment: PopupAdjustment.Slide
        implicitWidth: 260
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

            NetworkPopup {
                id: popupContent
                anchors.fill: parent
                anchors.margins: 12

                icon: root.icon
                stateColor: root.stateColor
                connectionName: root.connectionName
                connectivityLabel: root.connectivityLabel
                wifiConnected: root.wifiConnected
                wiredConnected: root.wiredConnected
                signalStrength: root.signalStrength
                secured: root.secured
                wifiDevice: root.wifiDevice
                wiredDevice: root.wiredDevice
                showDetails: root.showDetails
            }
        }
    }
}
