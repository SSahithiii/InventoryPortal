#!/usr/bin/env bash
set -euo pipefail

# === Config (matches your deploy step) ========================================
APP_DIR="${APP_DIR:-$HOME/.inventory_state}"      # state dir used by the workflow
CONTAINER="${CONTAINER:-inventory-app-container}"  # container name
PORT="${PORT:-5000}"
HEALTH_URL="${HEALTH_URL:-http://localhost:${PORT}/}"
HIST="$APP_DIR/.deploy_history"
LAST="$APP_DIR/.last_good_tag"    # full image ref, e.g. ghcr.io/owner/inventory-app:<sha>
PREV="$APP_DIR/.prev_good_tag"    # previous good image ref

# Optional: force rollback to prev (ignore last_good) -> ROLLBACK_PREV=1 scripts/rollback.sh
ROLLBACK_PREV="${ROLLBACK_PREV:-0}"

# === Preconditions ============================================================
mkdir -p "$APP_DIR"
[ -f "$LAST" ] || { echo "❌ $LAST not found. No last known-good image recorded."; exit 1; }

# === Discover current state ===================================================
current_image="$(docker inspect -f '{{.Config.Image}}' "$CONTAINER" 2>/dev/null || true)"
last_image="$(cat "$LAST")"
prev_image="$( [ -f "$PREV" ] && cat "$PREV" || echo "" )"

echo "↩️  ROLLBACK requested"
echo "   APP_DIR: $APP_DIR"
echo "   LAST:    $last_image"
echo "   PREV:    ${prev_image:-<none>}"
echo "   CURRENT: ${current_image:-<none>}"

# === Choose target ============================================================
target=""
if [ "$ROLLBACK_PREV" = "1" ] && [ -n "$prev_image" ]; then
  target="$prev_image"
else
  target="$last_image"
  # If we're already running LAST, prefer PREV if available
  if [ -n "$current_image" ] && [ "$current_image" = "$last_image" ] && [ -n "$prev_image" ]; then
    echo "   Already on last_good; selecting prev_good."
    target="$prev_image"
  fi
fi

[ -n "$target" ] || { echo "❌ No rollback target available."; exit 1; }
if [ -n "$current_image" ] && [ "$current_image" = "$target" ]; then
  echo "❌ Target equals the currently running image ($target). Aborting to avoid no-op."
  exit 1
fi

echo "🚀 Rolling back to: $target"
echo "   Pulling image (best-effort)…"
docker pull "$target" || true

echo "   Replacing container $CONTAINER …"
docker rm -f "$CONTAINER" 2>/dev/null || true
docker run -d --name "$CONTAINER" --restart unless-stopped -p "${PORT}:5000" "$target" >/dev/null

# === Health check =============================================================
echo "🩺 Health check at $HEALTH_URL …"
ok=0
for i in $(seq 1 30); do
  code="$(curl -s -o /dev/null -w '%{http_code}' "$HEALTH_URL" || echo 000)"
  if [ "$code" = "200" ]; then ok=1; break; fi
  sleep 2
done

if [ "$ok" -eq 1 ]; then
  echo "✅ Rollback healthy."

  # Rotate pointers for future rollbacks: prev <- last, last <- target
  [ -f "$LAST" ] && cp "$LAST" "$PREV" || true
  echo "$target" > "$LAST"
  echo "$(date -Iseconds) $target (manual rollback ok)" >> "$HIST"

  echo "---- STATE SAVED ----"
  echo "State directory: $APP_DIR"
  ls -la "$APP_DIR" || true
  echo "last_good ($LAST): $(cat "$LAST")"
  if [ -f "$PREV" ]; then
    echo "prev_good ($PREV): $(cat "$PREV")"
  else
    echo "prev_good ($PREV): <none yet>"
  fi
  echo "---------------------"
  exit 0
fi

echo "❌ Rolled-back container failed health check."
echo "$(date -Iseconds) $target (manual rollback failed)" >> "$HIST"
exit 1
