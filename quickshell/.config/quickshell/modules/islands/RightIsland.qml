import QtQuick
import "../"
import "../indicators"
import "../indicators/Calendar"
import "../indicators/Network"
import "../indicators/Bluetooth"
import "../indicators/Volume"

// Right island — date/time, network, bluetooth, volume, and battery
// indicators, each in its own pill, 16px apart (Island.qml's spacing).
Island {
    id: root
    anchors.right: parent.right

    ModulePill { Calendar {} }
    ModulePill { Network {} }
    ModulePill { Bluetooth {} }
    ModulePill { Volume {} }
    ModulePill { Battery {} }
}
