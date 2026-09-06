import QtQuick
import Quickshell.Io
import "../../"

// Native Wi-Fi network browser built directly on top of `nmcli`, instead of
// Quickshell.Networking's built-in network list. Scans with
// `nmcli -t -f BSSID,SSID,SIGNAL,SECURITY,IN-USE dev wifi list`, parses the
// colon-separated (and colon-escaped) output into a ListModel, and renders
// it with a ListView. Connecting runs
// `nmcli device wifi connect <ssid> [password <pwd>]`. If that fails because
// secrets/a password are required, a centered modal (WifiConnectDialog,
// styled like macOS's Wi-Fi password prompt) opens to collect it — instead
// of an inline row that used to resize/jitter the anchored popup.
Column {
    id: root
    width: parent.width
    spacing: 6

    // Set by the parent popup: scan while visible, stop otherwise.
    property bool active: false

    property bool scanning: false
    property string connectingSsid: ""

    ListModel { id: networkModel }

    // --- nmcli colon-separated line parsing -----------------------------
    // nmcli escapes literal colons inside field values with "\:", so a naive
    // String.split(":") would incorrectly split BSSIDs like
    // "F4\:52\:46\:A6\:D2\:FF". Walk the string manually, treating "\X" as a
    // literal X and unescaped ":" as a field separator.
    function parseNmcliLine(line) {
        const fields = [];
        let current = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length) {
                current += line[i + 1];
                i++;
            } else if (c === ":") {
                fields.push(current);
                current = "";
            } else {
                current += c;
            }
        }
        fields.push(current);
        return fields;
    }

    function refresh() {
        if (scanning) return;
        scanning = true;
        scanProcess.running = true;
    }

    Process {
        id: scanProcess
        command: ["nmcli", "-t", "-f", "BSSID,SSID,SIGNAL,SECURITY,IN-USE", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.length > 0);
                // Multiple BSSIDs can share an SSID (mesh/extenders); keep
                // only the strongest signal per SSID for a clean list.
                const bySsid = {};
                for (const line of lines) {
                    const fields = root.parseNmcliLine(line);
                    const bssid = fields[0] || "";
                    const ssid = fields[1] || "";
                    const signal = parseInt(fields[2], 10) || 0;
                    const security = fields[3] || "";
                    const inUse = (fields[4] || "").trim() === "*";

                    if (!ssid) continue; // skip hidden/blank SSIDs

                    const existing = bySsid[ssid];
                    if (!existing || signal > existing.signal) {
                        bySsid[ssid] = { bssid, ssid, signal, security, connected: inUse };
                    } else if (inUse) {
                        existing.connected = true;
                    }
                }

                const list = Object.values(bySsid).sort((a, b) => b.signal - a.signal);

                networkModel.clear();
                for (const n of list) {
                    networkModel.append({
                        ssid: n.ssid,
                        bssid: n.bssid,
                        signal: n.signal,
                        security: n.security,
                        connected: n.connected,
                    });
                }
                root.scanning = false;
            }
        }
    }

    Process {
        id: connectProcess
        property string targetSsid: ""

        stderr: StdioCollector {
            id: connectStderr
        }

        onExited: (exitCode) => {
            const failed = exitCode !== 0;

            if (failed) {
                const errText = connectStderr.text || "";
                const needsSecrets = /secret|password|key/i.test(errText);
                if (needsSecrets) {
                    connectDialog.errorText = connectDialog.visible ? "Incorrect password. Try again." : "";
                    connectDialog.connecting = false;
                    connectDialog.open(connectProcess.targetSsid);
                }
            } else if (connectDialog.visible && connectDialog.ssid === connectProcess.targetSsid) {
                connectDialog.visible = false;
            }

            root.connectingSsid = "";
            root.refresh();
        }
    }

    function connectTo(ssid, password) {
        connectingSsid = ssid;
        connectProcess.targetSsid = ssid;
        connectProcess.command = password
            ? ["nmcli", "device", "wifi", "connect", ssid, "password", password]
            : ["nmcli", "device", "wifi", "connect", ssid];
        connectProcess.running = true;
    }

    onActiveChanged: {
        if (active) refresh();
    }

    Timer {
        interval: 15000
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

    // Centered, macOS-style modal used to prompt for a Wi-Fi password.
    WifiConnectDialog {
        id: connectDialog
        onAccepted: (password) => root.connectTo(connectDialog.ssid, password)
    }

    Row {
        width: parent.width
        Text {
            color: Theme.subtle
            text: "Networks" + (root.scanning ? " (scanning...)" : "")
        }
    }

    ListView {
        id: listView
        width: parent.width
        height: Math.min(contentHeight, 200)
        clip: true
        interactive: contentHeight > height
        model: networkModel
        spacing: 2

        delegate: Rectangle {
            id: delegateRoot
            required property string ssid
            required property string bssid
            required property int signal
            required property string security
            required property bool connected
            required property int index

            width: listView.width
            height: rowContent.implicitHeight + 8
            radius: 6
            color: connected ? Theme.highlightMed : "transparent"

            readonly property bool secured: security.length > 0
            readonly property bool isConnecting: root.connectingSsid === ssid

            Row {
                id: rowContent
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 4
                spacing: 6

                Text {
                    color: Theme.text
                    text: delegateRoot.ssid
                    elide: Text.ElideRight
                    width: 130
                }
                Text {
                    color: Theme.subtle
                    text: delegateRoot.signal + "%"
                }
                Text {
                    visible: delegateRoot.secured
                    font.family: Theme.iconFontFamily
                    color: Theme.subtle
                    text: "\ue88d" // lock icon
                }
                Text {
                    visible: delegateRoot.isConnecting
                    color: Theme.gold
                    text: "..."
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: !delegateRoot.connected && !delegateRoot.isConnecting
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Try a bare connect first — works instantly for open
                    // networks and for secured networks with an existing
                    // saved profile/secrets. The password modal only opens
                    // (via connectProcess.onExited) if nmcli reports that
                    // secrets are actually required.
                    root.connectTo(delegateRoot.ssid, "");
                }
            }
        }
    }
}
