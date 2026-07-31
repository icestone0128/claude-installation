#!/bin/bash
# healthcheck.sh - Claude / Codex / AntiGravity 懶人包環境健檢(全唯讀,不改動任何設定)
# 對應 01-claude-lazypack.md「四、全域技能健檢與三方同步驗證」的所有檢查項目。
# 適用於 macOS + zsh。用法: bash 200_Reference/scripts/healthcheck.sh

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
GEMINI_CONFIG="${GEMINI_CONFIG:-$HOME/.gemini/config}"
SECRETS_DIR="${SECRETS_DIR:-$CODEX_HOME/secrets}"
PT="$CODEX_HOME/python-tools/bin"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
PASS=0; FAIL=0; WARN=0

ok()   { printf "${GREEN}[通過]${NC} %-22s %s\n" "$1" "$2"; PASS=$((PASS+1)); }
bad()  { printf "${RED}[缺失]${NC} %-22s %s\n" "$1" "$2"; FAIL=$((FAIL+1)); }
warn() { printf "${YELLOW}[注意]${NC} %-22s %s\n" "$1" "$2"; WARN=$((WARN+1)); }

# ver <label> <cmd...> : 命令存在則通過並印首行版本
ver() {
  local label="$1"; shift
  if command -v "$1" &>/dev/null; then ok "$label" "$("$@" 2>&1 | head -1)"; else bad "$label" "未安裝或不在 PATH"; fi
}

echo -e "${BLUE}==================================================${NC}"
echo -e "${GREEN}  Claude 懶人包 — 全域技能環境健檢${NC}"
echo -e "${BLUE}==================================================${NC}"

echo -e "\n${YELLOW}[A] 基礎服務${NC}"
ver "chezmoi (#16)"      chezmoi --version
ver "GitHub CLI (gh)"    gh --version
ver "git"                git --version
ver "node"               node -v
ver "npm"                npm -v
ver "mcpvault"           mcpvault --version

echo -e "\n  Git 全域身分:"
GN="$(git config --global user.name)"; GE="$(git config --global user.email)"
[ -n "$GN" ] && [ -n "$GE" ] && ok "git 身分" "$GN <$GE>" || warn "git 身分" "user.name / user.email 未設定完整"

echo -e "\n  GitHub 登入:"
gh auth status &>/dev/null && ok "gh auth" "已登入" || warn "gh auth" "未登入(執行 gh auth login)"

echo -e "\n  Claude Code:"
ver "claude CLI"         claude --version

echo -e "\n${YELLOW}[B] Python Tools (#34) & uv${NC}"
ver "uv"                 uv --version
ver "python3"            python3 --version
if [ -x "$PT/python-tools-python" ]; then
  R="$("$PT/python-tools-python" -c "import pandas, docx, pptx, pdfplumber; print('pandas/docx/pptx/pdfplumber ok')" 2>&1 | head -1)"
  case "$R" in *ok) ok "python-tools venv" "$R";; *) bad "python-tools venv" "$R";; esac
else
  bad "python-tools venv" "$PT/python-tools-python 不存在(需 LazyPack #34)"
fi

echo -e "\n${YELLOW}[C] 媒體 / 下載${NC}"
ver "ffmpeg"             ffmpeg -version
ver "yt-dlp (#31/#34)"   yt-dlp --version

echo -e "\n${YELLOW}[D] PDF / Poppler (#01/#18)${NC}"
ver "pdftoppm (Poppler)" pdftoppm -v
if command -v python3 &>/dev/null; then
  R="$(python3 -c "import pdfplumber; print('pdfplumber', pdfplumber.__version__)" 2>&1 | head -1)"
  case "$R" in pdfplumber*) ok "pdfplumber" "$R";; *) warn "pdfplumber" "系統 python3 無 pdfplumber(改用 python-tools venv)";; esac
fi

echo -e "\n${YELLOW}[E] 部署 / 知識 CLI${NC}"
ver "netlify (#28)"      netlify --version
ver "firebase (#08)"     firebase --version
ver "heptabase (#02)"    heptabase --version

echo -e "\n${YELLOW}[F] 語音 TTS (#26/#32/#37)${NC}"
command -v say &>/dev/null && ok "macOS say" "可用" || warn "macOS say" "找不到 say"
ver "edge-tts"           edge-tts --version
if [ -x "$PT/voice-reply" ] || command -v voice-reply &>/dev/null; then ok "voice-reply (#37)" "入口就緒"; else warn "voice-reply (#37)" "未在中立入口"; fi

echo -e "\n${YELLOW}[G] 瀏覽器 (Playwright #01)${NC}"
if [ -d "$HOME/Library/Caches/ms-playwright" ] && [ -n "$(ls -A "$HOME/Library/Caches/ms-playwright" 2>/dev/null)" ]; then
  ok "Playwright" "瀏覽器快取已存在"
else
  warn "Playwright" "無瀏覽器快取(需要時 npx playwright install)"
fi

echo -e "\n${YELLOW}[H] API secrets 安全 (#25)${NC}"
if [ -f "$SECRETS_DIR/gemini_api_key" ]; then
  PERM="$(stat -f '%A' "$SECRETS_DIR/gemini_api_key" 2>/dev/null)"
  [ "$PERM" = "600" ] && ok "gemini_api_key" "存在且權限 600" || warn "gemini_api_key" "存在但權限為 $PERM(建議 600)"
else
  warn "gemini_api_key" "未配置(全域 Gemini API 功能將無法調用)"
fi

echo -e "\n${YELLOW}[I] 三 Agent 入口 symlink${NC}"
for entry in \
  "$CLAUDE_HOME/CLAUDE.md" "$CLAUDE_HOME/skills" \
  "$CODEX_HOME/AGENTS.md" "$CODEX_HOME/skills" \
  "$HOME/.gemini/GEMINI.md" "$GEMINI_CONFIG/skills"; do
  if [ -L "$entry" ]; then
    [ -e "$entry" ] && ok "$(basename "$(dirname "$entry")")/$(basename "$entry")" "symlink 有效" \
                     || bad "$(basename "$(dirname "$entry")")/$(basename "$entry")" "symlink 斷鏈"
  else
    warn "$(basename "$(dirname "$entry")")/$(basename "$entry")" "非 symlink 或缺失"
  fi
done

echo -e "\n${YELLOW}[J] 需 Agent 觸發驗證(本腳本不自動測)${NC}"
echo -e "  - GPT Image Tool 生圖能力(image-generator / imagegen)"
echo -e "  - Kokoro / VoxCPM TTS 模型合成(hyperframes-media / voxcpm2-voice-cloner)"

echo -e "\n${BLUE}==================================================${NC}"
echo -e "  結果: ${GREEN}通過 $PASS${NC} / ${YELLOW}注意 $WARN${NC} / ${RED}缺失 $FAIL${NC}"
echo -e "${BLUE}==================================================${NC}"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
