import QtQuick
import Quickshell.Io
import "../"

// Control Center section for screen/keyboard brightness. Re-derives the
// same sysfs-backed state Brightness.qml computes for the bar icon and
// lays it out with ControlSlider - the same icon+label+percentage-header
// above-a-thin-track look the bar's own hover popup (BrightnessPopup.qml)
// uses, just sized for the wider Control Center column.
//
// Wrapped in a plain Item (rather than being a SectionCard itself) because
// SectionCard's default property is aliased to a Column's `children`,
// which only accepts visual Items — the non-visual FileView/Timer/Process
// helpers below must instead be declared as this Item's own (unrestricted)
// default children, as siblings of the visual SectionCard.
Item {
    id: root
    implicitHeight: card.implicitHeight
    height: card.implicitHeight

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

    readonly property string brIcon: {
        if (screenPct <= 33) return "\ue1ad";
        if (screenPct <= 66) return "\ue1ae";
        return "\ue1ac";
    }
    readonly property color brColor: Theme.grayLevel(screenRatio)
    readonly property color kbdColor: kbdOn ? Theme.grayLevel(kbdRatio) : Theme.muted

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

    SectionCard {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        title: "Brightness"
        icon: root.brIcon

        ControlSlider {
            width: parent.width
            icon: root.brIcon
            trackColor: Theme.gold
            pctText: root.screenPct + "%"
            label: "Screen brightness"
            maxValue: 100
            value: root.screenPct
            onMoved: (pct) => root.setScreenPct(pct)
        }

        ControlSlider {
            width: parent.width
            icon: "\uf7ed" // backlight_high
            trackColor: Theme.gold
            pctText: root.kbdOn ? root.kbdPct + "%" : "Off"
            label: "Keyboard backlight"
            maxValue: 100
            value: root.kbdPct
            onIconClicked: root.cycleKbd()
            onMoved: (pct) => root.setKbdLevel(Math.round((pct / 100) * root.kbdMax))
        }
    }
}
