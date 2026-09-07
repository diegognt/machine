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
        anchor.window: calendar.barWindow
        anchor.rect.x: calendar.barWindow ? calendar.mapToItem(calendar.barWindow.contentItem, 0, 0).x : 0
        anchor.rect.y: Theme.barHeight
        anchor.rect.width: calendar.width
        anchor.rect.height: 0
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.adjustment: PopupAdjustment.Slide
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
