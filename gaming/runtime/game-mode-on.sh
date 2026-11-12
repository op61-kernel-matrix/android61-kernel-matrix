#!/system/bin/sh
set -eu

# Experimental, opt-in gaming boost. It requests only frequencies already
# advertised by the running device and leaves all thermal controls intact.
STATE_DIR=/data/adb/nostalgiksu-gaming/state
mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"

save_once() {
  node="$1"
  key=$(printf '%s' "$node" | tr '/:' '__')
  state="$STATE_DIR/$key"
  [ -e "$state" ] || cat "$node" > "$state"
}

highest_value() {
  tr ' ' '\n' < "$1" | awk '/^[0-9]+$/ { if ($1 > max) max=$1 } END { if (max) print max }'
}

for policy in /sys/devices/system/cpu/cpufreq/policy*; do
  [ -d "$policy" ] || continue
  max=''
  if [ -r "$policy/scaling_available_frequencies" ]; then
    max=$(highest_value "$policy/scaling_available_frequencies")
  elif [ -r "$policy/cpuinfo_max_freq" ]; then
    max=$(cat "$policy/cpuinfo_max_freq")
  fi
  [ -n "$max" ] || continue
  for node in "$policy/scaling_max_freq" "$policy/scaling_min_freq"; do
    [ -w "$node" ] || continue
    save_once "$node"
    printf '%s\n' "$max" > "$node"
  done
done

for devfreq in /sys/class/devfreq/*; do
  [ -d "$devfreq" ] || continue
  name=$(basename "$devfreq" | tr '[:upper:]' '[:lower:]')
  case "$name" in
    *gpu*|*kgsl*|*mali*) ;;
    *) continue ;;
  esac
  [ -r "$devfreq/available_frequencies" ] || continue
  max=$(highest_value "$devfreq/available_frequencies")
  [ -n "$max" ] || continue
  for node in "$devfreq/max_freq" "$devfreq/min_freq"; do
    [ -w "$node" ] || continue
    save_once "$node"
    printf '%s\n' "$max" > "$node"
  done
done

printf '%s\n' 'Gaming boost requested at device-advertised stock maxima.'
printf '%s\n' 'Vendor DVFS, thermal mitigation and critical shutdown remain active.'
