#!/usr/bin/env bash
# republish-fixed.sh — Republish all skills as v1.0.1 to trigger ClawHub rescan
# Fixes applied: manifest bins/configPaths, JWT signature verification
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$REPO_DIR/republish.log"
MAX_BATCH=5
VERSION="1.0.1"

TOOLS=(
  accesslint apishield asyncguard authaudit bundlephobia cachelint cloudguard
  concurrencyguard configsafe containerlint cronlint cryptolint dateguard
  deadcode doccoverage envguard errorlens eventlint featurelint gqllint
  httplint i18ncheck inputshield licenseguard logsentry memguard migratesafe
  perfguard pipelinelint ratelint regexguard retrylint schemalint secretscan
  serdelint sqlguard styleguard testgap typedrift
)

log() {
  local ts
  ts=$(date -u '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] $*" | tee -a "$LOG_FILE"
}

PASSED=0
FAILED=0
COUNT=0

for tool in "${TOOLS[@]}"; do
  SKILL_PATH="$REPO_DIR/$tool"
  [ ! -f "$SKILL_PATH/SKILL.md" ] && continue

  if [ "$COUNT" -ge "$MAX_BATCH" ]; then
    log "Batch limit (5/hr). $PASSED published so far. Waiting 61 minutes..."
    sleep 3660
    COUNT=0
  fi

  log "Publishing $tool@$VERSION..."
  if clawhub publish "$SKILL_PATH" --slug "$tool" --name "$tool" --version "$VERSION" --changelog "Fix: declare all dependencies in manifest, add JWT signature verification, add configPaths declaration" >> "$LOG_FILE" 2>&1; then
    log "OK: $tool@$VERSION"
    PASSED=$((PASSED + 1))
    COUNT=$((COUNT + 1))
  else
    log "FAILED: $tool"
    FAILED=$((FAILED + 1))
    # If rate limited, wait and reset
    if grep -q "Rate limit" "$LOG_FILE" 2>/dev/null; then
      log "Rate limited. Waiting 61 minutes..."
      sleep 3660
      COUNT=0
      # Retry this one
      if clawhub publish "$SKILL_PATH" --slug "$tool" --name "$tool" --version "$VERSION" --changelog "Fix: manifest deps, JWT verification, configPaths" >> "$LOG_FILE" 2>&1; then
        log "OK (retry): $tool@$VERSION"
        PASSED=$((PASSED + 1))
        FAILED=$((FAILED - 1))
        COUNT=$((COUNT + 1))
      fi
    fi
  fi

  sleep 3
done

log "DONE: $PASSED published, $FAILED failed out of ${#TOOLS[@]}"

if [ "$PASSED" -ge 35 ]; then
  export TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN (see .claude/.env)
  export TELEGRAM_CHAT_ID=7391980743
  bash "/j/baremetal claude/tools/notify-telegram.sh" "ClawHub republish complete: $PASSED/$((PASSED+FAILED)) skills updated to v1.0.1 with security fixes. Check scanner results." 2>/dev/null || true
fi
