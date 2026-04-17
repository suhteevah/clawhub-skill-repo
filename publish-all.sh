#!/usr/bin/env bash
# publish-all.sh — Publish all 39 clawhub-lint analyzers as ClawHub skills
# Usage: bash publish-all.sh [--dry-run] [--resume]
# Rate limit: 5 skills/hour. Script batches automatically.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
RESUME=false
PROGRESS_FILE="$REPO_DIR/.publish-progress"
BATCH_SIZE=5
WAIT_SECONDS=3660  # 61 minutes between batches

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true
[[ "${1:-}" == "--resume" ]] && RESUME=true
[[ "${2:-}" == "--resume" ]] && RESUME=true

TOOLS=(
  accesslint apishield asyncguard authaudit bundlephobia cachelint cloudguard
  concurrencyguard configsafe containerlint cronlint cryptolint dateguard
  deadcode doccoverage envguard errorlens eventlint featurelint gqllint
  httplint i18ncheck inputshield licenseguard logsentry memguard migratesafe
  perfguard pipelinelint ratelint regexguard retrylint schemalint secretscan
  serdelint sqlguard styleguard testgap typedrift
)

# Load progress if resuming
declare -A PUBLISHED=()
if $RESUME && [ -f "$PROGRESS_FILE" ]; then
  while IFS= read -r line; do
    PUBLISHED["$line"]=1
  done < "$PROGRESS_FILE"
  echo "Resuming — ${#PUBLISHED[@]} already published"
fi

PASSED=0
FAILED=0
SKIPPED=0
BATCH_COUNT=0

for tool in "${TOOLS[@]}"; do
  # Skip already published
  if [[ -n "${PUBLISHED[$tool]+x}" ]]; then
    echo "DONE: $tool (already published)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  SKILL_PATH="$REPO_DIR/$tool"

  if [ ! -f "$SKILL_PATH/SKILL.md" ]; then
    echo "SKIP: $tool — no SKILL.md"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if $DRY_RUN; then
    echo "DRY-RUN: clawhub publish $SKILL_PATH --slug $tool --name $tool --version 1.0.0"
    PASSED=$((PASSED + 1))
    continue
  fi

  # Check if we need to wait for next batch
  if [ "$BATCH_COUNT" -ge "$BATCH_SIZE" ]; then
    TOTAL_DONE=$((PASSED + SKIPPED))
    REMAINING=$((${#TOOLS[@]} - TOTAL_DONE))
    echo ""
    echo "=== Batch limit reached (5/hr). $REMAINING remaining. Waiting 61 minutes... ==="
    echo "    ($(date) — will resume at $(date -d "+61 minutes" 2>/dev/null || echo "~1hr from now"))"
    echo ""
    sleep $WAIT_SECONDS
    BATCH_COUNT=0
  fi

  echo -n "Publishing $tool... "
  if clawhub publish "$SKILL_PATH" --slug "$tool" --name "$tool" --version "1.0.0" 2>&1; then
    echo "OK"
    PASSED=$((PASSED + 1))
    BATCH_COUNT=$((BATCH_COUNT + 1))
    echo "$tool" >> "$PROGRESS_FILE"
  else
    echo "FAILED"
    FAILED=$((FAILED + 1))
    # If rate limited, wait and retry once
    if [ "$BATCH_COUNT" -lt "$BATCH_SIZE" ]; then
      echo "  Unexpected failure — skipping"
    fi
  fi

  sleep 2
done

echo ""
echo "========================================="
echo "  Published: $PASSED"
echo "  Failed:    $FAILED"
echo "  Skipped:   $SKIPPED"
echo "  Total:     ${#TOOLS[@]}"
echo "========================================="
