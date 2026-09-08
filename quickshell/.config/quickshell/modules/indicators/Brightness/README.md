# Brightness Indicator

Bar indicator + hover popup managing the screen backlight and the keyboard
backlight **in conjunction**, from a single icon instead of two separate
ones — click-to-cycle the keyboard backlight and scroll-to-adjust screen
brightness straight from the bar icon, plus a popup with independent
sliders for both, backed directly by sysfs (`/sys/class/backlight`,
`/sys/class/leds`) via `Quickshell.Io.FileView` for reads and
`brightnessctl` for writes.

## Files

| File | Responsibility |
|---|---|
| `Brightness.qml` | Bar entry point. Reads screen/keyboard brightness reactively from sysfs via `Quickshell.Io.FileView` (`watchChanges: true`, so hotkey/external changes are picked up live), renders the bar icon, handles click-to-cycle (keyboard) and scroll-to-adjust (screen) directly on the bar icon, debounces writes through `brightnessctl`, and owns the hover-open `PopupWindow`. |
| `BrightnessPopup.qml` | Popup content only: screen brightness header (icon + %) + slider, keyboard backlight header (icon + % or "Off") + slider. Pure presentation — receives everything via properties/signals from `Brightness.qml`. |
| `BrightnessSlider.qml` | Shared draggable horizontal slider widget (0–100, no boost/tick-mark concept — unlike `VolumeSlider.qml`, brightness has no "over 100%" state). Used for both the screen and keyboard rows in `BrightnessPopup.qml`. |
| `qmldir` | Registers all three types under the `modules.indicators.Brightness` module so they can be imported as `import "../indicators/Brightness"`. |

## Data sources

- **Screen backlight** — `/sys/class/backlight/nvidia_wmi_ec_backlight/{brightness,max_brightness}`,
  a smooth 0–100 (well, 0–`max_brightness`) range.
- **Keyboard backlight** — `/sys/class/leds/asus::kbd_backlight/{brightness,max_brightness}`,
  a small stepped range (0–3 on this hardware: off/low/med/high), not a
  smooth percentage like the screen.
- Both device names are **hardcoded** to this machine's actual hardware
  (`brightnessctl -l` to discover the names on a different machine),
  the same way `Volume.qml`'s hotkeys hardcode `@DEFAULT_AUDIO_SINK@`
  rather than trying to be generic over hardware this shell doesn't run
  on.
- Reads go through `Quickshell.Io.FileView` with `watchChanges: true` +
  `onFileChanged: reload()`, so changes made outside the shell (hardware
  hotkeys via `hypridle`/`Hyprland`, another tool, etc.) are reflected
  immediately — no polling.
- **Writes go through `brightnessctl`, not a raw sysfs write** — both
  `brightness` nodes are `root:root 644` (not group/other-writable) on
  this system, so a raw write would fail for a normal user.
  `brightnessctl` itself talks to `logind`'s `SetBrightness` D-Bus method
  when it can't write the sysfs node directly, which "just works" for any
  user with an active graphical session — no root, no udev ACL rule, no
  `video` group membership required.
- Writes are **debounced** (40ms `Timer`) so dragging a popup slider
  doesn't spawn a `brightnessctl` process per pixel of movement — only
  the settled value is written.

## Workflow

**Bar icon (`Brightness.qml`)**
1. Reads `screenRaw`/`screenMax` and `kbdRaw`/`kbdMax` reactively from
   their respective `FileView`s.
2. Icon glyph reflects the **screen's** level: `brightness_low` (≤33%),
   `brightness_medium` (≤66%), `brightness_high` (>66%).
3. Icon **color** ramps with the screen's level across the RosePine Moon
   grayscale text hierarchy (`Theme.muted` → `Theme.subtle` → `Theme.text`,
   via `Theme.grayLevel(ratio)`), animated with a 200ms `ColorAnimation`
   so it fades smoothly between levels instead of cutting hard.
