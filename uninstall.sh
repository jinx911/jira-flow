#!/bin/bash
# jira-flow uninstaller — removes symlinks created by install.sh
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

REMOVED_SKILLS=0
REMOVED_AGENTS=0

# --- Remove skill symlinks ---

for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    name=$(basename "$skill_dir")
    target="$SKILLS_DIR/$name"

    if [ -L "$target" ]; then
        rm "$target"
        info "Removed skill symlink: $name"
        ((REMOVED_SKILLS++))
    elif [ -d "$target" ]; then
        warn "$target/ is a real directory (not a symlink). Skipping."
    fi
done

# --- Remove agent symlinks ---

for agent_file in "$SCRIPT_DIR/agents"/*.md; do
    [ -f "$agent_file" ] || continue
    name=$(basename "$agent_file")
    target="$AGENTS_DIR/$name"

    if [ -L "$target" ]; then
        rm "$target"
        info "Removed agent symlink: ${name%.md}"
        ((REMOVED_AGENTS++))
    elif [ -f "$target" ]; then
        warn "$target is a real file (not a symlink). Skipping."
    fi
done

echo ""
echo "Skills removed: $REMOVED_SKILLS"
echo "Agents removed: $REMOVED_AGENTS"
echo ""
info "jira-flow uninstalled. Your cloned repo is still at $SCRIPT_DIR"
echo "  Remove it manually if desired: rm -rf $SCRIPT_DIR"
