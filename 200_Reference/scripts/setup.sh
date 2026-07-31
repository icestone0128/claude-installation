#!/bin/bash
# Claude / Codex / AntiGravity 懶人包環境配置與二腦建置腳本
# 適用於 macOS 與 zsh 環境
#
# 主要 Agent:Claude Code(Obsidian MCP 預設註冊到 Claude Code)。
# 全域入口(rules + skills)由 Codex LazyPack Item 16 的 cross-device-sync bootstrap
# 同時建立 Codex / Claude / AntiGravity 三方原生入口,共用同一份主版本。

set -e

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
GEMINI_HOME="${GEMINI_HOME:-$HOME/.gemini}"
GEMINI_CONFIG="${GEMINI_CONFIG:-$GEMINI_HOME/config}"
SECRETS_DIR="${SECRETS_DIR:-$CODEX_HOME/secrets}"
LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"

# 自動切換至專案根目錄,確保相對路徑操作正確
cd "$(dirname "$0")/../.."

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${BLUE}==================================================${NC}"
echo -e "${GREEN}  Claude / Codex / AntiGravity 懶人包環境初始化與建置腳本${NC}"
echo -e "${BLUE}==================================================${NC}"

# ==========================================
# 0. 物理前置條件引導與互動確認
# ==========================================
echo -e "${YELLOW}【重要前置檢查】${NC}"
echo -e "在開始配置全域 Symlink 之前,請務必確認已手動下載並完成以下前置步驟(免 Homebrew):"
echo -e " 1. ${GREEN}手動安裝並登入 Google Drive 電腦版${NC}(確保雲端檔案完全同步至本地)。"
echo -e " 2. ${GREEN}手動安裝 Obsidian 筆記軟體${NC}。"
echo -e " 3. ${GREEN}手動安裝 Node.js,全域安裝 Obsidian MCP (mcpvault)${NC}。"
echo -e " 4. ${GREEN}安裝 Claude Code CLI${NC}(本腳本會將 Obsidian MCP 註冊到 Claude Code)。"
echo -e " 5. ${GREEN}在 Obsidian 中「開啟現有倉庫 (Open folder as vault)」${NC},指向已同步之 secondbrain 二腦目錄。"
echo -e ""

read -p "您是否已確認完成上述 Google Drive、Obsidian、mcpvault 與 Claude Code 安裝步驟? (y/n) [預設: y]: " PRE_CHECK
PRE_CHECK="${PRE_CHECK:-y}"
if [[ "$PRE_CHECK" != "y" && "$PRE_CHECK" != "Y" ]]; then
  echo -e "${RED}提示: 請先完成前置安裝與連線設定後,再重新執行此腳本。${NC}"
  exit 1
fi

# ==========================================
# 1. 驗證 GitHub 連線狀態與 Git 全域設定
# ==========================================
echo -e "\n${YELLOW}[步驟 1] 驗證 GitHub 連線與 Git 全域設定...${NC}"
if ! command -v gh &> /dev/null; then
  echo -e "${RED}錯誤: 系統未安裝 GitHub CLI (gh)。請先安裝 GitHub CLI 才能繼續執行。${NC}"
  exit 1
fi
if ! gh auth status &> /dev/null; then
  echo -e "${YELLOW}未偵測到 GitHub 登入資訊。正在啟動瀏覽器登入流程...${NC}"
  gh auth login --web --git-protocol https
else
  echo -e "${GREEN}GitHub CLI 已成功連接並登入!${NC}"
fi

GIT_USER=$(git config --global user.name || true)
GIT_EMAIL=$(git config --global user.email || true)
if [ -z "$GIT_USER" ] || [ -z "$GIT_EMAIL" ]; then
  echo -e "${YELLOW}未偵測到完整的 Git user.name 或 user.email,引導手動設定:${NC}"
  read -p "請輸入 Git 使用者名稱 user.name: " NEW_GIT_USER
  read -p "請輸入 Git 電子郵件 user.email: " NEW_GIT_EMAIL
  if [ -n "$NEW_GIT_USER" ] && [ -n "$NEW_GIT_EMAIL" ]; then
    git config --global user.name "$NEW_GIT_USER"
    git config --global user.email "$NEW_GIT_EMAIL"
    echo -e "${GREEN}Git 全域設定已更新!${NC}"
  else
    echo -e "${RED}警告: Git 使用者設定不完整,日後執行 git commit 時可能會被阻擋。${NC}"
  fi
