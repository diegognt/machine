import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import "../"

// Bottom-centered, floating application launcher. Toggled via
// `qs ipc call launcher toggle` (bound to `Mod + Space` in Hyprland).
PanelWindow {
    id: launcher

    // No left/right anchor: wlr-layer-shell centers horizontally by default.
    anchors {
        bottom: true
    }

    margins {
        bottom: 0
    }

    color: "transparent"
    visible: false
    focusable: true
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "app-launcher"

    readonly property real screenWidth: screen ? screen.width : 1920
    readonly property real screenHeight: screen ? screen.height : 1080

    implicitWidth: Math.round(screenWidth * 0.33)
    implicitHeight: Math.round(screenHeight * 0.25)

    property string searchText: ""
    property int selectedIndex: 0

    readonly property var allApps: {
        const apps = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        return apps
            .filter(a => !a.noDisplay)
            .slice()
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    readonly property var filteredApps: {
        const q = searchText.trim().toLowerCase();
        if (q.length === 0) return allApps;
        return allApps.filter(a => a.name.toLowerCase().indexOf(q) >= 0);
    }

    function open() {
        searchText = "";
        selectedIndex = 0;
        visible = true;
        searchInput.forceActiveFocus();
    }

    function close() {
        visible = false;
        searchText = "";
    }

    function toggle() {
        if (visible) close();
        else open();
    }

    function launch(entry) {
        if (!entry) return;
        entry.execute();
        close();
    }

    function moveSelection(delta) {
        if (filteredApps.length === 0) return;
        selectedIndex = (selectedIndex + delta + filteredApps.length) % filteredApps.length;
        appList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    onSearchTextChanged: selectedIndex = 0
    onVisibleChanged: if (visible) searchInput.forceActiveFocus()

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.toggle() }
        function open(): void { launcher.open() }
        function close(): void { launcher.close() }
    }

    Rectangle {
        anchors.fill: parent
        // Square off bottom corners and overshoot slightly since the window
        // sits flush against the screen's bottom edge.
        anchors.bottomMargin: -1
        topLeftRadius: 14
        topRightRadius: 14
        bottomLeftRadius: 0
        bottomRightRadius: 0
        color: Theme.base
        border.width: 1
        border.color: Theme.overlay

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // --- Search field ---
            Rectangle {
                width: parent.width
                height: 36
                radius: 8
                color: Theme.surface
                border.width: 1
                border.color: Theme.overlay

                Row {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.iconFontFamily
                        font.pixelSize: 18
                        color: Theme.subtle
                        text: "\ue8b6" // search
                    }

                    TextInput {
                        id: searchInput
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 30
                        color: Theme.text
                        font.pixelSize: 14
                        clip: true
                        text: launcher.searchText
                        onTextChanged: launcher.searchText = text

                        Keys.onEscapePressed: launcher.close()
                        Keys.onDownPressed: launcher.moveSelection(1)
                        Keys.onUpPressed: launcher.moveSelection(-1)
                        Keys.onReturnPressed: launcher.launch(launcher.filteredApps[launcher.selectedIndex])
                        Keys.onEnterPressed: launcher.launch(launcher.filteredApps[launcher.selectedIndex])
                    }
                }
            }

            // --- Scrolling application list ---
            ListView {
                id: appList
                width: parent.width
                height: parent.height - 46
                clip: true
                spacing: 4
                model: launcher.filteredApps
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: delegateRoot
                    required property var modelData
                    required property int index

                    width: appList.width
                    height: 40
                    radius: 8
                    color: index === launcher.selectedIndex
                        ? Theme.highlightMed
                        : (mouseArea.containsMouse ? Theme.highlightLow : "transparent")

                    Row {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 10

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 24
                            source: Quickshell.iconPath(delegateRoot.modelData.icon, "application-x-executable")
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 40
                            spacing: 0

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                color: Theme.text
                                font.pixelSize: 13
                                text: delegateRoot.modelData.name
                            }

                            Text {
                                visible: delegateRoot.modelData.comment.length > 0
                                width: parent.width
                                elide: Text.ElideRight
                                color: Theme.subtle
                                font.pixelSize: 11
                                text: delegateRoot.modelData.comment
                            }
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            launcher.selectedIndex = delegateRoot.index;
                            launcher.launch(delegateRoot.modelData);
                        }
                    }
                }

                Text {
                    visible: appList.count === 0
                    anchors.centerIn: parent
                    color: Theme.muted
                    text: "No applications found"
                }
            }
        }
    }
}
