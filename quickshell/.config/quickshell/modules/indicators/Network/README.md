# Network Indicator

Bar indicator + hover popup showing the current network connection
(wired/Wi-Fi), signal strength, connectivity status, a Wi-Fi radio toggle,
and a native `nmcli`-backed Wi-Fi network browser (scan/list/connect).

## Files

| File | Responsibility |
|---|---|
| `Network.qml` | Bar entry point. Derives connection state from `Quickshell.Networking` (`Networking`, `NetworkDevice`, `WifiNetwork`, ...), renders the bar label (icon + connection name), and owns the hover-open `PopupWindow`. |
| `NetworkPopup.qml` | Popup content only: header (icon + name + connectivity label), Wi-Fi/wired detail lines (signal, security, link speed), hosts `WifiToggle` and `WifiNetworkList`. Pure presentation — receives everything via properties from `Network.qml`. |
| `WifiToggle.qml` | Small pill switch bound to `Networking.wifiEnabled`; dims/disables itself when `Networking.wifiHardwareEnabled` is false (rfkill). |
| `WifiNetworkList.qml` | Independent from `Quickshell.Networking`'s device/network model. Runs `nmcli` directly via `Quickshell.Io.Process` to scan, list, and connect to Wi-Fi networks. See "Wi-Fi list workflow" below. |
| `qmldir` | Registers all four types under the `modules.indicators.Network` module so they can be imported as `import "../indicators/Network"`. |

## Data sources

- **Connection state, signal strength, connectivity, wired link speed, Wi-Fi
  radio enable/disable** → `Quickshell.Networking` (reactive, D-Bus/NetworkManager
  backed, no polling needed).
- **Wi-Fi network list, scanning, and connecting** → raw `nmcli` calls via
  `Quickshell.Io.Process`, independent of `Quickshell.Networking`'s own
  network list. This exists specifically to give full control over the
  scan/connect/password flow instead of relying on the built-in
  `WifiNetwork.connect()`/`connectWithPsk()` API.

## Wi-Fi list workflow (`WifiNetworkList.qml`)

1. **Scan** — while the popup is open (`active: true`), runs:
   ```
   nmcli -t -f BSSID,SSID,SIGNAL,SECURITY,IN-USE dev wifi list
   ```
   on load and every 15s via a `Timer`, using a `Process` + `StdioCollector`.

2. **Parse** — `nmcli -t` output is colon-separated, but literal colons
   inside a field (e.g. a BSSID `F4\:52\:46\:A6\:D2\:FF`) are escaped with
   `\:`. `parseNmcliLine()` walks the string manually (`\X` → literal `X`,
   unescaped `:` → field boundary) instead of using `String.split(":")`,
   which would otherwise shred BSSIDs. Multiple BSSIDs sharing one SSID
   (mesh/repeaters) are deduped, keeping the strongest signal.

3. **State** — parsed rows are pushed into a `ListModel` (`ssid`, `bssid`,
   `signal`, `security`, `connected`, `needsPassword`), sorted by signal
   strength.

4. **Display** — a `ListView` renders the `ListModel`: SSID, signal %, a
   lock glyph if secured, highlighted row if it's the active connection.

5. **Connect** — clicking a row runs:
   ```
   nmcli device wifi connect <ssid>            # open network, or secured
                                                 # network with saved secrets
   nmcli device wifi connect <ssid> password <pwd>  # after entering a password
   ```
   via a second `Process`. If the bare connect attempt fails and `nmcli`'s
   stderr mentions secrets/password/key, an inline password field expands
   under that row; submitting it retries the connect with `password <pwd>`.
   Either way, the list is re-scanned after the attempt settles.

## Requirements

- **`nmcli`** (NetworkManager CLI) must be installed and on `PATH` — used
  directly by `WifiNetworkList.qml` for scanning/connecting.
- **NetworkManager** must be the active network backend (systemd service
  running) — both `nmcli` and `Quickshell.Networking`'s `NetworkBackendType`
  need it; the rest of the indicator (`Network.qml`, connectivity, wired
  link speed, Wi-Fi radio toggle) relies on `Quickshell.Networking`, which
  itself talks to NetworkManager over D-Bus.
- **A Wi-Fi-capable device** for the Wi-Fi sections (toggle, network list,
  signal-strength icons) to be relevant — they hide themselves
  (`visible: !!root.wifiDevice`) if no `WifiDevice` is present, e.g.
  desktop with only wired networking.
- **Icon font**: icons use `font.family: Theme.iconFontFamily`, which
  resolves to `"Material Symbols Outlined"` (Google Material Symbols,
  package `ttf-material-symbols-variable`). Codepoints are the font's own
  Private Use Area glyph IDs (e.g. `network_wifi`, `lan`, `lock`). Verify
  it's installed/resolvable with `fc-match "Material Symbols Outlined"`;
  to use a different icon font, change `Theme.iconFontFamily` in
  `modules/Theme.qml` once, and every icon in the bar follows it.
- **Password prompts**: passwords typed into the inline `TextInput` are
  passed as plain CLI arguments to `nmcli device wifi connect ... password
  <pwd>`. This is only as secure as `nmcli`'s own handling of that argument
  (visible in process listings for the brief run of the command) — be aware
  of this if operating on a shared/multi-user machine.

## Usage

Registered in the bar via `RightIsland.qml`:

```qml
import "../indicators/Network"
...
Network {}
```

`Theme` (colors, `pillBackground`, `barHeight`) is provided by the parent
`modules/` scope and imported with `import "../../"` from within this
folder.
