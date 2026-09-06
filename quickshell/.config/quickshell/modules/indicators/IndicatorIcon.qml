import QtQuick
import "../"

// Shared "icon-only" indicator content: a single glyph from Theme's icon
// font, sized/aligned consistently across every icon-only indicator
// (Battery, Network, ...). Meant to be placed directly inside a ModulePill
// (optionally alongside an IndicatorLabel) so ModulePill's own
// `spacing`/`pillContentSpacing` creates a real gap between multiple
// indicator parts when more than one is present. Fixed 22x20 footprint
// regardless of glyph metrics, so icon-only indicators line up consistently.
Item {
    id: root

    property alias text: label.text
    property alias font: label.font
    property alias color: label.color

    readonly property int iconWidth: 22
    readonly property int iconHeight: 20

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    implicitWidth: iconWidth
    implicitHeight: iconHeight

    Text {
        id: label
        anchors.centerIn: parent
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        font.family: Theme.iconFontFamily
        font.pixelSize: Theme.iconSize
        color: Theme.text
    }
}
