#!/system/bin/sh
set -eu

STATE_DIR=/data/adb/nostalgiksu-gaming/state
[ -d "$STATE_DIR" ] || exit 0

restore_node() {
  node="$1"
  key=$(printf '%s' "$node" | tr '/:' '__')
  state="$STATE_DIR/$key"
  [ -r "$state" ] || return 0
  [ -w "$node" ] || return 0
  cat "$state" > "$node"
  rm -f "$state"
}

for policy in /sys/devices/system/cpu/cpufreq/policy*; do
  [ -d "$policy" ] || continue
  restore_node "$policy/scaling_min_freq"
  restore_node "$policy/scaling_max_freq"
done

for devfreq in /sys/class/devfreq/*; do
  [ -d "$devfreq" ] || continue
  restore_node "$devfreq/min_freq"
  restore_node "$devfreq/max_freq"
done

rmdir "$STATE_DIR" 2>/dev/null || true
printf '%s\n' 'Previous CPU/GPU frequency limits restored.'
