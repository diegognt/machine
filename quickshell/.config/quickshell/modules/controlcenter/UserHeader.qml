import QtQuick
import Quickshell
import Quickshell.Io
import "../"

// Very top of the Control Center: avatar + "Display Name" / "user@host".
// Username comes from the $USER env var (always present for a
// user-session process); the display name and hostname are read
// separately since neither is reliably available as an env var to a
// compositor-launched process — hostname via /etc/hostname (FileView,
// reactive to hostnamectl changes), display name via `getent passwd`
// (Process, mirrors CalendarPopup.qml's uptime-via-Process pattern).
Item {
    id: root
    implicitHeight: row.implicitHeight

    readonly property string username: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""
    property string fullName: username
    property string hostname: ""

    FileView {
        id: hostnameFile
        path: "/etc/hostname"
        watchChanges: true
        onLoaded: root.hostname = text().trim()
        onFileChanged: reload()
    }

    Process {
        id: gecosProc
        command: ["getent", "passwd", root.username]
        running: root.username.length > 0
        stdout: StdioCollector {
            onStreamFinished: {
                // passwd format: name:x:uid:gid:GECOS:home:shell
                const fields = this.text.trim().split(":");
                const gecos = fields.length > 4 ? fields[4].split(",")[0].trim() : "";
                root.fullName = gecos.length > 0 ? gecos : root.username;
            }
        }
    }

    Row {
        id: row
        width: parent.width
        spacing: 12

        UserAvatar {
            anchors.verticalCenter: parent.verticalCenter
            username: root.username
            displayName: root.fullName
            size: 48
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 48 - row.spacing
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: Theme.text
                font.pixelSize: 16
                font.bold: true
                text: root.fullName
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: Theme.subtle
                font.pixelSize: 12
                text: root.username + "@" + root.hostname
            }
        }
    }
}
