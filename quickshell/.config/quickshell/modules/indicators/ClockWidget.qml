import QtQuick
import Quickshell.Io
import "../"

Text {
    id: clock
    anchors.verticalCenter: parent.verticalCenter
    font.capitalization: Font.Capitalize
    font.pixelSize: Theme.fontSize
    color: Theme.text

    Process {
        id: dateProc
        command: ["date", "+%a %-d %b %-l:%M%p"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: clock.text = this.text
        }
    }

    Timer {
        interval: 59000
        running: true
        repeat: true
        onTriggered: dateProc.running = true
    }
}
