import QtQuick
import "../"

// Square quick-toggle button (GNOME/macOS quick-settings style): an icon
// + label, filled with the accent color when active and Theme.surface
// otherwise. Purely presentational — state and the actual toggle action,
// as well as this tile's actual size (kept square by the caller, e.g.
// ConnectivitySection binding width and height to the same value), are
// owned by whoever instantiates it.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    property bool available: true
    signal clicked()

    implicitWidth: 64
    implicitHeight: 64
    radius: 14
    color: active ? Theme.iris : Theme.surface
    opacity: available ? 1.0 : 0.4

    // Icon/label scale with the tile's own size (rather than fixed pixel
    // sizes) so bigger tiles - e.g. the square Wi-Fi/Bluetooth tiles in
    // ConnectivitySection, sized off the section's available width - get
    // proportionally bigger content instead of looking sparse. Clamped so
    // a tile shrunk well below 64px doesn't shrink the text into
    // illegibility, or an oversized tile balloon the label absurdly.
    readonly property int iconPixelSize: Math.max(18, Math.min(32, Math.round(height * 0.32)))
    readonly property int labelPixelSize: Math.max(11, Math.min(16, Math.round(height * 0.16)))

    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Column {
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: Theme.iconFontFamily
            font.pixelSize: root.iconPixelSize
            color: root.active ? Theme.base : Theme.text
            text: root.icon
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: root.labelPixelSize
            font.bold: true
            color: root.active ? Theme.base : Theme.subtle
            text: root.label
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.available
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
