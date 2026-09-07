# Bluetooth Indicator

Bar indicator + hover popup showing Bluetooth adapter/connection state, an
always-visible list of paired devices (connect/disconnect/forget, battery
%), and a centered "Pair new device" dialog for scanning and pairing new
devices — backed natively by BlueZ over D-Bus via `Quickshell.Bluetooth`
(no `bluedevil`/KDE integration required).

## Files

| File | Responsibility |
|---|---|
| `Bluetooth.qml` | Bar entry point. Derives adapter/connection state from `Quickshell.Bluetooth` (`Bluetooth`, `BluetoothAdapter`, `BluetoothDevice`), renders the bar icon, and owns the hover-open `PopupWindow`. |
| `BluetoothPopup.qml` | Popup content only: header (icon + connection label), power toggle, hosts `PairedDevices` and the "Pair new device" button that opens `PairDeviceDialog`. Pure presentation — receives everything via properties from `Bluetooth.qml`. |
| `BluetoothToggle.qml` | Small pill switch bound to `adapter.enabled`; dims/disables itself when no adapter is present. |
| `PairedDevices.qml` | Always-visible, scrollable list of already paired/bonded devices — connect/disconnect, forget, battery % if reported. Does not scan; purely reflects `adapter.devices`. |
| `PairDeviceDialog.qml` | Centered, full-screen modal (mirrors `Network/WifiConnectDialog.qml`'s pattern) for scanning and pairing **new** devices. Drives `adapter.discovering` and a `bt-agent` pairing agent process for its own lifetime only. See "Pairing workflow" below. |
| `qmldir` | Registers all types under the `modules.indicators.Bluetooth` module so they can be imported as `import "../indicators/Bluetooth"`. |

## Data sources

- **Adapter state, device list, connect/disconnect/pair/forget, battery %**
  → `Quickshell.Bluetooth` (reactive, BlueZ D-Bus backed, no polling
  needed). This is a module built into Quickshell itself — it does **not**
  depend on `bluedevil`, `qt6-connectivity`, or any KDE component.
- **Pairing agent (PIN/confirmation handling)** → external `bt-agent`
  process (see below), since `Quickshell.Bluetooth` does not register its
  own BlueZ agent.

## Pairing workflow (`PairDeviceDialog.qml`)

BlueZ requires a **pairing agent** registered on D-Bus to answer
`RequestConfirmation` / `RequestPasskey` / `RequestPinCode` / `Authorize`
callbacks during pairing. `Quickshell.Bluetooth` does not register one
itself (an upstream gap — see
[quickshell-mirror/quickshell#138](https://github.com/quickshell-mirror/quickshell/pull/138),
closed without landing). Without any agent registered, `device.pair()`
silently fails for any device that needs more than the most trivial
handshake.

To work around this, `PairDeviceDialog.qml` spawns its own agent for as
long as the dialog is open:

1. **Open** — `dialog.open()`:
   - Shows the centered modal.
   - Starts a `Quickshell.Io.Process` running
     `bt-agent --capability=NoInputNoOutput` (from `bluez-tools`), which
     auto-accepts "Just Works"-style pairing confirmations — covers the
     vast majority of headphones, mice, keyboards, etc. without needing a
     displayed PIN.
   - Sets `adapter.discovering = true` to start scanning.

2. **Filter** — `pairableDevices` only includes devices that are **not**
   already paired/bonded **and** have a genuine human-readable name
   (`hasHumanReadableName()` rejects blank names and MAC-address-as-name
   fallbacks like `CF:0B:0D:70:2D:D9`), hiding anonymous BLE beacon noise.

3. **Pair → auto-connect** — clicking **Pair** on a row calls
   `device.pair()`. A `Connections` block watches `pairingChanged`; once
   pairing finishes successfully (`paired && !pairing && !connected`), it
   automatically sets `device.trusted = true` and calls `device.connect()`
   — so pairing and connecting happen as a single user action instead of
   two, and the device also reconnects on its own in the future (e.g. next
   power-on) without needing this dialog again.

4. **Close** — `dialog.close()`:
   - Hides the modal.
   - Stops the `bt-agent` process (unregisters the agent).
   - Sets `adapter.discovering = false` to stop scanning.

   Note: the dialog's own lifecycle is intentionally **not** tied to the
   hover popup's `showDetails` — it's a separate top-level surface with its
   own backdrop/close button, so moving the mouse away from the bar icon
   after opening the dialog does not close it.

## Requirements

### Packages (Arch Linux)

| Package | Purpose | Required? |
|---|---|---|
| `bluez` | Core Bluetooth protocol stack (`bluetoothd` daemon) | **Yes** — everything depends on this |
| `bluez-utils` | CLI utilities (`bluetoothctl`, etc.), useful for debugging | Recommended |
| `bluez-tools` | Provides `bt-agent`, used by `PairDeviceDialog.qml` for pairing | **Yes** — pairing new devices will silently fail without it |
| `quickshell` | Provides the `Quickshell.Bluetooth` QML module itself | **Yes** (already required for the whole shell) |
| `ttf-material-symbols-variable` | Icon font (`Theme.iconFontFamily`) used for all glyphs in this indicator | **Yes** (shared across the whole bar, not Bluetooth-specific) |

Install everything Bluetooth-specific with:

```bash
sudo pacman -S bluez bluez-utils bluez-tools
```

**Explicitly not required**: `bluedevil`, `qt6-connectivity`, `blueman`, or
any KDE/GTK Bluetooth applet. `Quickshell.Bluetooth` talks to
`bluetoothd` directly over D-Bus.

### Services

`bluetooth.service` must be enabled and running (it's a systemd **system**
service, not user):

```bash
sudo systemctl enable --now bluetooth.service
```

Verify:

```bash
systemctl status bluetooth.service
```

### Hardware

A Bluetooth adapter must be present and not blocked (`rfkill`). If
`Bluetooth.defaultAdapter` is `null`, the indicator shows "No Bluetooth
adapter found" and disables the toggle/pairing UI.

```bash
rfkill list bluetooth
```

## Usage

Registered in the bar via `RightIsland.qml`:

```qml
import "../indicators/Bluetooth"
...
Bluetooth {}
```

`Theme` (colors, `pillBackground`, `barHeight`) is provided by the parent
`modules/` scope and imported with `import "../../"` from within this
folder.
