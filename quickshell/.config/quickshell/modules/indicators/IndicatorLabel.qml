import QtQuick
import "../"

// Shared "text" indicator content: a single line of body text, sized/styled
// consistently across every text-based indicator (ClockWidget, ...). Meant
// to be placed directly inside a ModulePill (optionally alongside an
// IndicatorIcon) so ModulePill's own `spacing`/`pillContentSpacing` creates
// a real gap between multiple indicator parts when more than one is
// present. Carries its own fixed 6px horizontal spacing (left/right) around
// the text itself, independent of ModulePill's own padding/spacing.
Item {
    id: root

    property alias text: label.text
    property alias font: label.font
    property alias color: label.color

    readonly property int horizontalSpacing: 6

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    implicitWidth: label.implicitWidth + horizontalSpacing * 2
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: Theme.fontSize
        color: Theme.text
    }
}