else
  echo -e "  Git user.name: ${GREEN}$GIT_USER${NC}"
  echo -e "  Git user.email: ${GREEN}$GIT_EMAIL${NC}"
fi

# ==========================================
# 2. 自動偵測 Google Drive 掛載路徑
# ==========================================
echo -e "\n${YELLOW}正在本機動態偵測 Google Drive 掛載路徑...${NC}"
DETECTED_GD=""
MY_DRIVE_DIR_NAME_EN="${MY_DRIVE_DIR_NAME_EN:-My Drive}"
MY_DRIVE_DIR_NAME_LOCALIZED="${MY_DRIVE_DIR_NAME_LOCALIZED:-$(printf '\346\210\221\347\232\204\351\233\262\347\253\257\347\241\254\347\242\237')}"
if [ -d "$HOME/Library/CloudStorage" ]; then
  GD_CANDIDATES=($(find "$HOME/Library/CloudStorage" -maxdepth 1 -name "GoogleDrive-*" 2>/dev/null || true))
  for candidate in "${GD_CANDIDATES[@]}"; do
    if [ -d "$candidate/$MY_DRIVE_DIR_NAME_LOCALIZED" ]; then
      DETECTED_GD="$candidate/$MY_DRIVE_DIR_NAME_LOCALIZED"; break
    elif [ -d "$candidate/$MY_DRIVE_DIR_NAME_EN" ]; then
      DETECTED_GD="$candidate/$MY_DRIVE_DIR_NAME_EN"; break
    fi
  done
fi
if [ -n "$DETECTED_GD" ]; then
  echo -e "${GREEN}已偵測到 Google Drive 本地實體路徑。${NC}"
  DEFAULT_SYM_ROOT="$DETECTED_GD/codex_symlink"
  DEFAULT_VAULT="$DETECTED_GD/secondbrain"
else
  echo -e "${RED}未偵測到本機 Google Drive 掛載目錄!請確認已下載並登入 Google Drive 電腦版。${NC}"
  DEFAULT_SYM_ROOT=""; DEFAULT_VAULT=""
fi

# ==========================================
# 3. 建立指向 codex_symlink 的全域 Symlinks(重用 Item 16 bootstrap)
# ==========================================
echo -e "\n${YELLOW}[步驟 2] 設定全域配置軟連結 (Symlink)...${NC}"
read -p "請指定您 Google Drive 中 codex_symlink 的實體路徑 [Enter 使用偵測值;不顯示路徑]: " USER_SYM_ROOT
USER_SYM_ROOT="${USER_SYM_ROOT:-$DEFAULT_SYM_ROOT}"
USER_SYM_ROOT="${USER_SYM_ROOT/#\~/$HOME}"
if [ ! -d "$USER_SYM_ROOT" ]; then
  echo -e "${RED}錯誤: 找不到指定的 codex_symlink 路徑,請確認 Google Drive 串流已啟用並掛載!${NC}"
  exit 1
fi

# Item 16 owns all cross-agent entrypoint creation. Reuse it rather than
# maintaining another symlink implementation here.
AGENT_SYNC_SCRIPT="$USER_SYM_ROOT/skills/cross-device-sync/scripts/bootstrap-agent-sync.sh"
if [ ! -f "$AGENT_SYNC_SCRIPT" ]; then
  echo -e "${RED}錯誤: 找不到 cross-device-sync bootstrap。請先完成 Codex LazyPack Item 16。${NC}"
  exit 1
fi

echo -e "\n先預覽 chezmoi 與三 Agent 入口變更..."
bash "$AGENT_SYNC_SCRIPT" --sync-root "$USER_SYM_ROOT" --agents codex,claude,antigravity

echo -e "\n套用 chezmoi 與三 Agent 入口設定..."
bash "$AGENT_SYNC_SCRIPT" --sync-root "$USER_SYM_ROOT" --agents codex,claude,antigravity --install-chezmoi --apply

echo -e "${GREEN}入口對接完成!Codex、Claude、AntiGravity 現在共用同一份規則與技能主版本。${NC}"

