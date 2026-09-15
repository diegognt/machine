import QtQuick
import Quickshell
import Quickshell.Io
import "../"

// Control Center section for at-a-glance hardware metrics: CPU, Memory,
// GPU (AMD iGPU and/or NVIDIA dGPU - both, either, or neither shown
// depending on what's actually present/queryable), and Network
// throughput. Pinned at the very end of the Control Center's section
// list, below the interactive controls above.
//
// Sampling is delegated entirely to scripts/hwmetrics.sh (see that file's
// own header comment for why: CPU%/network throughput both need two
// samples separated by a sleep, and hwmon/DRM sysfs paths must be
// resolved by device *name* since hwmon numbering isn't stable across
// reboots - both are far more readable as a real shell script than an
// inline `sh -c '...'` string). The script emits `key=value` lines;
// unavailable metrics (e.g. nvidia-smi failing due to a driver/library
// version mismatch until next reboot) are simply omitted rather than
// emitting a placeholder, which is why every metric property below has an
// explicit "not sampled yet / unavailable" default and every GPU row is
// `visible` only once its busy-percent key has actually been seen.
//
// Wrapped in a plain Item (see BrightnessSection.qml's header comment) so
// the non-visual Process/Timer helpers can live as siblings of the visual
// SectionCard instead of inside its Column-based default content.
Item {
    id: root
    implicitHeight: card.implicitHeight
    height: card.implicitHeight

    property int cpuPct: 0
    property real cpuTemp: -1
    property int memPct: 0
    property real memUsedGb: 0
    property real memTotalGb: 0
    property bool amdGpuSeen: false
    property int amdGpuBusy: 0
    property real amdGpuTemp: -1
    property real amdGpuPower: -1
    property bool nvidiaGpuSeen: false
    property int nvidiaGpuBusy: 0
    property real nvidiaGpuTemp: -1
    property real nvidiaGpuPower: -1
    property real netRxKbps: 0
    property real netTxKbps: 0

    function formatRate(kbps) {
        if (kbps >= 1024) return (kbps / 1024).toFixed(1) + " MB/s";
        return kbps.toFixed(0) + " KB/s";
    }

    // Green -> gold -> red as load/temperature climbs, shared by every
    // ratio-driven progress bar and temperature badge below.
    function loadColor(ratio) {
        if (ratio >= 0.85) return Theme.error;
        if (ratio >= 0.6) return Theme.warning;
        return Theme.success;
    }

    function tempColor(celsius) {
        if (celsius >= 85) return Theme.error;
        if (celsius >= 70) return Theme.warning;
        return Theme.subtle;
    }

    Process {
        id: sampler
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/hwmetrics.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.amdGpuSeen = false;
                root.nvidiaGpuSeen = false;

                for (const line of this.text.split("\n")) {
                    const eq = line.indexOf("=");
                    if (eq < 0) continue;
                    const key = line.substring(0, eq);
                    const value = line.substring(eq + 1);

                    switch (key) {
                    case "cpu_pct": root.cpuPct = parseInt(value, 10) || 0; break;
                    case "cpu_temp": root.cpuTemp = parseFloat(value); break;
                    case "mem_pct": root.memPct = parseInt(value, 10) || 0; break;
                    case "mem_used_gb": root.memUsedGb = parseFloat(value); break;
                    case "mem_total_gb": root.memTotalGb = parseFloat(value); break;
                    case "gpu_amd_busy": root.amdGpuSeen = true; root.amdGpuBusy = parseInt(value, 10) || 0; break;
                    case "gpu_amd_temp": root.amdGpuTemp = parseFloat(value); break;
                    case "gpu_amd_power": root.amdGpuPower = parseFloat(value); break;
                    case "gpu_nvidia_busy": root.nvidiaGpuSeen = true; root.nvidiaGpuBusy = parseInt(value, 10) || 0; break;
                    case "gpu_nvidia_temp": root.nvidiaGpuTemp = parseFloat(value); break;
                    case "gpu_nvidia_power": root.nvidiaGpuPower = parseFloat(value); break;
                    case "net_rx_kbps": root.netRxKbps = parseFloat(value); break;
                    case "net_tx_kbps": root.netTxKbps = parseFloat(value); break;
                    }
                }
            }
        }
    }

    // The script itself blocks for ~0.5s (its sampling window), so a 3s
    // repeat interval keeps the section reasonably live without spawning
    // an overlapping process before the previous one finishes.
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: sampler.running = true
    }

    SectionCard {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        title: "Hardware"
        icon: "\ue322" // memory

        MetricRow {
            width: parent.width
            icon: "\ue30d" // developer_board (CPU)
            label: "CPU"
            value: root.cpuPct + "%"
            ratio: root.cpuPct / 100
            ratioColor: root.loadColor(root.cpuPct / 100)
            tempText: root.cpuTemp >= 0 ? root.cpuTemp.toFixed(0) + "\u00b0C" : ""
            tempColor: root.tempColor(root.cpuTemp)
        }

        MetricRow {
            width: parent.width
            icon: "\uead0" // memory (RAM)
            label: "Memory"
            value: root.memUsedGb.toFixed(1) + " / " + root.memTotalGb.toFixed(1) + " GB"
            ratio: root.memPct / 100
            ratioColor: root.loadColor(root.memPct / 100)
        }

        MetricRow {
            width: parent.width
            visible: root.amdGpuSeen
            icon: "\ue30d" // developer_board (GPU)
            label: "GPU (AMD)"
            value: root.amdGpuBusy + "%"
            ratio: root.amdGpuBusy / 100
            ratioColor: root.loadColor(root.amdGpuBusy / 100)
            tempText: root.amdGpuTemp >= 0 ? root.amdGpuTemp.toFixed(0) + "\u00b0C" : ""
            tempColor: root.tempColor(root.amdGpuTemp)
            powerText: root.amdGpuPower >= 0 ? root.amdGpuPower.toFixed(0) + "W" : ""
        }

        MetricRow {
            width: parent.width
            visible: root.nvidiaGpuSeen
            icon: "\ue30d" // developer_board (GPU)
            label: "GPU (NVIDIA)"
            value: root.nvidiaGpuBusy + "%"
            ratio: root.nvidiaGpuBusy / 100
            ratioColor: root.loadColor(root.nvidiaGpuBusy / 100)
            tempText: root.nvidiaGpuTemp >= 0 ? root.nvidiaGpuTemp.toFixed(0) + "\u00b0C" : ""
            tempColor: root.tempColor(root.nvidiaGpuTemp)
            powerText: root.nvidiaGpuPower >= 0 ? root.nvidiaGpuPower.toFixed(0) + "W" : ""
        }

        MetricRow {
            width: parent.width
            icon: "\uf012" // network_check
            label: "Network"
            value: "\u2193" + root.formatRate(root.netRxKbps) + "  \u2191" + root.formatRate(root.netTxKbps)
            ratio: -1
        }
    }
}