4. **Left click** on the bar icon cycles the keyboard backlight
   (off → low → ... → max → off), matching a physical keyboard-backlight
   toggle key.
5. **Scroll wheel** over the bar icon steps screen brightness by 5% per
   notch, matching the `XF86MonBrightnessUp`/`Down` hotkeys' own step
   size.
6. **Hover** opens the popup (150ms close-delay bridges the gap between
   the bar icon and the popup window, same mechanic as
   Battery/Network/Bluetooth/Volume).

**Popup (`BrightnessPopup.qml`)**
1. **Screen header** — icon + `NN%`, "Screen brightness" label.
2. **Screen row** — icon + `BrightnessSlider` bound to `screenPct`; drag
   sets brightness immediately (debounced write).
3. **Keyboard header** — icon (a `backlight_high` glyph — a panel with
   light rays, chosen over the generic `keyboard` outline glyph since it
   reads more clearly as "backlight" specifically) + `NN%` or `"Off"`,
   "Keyboard backlight" label.
4. **Keyboard row** — same `backlight_high` icon (click to cycle,
   mirroring the bar icon's click behavior) + `BrightnessSlider` bound to
   `kbdPct`.
5. Both keyboard icons' color ramps the same way as the screen icon
   (`Theme.grayLevel(kbdRatio)`, animated), but falls back to
   `Theme.muted` while the backlight is fully off.

## Requirements

### Packages (Arch Linux)

| Package | Purpose | Required? |
|---|---|---|
| `brightnessctl` | Reads/writes brightness for both backlight and LED-class devices; falls back to `logind`'s `SetBrightness` D-Bus call when it can't write sysfs directly | **Yes** |
| `quickshell` | Provides the `Quickshell.Io` (`FileView`, `Process`) QML modules used to read sysfs and run `brightnessctl` | **Yes** (already required for the whole shell) |
| `ttf-material-symbols-variable` | Icon font (`Theme.iconFontFamily`) used for all glyphs in this indicator | **Yes** (shared across the whole bar, not Brightness-specific) |

```bash
sudo pacman -S brightnessctl
```

### Hardware

- A backlight device under `/sys/class/backlight/` (screen). If there is
  none (desktop, external monitor with no DDC/CI support wired up),
  `screenRaw`/`screenMax` both fall back to 0/100 rather than erroring.
- A keyboard-backlight LED device under `/sys/class/leds/` (e.g.
  `asus::kbd_backlight` — name varies by vendor: `dell::kbd_backlight`,
  `tpacpi::kbd_backlight`, etc. on other laptops). Run `brightnessctl -l`
  to find the exact name on a given machine and update `kbdDevice` in
  `Brightness.qml` accordingly — this indicator does not attempt to
  auto-discover it.

### Permissions

No special group membership or udev rule is required as long as
`brightnessctl` is used for writes (see "Data sources" above) — it goes
through `logind`, which already grants brightness-write access to the
user of the active graphical session. If you ever swap the writer for a
raw `echo N > .../brightness`, you'd need a `video`-group-writable ACL
or udev rule instead (not needed here).

## Usage

Registered in the bar via `RightIsland.qml`, between Volume and Battery:

```qml
import "../indicators/Brightness"
...
Brightness {}
```

`Theme` (colors, `grayLevel()`, `pillBackground`, `barHeight`) is provided
by the parent `modules/` scope and imported with `import "../../"` from
within this folder.

## Related keybindings

Hardware multimedia keys are wired independently in Hyprland
(`hypr/.config/hypr/keybindings.lua`) via `brightnessctl`, so screen
brightness can still be changed with no bar/popup interaction at all
(there's no dedicated hardware key for the keyboard backlight on this
machine, so it's bar/popup-only):

```lua
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
```

Both paths (hotkeys and the bar/popup) write through `brightnessctl`
straight to the same sysfs node, and reads stay in sync via `FileView`'s
`watchChanges: true`, so they never drift apart from each other.
