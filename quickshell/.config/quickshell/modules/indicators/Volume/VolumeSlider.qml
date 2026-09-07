import QtQuick
import "../../"

// Minimal draggable horizontal slider used for both the output (sink) and
// input (source/mic) volume rows in VolumePopup.qml. Values range 0..maxValue
// (maxValue > 1 allows boosted gain, matching what PipeWire/WirePlumber
// itself permits), with a small tick mark at the 100% mark whenever boost is
// allowed so the "unboosted" position is still visible.
Item {
    id: root

    property real value: 0
    property real maxValue: 1.0
    property bool enabled: true
    signal moved(real value)

    implicitHeight: 18

    readonly property real ratio: maxValue > 0 ? Math.max(0, Math.min(1, value / maxValue)) : 0

    opacity: enabled ? 1.0 : 0.4

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surface

        Rectangle {
            height: parent.height
            radius: parent.radius
            width: root.ratio * parent.width
            color: root.value > 1.0 ? Theme.gold : Theme.pine
        }

        Rectangle {
            visible: root.maxValue > 1.0
            width: 2
            height: parent.height
            color: Theme.overlay
            x: (1.0 / root.maxValue) * parent.width - width / 2
        }
    }

    Rectangle {
        id: handle
        width: 14
        height: 14
        radius: 7
        color: Theme.text
        anchors.verticalCenter: parent.verticalCenter
        x: root.ratio * (parent.width - width)
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor

        function updateFromX(x) {
            const ratio = Math.max(0, Math.min(1, x / width));
            root.moved(ratio * root.maxValue);
        }

        onPressed: (mouse) => updateFromX(mouse.x)
        onPositionChanged: (mouse) => { if (pressed) updateFromX(mouse.x); }
    }
}
