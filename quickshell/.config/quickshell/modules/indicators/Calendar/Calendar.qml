import QtQuick
import Quickshell
import "../../"
import "../"

IndicatorLabel {
    id: calendar
    font.capitalization: Font.Capitalize

    SystemClock {
        id: sysClock
        // Minutes precision avoids waking up every second, saving battery.
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(sysClock.date, "ddd, MMM d  hh:mmAP")

    // Hover-popup mechanics (mirrors Battery.qml/Network.qml).
    property bool showDetails: false

    Timer {
        id: hideTimer
        interval: 150
        onTriggered: calendar.showDetails = false
    }

    function keepOpen() {
        hideTimer.stop();
        calendar.showDetails = true;
    }

    function scheduleClose() {
        hideTimer.restart();
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: calendar.keepOpen()
        onExited: calendar.scheduleClose()
    }

    // Hover-triggered detail popup: anchored to the Bar (PanelWindow)
    // itself rather than this indicator item, so its top edge always sits
    // exactly at the bar's own bottom edge - regardless of how this item
    // is vertically centered inside its (shorter) pill - instead of
    // overlapping the indicator/pill. Horizontally it still centers under
    // this item via the mapped anchor rect below.
    readonly property var barWindow: QsWindow.window

    PopupWindow {
        id: popup

        // Centered horizontally under the indicator label and flush below
        // the bar. A plain reactive binding on anchor.rect.x/y isn't
        // reliable here (see Quickshell's own Tooltip.qml) — the anchor
        // point must be (re)computed in onAnchoring, which fires whenever
        // the popup is (re)positioned, using the already-known
        // implicitWidth. With the default Top|Left edges and
        // Bottom|Right gravity, the popup grows down-right from that
        // computed point, so setting rect.x to the already-centered x
        // places the popup's left edge exactly there.
        anchor {
            window: calendar.barWindow
            gravity: Edges.Bottom | Edges.Right
            adjustment: PopupAdjustment.Slide

            onAnchoring: {
                if (!calendar.barWindow) return;
                const pos = calendar.mapToItem(calendar.barWindow.contentItem, calendar.width / 2 - popup.implicitWidth / 2, 0);
                anchor.rect.x = pos.x;
                anchor.rect.y = Theme.barHeight;
            }
        }
        implicitWidth: 260
        implicitHeight: popupContent.implicitHeight + 24
        visible: calendar.showDetails
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.pillBackground
            border.width: 2
            border.color: Theme.overlay

            HoverHandler {
                onHoveredChanged: {
                    if (hovered) calendar.keepOpen();
                    else calendar.scheduleClose();
                }
            }

            CalendarPopup {
                id: popupContent
                anchors.fill: parent
                anchors.margins: 12
                today: sysClock.date
            }
        }
    }
}
