import QtQuick

// Shared rounded, translucent background used behind each bar module.
Rectangle {
    id: root
    default property alias content: contentRow.children
    property alias spacing: contentRow.spacing

    readonly property bool hovered: hoverArea.containsMouse

    anchors.verticalCenter: parent.verticalCenter
    color: Theme.pillBackground
    radius: 8
    implicitWidth: contentRow.implicitWidth + Theme.spacingLarge + Theme.spacingSmall
    implicitHeight: contentRow.implicitHeight + Theme.spacingSmall + 4

    border.width: 2
    border.color: root.hovered ? Theme.overlay : Theme.pillBorder
    Behavior on border.color { ColorAnimation { duration: 150 } }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: Theme.spacingSmall
    }
}
