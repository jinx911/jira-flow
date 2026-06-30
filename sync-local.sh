#!/bin/bash
# sync-local.sh — 把仓库里的 dev-flow 系列 skill 同步到本地 ~/.claude/skills/
#
# 用真实目录拷贝（非符号链接）：避免 project-config.md 等 per-user 生成文件写回仓库。
# 代价：仓库改动不会自动反映到本地，每次改完 skill 需重跑本脚本。
#
# 用法:
#   ./sync-local.sh             # 同步 dev-flow 全家桶（默认）
#   ./sync-local.sh --all       # 额外同步 create-team/delete-team/git-ops
#   ./sync-local.sh --no-cleanup # 不清理旧 jira-flow/init-jira-flow 残留
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/skills"
DEST="$HOME/.claude/skills"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${GREEN}[INFO]${NC} $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
err(){  echo -e "${RED}[ERROR]${NC} $1"; }

# 默认同步 dev-flow 全家桶；--all 追加依赖 skill
DEFAULT_SKILLS=(dev-flow init-dev-flow spec-author dev-loop review-test ship)
EXTRA_SKILLS=(create-team delete-team git-ops)

# 某些 skill 含 per-user 生成文件（不在仓库），同步时必须保留
# 仅 dev-flow 有 project-config.md（由 /init-dev-flow 生成）
preserve_file() {
  case "$1" in
    dev-flow) echo "project-config.md" ;;
    *)        echo "" ;;
  esac
}

# --- 解析参数 ---
SKILLS=("${DEFAULT_SKILLS[@]}")
CLEANUP_LEGACY=1
while [ $# -gt 0 ]; do
  case "$1" in
    --all)         SKILLS+=("${EXTRA_SKILLS[@]}"); info "追加依赖 skill: ${EXTRA_SKILLS[*]}" ;;
    --no-cleanup)  CLEANUP_LEGACY=0 ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) err "未知参数: $1"; exit 1 ;;
  esac
  shift
done

[ -d "$DEST" ] || { err "未找到 $DEST，请先运行一次 Claude Code 初始化 ~/.claude/。"; exit 1; }

# --- 1. 清理旧 jira-flow 残留 ---
if [ "$CLEANUP_LEGACY" = 1 ]; then
  for legacy in jira-flow init-jira-flow; do
    if [ -e "$DEST/$legacy" ] || [ -L "$DEST/$legacy" ]; then
      rm -rf "$DEST/$legacy"
      info "清理旧残留: $legacy"
    fi
  done
fi

# --- 2. 逐个同步 ---
for skill in "${SKILLS[@]}"; do
  [ -d "$SRC/$skill" ] || { warn "仓库无此 skill，跳过: $skill"; continue; }

  pf="$(preserve_file "$skill")"
  backup=""
  # 备份 per-user 文件
  if [ -n "$pf" ] && [ -f "$DEST/$skill/$pf" ]; then
    backup="$(mktemp -d)"
    cp "$DEST/$skill/$pf" "$backup/"
    info "备份 $skill/$pf"
  fi

  # 先删后拷，保证目录干净
  rm -rf "$DEST/$skill"
  cp -R "$SRC/$skill" "$DEST/$skill"

  # 恢复 per-user 文件
  if [ -n "$backup" ]; then
    cp "$backup/$pf" "$DEST/$skill/$pf"
    rm -rf "$backup"
    info "恢复 $skill/$pf (per-user 配置已保留)"
  fi

  info "同步: $skill"
done

# --- 3. 校验 ---
echo ""
info "校验："
OK=1
for skill in "${SKILLS[@]}"; do
  if [ -f "$DEST/$skill/SKILL.md" ]; then
    echo "  ✅ $skill/SKILL.md"
  else
    echo "  ❌ $skill/SKILL.md 缺失"; OK=0
  fi
done
if [ -f "$DEST/dev-flow/project-config.md" ]; then
  echo "  ✅ dev-flow/project-config.md（per-user，已保留）"
else
  warn "  dev-flow/project-config.md 不存在——运行 /init-dev-flow 生成，或手动创建"
fi

echo ""
if [ "$OK" = 1 ]; then
  info "同步完成。开新会话后 /dev-flow、/init-dev-flow、/spec-author 等即可生效。"
else
  err "部分 skill 校验失败，请检查上方输出。"; exit 1
fi
