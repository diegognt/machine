import QtQuick
import "../"

// Compact "at a glance" hardware metric row: icon + label on the left,
// a big value + optional color-coded temperature badge on the right,
// and a thin progress bar underneath summarizing load as a single glance
// (hidden entirely when `ratio < 0` - e.g. Network, which has no single
// 0-100% figure). The temperature badge itself is likewise only shown
// when `tempText` is non-empty, so metrics where a temperature reading
// doesn't make sense (Memory, Network) simply omit it rather than
// showing an empty/placeholder badge.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string value: ""
    property real ratio: -1          // 0..1, or -1 to hide the progress bar
    property color ratioColor: Theme.pine
    property string tempText: ""     // empty hides the temperature badge
    property color tempColor: Theme.text
    property string powerText: ""    // empty hides the power/consumption badge

    implicitHeight: contentColumn.implicitHeight

    Column {
        id: contentColumn
        width: parent.width
        spacing: 6

        Item {
            id: headerRow
            width: parent.width
            height: Math.max(iconLabelRow.implicitHeight, valueBadgeRow.implicitHeight)

            Row {
                id: iconLabelRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.iconFontFamily
                    font.pixelSize: 16
                    color: Theme.subtle
                    text: root.icon
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.subtle
                    font.pixelSize: 12
                    text: root.label
                }
            }

            Row {
                id: valueBadgeRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.text
                    font.pixelSize: 14
                    font.bold: true
                    text: root.value
                }

                Rectangle {
                    visible: root.powerText.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 5
                    color: Theme.surface
                    implicitWidth: powerLabel.implicitWidth + 12
                    implicitHeight: powerLabel.implicitHeight + 4

                    Text {
                        id: powerLabel
                        anchors.centerIn: parent
                        color: Theme.gold
                        font.pixelSize: 11
                        font.bold: true
                        text: root.powerText
                    }
                }

                Rectangle {
                    visible: root.tempText.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 5
                    color: Theme.surface
                    implicitWidth: tempLabel.implicitWidth + 12
                    implicitHeight: tempLabel.implicitHeight + 4

                    Text {
                        id: tempLabel
                        anchors.centerIn: parent
                        color: root.tempColor
                        font.pixelSize: 11
                        font.bold: true
                        text: root.tempText
                    }
                }
            }
        }

        Rectangle {
            visible: root.ratio >= 0
            width: parent.width
            height: 4
            radius: 2
            color: Theme.overlay

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.ratio))
                height: parent.height
                radius: parent.radius
                color: root.ratioColor

                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
    }
}
