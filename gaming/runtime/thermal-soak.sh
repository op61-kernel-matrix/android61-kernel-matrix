#!/system/bin/sh
set -eu
package=${1:-}
[ -n "$package" ] || { echo "usage: $0 <game.package> [minutes]" >&2; exit 2; }
minutes=${2:-30}
seconds=$((minutes * 60))
MODDIR=${0%/*}

cleanup() {
  "$MODDIR/game-mode-off.sh" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

"$MODDIR/game-mode-on.sh"
"$MODDIR/collect-gaming-telemetry.sh" "$package" "$seconds"
