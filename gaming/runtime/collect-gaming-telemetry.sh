#!/system/bin/sh
set -eu
package=${1:-}
[ -n "$package" ] || { echo "usage: $0 <game.package> [seconds]" >&2; exit 2; }
seconds=${2:-120}
out=/data/local/tmp/nostalgiksu-gaming-$(date +%Y%m%d-%H%M%S)
mkdir -p "$out"

getevent -lt > "$out/input-events.txt" 2>&1 &
input_pid=$!
dumpsys gfxinfo "$package" reset >/dev/null 2>&1 || true

i=0
while [ "$i" -lt "$seconds" ]; do
  {
    date +%s
    dumpsys thermalservice 2>/dev/null
    for p in /sys/devices/system/cpu/cpufreq/policy*; do
      [ -r "$p/scaling_cur_freq" ] && printf '%s %s\n' "$p" "$(cat "$p/scaling_cur_freq")"
    done
  } >> "$out/thermal-frequency.txt"
  sleep 1
  i=$((i + 1))
done

kill "$input_pid" 2>/dev/null || true
wait "$input_pid" 2>/dev/null || true
dumpsys gfxinfo "$package" framestats > "$out/frame-stats.txt" 2>&1 || true
dumpsys SurfaceFlinger --latency > "$out/surfaceflinger-latency.txt" 2>&1 || true
cat /proc/pressure/cpu > "$out/psi-cpu.txt" 2>/dev/null || true
cat /proc/pressure/memory > "$out/psi-memory.txt" 2>/dev/null || true
echo "$out"
