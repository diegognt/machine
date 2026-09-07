import QtQuick
import "../"
import "../indicators"
import "../indicators/Calendar"
import "../indicators/Network"
import "../indicators/Bluetooth"

// Right island — date/time, network, bluetooth, and battery indicators,
// each in its own pill, 16px apart (Island.qml's spacing).
Island {
    id: root
    anchors.right: parent.right

    ModulePill { Calendar {} }
    ModulePill { Network {} }
    ModulePill { Bluetooth {} }
    ModulePill { Battery {} }
}
