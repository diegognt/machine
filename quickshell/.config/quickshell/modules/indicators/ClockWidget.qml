import QtQuick
import Quickshell.Io
import "../"

IndicatorLabel {
    id: clock
    font.capitalization: Font.Capitalize

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
