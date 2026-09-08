import QtQuick
import "../../"

// Hover-popup content: screen brightness header+slider, keyboard backlight
// header+slider. Pure presentation — receives everything via properties
// and signals from Brightness.qml.
Column {
    id: root
    spacing: 8

    property string icon: ""
    property color stateColor: Theme.text
    property color kbdColor: Theme.muted
    property int screenPct: 0
    property int kbdPct: 0
    property bool kbdOn: false

    signal screenMoved(real pct)
    signal kbdMoved(real pct)
    signal kbdToggled()

    Item {
        width: parent.width
        height: nameText.height + stateText.height

        Text {
            id: headerIcon
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.iconFontFamily
            font.pixelSize: 32
            color: root.stateColor
            text: root.icon

            Behavior on color {
                ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }

        Text {
            id: nameText
            anchors.left: headerIcon.right
            anchors.leftMargin: 8
            anchors.top: parent.top
            color: Theme.text
            font.pixelSize: 16
            font.bold: true
            text: root.screenPct + "%"
        }
        Text {
            id: stateText
            anchors.left: nameText.left
            anchors.top: nameText.bottom
            color: Theme.subtle
            text: "Screen brightness"
        }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.surface }

    Row {
        width: parent.width
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.iconFontFamily
            font.pixelSize: 18
            color: root.stateColor
            text: "\ue1ac" // brightness_high

            Behavior on color {
                ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }

        BrightnessSlider {
            width: parent.width - 30
            anchors.verticalCenter: parent.verticalCenter
            value: root.screenPct
            onMoved: (v) => root.screenMoved(v)
        }
    }

    Rectangle { width: parent.width; height: 1; color: Theme.surface }

    Item {
        width: parent.width
        height: kbdPctText.height + kbdStateText.height

        Text {
            id: kbdHeaderIconText
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.iconFontFamily
            font.pixelSize: 32
            color: root.kbdColor
            text: "\uf7ed" // backlight_high

            Behavior on color {
                ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }

        Text {
            id: kbdPctText
            anchors.left: kbdHeaderIconText.right
            anchors.leftMargin: 8
            anchors.top: parent.top
            color: Theme.text
            font.pixelSize: 16
            font.bold: true
            text: root.kbdOn ? root.kbdPct + "%" : "Off"
        }
        Text {
            id: kbdStateText
            anchors.left: kbdPctText.left
            anchors.top: kbdPctText.bottom
            color: Theme.subtle
            text: "Keyboard backlight"
        }
    }

    Row {
        width: parent.width
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.iconFontFamily
            font.pixelSize: 18
            color: root.kbdColor
            text: "\uf7ed" // backlight_high

            Behavior on color {
                ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.kbdToggled()
            }
        }

        BrightnessSlider {
            width: parent.width - 30
            anchors.verticalCenter: parent.verticalCenter
            value: root.kbdPct
            onMoved: (v) => root.kbdMoved(v)
        }
    }
}
