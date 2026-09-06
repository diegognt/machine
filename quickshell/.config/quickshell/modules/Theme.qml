pragma Singleton
import QtQuick 2.15

/*
    Rose Pine Moon
    Reference: https://rosepinetheme.com/palette/
    Source: ~/Downloads/RosePineMoon.qml

    Registered as the "Theme" singleton for the quickshell bar.
    Usage: import "../" ; Rectangle { color: Theme.love }
*/
QtObject {
    id: theme

    // ---- Base ----
    readonly property color base:    "#232136"
    readonly property color surface: "#2a273f"
    readonly property color overlay: "#393552"

    // ---- Text hierarchy ----
    readonly property color muted:  "#6e6a86"
    readonly property color subtle: "#908caa"
    readonly property color text:   "#e0def4"

    // ---- Accents ----
    readonly property color love: "#eb6f92"
    readonly property color gold: "#f6c177"
    readonly property color rose: "#ea9a97"
    readonly property color pine: "#3e8fb0"
    readonly property color foam: "#9ccfd8"
    readonly property color iris: "#c4a7e7"

    // ---- Highlights (selection / hover states) ----
    readonly property color highlightLow:  "#2a283e"
    readonly property color highlightMed:  "#44415a"
    readonly property color highlightHigh: "#56526e"

    // ---- Convenience semantic aliases ----
    readonly property color background:    base
    readonly property color surfaceAlt:    surface
    readonly property color border:        overlay
    readonly property color textPrimary:   text
    readonly property color textSecondary: subtle
    readonly property color textDisabled:  muted
    readonly property color accent:        iris
    readonly property color error:         love
    readonly property color warning:       gold
    readonly property color success:       pine
    readonly property color info:          foam
    readonly property color selection:     highlightMed
    readonly property color hover:         highlightLow

    // ---- Bar-specific ----
    // Top bar surface itself: RosePineMoon "base" color at 80% opacity.
    readonly property color barBackground: Qt.rgba(base.r, base.g, base.b, 0.8)

    // Background used behind each island/indicator pill: RosePineMoon
    // "surface" color.
    readonly property color pillBackground: surface

    // Border color used on island/indicator pills (normal state).
    readonly property color pillBorder: muted

    // Global top bar height. Used by Bar.qml for the PanelWindow's
    // implicitHeight, and by any popup/tooltip that needs to offset itself
    // below the bar (e.g. PopupWindow anchor.margins.top). Fixed regardless
    // of content.
    readonly property int barHeight: 48

    // Padding between the bar's own edges and the islands placed inside it.
    readonly property int barPaddingHorizontal: 6
    readonly property int barPaddingVertical: 4

    // Fixed height for each indicator pill (ModulePill), owned solely by
    // the pill itself — independent of barHeight/barPaddingVertical so it
    // doesn't silently shift if the bar's own sizing changes.
    readonly property int pillHeight: 38

    // Corner radius for each indicator pill (ModulePill).
    readonly property int pillRadius: 6

    // Space between the pill's content and its edge/border, both
    // horizontally and vertically.
    readonly property int pillPaddingHorizontal: 6
    readonly property int pillPaddingVertical: 6

    // Gap between elements inside a single pill's content row (e.g. icon +
    // label). Default spacing for ModulePill; individual pills can override
    // via their own `spacing` property.
    readonly property int pillContentSpacing: 10

    // Global icon size for icon-only bar indicators (Battery, Network, ...)
    // so they render at a consistent size. Popup header icons use their own
    // larger size independently.
    readonly property int iconSize: 18

    // Default text size used by any indicator's text (labels, popup body
    // text, etc.) - deliberately distinct from iconSize so icon glyphs and
    // regular text don't fight for the same scale.
    readonly property int fontSize: 14

    // Global icon font. Every icon glyph in the bar/popups should use this
    // (Google Material Symbols, outlined style) instead of mixing
    // FontAwesome/Nerd Font glyph sets.
    readonly property string iconFontFamily: "Material Symbols Outlined"

    // Gap between separate pills within the same island.
    readonly property int islandSpacing: 8
}
