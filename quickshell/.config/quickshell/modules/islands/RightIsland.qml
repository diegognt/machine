import QtQuick
import "../"
import "../indicators"
import "../indicators/Calendar"
import "../indicators/Network"

// Right island — date/time, network, and battery indicators, each in its
// own pill, 16px apart (Island.qml's spacing).
Island {
    id: root
    anchors.right: parent.right

    ModulePill { Calendar {} }
    ModulePill { Network {} }
    ModulePill { Battery {} }
}
