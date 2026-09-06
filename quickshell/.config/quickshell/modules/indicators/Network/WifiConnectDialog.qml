import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../"

// Native, macOS-style "Enter the password for..." modal. Unlike a
// PopupWindow anchored to a bar item, this is a full-screen, centered
// top-level surface — it doesn't reposition itself while typing, doesn't
// jitter when its content resizes, and grabs keyboard focus properly for
// the password field.
PanelWindow {
    id: dialog

    property string ssid: ""
    property bool connecting: false
    property string errorText: ""
    property bool showPasswordText: false

    signal accepted(string password)
    signal cancelled()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: false
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function open(forSsid) {
        ssid = forSsid;
        errorText = "";
        connecting = false;
        passwordInput.text = "";
        showPasswordText = false;
        visible = true;
        passwordInput.forceActiveFocus();
    }

    function close() {
        visible = false;
        cancelled();
    }

    function submit() {
        if (passwordInput.text.length === 0) return;
        connecting = true;
        accepted(passwordInput.text);
    }

    onVisibleChanged: {
        if (visible) passwordInput.forceActiveFocus();
    }

    // Dimmed backdrop — click outside the card to cancel.
    Rectangle {
        anchors.fill: parent
        color: "#B0000000"

        MouseArea {
            anchors.fill: parent
            onClicked: dialog.close()
        }
    }

    // Card
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 340
        implicitHeight: content.implicitHeight + 32
        radius: 12
        color: Theme.base
        border.width: 2
        border.color: Theme.overlay

        // Swallow clicks so they don't fall through to the backdrop.
        MouseArea { anchors.fill: parent }

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.iconFontFamily
                font.pixelSize: 40
                color: Theme.foam
                text: "\ue1ba" // network_wifi
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: Theme.text
                font.pixelSize: 14
                text: "Enter the password for \u201C" + dialog.ssid + "\u201D"
            }

            Rectangle {
                width: parent.width
                height: 32
                radius: 6
                color: Theme.surface
                border.width: 1
                border.color: Theme.overlay

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.margins: 8
                    color: Theme.text
                    font.pixelSize: 13
                    echoMode: dialog.showPasswordText ? TextInput.Normal : TextInput.Password
                    clip: true
                    selectByMouse: true
                    onAccepted: dialog.submit()
                }
            }

            Text {
                visible: dialog.errorText.length > 0
                width: parent.width
                wrapMode: Text.WordWrap
                color: Theme.love
                font.pixelSize: 12
                text: dialog.errorText
            }

            Row {
                spacing: 6

                Rectangle {
                    width: 14
                    height: 14
                    radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: dialog.showPasswordText ? Theme.pine : "transparent"
                    border.width: 1
                    border.color: Theme.subtle

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dialog.showPasswordText = !dialog.showPasswordText
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.subtle
                    font.pixelSize: 12
                    text: "Show password"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dialog.showPasswordText = !dialog.showPasswordText
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 8
                layoutDirection: Qt.RightToLeft

                Rectangle {
                    width: 72
                    height: 28
                    radius: 6
                    color: (passwordInput.text.length > 0 && !dialog.connecting) ? Theme.pine : Theme.surface
                    opacity: dialog.connecting ? 0.6 : 1.0

                    Text {
                        anchors.centerIn: parent
                        color: Theme.text
                        font.bold: true
                        text: dialog.connecting ? "..." : "Join"
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: passwordInput.text.length > 0 && !dialog.connecting
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dialog.submit()
                    }
                }

                Rectangle {
                    width: 72
                    height: 28
                    radius: 6
                    color: Theme.surface

                    Text {
                        anchors.centerIn: parent
                        color: Theme.text
                        text: "Cancel"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dialog.close()
                    }
                }
            }
        }
    }
}
