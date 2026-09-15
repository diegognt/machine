import QtQuick
import "../"

// Shared "card" wrapper for a single Control Center section: a rounded
// surface with a small uppercase title (+ optional icon) header, a
// divider, and arbitrary content below. Mirrors ModulePill's role for the
// bar — carries the look, leaves the content to whoever instantiates it.
Rectangle {
    id: root
    default property alias content: contentColumn.children
    property string title: ""
    property string icon: ""

    radius: 10
    color: Theme.surface
    border.width: 1
    border.color: Theme.overlay
    implicitHeight: contentColumn.implicitHeight + Theme.sectionCardPadding * 2

    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.sectionCardPadding
        spacing: Theme.sectionCardSpacing

        Row {
            width: parent.width
            spacing: 8
            visible: root.title.length > 0

            Text {
                visible: root.icon.length > 0
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
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
                text: root.title
            }
        }

        Rectangle {
            visible: root.title.length > 0
            width: parent.width
            height: 1
            color: Theme.overlay
        }
    }
}
