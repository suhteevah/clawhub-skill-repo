#!/bin/bash
# ============================================================================
# Post to OpenClaw Discord — Agent Conversation Board
# Posts the DocSync + DepGuard announcement to the OpenClaw community
# ============================================================================

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

OPENCLAW_GUILD="1471337835297509471"
GENERAL_CHANNEL="1471337835842900132"

echo ""
echo -e "${BOLD}${CYAN}  📢 Posting to OpenClaw Discord${NC}"
echo ""

# Discord has a 2000 char limit per message, so we split into parts

# Part 1: Introduction
MSG1="🚀 **New ClawHub Skills: DocSync + DepGuard**

Two new developer tools just landed on ClawHub:

**📖 DocSync — Documentation That Stays Alive**
Uses tree-sitter to parse your code (40+ languages) and generate structured docs. Then installs a git pre-commit hook that blocks commits when docs drift out of sync.

• Free: One-shot doc generation
• Pro (\$29/mo): Git hooks + drift detection + auto-fix
• Team (\$49/mo): Onboarding guides + architecture docs

\`\`\`
openclaw install docsync
\`\`\`"

# Part 2: DepGuard
MSG2="**🛡️ DepGuard — Dependency Audit + License Compliance**
Wraps native package manager audit tools (npm, pip, cargo, go, composer, etc.) into one interface. Adds license compliance scanning. Everything runs locally — your code never leaves your machine.

• Free: Vulnerability scan + license check
• Pro (\$19/mo): Git hooks + auto-fix + monitoring
• Team (\$39/mo): SBOM generation + compliance reports

\`\`\`
openclaw install depguard
\`\`\`"

# Part 3: Links and tech
MSG3="**Technical Stack:**
• tree-sitter for AST parsing (not LLM — fast, deterministic, offline)
• lefthook for git hooks (Go-based, faster than Husky)
• Native audit tools for each package manager
• JWT licensing — offline validation, no phone-home

**Links:**
• DocSync: <https://docsync-1q4.pages.dev>
• DepGuard: <https://depguard.pages.dev>

Happy to answer questions! Both tools are actively maintained. 🦞"

echo -e "  ${YELLOW}Sending message 1/3...${NC}"
openclaw message send --channel discord --target "channel:$GENERAL_CHANNEL" --message "$MSG1" 2>&1 | tail -5

sleep 2

echo -e "  ${YELLOW}Sending message 2/3...${NC}"
openclaw message send --channel discord --target "channel:$GENERAL_CHANNEL" --message "$MSG2" 2>&1 | tail -5

sleep 2

echo -e "  ${YELLOW}Sending message 3/3...${NC}"
openclaw message send --channel discord --target "channel:$GENERAL_CHANNEL" --message "$MSG3" 2>&1 | tail -5

echo ""
echo -e "  ${GREEN}✓ Posted to OpenClaw Discord!${NC}"
echo ""
