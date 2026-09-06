import QtQuick

// Shared rounded, translucent background used behind each bar module. Its
// height always fills the Island (which itself fills the bar's padded
// content area) — the bar/island are solely responsible for the space
// between indicators and the screen edges. This pill only manages its own
// internal spacing: the padding between its content and its own edges.
Rectangle {
    id: root
    default property alias content: contentRow.children
    property alias spacing: contentRow.spacing

    readonly property bool hovered: hoverArea.containsMouse

    anchors.verticalCenter: parent.verticalCenter
    height: Theme.pillHeight
    color: Theme.pillBackground
    radius: Theme.pillRadius
    implicitWidth: contentRow.implicitWidth + Theme.pillPaddingHorizontal * 2

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: Theme.pillContentSpacing
    }
}
