# Hyprland Scrolling Layout — Workflow Cheat-Sheet

This configuration utilizes Hyprland's built-in **`scrolling`** layout, creating an infinite horizontal "tape" or carousel of columns. Windows never get squished when opening multiple applications; columns retain readable widths, and the viewport smoothly slides horizontally as focus moves.

---

## Mental Model: The Stream (Workflow 1)

Instead of fragmenting work across multiple virtual workspaces, arrange your active working context along a continuous left-to-right strip:

```
[Secondary/Chat (33%)] <---> [IDE / Main Editor (67%)] <---> [Browser / Docs (67%)] <---> [Terminal (50%)]
```

- **Columns**: Units of horizontal layout along the tape.
- **Stacks**: Multiple windows stacked vertically within the same column (e.g. editor + terminal).
- **Dynamic Widths**: Quickly flip column widths between presets (`33%`, `50%`, `67%`, `100%`).

---

## Keybindings Cheat-Sheet

> Note: `Super` refers to the Windows / Command key (`mainMod`).

### 1. Stream Navigation & Positioning

| Action | Shortcut | Description |
| :--- | :--- | :--- |
| **Move Left / Right** | `Super + Left` / `Super + Right` | Slide viewport between columns across the tape |
| **Vim Left / Right** | `Super + H` / `Super + L` | Slide viewport between columns (vim keys) |
| **Move Up / Down** | `Super + Up` / `Super + Down` | Move focus within a vertically stacked column |
| **Vim Up / Down** | `Super + K` / `Super + J` | Move focus within a vertically stacked column (vim keys) |
| **Jump to Start** | `Super + Home` | Leap instantly to the first column on the tape |
| **Jump to End** | `Super + End` | Leap instantly to the last column on the tape |
| **Center / Fit** | `Super + C` | Re-center / fit the active column into viewport |

---

### 2. Column Sizing & Presets

Columns cycle through predefined widths: **`0.333` (33%) $\leftrightarrow$ `0.5` (50%) $\leftrightarrow$ `0.667` (67%) $\leftrightarrow$ `1.0` (100%)**.

| Action | Shortcut | Description |
| :--- | :--- | :--- |
| **Grow Preset** | `Super + ]` or `Super + =` | Step width up (`33%` $\to$ `50%` $\to$ `67%` $\to$ `100%`) |
| **Shrink Preset** | `Super + [` or `Super + -` | Step width down (`100%` $\to$ `67%` $\to$ `50%` $\to$ `33%`) |
| **Fullscreen** | `Super + F` | Toggle true fullscreen on the active window |

> **Navigation while Fullscreen**: `binds:movefocus_cycles_fullscreen = true` is enabled. You can continue using your navigation shortcuts (`Super + Left / Right` or `Super + H / L`) to cycle through other windows while preserving fullscreen.

---

### 3. Column Stacking & Organization

| Action | Shortcut | Description |
| :--- | :--- | :--- |
| **Stack / Expel** | `Super + BackSpace` | Consume adjacent window into current column, or expel if already stacked |
| **Promote Window** | `Super + Shift + BackSpace` | Pop window out of vertical stack into its own standalone column |
| **Move Window Left** | `Super + Ctrl + Left` / `H` | Move window position to the left column |
| **Move Window Right**| `Super + Ctrl + Right` / `L` | Move window position to the right column |
| **Move Window Up** | `Super + Ctrl + Up` / `K` | Move window upward within the current column stack |
| **Move Window Down** | `Super + Ctrl + Down` / `J` | Move window downward within the current column stack |

---

### 4. Applications & System

| Action | Shortcut | Description |
| :--- | :--- | :--- |
| **Terminal** | `Super + Return` | Launch Ghostty |
| **Application Menu** | `Super + Space` | Launch Hyprlauncher |
| **Browser** | `Super + W` | Launch Firefox |
| **File Manager** | `Super + E` | Launch Dolphin |
| **Close Window** | `Super + Q` | Close focused window |
| **Toggle Floating** | `Super + V` | Toggle floating state |
| **Exit / Power Menu** | `Super + M` | Exit Hyprland / launch hyprshutdown |
| **Special Workspace**| `Super + S` | Toggle scratchpad / magic workspace |
| **Move to Scratchpad**| `Super + Shift + S`| Move active window into magic scratchpad |

---

## Configuration Architecture

The Hyprland Lua configuration is modularized by domain in `hypr/.config/hypr/`:

- **`hyprland.lua`**: Root loader requiring domain modules.
- **`look_and_feel.lua`**: General layout selection (`scrolling`), gaps, borders, decorations, and scrolling options:
  - `column_width = 0.5`
  - `explicit_column_widths = "0.333, 0.5, 0.667, 1.0"`
  - `fullscreen_on_one_column = true`
  - `focus_fit_method = 1`
  - `wrap_focus = true`, `wrap_swapcol = true`
  - `direction = "right"`
- **`keybindings.lua`**: All shortcuts including the stream navigation and column management binds.
- **`programs.lua`**: Default application table (`terminal`, `fileManager`, `menu`, `browser`).
- **`input.lua`**: Keyboard, mouse, and natural scrolling settings.
- **`monitors.lua`**: Display resolutions, refresh rates, and scale.
- **`rules.lua`**: Window rules and workspace rules:
  - Terminal (`ghostty`) and Browser (`firefox`) automatically spawn at 100% column width (`scrolling_width = 1.0`).
- **`environment.lua`**: Environment variables.
