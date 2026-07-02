#!/bin/bash
# dev-flow installer — symlinks skills and agents into ~/.claude/
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
AGENTS_DIR="$CLAUDE_DIR/agents"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Prerequisites ---

if ! command -v claude &>/dev/null; then
    error "Claude Code CLI not found. Install it first: https://docs.anthropic.com/en/docs/claude-code"
    exit 1
fi
info "Claude Code CLI found"

if [ ! -d "$CLAUDE_DIR" ]; then
    error "~/.claude/ not found. Run Claude Code at least once to initialize."
    exit 1
fi

# Check superpowers plugin
if [ ! -d "$SKILLS_DIR" ] || ! ls "$SKILLS_DIR"/superpowers* &>/dev/null 2>&1; then
    warn "superpowers plugin not detected in $SKILLS_DIR/"
    warn "dev-flow requires superpowers >= 5.0.0. Install it before using dev-flow."
fi

# --- Install Skills ---

mkdir -p "$SKILLS_DIR"

SKILL_COUNT=0
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    name=$(basename "$skill_dir")
    target="$SKILLS_DIR/$name"

    if [ -L "$target" ]; then
        rm "$target"
    elif [ -d "$target" ]; then
        warn "Existing $target/ is a real directory (not a symlink). Skipping to avoid data loss."
        warn "Remove it manually if you want to replace it: rm -rf $target"
        continue
    fi

    ln -s "$skill_dir" "$target"
    info "Linked skill: $name"
    ((SKILL_COUNT++))
done

info "Installed $SKILL_COUNT skills"

# --- Install Agents ---

mkdir -p "$AGENTS_DIR"

AGENT_COUNT=0
for agent_file in "$SCRIPT_DIR/agents"/*.md; do
    [ -f "$agent_file" ] || continue
    name=$(basename "$agent_file")
    target="$AGENTS_DIR/$name"

    if [ -L "$target" ]; then
        rm "$target"
    elif [ -f "$target" ]; then
        warn "Existing $target is a real file (not a symlink). Skipping."
        continue
    fi

    ln -s "$agent_file" "$target"
    info "Linked agent: ${name%.md}"
    ((AGENT_COUNT++))
done

info "Installed $AGENT_COUNT agents"

# --- Summary ---

echo ""
echo "========================================="
echo "  dev-flow installed successfully!"
echo "========================================="
echo ""
echo "Skills:  $SKILL_COUNT linked to $SKILLS_DIR/"
echo "Agents:  $AGENT_COUNT linked to $AGENTS_DIR/"
echo ""
echo "Next steps:"
echo "  1. Ensure superpowers plugin is installed (>= 5.0.0)"
echo "  2. Ensure atlassian-rovo MCP is configured in Claude Code"
echo "  3. Run: /init-dev-flow"
echo "  4. Run: /dev-flow <ISSUE-KEY>"
echo ""