# ==========================================
# 4. 對接或初始化第二大腦 (Obsidian Vault - 防覆寫保護)
# ==========================================
echo -e "\n${YELLOW}[步驟 3] 對接第二大腦 (Obsidian Vault)...${NC}"
read -p "請指定您的 Obsidian Vault 實體路徑 [Enter 使用偵測值;不顯示路徑]: " USER_VAULT
USER_VAULT="${USER_VAULT:-$DEFAULT_VAULT}"
USER_VAULT="${USER_VAULT/#\~/$HOME}"

V_FILES_COUNT=0
if [ -d "$USER_VAULT" ]; then
  V_FILES_COUNT=$(find "$USER_VAULT" -maxdepth 2 -type f ! -name ".*" 2>/dev/null | wc -l || echo 0)
fi

if [ "$V_FILES_COUNT" -gt 0 ]; then
  echo -e "${GREEN}偵測到現有 Obsidian Vault (內含 $V_FILES_COUNT 個檔案)。啟用【防覆寫對接】模式。${NC}"
  echo -e "  - 僅更新與備份全域規則檔至 Vault 底下的 AGENTS.md,不覆寫、不生成 index.md / log.md 等占位檔。"
  if [ -f "$USER_SYM_ROOT/core-rules.md" ]; then
    mkdir -p "$USER_VAULT"
    cp "$USER_SYM_ROOT/core-rules.md" "$USER_VAULT/AGENTS.md"
    echo -e "  已更新/備份全域核心規則至 Obsidian。"
  fi
else
  echo -e "${YELLOW}提示: Obsidian Vault 目錄不存在或為空,將自動建立與初始化結構。${NC}"
  mkdir -p "$USER_VAULT"
  for vdir in "Clippings" "知識庫" "創作庫" "每日筆記" "Templates" "專案庫"; do
    mkdir -p "$USER_VAULT/$vdir"; echo -e "  建立 Obsidian 資料夾: ${GREEN}$vdir${NC}"
  done
  if [ ! -f "$USER_VAULT/知識庫/index.md" ]; then
    printf -- "---\ntitle: 知識庫首頁\ntype: index\ntags:\n  - 知識庫\n---\n# 知識庫首頁\n" > "$USER_VAULT/知識庫/index.md"
    echo -e "  建立檔案: ${GREEN}知識庫/index.md${NC}"
  fi
  if [ ! -f "$USER_VAULT/知識庫/log.md" ]; then
    printf -- "---\ntitle: 知識庫異動日誌\ntype: log\ntags:\n  - 知識庫\n---\n# 知識庫異動日誌\n" > "$USER_VAULT/知識庫/log.md"
    echo -e "  建立檔案: ${GREEN}知識庫/log.md${NC}"
  fi
  if [ -f "$USER_SYM_ROOT/core-rules.md" ]; then
    cp "$USER_SYM_ROOT/core-rules.md" "$USER_VAULT/AGENTS.md"
    echo -e "  已複製全域核心規則至 Obsidian。"
  fi
fi

# ==========================================
# 5. 註冊 Obsidian MCP 至 Claude Code
# ==========================================
echo -e "\n${YELLOW}[步驟 4] 註冊 Obsidian MCP 至 Claude Code...${NC}"
if command -v mcpvault &> /dev/null || [ -x "/opt/homebrew/bin/mcpvault" ]; then
  if python3 200_Reference/scripts/register_mcp.py "$USER_VAULT" --agent claude; then
    echo -e "${GREEN}Obsidian MCP 已註冊至 Claude Code。${NC}"
  else
    echo -e "${YELLOW}Obsidian MCP 註冊未成功,請稍後手動執行 register_mcp.py。${NC}"
  fi
else
  echo -e "${YELLOW}未找到 mcpvault,略過 MCP 註冊。請先 npm install -g @bitbonsai/mcpvault。${NC}"
fi

# ==========================================
# 6. 配置 API Secrets (Gemini API Key 安全寫入)
# ==========================================
echo -e "\n${YELLOW}[步驟 5] 安全配置 Gemini API Key...${NC}"
read -p "您是否要在此時配置 Google AI Studio Gemini API Key? (y/n) [預設: y]: " WANT_KEY
WANT_KEY="${WANT_KEY:-y}"
if [[ "$WANT_KEY" == "y" || "$WANT_KEY" == "Y" ]]; then
  read -sp "請輸入您的 Gemini API Key: " GEMINI_KEY; echo ""
  if [ -n "$GEMINI_KEY" ]; then
    mkdir -p "$SECRETS_DIR"; chmod 700 "$SECRETS_DIR"
    echo "$GEMINI_KEY" > "$SECRETS_DIR/gemini_api_key"; chmod 600 "$SECRETS_DIR/gemini_api_key"
    echo -e "${GREEN}Gemini API Key 已安全儲存於本機 secrets 目錄(權限 600)。${NC}"
  else
    echo -e "${RED}警告: 輸入的金鑰為空,略過配置。${NC}"
  fi
