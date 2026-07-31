---
name: claude-lazy-packs
description: Claude 懶人包 — 服務連接與工作流程設定。說「Claude 懶人包」「安裝 Claude 設定」時載入。
---

# Claude 懶人包 — AI Agent 自動安裝與設定入口

當使用者給你這個 repo 網址並說要安裝時,請依以下流程執行。本專案作為服務連接與工作流程的設定指引;全域技能均已在全域目錄中管理,不需額外重複安裝個別 Skill。主要 Agent 為 Claude Code,但全域入口由 Item 16 bootstrap 同時建立 Codex / Claude / AntiGravity 三方。

## 步驟一:安裝與連接基礎服務 (必要前置環境準備 - 免 Homebrew)

引導使用者手動前往官網下載並安裝以下實體軟體,完全免除 Homebrew:
1. **安裝 Node.js 與 npm**:提供 `npx` 運行環境(前往 Node 官方網站下載安裝包)。
2. **安裝 Google Drive 電腦版**:登入帳號並確認全域 `codex_symlink` 和二腦 `secondbrain` 已完全同步下載至本機掛載點下。
3. **安裝 Obsidian Desktop**:下載安裝後開啟,選擇「開啟現有倉庫 (Open folder as vault)」,指向已同步之本地二腦路徑,加載過往所有記錄。
4. **安裝 Claude Code CLI**:前往官方安裝 Claude Code,確認 `claude --version` 可用(本專案將 Obsidian MCP 註冊到 Claude Code)。
5. **安裝與註冊 Obsidian MCP (`mcpvault`)**:全域執行 `npm install -g @bitbonsai/mcpvault`,並用 `claude mcp add` 或本專案 `register_mcp.py` 將 `obsidian` 註冊到 Claude Code。
6. **安裝 Git 與 GitHub CLI**:Git 透過官網或 Xcode 命令列安裝;GitHub CLI 下載後執行 `gh auth login` 登入。
7. **安裝 Python 3、uv、chezmoi 與 FFmpeg、yt-dlp**:提供全域技能之文字與媒體依賴。

## 步驟二:執行自動化設定腳本與設定 Symlink

引導使用者在本專案目錄下執行:
```bash
./200_Reference/scripts/setup.sh
```
此腳本會互動引導並自動完成:偵測 Google Drive 與 Vault 路徑、補全 Git 身分、重用 Item 16 bootstrap 建立三 Agent 入口、將 Obsidian MCP 註冊到 Claude Code、安全寫入 Gemini API Key、初始化本地資料層與知識範本、配置 PATH,最後執行環境健檢。

## 步驟三:建置與驗證第二大腦對接 (防覆寫保護)

1. **防覆寫保護**:若 Obsidian Vault 已有檔案,僅更新規則檔至 `secondbrain/AGENTS.md`,絕不生成占位檔案。若路徑全新才初始化。
2. 初始化專案本地資料層(`100_Todo` 與 `200_Reference`)。
3. 驗證連線:要求 Claude Code 透過 `obsidian` MCP 讀寫二腦。

## 步驟四:全域技能健檢與三方同步驗證

執行 `bash 200_Reference/scripts/healthcheck.sh`(全唯讀),並對照 [01-claude-lazypack.md](./200_Reference/lazy-pack/01-claude-lazypack.md) 第四章:
1. 驗證基礎服務(chezmoi / gh / node / npm / mcpvault / claude CLI / Google Drive)。
2. 驗證進階依賴(Python Tools & uv、生圖、Playwright、Poppler/pdfplumber、FFmpeg、yt-dlp、Heptabase / Netlify / Firebase CLI、Edge-TTS / voice-reply、API secrets)。
3. 校驗「全域 Skill (`codex_symlink/skills`)」「LazyPack 本手冊」「Obsidian 駕駛艙」三方相容(Codex / Claude / AntiGravity 共用同一主版本與路徑)。
4. 遇到沙盒限制時,將 PIP / NPM / Python 執行與工作路徑列為沙盒例外 `writable_roots`。

## 步驟五:完成回報格式

完成後,依 [01-claude-lazypack.md](./200_Reference/lazy-pack/01-claude-lazypack.md) 第五章的回報格式輸出狀態。
