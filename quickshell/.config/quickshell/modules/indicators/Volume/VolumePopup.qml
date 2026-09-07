import QtQuick
import Quickshell.Services.Pipewire
import "../../"

// Hover-popup content: header (icon + level), output volume/mute row,
// input (mic) volume/mute row, and output/input device switcher lists.
// Kept separate from Volume.qml so the PopupWindow's content can be
// iterated on independently of the bar-label/hover-open mechanics.
Column {
    id: root
    spacing: 8

    // --- Inputs, supplied by Volume.qml ---
    property string icon: ""
    property color stateColor: Theme.text
    property var sink: null
    property var source: null
    property bool sinkReady: false
    property bool sourceReady: false
    property int pct: 0
    property bool muted: false
    property var outputDevices: []
    property var inputDevices: []
    property bool showDetails: false

    function displayName(node) {
        const raw = (node.description || node.nickname || node.name || "").trim();
        return raw.length > 0 ? raw : "Unknown device";
    }

    Item {
        width: parent.width
        height: nameText.height + stateText.height

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
            id: nameText
            anchors.left: headerIcon.right
            anchors.leftMargin: 8
            anchors.top: parent.top
            color: Theme.text
            font.pixelSize: 16
            font.bold: true
            text: root.sinkReady ? (root.muted ? "Muted" : root.pct + "%") : "No output device"
        }
        Text {
            id: stateText
            anchors.left: nameText.left
            anchors.top: nameText.bottom
            color: Theme.subtle
            text: root.sinkReady ? root.displayName(root.sink) : ""
        }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.surface }

    // --- Output volume row ---
    Row {
        width: parent.width
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.iconFontFamily
            font.pixelSize: 18
            color: root.muted ? Theme.gold : Theme.text
            text: root.muted ? "\ue04e" : "\ue050" // volume_mute / volume_up

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                enabled: root.sinkReady
                cursorShape: Qt.PointingHandCursor
                onClicked: root.sink.audio.muted = !root.sink.audio.muted
            }
        }

        VolumeSlider {
            width: parent.width - 30
            anchors.verticalCenter: parent.verticalCenter
            enabled: root.sinkReady
            maxValue: 1.5
            value: root.sinkReady ? root.sink.audio.volume : 0
            onMoved: (v) => {
                if (!root.sinkReady) return;
                root.sink.audio.muted = false;
                root.sink.audio.volume = v;
            }
        }
    }

    // --- Output device switcher ---
    Text {
        visible: root.outputDevices.length > 1
        color: Theme.subtle
        text: "Output device"
    }

    Repeater {
        model: root.outputDevices.length > 1 ? root.outputDevices : []

        delegate: Rectangle {
            id: outDelegate
            required property var modelData

            width: root.width
            height: outLabel.implicitHeight + 8
            radius: 6
            color: modelData === root.sink ? Theme.highlightMed : (outArea.containsMouse ? Theme.highlightLow : "transparent")

            Text {
                id: outLabel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 6
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                elide: Text.ElideRight
                text: root.displayName(outDelegate.modelData)
            }

            MouseArea {
                id: outArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Pipewire.preferredDefaultAudioSink = outDelegate.modelData
            }
        }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.surface }

    // --- Input (mic) volume row ---
    Row {
        width: parent.width
        spacing: 8
        visible: root.sourceReady

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.iconFontFamily
            font.pixelSize: 18
            color: (root.sourceReady && root.source.audio.muted) ? Theme.gold : Theme.text
            text: (root.sourceReady && root.source.audio.muted) ? "\uf461" : "\ue029" // mic_off / mic

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                enabled: root.sourceReady
                cursorShape: Qt.PointingHandCursor
                onClicked: root.source.audio.muted = !root.source.audio.muted
            }
        }

        VolumeSlider {
            width: parent.width - 30
            anchors.verticalCenter: parent.verticalCenter
            enabled: root.sourceReady
            maxValue: 1.5
            value: root.sourceReady ? root.source.audio.volume : 0
            onMoved: (v) => {
                if (!root.sourceReady) return;
                root.source.audio.muted = false;
                root.source.audio.volume = v;
            }
        }
    }

    Text {
        visible: !root.sourceReady
        color: Theme.muted
        text: "No input device"
    }

    // --- Input device switcher ---
    Text {
        visible: root.inputDevices.length > 1
        color: Theme.subtle
        text: "Input device"
    }

    Repeater {
        model: root.inputDevices.length > 1 ? root.inputDevices : []

        delegate: Rectangle {
            id: inDelegate
            required property var modelData

            width: root.width
            height: inLabel.implicitHeight + 8
            radius: 6
            color: modelData === root.source ? Theme.highlightMed : (inArea.containsMouse ? Theme.highlightLow : "transparent")

            Text {
                id: inLabel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 6
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                elide: Text.ElideRight
                text: root.displayName(inDelegate.modelData)
            }

            MouseArea {
                id: inArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Pipewire.preferredDefaultAudioSource = inDelegate.modelData
            }
        }
    }
}
