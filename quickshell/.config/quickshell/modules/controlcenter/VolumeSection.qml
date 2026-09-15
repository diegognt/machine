import QtQuick
import Quickshell.Services.Pipewire
import "../"

// Control Center section for audio state. Re-derives the same state
// Volume.qml computes for the bar icon and lays it out with
// ControlSlider - the same icon+label+percentage-header-above-a-thin-track
// look the bar's own hover popup (VolumePopup.qml) uses, just sized for
// the wider Control Center column. Device switcher lists are
// intentionally left out here (still available from the bar's hover
// popup) to keep this section compact.
//
// Wrapped in a plain Item (see BrightnessSection.qml's header comment) so
// the non-visual PwObjectTracker helper can live as a sibling of the
// visual SectionCard instead of inside its Column-based default content.
Item {
    id: root
    implicitHeight: card.implicitHeight
    height: card.implicitHeight

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool sinkReady: !!(sink && sink.ready && sink.audio)
    readonly property bool sourceReady: !!(source && source.ready && source.audio)

    readonly property real volume: sinkReady ? sink.audio.volume : 0
    readonly property bool muted: sinkReady && sink.audio.muted

    readonly property var allNodes: Pipewire.nodes.values
    readonly property var outputDevices: allNodes.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var inputDevices: allNodes.filter(n => !n.isSink && !n.isStream && n.audio)

    PwObjectTracker {
        objects: [root.sink, root.source, ...root.outputDevices, ...root.inputDevices].filter(n => !!n)
    }

    function displayName(node) {
        const raw = (node.description || node.nickname || node.name || "").trim();
        return raw.length > 0 ? raw : "Unknown device";
    }

    readonly property string volIcon: {
        if (!sinkReady) return "\ue04f";
        if (muted || volume <= 0) return "\ue04e";
        if (volume <= 0.5) return "\ue04d";
        return "\ue050";
    }

    readonly property string srcIcon: (sourceReady && source.audio.muted) ? "\uf461" : "\ue029"

    SectionCard {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        title: "Sound"
        icon: root.volIcon

        ControlSlider {
            width: parent.width
            enabled: root.sinkReady
            icon: root.volIcon
            trackColor: root.muted ? Theme.gold : Theme.pine
            pctText: root.sinkReady ? (root.muted ? "Muted" : Math.round(root.volume * 100) + "%") : "0%"
            label: root.sinkReady ? root.displayName(root.sink) : "No output device"
            maxValue: 1.5
            value: root.volume
            onIconClicked: if (root.sinkReady) root.sink.audio.muted = !root.sink.audio.muted
            onMoved: (v) => {
                if (!root.sinkReady) return;
                root.sink.audio.muted = false;
                root.sink.audio.volume = v;
            }
        }

        ControlSlider {
            width: parent.width
            visible: root.sourceReady
            enabled: root.sourceReady
            icon: root.srcIcon
            trackColor: (root.sourceReady && root.source.audio.muted) ? Theme.gold : Theme.foam
            pctText: root.sourceReady ? ((root.source.audio.muted) ? "Muted" : Math.round(root.source.audio.volume * 100) + "%") : "0%"
            label: root.sourceReady ? root.displayName(root.source) : "No input device"
            maxValue: 1.5
            value: root.sourceReady ? root.source.audio.volume : 0
            onIconClicked: if (root.sourceReady) root.source.audio.muted = !root.source.audio.muted
            onMoved: (v) => {
                if (!root.sourceReady) return;
                root.source.audio.muted = false;
                root.source.audio.volume = v;
            }
        }
    }
}