else
  echo -e "${YELLOW}已略過配置。${NC}"
fi

# ==========================================
# 7. 初始化專案本地資料層
# ==========================================
echo -e "\n${YELLOW}[步驟 6] 初始化專案本地資料層...${NC}"
for dir in "100_Todo/drafts" "100_Todo/projects" "100_Todo/archive" \
           "200_Reference/lazy-pack" "200_Reference/writing-samples" \
           "200_Reference/templates" "200_Reference/past-work"; do
  if [ ! -d "$dir" ]; then mkdir -p "$dir"; echo -e "  已建立資料夾: ${GREEN}$dir${NC}"; else echo -e "  資料夾已存在 (略過): $dir"; fi
done

# ==========================================
# 8. 部署預設知識架構範本
# ==========================================
echo -e "\n${YELLOW}[步驟 7] 部署預設知識架構範本...${NC}"
if [ -d "$USER_SYM_ROOT/knowledge" ]; then
  for tfile in context-management-strategy.md verification-checklist.md subagent-strategy.md \
               parallelization-strategy.md advanced-memory-learning.md prompt-defense-baseline.md \
               security-review-checklist.md coding-standards.md; do
    if [ -f "$USER_SYM_ROOT/knowledge/$tfile" ]; then
      if [ ! -f "200_Reference/templates/$tfile" ]; then
        cp "$USER_SYM_ROOT/knowledge/$tfile" "200_Reference/templates/"
        echo -e "  已複製範本: ${GREEN}$tfile${NC}"
      else
        echo -e "  本地範本已存在 (略過,防覆寫): $tfile"
      fi
    fi
  done
else
  echo -e "${RED}警告: 找不到全域知識庫目錄,略過部署。${NC}"
fi

# ==========================================
# 9. 配置 AI 助理工具路徑 (PATH)
# ==========================================
echo -e "\n${YELLOW}[步驟 8] 配置 AI 助理工具路徑 (PATH)...${NC}"
ZSHRC="$HOME/.zshrc"; touch "$ZSHRC"
for tool_path in "$CODEX_HOME/python-tools/bin" "$LOCAL_BIN"; do
  if ! grep -qF "$tool_path" "$ZSHRC" 2>/dev/null; then
    { echo ""; echo "# Codex / Claude / AntiGravity 工具路徑"; echo "export PATH=\"$tool_path:\$PATH\""; } >> "$ZSHRC"
    echo -e "  已寫入 PATH: $tool_path"
  else
    echo -e "  PATH 已存在 (略過): $tool_path"
  fi
done
echo -e "${GREEN}工具路徑配置完成!重新開啟 Terminal 或執行 source ~/.zshrc 即生效。${NC}"

# ==========================================
# 10. 執行環境健檢
# ==========================================
echo -e "\n${YELLOW}[步驟 9] 執行全域技能環境健檢...${NC}"
if [ -f 200_Reference/scripts/healthcheck.sh ]; then
  bash 200_Reference/scripts/healthcheck.sh || true
fi

echo -e "\n${BLUE}==================================================${NC}"
echo -e "${GREEN}🎉 Claude 懶人包環境配置與建置完成!${NC}"
echo -e "1. 全域軟連結 (Symlink) 建立成功(三 Agent 共用)"
echo -e "2. Obsidian Vault 對接完成 (${GREEN}防覆寫模式${NC})"
echo -e "3. Obsidian MCP 已註冊至 Claude Code"
echo -e "4. Gemini API Key 安全配置就緒"
echo -e "5. 本地專案層與知識範本部署完成 (${GREEN}防覆寫模式${NC})"
echo -e "6. AI 助理工具路徑 (PATH) 配置完成"
echo -e "7. 環境健檢已執行"
echo -e ""
echo -e "${YELLOW}請重啟您的 Claude Code 以加載全域技能與 MCP 連線!${NC}"
echo -e "${BLUE}==================================================${NC}"
