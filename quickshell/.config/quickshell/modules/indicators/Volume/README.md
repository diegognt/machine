# Volume Indicator

Bar indicator + hover popup for audio: shows the default output level/mute
state, click-to-mute and scroll-to-adjust straight from the bar icon, and a
popup with output/input (mic) volume sliders, mute toggles, and output/input
device switchers — backed natively by PipeWire/WirePlumber via
`Quickshell.Services.Pipewire` (no `pactl`/`pamixer`/`wpctl` shelling out
required).

## Files

| File | Responsibility |
|---|---|
| `Volume.qml` | Bar entry point. Derives output/input state from `Quickshell.Services.Pipewire` (`Pipewire`, `PwNode`, `PwObjectTracker`), renders the bar icon, handles click-to-mute and scroll-to-adjust directly on the bar icon, and owns the hover-open `PopupWindow`. |
| `VolumePopup.qml` | Popup content only: header (icon + level + device name), output volume slider + mute, input (mic) volume slider + mute, and output/input device switcher lists. Pure presentation — receives everything via properties from `Volume.qml`. |
| `VolumeSlider.qml` | Shared draggable horizontal slider widget (0..`maxValue`, supports boosted gain past 100% with a tick mark at the unboosted position). Used for both the output and input rows in `VolumePopup.qml`. |
| `qmldir` | Registers all three types under the `modules.indicators.Volume` module so they can be imported as `import "../indicators/Volume"`. |

## Data sources

- **Default sink/source, volume, mute, per-device list** →
  `Quickshell.Services.Pipewire` (reactive, PipeWire/WirePlumber backed over
  its native protocol, no polling needed).
- **Every node referenced (defaults + device lists) is wrapped in a
  `PwObjectTracker`** — required by Quickshell's Pipewire service: a node's
  `.audio`/`.ready` properties are invalid, and the node itself can be
  garbage-collected out from under you, until it's tracked this way.
- Volume is 0.0–1.0 (100%) but PipeWire/WirePlumber allow boosting past
  100%; the sliders/scroll wheel here cap boost at 1.5 (150%) to match
  typical WirePlumber defaults.

## Workflow

**Bar icon (`Volume.qml`)**
1. Reads `Pipewire.defaultAudioSink` / `defaultAudioSource` reactively.
2. Icon glyph reflects state: no sink → `volume_off`, muted or 0% →
   `volume_mute`, ≤50% → `volume_down`, >50% → `volume_up`.
3. **Left click** on the bar icon toggles mute on the default sink
   directly, no popup needed.
4. **Scroll wheel** over the bar icon steps the default sink's volume by
   5% per notch (unmuting first if needed), matching the
   `XF86AudioRaiseVolume`/`LowerVolume` hotkeys' own step size.
5. **Hover** opens the popup (150ms close-delay bridges the gap between
   the bar icon and the popup window, same mechanic as Battery/Network/
   Bluetooth).

**Popup (`VolumePopup.qml`)**
1. Header shows the current icon, level (`Muted` or `NN%`), and the active
   output device's name.
2. **Output row** — mute icon (click to toggle) + `VolumeSlider` bound to
   `sink.audio.volume` (drag to set, unmutes automatically on drag).
3. **Output device list** — only shown when more than one physical sink
   exists (`isSink && !isStream`); clicking a row sets
   `Pipewire.preferredDefaultAudioSink`, switching the system default.
4. **Input row** — same pattern as output, bound to `source.audio.volume`
   /`muted`; hidden (shows "No input device") if there's no default source.
5. **Input device list** — same pattern as the output list, filtered to
   `!isSink && !isStream` nodes, sets `Pipewire.preferredDefaultAudioSource`.

Both `Volume.qml` and `VolumePopup.qml` filter `Pipewire.nodes.values` down
to real hardware/software devices (`!isStream`) rather than per-application
stream nodes — this indicator is a system output/input mixer, not a
per-app volume mixer (e.g. pavucontrol's playback tab).

## Requirements

### Packages (Arch Linux)

| Package | Purpose | Required? |
|---|---|---|
| `pipewire` | Core multimedia server; owns all audio routing | **Yes** |
| `pipewire-pulse` | PulseAudio-compatible server on top of PipeWire | **Yes** — needed by any Pulse-protocol client (browsers, Discord, etc.); also what `pactl`/`wpctl` talk to if you use them for debugging |
| `pipewire-alsa` | ALSA-compatible layer on top of PipeWire | Recommended — needed by ALSA-only apps |
| `wireplumber` | Session/policy manager for PipeWire (device routing, default sink/source selection, volume persistence) | **Yes** — `Quickshell.Services.Pipewire` talks to the graph WirePlumber manages |
| `quickshell` | Provides the `Quickshell.Services.Pipewire` QML module itself | **Yes** (already required for the whole shell) |
| `ttf-material-symbols-variable` | Icon font (`Theme.iconFontFamily`) used for all glyphs in this indicator | **Yes** (shared across the whole bar, not Volume-specific) |

Install everything audio-specific with:

```bash
sudo pacman -S pipewire pipewire-pulse pipewire-alsa wireplumber
```

**Explicitly not required**: `pulseaudio` (conflicts with
`pipewire-pulse`), `pamixer`, `pavucontrol` (useful standalone for
per-app mixing/debugging, but not a dependency of this indicator),
`alsa-utils`'s `amixer` — this indicator talks to PipeWire directly
through Quickshell's own service, no CLI tool is shelled out to.

### Services

`pipewire`, `pipewire-pulse`, and `wireplumber` are user-level systemd
services, normally socket-activated automatically (no need to `enable` them
manually on most setups — the sockets start them on first connection). If
they aren't running:

```bash
systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service
```

Verify:

```bash
systemctl --user status pipewire pipewire-pulse wireplumber
pactl info   # should report "Server Name: PulseAudio (on PipeWire ...)"
```

### Hardware

At least one audio sink (speakers/headphones/HDMI) is expected for the
indicator to show anything other than "No output device"; a source
(microphone) is optional — the mic row simply hides itself
(`visible: root.sourceReady`) if `Pipewire.defaultAudioSource` is null.

## Usage

Registered in the bar via `RightIsland.qml`:

```qml
import "../indicators/Volume"
...
Volume {}
```

`Theme` (colors, `pillBackground`, `barHeight`) is provided by the parent
`modules/` scope and imported with `import "../../"` from within this
folder.

## Related keybindings

Hardware multimedia keys are wired independently in Hyprland
(`hypr/.config/hypr/keybindings.lua`) via `wpctl`, so volume can still be
changed with no bar/popup interaction at all:

```lua
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
```

Both paths (hotkeys via `wpctl`, and the bar/popup via
`Quickshell.Services.Pipewire`) operate on the same live PipeWire graph, so
they always stay in sync with each other.
