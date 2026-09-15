import QtQuick
import "../"

// Standard-looking slider for Control Center sections (Sound, Brightness):
// icon + label + percentage in a header row, with a normal thin draggable
// track underneath — the same layout the bar's own hover popups already
// use (VolumePopup.qml/BrightnessPopup.qml's icon+text header above a
// VolumeSlider/BrightnessSlider), just sized for the wider Control Center
// column instead of the narrower bar popup.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string pctText: ""
    property real value: 0
    property real maxValue: 1.0
    property bool enabled: true
    property color trackColor: Theme.pine
    // Fired when the icon glyph itself (not the track) is clicked -
    // callers use this for mute/power toggles.
    signal iconClicked()
    signal moved(real value)

    implicitHeight: headerRow.implicitHeight + 8 + track.height
    opacity: enabled ? 1.0 : 0.4

    readonly property real ratio: maxValue > 0 ? Math.max(0, Math.min(1, value / maxValue)) : 0

    Row {
        id: headerRow
        width: parent.width
        spacing: 10

        Text {
            id: iconText
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.iconFontFamily
            font.pixelSize: 18
            color: Theme.text
            text: root.icon

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: root.enabled
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: headerRow.width - iconText.width - headerRow.spacing * 2 - pctLabel.implicitWidth
            elide: Text.ElideRight
            color: Theme.text
            font.pixelSize: 13
            text: root.label
        }

        Text {
            id: pctLabel
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.subtle
            font.pixelSize: 13
            text: root.pctText
        }
    }

    Item {
        id: track
        anchors.top: headerRow.bottom
        anchors.topMargin: 8
        width: parent.width
        height: 8

        Rectangle {
            id: trackBackground
            anchors.fill: parent
            radius: height / 2
            color: Theme.surface

            Rectangle {
                height: parent.height
                radius: parent.radius
                width: root.ratio * parent.width
                color: root.trackColor

                Behavior on width { enabled: !dragArea.pressed; NumberAnimation { duration: 120 } }
            }
        }

        Rectangle {
            id: handle
            width: 16
            height: 16
            radius: 8
            color: Theme.text
            anchors.verticalCenter: parent.verticalCenter
            x: root.ratio * (parent.width - width)
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            anchors.margins: -6
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
}
