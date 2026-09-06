import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../"

Item {
    id: root
    anchors.verticalCenter: parent.verticalCenter
    visible: device.isLaptopBattery
    implicitWidth: label.implicitWidth
    implicitHeight: Theme.iconSize

    readonly property var device: UPower.displayDevice

    // --- Raw UPower properties ---
    // Reactive: updates immediately whenever UPower pushes a D-Bus signal
    // (no manual polling/throttling needed).
    readonly property real percentage: device.percentage      // 0.0 - 1.0
    readonly property int pct: Math.round(percentage * 100)
    readonly property int state: device.state                 // UPowerDeviceState.Enum
    readonly property real timeToEmpty: device.timeToEmpty    // seconds
    readonly property real timeToFull: device.timeToFull      // seconds
    readonly property real changeRate: device.changeRate      // watts
    readonly property real energy: device.energy
    readonly property real energyCapacity: device.energyCapacity
    readonly property real healthPercentage: device.healthPercentage
    readonly property bool healthSupported: device.healthSupported
    readonly property string model: device.model

    // --- Derived state booleans ---
    readonly property bool charging:         state === UPowerDeviceState.Charging
    readonly property bool discharging:      state === UPowerDeviceState.Discharging
    readonly property bool fullyCharged:     state === UPowerDeviceState.FullyCharged
    readonly property bool pendingCharge:    state === UPowerDeviceState.PendingCharge
    readonly property bool pendingDischarge: state === UPowerDeviceState.PendingDischarge
    readonly property bool empty:            state === UPowerDeviceState.Empty

    // --- Time remaining, formatted as "Hh Mm" or "Mm" ---
    function formatTime(seconds) {
        if (!seconds || seconds <= 0) return "";
        const totalMinutes = Math.round(seconds / 60);
        const h = Math.floor(totalMinutes / 60);
        const m = totalMinutes % 60;
        return h > 0 ? (h + "h " + m + "m") : (m + "m");
    }

    readonly property string timeText: {
        if (charging || pendingCharge) return formatTime(timeToFull);
        if (discharging) return formatTime(timeToEmpty);
        return "";
    }

    readonly property string rateText: changeRate > 0 ? changeRate.toFixed(1) + "W" : ""

    readonly property string stateLabel: {
        if (fullyCharged) return "Fully charged";
        if (charging) return "Charging";
        if (pendingCharge) return "Pending charge";
        if (pendingDischarge) return "Pending discharge";
        if (empty) return "Empty";
        return "Discharging";
    }

    readonly property string icon: {
        if (fullyCharged) return "\ue1a4";              // battery_full
        if (charging || pendingCharge) return "\ue1a3"; // battery_charging_full
        if (empty) return "\ue19c";                      // battery_alert
        if (pct <= 10) return "\ue19c";                  // battery_alert
        if (pct <= 35) return "\uebe0";                  // battery_2_bar
        if (pct <= 65) return "\uebe2";                  // battery_4_bar
        if (pct <= 90) return "\uebd2";                  // battery_6_bar
        return "\ue1a4";                                  // battery_full
    }

    readonly property color stateColor: {
        if (charging || pendingCharge || fullyCharged) return Theme.success;
        if (pct <= 15 && discharging) return Theme.error;
        return Theme.text;
    }

    // Popup is shown while hovering either the indicator itself or the
    // popup's own content. A short hide-delay bridges the small gap between
    // the two separate windows so quickly moving the cursor down into the
    // popup doesn't cause it to disappear first.
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

    // Icon-only in the bar; full detail (percentage, time, rate, health,
    // power profile) lives in the hover popup below. Fixed height +
    // centered alignment keeps it lined up with other icon-only
    // indicators regardless of this font's own line-height metrics.
    Text {
        id: label
        anchors.centerIn: parent
        height: Theme.iconSize
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        font.family: Theme.iconFontFamily
        font.pixelSize: Theme.iconSize
        color: root.stateColor
        text: root.icon
    }

    MouseArea {
        id: hoverArea
        anchors.fill: label
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.keepOpen()
        onExited: root.scheduleClose()
    }

    // Hover-triggered detail popup: state, time, rate, health, model, and a
    // power-profile switcher. Anchored below the bar using the shared
    // Theme.barHeight so the offset stays correct if the bar height changes.
    PopupWindow {
        id: popup
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.adjustment: PopupAdjustment.Slide
        anchor.margins.top: Theme.barHeight
        implicitWidth: 240
        implicitHeight: detailCol.implicitHeight + 24
        visible: root.showDetails
        color: "transparent"

        Rectangle {
            id: popupBackground
            anchors.fill: parent
            radius: 8
            color: Theme.pillBackground
            border.width: 2
            border.color: Theme.overlay

            MouseArea {
                id: popupHoverArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onEntered: root.keepOpen()
                onExited: root.scheduleClose()
            }

            Column {
                id: detailCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header: icon stretched to the full height of the two-line
                // text block (percentage + state label), vertically centered
                // alongside it.
                Item {
                    width: parent.width
                    height: pctText.height + stateLabelText.height

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
                        id: pctText
                        anchors.left: headerIcon.right
                        anchors.leftMargin: 8
                        anchors.top: parent.top
                        color: Theme.text
                        font.pixelSize: 16
                        font.bold: true
                        text: root.pct + "%"
                    }
                    Text {
                        id: stateLabelText
                        anchors.left: pctText.left
                        anchors.top: pctText.bottom
                        color: Theme.subtle
                        text: root.stateLabel
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.surface }

                // Time / rate
                Text {
                    visible: root.timeText.length > 0
                    color: Theme.text
                    text: (root.charging || root.pendingCharge ? "Time to full: " : "Time to empty: ") + root.timeText
                }
                Text {
                    visible: root.rateText.length > 0
                    color: Theme.text
                    text: "Power draw: " + root.rateText
                }

                // Health
                Text {
                    visible: root.healthSupported
                    color: Theme.text
                    text: "Health: " + Math.round(root.healthPercentage) + "%"
                }

                // Model
                Text {
                    visible: root.model.length > 0
                    color: Theme.subtle
                    text: root.model
                }

                Rectangle { width: parent.width; height: 1; color: Theme.surface }

                // Power profile switcher
                Text {
                    color: Theme.subtle
                    text: "Power profile"
                }
                Row {
                    spacing: 6

                    Repeater {
                        model: [
                            { label: "Saver",       value: PowerProfile.PowerSaver },
                            { label: "Balanced",    value: PowerProfile.Balanced },
                            { label: "Performance", value: PowerProfile.Performance },
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: PowerProfiles.profile === modelData.value
                            readonly property bool disabled: modelData.value === PowerProfile.Performance && !PowerProfiles.hasPerformanceProfile

                            radius: 6
                            color: active ? Theme.pine : Theme.surface
                            opacity: disabled ? 0.4 : 1.0
                            implicitWidth: profileLabel.implicitWidth + 12
                            implicitHeight: profileLabel.implicitHeight + 8

                            Text {
                                id: profileLabel
                                anchors.centerIn: parent
                                color: Theme.text
                                text: parent.modelData.label
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !parent.disabled
                                cursorShape: Qt.PointingHandCursor
                                onClicked: PowerProfiles.profile = parent.modelData.value
                            }
                        }
                    }
                }
            }
        }
    }
}
