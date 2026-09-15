import QtQuick
import Quickshell
import Quickshell.Widgets
import "../"

// Circular user avatar. Tries a short list of well-known face-image
// locations (~/.face, ~/.face.icon, AccountsService's per-user icon) in
// order; if none of them load (common on a fresh system with no avatar
// ever set — as is the case here), falls back to a colored circle with
// the user's initials, so the header never shows a broken-image icon.
Item {
    id: root

    property string username: ""
    property string displayName: username
    property int size: 48

    implicitWidth: size
    implicitHeight: size

    readonly property var candidatePaths: [
        Quickshell.env("HOME") + "/.face",
        Quickshell.env("HOME") + "/.face.icon",
        "/var/lib/AccountsService/icons/" + root.username,
    ]
    property int candidateIndex: 0
    property bool imageFailed: false

    readonly property string initials: {
        const parts = root.displayName.trim().split(/\s+/).filter(p => p.length > 0);
        if (parts.length === 0) return "?";
        if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
        return String(parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }

    // Fallback: colored circle + initials, drawn underneath the image so
    // it's only ever visible once the image is confirmed unavailable.
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.iris
        visible: root.imageFailed

        Text {
            anchors.centerIn: parent
            color: Theme.base
            font.pixelSize: Math.round(root.size * 0.4)
            font.bold: true
            text: root.initials
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        visible: !root.imageFailed

        Image {
            id: avatarImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: root.candidateIndex < root.candidatePaths.length
                ? "file://" + root.candidatePaths[root.candidateIndex]
                : ""

            onStatusChanged: {
                if (status !== Image.Error) return;
                if (root.candidateIndex < root.candidatePaths.length - 1) {
                    root.candidateIndex += 1;
                } else {
                    root.imageFailed = true;
                }
            }
        }
    }
}
