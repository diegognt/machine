import QtQuick
import Quickshell
import Quickshell.Io
import "../../"
import "../"

// Bar entry point for the brightness indicator: screen backlight + keyboard
// backlight managed in conjunction from a single icon. Reads sysfs
// (/sys/class/backlight, /sys/class/leds) reactively via FileView; writes
// go through brightnessctl (logind SetBrightness, no root/udev ACL
// needed). See README.md in this folder.
IndicatorIcon {
    id: root
    color: root.stateColor
    text: root.icon

    readonly property string screenDevice: "nvidia_wmi_ec_backlight"
    readonly property int screenRaw: parseInt(screenBrightnessFile.text().trim(), 10) || 0
    readonly property int screenMax: parseInt(screenMaxFile.text().trim(), 10) || 100
    readonly property real screenRatio: screenMax > 0 ? Math.max(0, Math.min(1, screenRaw / screenMax)) : 0
    readonly property int screenPct: Math.round(screenRatio * 100)

    FileView {
        id: screenBrightnessFile
        path: "/sys/class/backlight/" + root.screenDevice + "/brightness"
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: screenMaxFile
        path: "/sys/class/backlight/" + root.screenDevice + "/max_brightness"
    }

    readonly property string kbdDevice: "asus::kbd_backlight"
    readonly property int kbdRaw: parseInt(kbdBrightnessFile.text().trim(), 10) || 0
    readonly property int kbdMax: parseInt(kbdMaxFile.text().trim(), 10) || 1
    readonly property real kbdRatio: kbdMax > 0 ? Math.max(0, Math.min(1, kbdRaw / kbdMax)) : 0
    readonly property int kbdPct: Math.round(kbdRatio * 100)
    readonly property bool kbdOn: kbdRaw > 0

    FileView {
        id: kbdBrightnessFile
        path: "/sys/class/leds/" + root.kbdDevice + "/brightness"
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: kbdMaxFile
        path: "/sys/class/leds/" + root.kbdDevice + "/max_brightness"
    }

    readonly property string icon: {
        if (screenPct <= 33) return "\ue1ad";  // brightness_low
        if (screenPct <= 66) return "\ue1ae";  // brightness_medium
        return "\ue1ac";                        // brightness_high
    }

    // Not readonly: Behavior needs write access to animate transitions.
    property color stateColor: Theme.grayLevel(screenRatio)
    property color kbdColor: kbdOn ? Theme.grayLevel(kbdRatio) : Theme.muted

    Behavior on stateColor {
        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on kbdColor {
        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    property int pendingScreenPct: -1
    property int pendingKbdLevel: -1

    Timer {
        id: screenWriteTimer
        interval: 40
        onTriggered: {
            if (root.pendingScreenPct < 0) return;
            screenSetProcess.command = ["brightnessctl", "-d", root.screenDevice, "set", root.pendingScreenPct + "%"];
            screenSetProcess.running = true;
            root.pendingScreenPct = -1;
        }
    }
    Process { id: screenSetProcess }

    function setScreenPct(pct) {
        pendingScreenPct = Math.max(1, Math.min(100, Math.round(pct)));
        screenWriteTimer.restart();
    }

    Timer {
        id: kbdWriteTimer
        interval: 40
        onTriggered: {
            if (root.pendingKbdLevel < 0) return;
            kbdSetProcess.command = ["brightnessctl", "-d", root.kbdDevice, "set", String(root.pendingKbdLevel)];
            kbdSetProcess.running = true;
            root.pendingKbdLevel = -1;
        }
    }
    Process { id: kbdSetProcess }

    function setKbdLevel(level) {
        pendingKbdLevel = Math.max(0, Math.min(kbdMax, Math.round(level)));
        kbdWriteTimer.restart();
    }

    function cycleKbd() {
        setKbdLevel((kbdRaw + 1) % (kbdMax + 1));
    }

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
        acceptedButtons: Qt.LeftButton
        onEntered: root.keepOpen()
        onExited: root.scheduleClose()
        onClicked: root.cycleKbd()
        onWheel: (wheel) => {
            const step = 5;
            const delta = wheel.angleDelta.y > 0 ? step : -step;
            root.setScreenPct(root.screenPct + delta);
        }
    }

    readonly property var barWindow: QsWindow.window

    PopupWindow {
        id: popup

        anchor {
            window: root.barWindow
            gravity: Edges.Bottom | Edges.Right
            adjustment: PopupAdjustment.Slide

            onAnchoring: {
                if (!root.barWindow) return;
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

            BrightnessPopup {
                id: popupContent
                anchors.fill: parent
                anchors.margins: 12

                icon: root.icon
                stateColor: root.stateColor
                kbdColor: root.kbdColor
                screenPct: root.screenPct
                kbdPct: root.kbdPct
                kbdOn: root.kbdOn
                onScreenMoved: (pct) => root.setScreenPct(pct)
                onKbdMoved: (pct) => root.setKbdLevel(Math.round((pct / 100) * root.kbdMax))
                onKbdToggled: root.cycleKbd()
            }
        }
    }
}
