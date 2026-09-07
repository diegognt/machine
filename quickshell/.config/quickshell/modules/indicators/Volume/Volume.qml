import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../../"
import "../"

// Bar entry point for the volume indicator: mirrors Network.qml/Bluetooth.qml.
// Derives output/input state directly from Quickshell.Services.Pipewire (no
// pactl/pamixer/wpctl scripting), renders the bar icon, and hosts the
// hover-popup (VolumePopup.qml) which itself hosts the volume sliders and
// output/input device switchers. See README.md in this folder for the full
// picture.
IndicatorIcon {
    id: root
    color: root.stateColor
    text: root.icon

    // --- Default nodes ---
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool sinkReady: !!(sink && sink.ready && sink.audio)
    readonly property bool sourceReady: !!(source && source.ready && source.audio)

    readonly property real volume: sinkReady ? sink.audio.volume : 0
    readonly property int pct: Math.round(volume * 100)
    readonly property bool muted: sinkReady && sink.audio.muted

    // --- All physical audio device nodes (not app streams), for the
    // output/input device switcher lists in the popup. ---
    readonly property var allNodes: Pipewire.nodes.values
    readonly property var outputDevices: allNodes.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var inputDevices: allNodes.filter(n => !n.isSink && !n.isStream && n.audio)

    // Every node ever referenced (defaults + device lists) must be tracked,
    // otherwise .audio/.ready are invalid and the objects can be collected
    // out from under us while pipewire nodes come and go.
    PwObjectTracker {
        objects: [sink, source, ...outputDevices, ...inputDevices].filter(n => !!n)
    }

    readonly property string icon: {
        if (!sinkReady) return "\ue04f";                 // volume_off (no sink)
        if (muted || volume <= 0) return "\ue04e";       // volume_mute
        if (volume <= 0.5) return "\ue04d";              // volume_down
        return "\ue050";                                  // volume_up
    }

    readonly property color stateColor: {
        if (!sinkReady) return Theme.muted;
        if (muted) return Theme.gold;
        return Theme.text;
    }

    // Hover-popup mechanics (mirrors Battery.qml / Network.qml / Bluetooth.qml).
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

    // Scroll-to-adjust: matches the XF86AudioRaise/LowerVolume hotkeys'
    // 5% step, without needing to open the popup.
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onEntered: root.keepOpen()
        onExited: root.scheduleClose()
        onClicked: {
            if (root.sinkReady)
                root.sink.audio.muted = !root.sink.audio.muted;
        }
        onWheel: (wheel) => {
            if (!root.sinkReady) return;
            const step = 0.05;
            const delta = wheel.angleDelta.y > 0 ? step : -step;
            root.sink.audio.muted = false;
            root.sink.audio.volume = Math.max(0, Math.min(1.5, root.sink.audio.volume + delta));
        }
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

            VolumePopup {
                id: popupContent
                anchors.fill: parent
                anchors.margins: 12

                icon: root.icon
                stateColor: root.stateColor
                sink: root.sink
                source: root.source
                sinkReady: root.sinkReady
                sourceReady: root.sourceReady
                pct: root.pct
                muted: root.muted
                outputDevices: root.outputDevices
                inputDevices: root.inputDevices
                showDetails: root.showDetails
            }
        }
    }
}
