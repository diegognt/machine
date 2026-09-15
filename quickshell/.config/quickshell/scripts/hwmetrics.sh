#!/usr/bin/env bash
# Single-shot hardware metrics sampler for the Control Center's
# HardwareSection.qml. Emits one `key=value` pair per line to stdout;
# metrics that can't be read on this machine (e.g. nvidia-smi failing due
# to a kernel-module/library version mismatch until next reboot) are
# simply omitted rather than emitting a placeholder, so the QML side can
# tell "unavailable" apart from "genuinely zero".
#
# Rationale for a standalone script rather than inlining this in QML's
# Process.command: computing CPU%/network throughput needs two samples
# separated by a sleep, and hwmon/drm sysfs paths need to be resolved by
# device *name* (hwmon numbering isn't stable across reboots) - both are
# far more readable/testable as a real shell script than a one-line
# `sh -c '...'` string embedded in a .qml file.

set -u

SAMPLE_INTERVAL=0.5

# --- Resolve hwmon directories by name (numbering isn't stable) ---
k10temp_dir=""
amdgpu_dir=""
for dir in /sys/class/hwmon/hwmon*; do
    [ -r "$dir/name" ] || continue
    name=$(cat "$dir/name" 2>/dev/null)
    case "$name" in
        k10temp) k10temp_dir="$dir" ;;
        amdgpu)  amdgpu_dir="$dir" ;;
    esac
done

# --- Sample 1: CPU total/idle jiffies, network rx/tx bytes ---
read_cpu_jiffies() {
    awk '/^cpu / { total = 0; for (i = 2; i <= NF; i++) total += $i; print total, $5 }' /proc/stat
}
read_net_bytes() {
    awk 'NR > 2 && $1 !~ /^lo:/ { rx += $2; tx += $10 } END { print rx+0, tx+0 }' /proc/net/dev
}

read cpu_total1 cpu_idle1 <<< "$(read_cpu_jiffies)"
read net_rx1 net_tx1 <<< "$(read_net_bytes)"

sleep "$SAMPLE_INTERVAL"

read cpu_total2 cpu_idle2 <<< "$(read_cpu_jiffies)"
read net_rx2 net_tx2 <<< "$(read_net_bytes)"

# --- CPU usage % over the sample window ---
d_total=$((cpu_total2 - cpu_total1))
d_idle=$((cpu_idle2 - cpu_idle1))
if [ "$d_total" -gt 0 ]; then
    cpu_pct=$(( (100 * (d_total - d_idle)) / d_total ))
    echo "cpu_pct=$cpu_pct"
fi

# --- CPU temperature (Tctl) ---
if [ -n "$k10temp_dir" ] && [ -r "$k10temp_dir/temp1_input" ]; then
    raw=$(cat "$k10temp_dir/temp1_input")
    echo "cpu_temp=$(awk -v r="$raw" 'BEGIN { printf "%.1f", r / 1000 }')"
fi

# --- Memory ---
mem_total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
mem_avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
if [ -n "${mem_total_kb:-}" ] && [ -n "${mem_avail_kb:-}" ] && [ "$mem_total_kb" -gt 0 ]; then
    mem_used_kb=$((mem_total_kb - mem_avail_kb))
    echo "mem_pct=$(( (100 * mem_used_kb) / mem_total_kb ))"
    echo "mem_used_gb=$(awk -v k="$mem_used_kb" 'BEGIN { printf "%.1f", k / 1048576 }')"
    echo "mem_total_gb=$(awk -v k="$mem_total_kb" 'BEGIN { printf "%.1f", k / 1048576 }')"
fi

# --- AMD iGPU (busy % via DRM, temp/power via hwmon) ---
if [ -n "$amdgpu_dir" ]; then
    amdgpu_device=$(readlink -f "$amdgpu_dir/device" 2>/dev/null)
    for card in /sys/class/drm/card[0-9]*; do
        [ -e "$card/device" ] || continue
        card_device=$(readlink -f "$card/device" 2>/dev/null)
        if [ "$card_device" = "$amdgpu_device" ] && [ -r "$card/device/gpu_busy_percent" ]; then
            echo "gpu_amd_busy=$(cat "$card/device/gpu_busy_percent")"
            break
        fi
    done
    [ -r "$amdgpu_dir/temp1_input" ] && \
        echo "gpu_amd_temp=$(awk -v r="$(cat "$amdgpu_dir/temp1_input")" 'BEGIN { printf "%.0f", r / 1000 }')"
    [ -r "$amdgpu_dir/power1_input" ] && \
        echo "gpu_amd_power=$(awk -v r="$(cat "$amdgpu_dir/power1_input")" 'BEGIN { printf "%.1f", r / 1000000 }')"
fi

# --- NVIDIA dGPU (via nvidia-smi; silently omitted if unavailable, e.g.
# driver/library version mismatch until the next reboot) ---
if command -v nvidia-smi >/dev/null 2>&1; then
    # nvidia-smi prints its own errors (e.g. a kernel-module/userspace
    # version mismatch after an nvidia-utils update, before reboot) to
    # *stdout* as a human-readable sentence rather than CSV, so instead of
    # trusting the exit code (unreliable to capture through a `| head`
    # pipe without `pipefail`), just check the output actually looks like
    # the three-field CSV row we asked for.
    nvidia_line=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,power.draw \
        --format=csv,noheader,nounits 2>/dev/null | head -n1)
    if [ -n "$nvidia_line" ] && [ "$(echo "$nvidia_line" | tr -cd ',' | wc -c)" -eq 2 ]; then
        nvidia_busy=$(echo "$nvidia_line" | cut -d',' -f1 | tr -d ' ')
        nvidia_temp=$(echo "$nvidia_line" | cut -d',' -f2 | tr -d ' ')
        nvidia_power=$(echo "$nvidia_line" | cut -d',' -f3 | tr -d ' ')
        [ -n "$nvidia_busy" ] && echo "gpu_nvidia_busy=$nvidia_busy"
        [ -n "$nvidia_temp" ] && echo "gpu_nvidia_temp=$nvidia_temp"
        [ -n "$nvidia_power" ] && echo "gpu_nvidia_power=$nvidia_power"
    fi
fi

# --- Network throughput (KB/s over the same sample window) ---
d_rx=$((net_rx2 - net_rx1))
d_tx=$((net_tx2 - net_tx1))
echo "net_rx_kbps=$(awk -v b="$d_rx" -v s="$SAMPLE_INTERVAL" 'BEGIN { printf "%.1f", (b / s) / 1024 }')"
echo "net_tx_kbps=$(awk -v b="$d_tx" -v s="$SAMPLE_INTERVAL" 'BEGIN { printf "%.1f", (b / s) / 1024 }')"
