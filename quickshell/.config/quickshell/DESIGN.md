# Quickshell Design System

Living reference for this shell's look & feel. Treat this as source of truth
for *intent* — `modules/Theme.qml` is source of truth for *exact values*.
When they drift apart, update both in the same change.

If a reference screenshot is added to the repo (e.g. `design/reference-*.png`),
list it under "References" below and note what it documents (a specific
component, a full panel, a color mood, etc.), so future changes can be
checked against it.

## References

- _(none yet — drop screenshots here, e.g. `design/control-center.png`, and
  list them with a one-line description of what they capture)_

## Palette — Rose Pine Moon

Source: https://rosepinetheme.com/palette/. All colors are centralized in
`modules/Theme.qml` — never hardcode a hex color in a component; reference
`Theme.<name>` instead, even if it means adding a new semantic alias.

| Role | Property | Hex | Usage |
|---|---|---|---|
| Base background | `Theme.base` | `#232136` | Window backgrounds (Launcher, Control Center) |
| Surface | `Theme.surface` | `#2a273f` | Pills, cards, sliders' unfilled track |
| Overlay | `Theme.overlay` | `#393552` | Borders, dividers |
| Muted text | `Theme.muted` | `#6e6a86` | Disabled/low-emphasis text |
| Subtle text | `Theme.subtle` | `#908caa` | Secondary text, labels |
| Primary text | `Theme.text` | `#e0def4` | Primary text, active icons |
| Love (red/pink) | `Theme.love` | `#eb6f92` | Errors |
| Gold | `Theme.gold` | `#f6c177` | Warnings, muted-state, brightness accents |
| Rose | `Theme.rose` | `#ea9a97` | Reserved |
| Pine (blue) | `Theme.pine` | `#3e8fb0` | Success, output-volume accent |
| Foam (cyan) | `Theme.foam` | `#9ccfd8` | Info, input/mic accent |
| Iris (purple) | `Theme.iris` | `#c4a7e7` | Primary accent — active toggles, selection, links |

Semantic aliases (`Theme.error`, `Theme.warning`, `Theme.success`,
`Theme.info`, `Theme.accent`, `Theme.selection`, `Theme.hover`, ...) exist
so components can express *intent* instead of picking a Rose Pine color
name directly. Prefer the semantic alias unless the raw palette name reads
more clearly at the call site (e.g. picking `Theme.foam` specifically for
"this is the microphone/input row, distinct from the pine output row").

## Iconography

- Single icon font project-wide: `Theme.iconFontFamily` = "Material Symbols
  Outlined". Never mix in FontAwesome/Nerd Font glyphs.
- Bar-level icons: `Theme.iconSize` (18px).
- Popup/section header icons: ~32px (matches the two-line header pattern
  in `*Popup.qml` files — icon spans the full height of a name+state text
  block).
- `ToggleTile` icons: scaled to the tile's own size (see Components below).

## Spacing & Sizing Tokens

All in `modules/Theme.qml`. Two independent scales exist — the **bar**
scale and the **Control Center** scale — because they're visually distinct
surfaces (floating pills on a translucent bar vs. a solid side panel).

### Bar scale
| Token | Value | Meaning |
|---|---|---|
| `barHeight` | 48 | Fixed bar height |
| `barPaddingHorizontal` / `Vertical` | 6 / 4 | Bar edge → islands |
| `pillHeight` | 38 | Every ModulePill's height |
| `pillRadius` | 6 | ModulePill corner radius |
| `pillPaddingHorizontal` / `Vertical` | 6 / 6 | Pill edge → content |
| `pillContentSpacing` | 10 | Gap between parts inside one pill |
| `islandSpacing` | 8 | Gap between pills within an island |

### Control Center scale
| Token | Value | Meaning |
|---|---|---|
| `controlCenterWidthRatio` | 0.25 | Panel width = 25% of screen width |
| `controlCenterPadding` | 16 | Panel edge → header/section list |
| `controlCenterHeaderSpacing` | 12 | Header → section list gap |
| `controlCenterSectionSpacing` | 12 | Gap between section cards |
| `sectionCardPadding` | 12 | SectionCard edge → its content |
| `sectionCardSpacing` | 10 | Gap between a card's internal pieces |

**Rule of thumb**: if you're adding a new spacing/sizing constant used by
more than one component, promote it to `Theme.qml` rather than repeating a
literal.

## Layout Primitives

- **`Island`** — pure horizontal layout container (no visuals) for a group
  of pills on the bar. Owns only inter-pill spacing.
- **`ModulePill`** — the bar's visual "chip": rounded `Theme.pillBackground`
  rectangle, fixed `pillHeight`, hosts one bar indicator's content.
- **`SectionCard`** — the Control Center's equivalent of ModulePill: a
  rounded `Theme.surface` card with an optional uppercase title+icon
  header, a divider, and arbitrary content below. Every Control Center
  section should be built as (or wrap) a `SectionCard`, *unless* it needs
  non-visual helpers (`FileView`, `Timer`, `Process`, `PwObjectTracker`,
  `SystemClock`, ...) as direct children — those can't live inside
  SectionCard's `Column`-based default content, so in that case wrap a
  plain `Item` around a sibling pair of (helpers) + (`SectionCard { ... }`)
  — see `BrightnessSection.qml`/`VolumeSection.qml`/`HardwareSection.qml`
  for the pattern.

## Components

