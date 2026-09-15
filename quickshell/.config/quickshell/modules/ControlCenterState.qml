pragma Singleton
import QtQuick 2.15

// Shared open/close state for the Control Center panel. Kept as its own
// singleton (rather than a property on the panel itself) so the trigger
// indicator (ControlCenterToggle, in RightIsland) and the panel
// (controlcenter/ControlCenter.qml, instantiated separately in shell.qml)
// can both react to/drive the same state without a direct reference to
// each other — mirrors how Theme is shared across every module.
QtObject {
    id: root

    property bool visible: false

    function open() {
        root.visible = true;
    }

    function close() {
        root.visible = false;
    }

    function toggle() {
        root.visible = !root.visible;
    }
}
