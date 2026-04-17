#!/usr/bin/env bash
# fix-manifests.sh — Fix SKILL.md metadata across all skills
# 1. Update bins to include python3 and jq
# 2. Add configPaths field if missing
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
count=0

for skill_md in "$REPO_ROOT"/*/SKILL.md; do
  skill_name="$(basename "$(dirname "$skill_md")")"

  # 1. Update bins: ["git", "bash"] -> ["git", "bash", "python3", "jq"]
  if grep -q '"bins": \["git", "bash"\]' "$skill_md"; then
    sed -i 's/"bins": \["git", "bash"\]/"bins": ["git", "bash", "python3", "jq"]/' "$skill_md"
    echo "[FIXED bins] $skill_name"
  elif grep -q '"bins"' "$skill_md"; then
    echo "[SKIP bins - non-standard] $skill_name"
  else
    echo "[SKIP bins - not found] $skill_name"
  fi

  # 2. Add configPaths if missing
  if ! grep -q '"configPaths"' "$skill_md"; then
    python3 -c "
import sys, re
sys.stdout.reconfigure(encoding='utf-8', errors='replace')
fpath = sys.argv[1]
sname = sys.argv[2]
with open(fpath, 'r', encoding='utf-8') as f:
    content = f.read()
pattern = r'(\"requires\":\s*\{[^}]+\})'
match = re.search(pattern, content)
if match:
    replacement = match.group(1) + ',\n      \"configPaths\": [\"~/.openclaw/openclaw.json\"]'
    content = content[:match.start()] + replacement + content[match.end():]
    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'[FIXED configPaths] {sname}')
else:
    print(f'[SKIP configPaths - no requires block] {sname}')
" "$skill_md" "$skill_name"
  else
    echo "[SKIP configPaths - already present] $skill_name"
  fi

  count=$((count + 1))
done

echo ""
echo "Processed $count SKILL.md files."
