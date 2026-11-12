#!/system/bin/sh
MODDIR=${0%/*}
DATA_DIR=/data/adb/nostalgiksu-gaming
GAMES_FILE="$DATA_DIR/games.list"
ACTIVE_FILE="$DATA_DIR/active-package"
mkdir -p "$DATA_DIR"
chmod 0700 "$DATA_DIR"

if [ ! -e "$GAMES_FILE" ]; then
  cat > "$GAMES_FILE" <<'EOF'
# One Android package name per line, for example:
# com.example.game
EOF
fi

current_package() {
  dumpsys window windows 2>/dev/null | awk '
    /mCurrentFocus|mFocusedApp/ {
      for (i=1; i<=NF; i++) if ($i ~ /[A-Za-z0-9_.]+\/[A-Za-z0-9_.$]+/) {
        split($i, p, "/"); gsub(/[{}]/, "", p[1]); print p[1]; exit
      }
    }'
}

is_game() {
  package="$1"
  [ -n "$package" ] || return 1
  grep -v '^[[:space:]]*#' "$GAMES_FILE" | grep -qxF "$package"
}

while true; do
  package=$(current_package || true)
  active=''
  [ -r "$ACTIVE_FILE" ] && active=$(cat "$ACTIVE_FILE")
  if is_game "$package"; then
    if [ "$active" != "$package" ]; then
      [ -z "$active" ] || "$MODDIR/game-mode-off.sh" >/dev/null 2>&1 || true
      cmd game mode performance "$package" >/dev/null 2>&1 || true
      "$MODDIR/game-mode-on.sh" >/dev/null 2>&1
      printf '%s\n' "$package" > "$ACTIVE_FILE"
    fi
  elif [ -n "$active" ]; then
    cmd game mode standard "$active" >/dev/null 2>&1 || true
    "$MODDIR/game-mode-off.sh" >/dev/null 2>&1 || true
    rm -f "$ACTIVE_FILE"
  fi
  sleep 3
done