### ToggleTile
Quick-toggle button (Wi-Fi/Bluetooth-style, GNOME/macOS quick settings).
Icon + label centered, `Theme.iris` fill when active, `Theme.surface`
otherwise, `opacity: 0.4` when unavailable. Icon/label font sizes scale
off the tile's own `height` (clamped 18–32px icon, 11–16px label) rather
than being fixed, so tiles of different sizes get proportionally sized
content. Used by `ConnectivitySection` as short, wide tiles (half the
section's width, half that width's height again) rather than squares.

### ControlSlider
Standard-looking slider for Control Center sections that need a
draggable value (Sound, Brightness): icon + label + percentage in a
header row, with a normal thin (8px) rounded track and round handle
underneath — matching the same visual language as the bar's own
`VolumeSlider.qml`/`BrightnessSlider.qml`, just sized for the wider
Control Center column. The icon has its own click handler
(`iconClicked()`) for mute/power toggles, independent of dragging the
track.

### MetricRow
Compact "at a glance" hardware metric row used by `HardwareSection`: icon
+ label on the left, a value + optional temperature/power badges on the
right, and a thin color-coded progress bar underneath. The progress bar
is hidden when `ratio < 0` (e.g. Network, which has no single 0–100%
figure); the temperature/power badges are hidden whenever their
corresponding `tempText`/`powerText` is empty, so metrics that don't have
a meaningful reading for a given piece of hardware simply omit it.

### UserAvatar / UserHeader
`UserAvatar` is a circular avatar that tries a short list of well-known
face-image paths, falling back to a colored circle with the user's
initials if none load. `UserHeader` combines it with a two-line text
block (full name / `user@host`) at the very top of the Control Center.

### SessionControls
Row of session/power-management buttons (Lock, Logout, Suspend, Reboot,
Shutdown) directly below `UserHeader`, firing the same commands already
used by this config's `hypridle.conf`/`keybindings.lua` via
`Quickshell.execDetached`.

## Motion

- Toggle/state color transitions: `ColorAnimation { duration: 150-200;
  easing.type: Easing.OutCubic }`.
- Slider fill width: `NumberAnimation { duration: 120 }`, disabled while
  actively dragging (`enabled: !dragArea.pressed`) so live drags feel
  1:1 instead of lagging behind a tween.
- Panel slide in/out (Control Center): margin-based, `NumberAnimation {
  duration: 220; easing.type: Easing.OutCubic }` on `margins.right`
  (window stays `visible: true`; the margin itself parks it off-screen).
- Switch toggle thumb (WifiToggle/BluetoothToggle): `NumberAnimation {
  duration: 120 }` on `x`.
- Hardware metric progress bars: `NumberAnimation { duration: 300;
  easing.type: Easing.OutCubic }` on width, since these update on a slow
  (~3s) poll interval rather than live dragging.

## Control Center — Structure & Conventions

- One `PanelWindow`, anchored `top+bottom+right`, `implicitWidth:
  screenWidth * Theme.controlCenterWidthRatio`, `exclusionMode:
  ExclusionMode.Ignore` (overlay, doesn't reserve screen space like the
  bar). Open/close state lives in the `ControlCenterState` singleton, not
  on the window itself, so the trigger (`ControlCenterToggle`, last pill
  in `RightIsland`) and the window can both react to shared state.
- Sliding is done via `margins.right` (0 ↔ `-panelWidth`) with a
  `Behavior`, **not** by toggling `visible` — a hidden window never
  animates.
- Header (top → bottom): `UserHeader` + close button, `SessionControls`,
  divider. Below that, the scrollable section list, currently:
  Connectivity (fast toggles) → Sound → Brightness → Hardware (metrics,
  pinned last). Re-evaluate this order whenever adding/removing a section
  rather than just appending at the end.
- Sections reuse bar-side state-derivation logic (e.g. icon/color rules
  from `Volume.qml`, `Brightness.qml`) by duplicating the same computed
  properties rather than importing the bar indicator directly — sections
  are meant to be independently laid out, only the *state logic* is meant
  to match 1:1. When the bar's derivation logic changes, update the
  Control Center section's copy too.
- Full device lists / secondary detail (paired BT devices, Wi-Fi network
  scan, power profile switcher, battery health, calendar/uptime, etc.)
  intentionally stay in the bar's own hover popups rather than being
  duplicated into the Control Center.

## Working Conventions

- No hardcoded hex colors or magic-number spacing/sizing in component
  files — always go through `Theme.qml`. If a value is only used once and
  is unlikely to be reused, a local `readonly property` is fine, but if
  it's shared across ≥2 files (or conceptually *should* be, like
  panel-edge padding), promote it to `Theme.qml`.
- Non-visual QML types (`FileView`, `Timer`, `Process`, `PwObjectTracker`,
  `SystemClock`, `IpcHandler`, ...) cannot be children of a component
  whose `default property` is aliased to a `Row`/`Column`/`Grid`'s
  `children` (e.g. `SectionCard`, `ModulePill`). Declare them as siblings
  in a wrapping plain `Item` instead.
- Every `*Section.qml` in `modules/controlcenter/` should have a header
  comment explaining: (a) what state it derives and from where, (b) any
  non-obvious layout constraint (e.g. the Item-wrapping-SectionCard
  workaround above).
- Shell scripts invoked from QML (e.g. `scripts/hwmetrics.sh`) should be
  standalone, commented files rather than inline `sh -c '...'` strings
  once they need more than a couple of pipes — far more readable/testable.
