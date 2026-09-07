# Calendar Indicator

Bar indicator + hover popup showing the current date/time, a month
calendar grid, and a couple of small "system" facts (ISO week number,
uptime).

## Files

| File | Responsibility |
|---|---|
| `Calendar.qml` | Bar entry point. Wraps `IndicatorLabel` to render the bar text (day, date, time) from a `SystemClock`, and owns the hover-open `PopupWindow` + hover mechanics (mirrors `Battery.qml`/`Network.qml`). |
| `CalendarPopup.qml` | Popup content only: month/year header, ISO week number, day-of-week row, 6×7 month grid with today highlighted, and an uptime line. Pure presentation — receives `today` as a property from `Calendar.qml`. Has a commented-out stub for a future agenda/events section. |
| `qmldir` | Registers both types under the `modules.indicators.Calendar` module so they can be imported as `import "../indicators/Calendar"`. |

## Data sources

- **Bar clock text** → `Quickshell`'s `SystemClock`, with `precision:
  SystemClock.Minutes` so it only updates once a minute (no per-second
  ticking, saves battery). Formatted via `Qt.formatDateTime(sysClock.date,
  "ddd, MMM d  hh:mmAP")`.
- **Month grid** → plain QML `Date` math in `CalendarPopup.qml` (no process
  spawning), driven by the same `today` value passed down from
  `Calendar.qml`'s `sysClock.date`. Cheap and only recomputes when the
  minute changes.
- **Uptime** → `uptime -p` via `Quickshell.Io.Process` + `StdioCollector`,
  refreshed every 60s by a `Timer`. Same shell-out pattern as the old
  date-based `ClockWidget.qml` and `NetworkPopup.qml`'s `nmcli` calls.

## Popup positioning

The popup anchors to the **Bar (`PanelWindow`)** itself rather than the
indicator item, via `QsWindow.window` (from `import Quickshell`):

```qml
readonly property var barWindow: QsWindow.window

PopupWindow {
    anchor.window: calendar.barWindow
    anchor.rect.x: calendar.mapToItem(calendar.barWindow.contentItem, 0, 0).x
    anchor.rect.y: Theme.barHeight
    anchor.rect.width: calendar.width
    anchor.rect.height: 0
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.Slide
}
```

This keeps the popup's top edge flush with the bar's actual bottom edge
(`Theme.barHeight`) regardless of how the indicator item is vertically
centered inside its (shorter) pill, while still horizontally centering it
under the indicator via the mapped `anchor.rect.x`/`width`. The same
pattern is used by `Battery.qml` and `Network/Network.qml`.

## Requirements

- **`uptime`** (procps/util-linux) must be installed and on `PATH` for the
  uptime line in the popup. Not required for the bar clock or month grid.
- **Icon font**: not used directly by this indicator (text-only), but the
  shared `IndicatorLabel` base still pulls sizing/colors from `Theme`
  (`Theme.fontSize`, `Theme.text`).

## Usage

Registered in the bar via `RightIsland.qml`:

```qml
import "../indicators/Calendar"
...
Calendar {}
```

`Theme` (colors, `barHeight`, `pillBackground`) is provided by the parent
`modules/` scope and imported with `import "../../"` from within this
folder.
