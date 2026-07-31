# Claude 懶人包 #01:服務連接與工作流程設定

> 版本:v1.0 (Claude 版,改寫自 AntiGravity 懶人包 v2.8)
> 更新日期:2026-08-01
> 語系偏好:繁體中文(Taiwan)

這份懶人包的目標,是讓 Claude Code 使用者能在**完全乾淨的第二台電腦**上,快速且安全地連接 GitHub 與 Obsidian,並建立「開工 / 收工 / 新專案初始化」工作流程。主要 Agent 為 Claude Code,但全域入口由 Codex LazyPack Item 16 的 chezmoi bootstrap 同時建立 Codex / Claude / AntiGravity 三方原生入口,共用同一份 `codex_symlink` 規則與技能主版本。NotebookLM 與 Firebase 的連線已由全域配置接管,本指引不重複設定。

本文件只放可公開教學的設定流程,不放任何個人帳號 token、密碼或敏感測試專案資訊。

---

## 一、安裝與連接基礎服務 (必要前置環境準備 - 免 Homebrew 手動下載與安裝流程)

在進行任何 Symlink 對接前,請依序手動完成以下軟體安裝與 MCP 配置。這是讓您在新電腦上成功加載雲端全域配置與 Obsidian 第二大腦記錄的物理先決條件。

### 1. 安裝 Node.js 與 npm (Obsidian MCP 運行底層)
- **目的**:提供 `npx` 與全球套件管理環境,這是運行 `mcpvault` 與其他 AI 助理工具的底層依賴。
- **下載指引**:前往 [Node.js 官方網站(推薦下載 LTS 版本)](https://nodejs.org/) 下載 macOS `.pkg` 安裝程式,雙擊執行安裝。
- **驗證環境**:
  ```bash
  node -v
  npm -v
  ```

### 2. 安裝 Google Drive 電腦版並同步雲端檔案
- **目的**:將您雲端硬碟中的全域資源母資料夾 `codex_symlink` 和第二大腦資料夾 `secondbrain` 同步至本機。
- **下載指引**:前往 [Google Drive 電腦版官方下載頁](https://www.google.com/drive/download/) 下載 macOS `.dmg`,安裝後拖移至「應用程式」。
- **雲端同步與掛載**:
  1. 啟動 Google Drive 電腦版並登入。
  2. 確認 macOS 本地實體掛載點(預設位於 `{{GOOGLE_DRIVE_ROOT}}`)已建立。
  3. **關鍵等待**:確認該目錄下的 `codex_symlink` 與 `secondbrain` 已**完全同步下載至本地**。

### 3. 安裝 Obsidian Desktop 並開啟現有二腦
- **目的**:本機筆記管理與專案駕駛艙。
- **下載指引**:前往 [Obsidian 官方網站](https://obsidian.md/) 下載 macOS `.dmg`,安裝並開啟。
- **開啟現有二腦**:
  1. 在 Obsidian 歡迎畫面選擇 **「開啟現有倉庫 (Open folder as vault)」**。
  2. 選擇已同步至本地的二腦資料夾路徑(如:`{{OBSIDIAN_VAULT}}`)。
  3. 確認過往所有筆記、工作流程與專案駕駛艙成功加載。

### 4. 安裝 Claude Code CLI
- **目的**:本懶人包的主要 AI Agent。
- **下載指引**:依 [Claude Code 官方文件](https://docs.claude.com/en/docs/claude-code) 安裝 Claude Code CLI。
- **驗證環境**:
  ```bash
  claude --version
  ```

### 5. 安裝與註冊 Obsidian MCP (至 Claude Code)
- **目的**:讓 Claude Code 可以直接透過工具 API 讀寫您的 Obsidian 第二大腦。
- **安裝指令**:
  ```bash
  npm install -g @bitbonsai/mcpvault
  ```
- **配置 MCP 伺服器(擇一)**:
  - **方式 A — 官方 CLI(推薦)**:
    ```bash
    claude mcp add --scope user obsidian "$(command -v mcpvault)" "{{OBSIDIAN_VAULT}}"
    ```
  - **方式 B — 自動化註冊腳本**:直接執行本 repo 提供的腳本,它會自動定位 `mcpvault`、優先使用 `claude mcp add`,並安全保留其他既有 MCP(如 google-workspace、notebooklm、firebase):
    ```bash
    python3 200_Reference/scripts/register_mcp.py "{{OBSIDIAN_VAULT}}" --agent claude
    ```
  *(Claude Code 的使用者層 MCP 設定存放於 `~/.claude.json` 的 `mcpServers`;腳本詳細原始碼請參見文末附錄一。)*

### 6. 安裝 Git 與 GitHub CLI (`gh`) 並登入
- **Git 手動下載**:前往 [Git 官方網站](https://git-scm.com/downloads),或在 Terminal 輸入 `git --version` 觸發安裝 Xcode Command Line Tools。
- **GitHub CLI (`gh`) 手動下載**:前往 [GitHub CLI 官網](https://cli.github.com/) 下載 macOS 預編譯檔,移動至 PATH。
- **登入與驗證**:
  ```bash
  gh auth login --web --git-protocol https
  gh auth status
  ```

### 7. 安裝 Python 3、uv、chezmoi 與媒體工具
- **Python 3 & pip**:前往 [Python 官方網站](https://www.python.org/downloads/) 下載 `.pkg` 安裝。
- **uv 套件管理器(推薦)**:`curl -LsSf https://astral.sh/uv/install.sh | sh`。
- **chezmoi (跨 Agent 與跨裝置設定同步 #16)**:`curl -fsLS get.chezmoi.io | sh`;用於管理三 Agent 原生入口與共用環境 bridge。
- **Python Tools 全域工具包 (#34)**:與 Codex Installation 共用本機 `{{CODEX_HOME}}/python-tools` 唯一實體 runtime(含 `python-docx`, `openpyxl`, `python-pptx`, `pdfplumber`, `PyMuPDF`, `reportlab`, `markitdown`, `ocrmypdf`);共用中立入口位於 `~/.local/share/agent-tools/python-tools`。
- **Poppler (PDF 頁面渲染 #01/#18)**:`pdf` skill 若要把 PDF 頁面渲染成圖片做視覺檢查需 Poppler,提供 `pdftoppm`, `pdfinfo`, `pdftocairo`。
- **FFmpeg**:前往 [FFmpeg 官網](https://ffmpeg.org/download.html#build-mac) 下載靜態執行檔,移至 PATH。
- **yt-dlp**:`pip3 install yt-dlp`。

### 8. 安全規則
- 嚴禁將個人 GitHub token、API keys 寫進 Markdown、AGENTS.md、Obsidian 對外筆記或 commit。
- commit 前務必先檢查 diff,嚴禁自動無差別提交。

---

## 二、設定全域配置軟連結 (Symlink)

在步驟一的基礎軟體、MCP 註冊與二腦連線完成後,執行設定腳本建立指向 `codex_symlink` 的全域軟連結。

### 執行設定腳本
```bash
./200_Reference/scripts/setup.sh
```

### 腳本執行互動填寫與對接邏輯:
- **互動確認路徑**:動態偵測並讓您確認 `codex_symlink` 與 `secondbrain` 目錄。
- **Git 全域設定補全**:若 `user.name` 或 `user.email` 為空,提示輸入並寫入 `git config --global`。
- **重用 Item 16 bootstrap**:呼叫 `cross-device-sync/scripts/bootstrap-agent-sync.sh` 預覽 → 備份 → 建立 Codex / Claude / AntiGravity 三方原生入口(rules + skills),並安裝必要的 chezmoi。
- **Obsidian MCP 註冊至 Claude Code**:自動執行 `register_mcp.py --agent claude`。
- **Gemini API Key 安全配置**:互動輸入,寫入 `{{SECRETS_DIR}}/gemini_api_key`(權限 600,排除於 Git)。
- **Obsidian Vault 結構初始化**:全新目錄時建立 `Clippings`、`知識庫`、`創作庫`、`每日筆記`、`Templates`、`專案庫` 六個目錄。
- **AI 助理工具路徑 (PATH) 配置**:將 `{{CODEX_HOME}}/python-tools/bin` 與 `{{LOCAL_BIN}}` 寫入 `~/.zshrc`。
- **環境健檢**:最後自動執行 `healthcheck.sh`。

*執行完成後,請重啟 Claude Code。重啟後便能加載 `arry-assistant` 等全域技能,繼承跨專案記憶。*

---

## 三、對接與驗證第二大腦 (防覆寫保護)

### 1. 腳本防覆寫機制說明
- **安全保護**:若 Obsidian Vault 中已存在檔案,腳本**僅更新全域核心規則至 Vault 底下的 `AGENTS.md`,絕不替換或生成 `index.md`、`log.md` 等占位檔**。若目錄全新才初始化建立結構。

### 2. 專案本地層初始化
- 腳本已自動建立本地 `100_Todo` 和 `200_Reference` 目錄。

### 3. 驗證 Obsidian MCP 連線與讀寫
- 重啟 Claude Code 後,在對話中要求它透過 `obsidian` MCP 讀取二腦根目錄的 `AGENTS.md`,驗證連線暢通。

---

## 四、全域技能健檢與三方同步驗證 (必要步驟)

為確保 Claude Code 在第二台電腦上擁有完整無障礙的工作能力,設定完成後**必須執行依賴健檢與三方同步驗證**。可直接執行自動化健檢腳本:

```bash
bash 200_Reference/scripts/healthcheck.sh
```

該腳本全程唯讀,對應以下所有檢查項目:

### 1. 驗證步驟一已安裝之基礎服務連線狀態
- [ ] **chezmoi (#16)**:`chezmoi --version` 與 `chezmoi status`,確認三 Agent 入口與 bridge 已配置。
- [ ] **GitHub CLI (`gh`)**:`git --version`、`gh auth status`,確認登入正常且未受無效 `GITHUB_TOKEN` 污染。
- [ ] **Node.js & npm**:`node -v`、`npm -v`。
- [ ] **Claude Code CLI**:`claude --version`,並確認 `claude mcp list` 含 `obsidian`。
- [ ] **Obsidian MCP (`mcpvault`)**:Claude Code 能透過 `obsidian` MCP 讀寫二腦。
- [ ] **Google Drive 掛載與二腦對接**:確認 `codex_symlink` 與 `secondbrain` 已同步且可讀取。

### 2. 驗證與補充全域技能的進階依賴環境
- [ ] **Python Tools (#34) & uv**:`python3 --version`、`uv --version`;測試 `{{CODEX_HOME}}/python-tools/bin/python-tools-python -c "import pandas, docx, pptx, pdfplumber; print('ok')"`(供 `doc-to-md`, `audio-to-md`, `pdf` 使用)。
- [ ] **GPT Image Tool (生圖技能)**:Claude Code 調用 `image-generator` 進行一次低風險生圖測試(供 `image-generator`, `visual-note-generator`, `social-cards` 使用)。*需 Agent 觸發,healthcheck.sh 不自動測。*
- [ ] **Playwright 瀏覽器 (#01)**:確認無頭瀏覽器可用,缺失時 `npx playwright install`(供 `playwright`, `social-cards`, `website-to-hyperframes` 使用)。
- [ ] **PDF / Poppler (#01/#18)**:`pdftoppm -v` 與 `pdfplumber` 可用於 PDF 渲染與抽取。
- [ ] **Voice Reply (#37)**:`voice-reply` 與 Edge-TTS / macOS `say` 播放功能。
- [ ] **Voice Input Normalization (#36)**:語音輸入標點與專有名詞正規化規則。
- [ ] **FFmpeg**:`ffmpeg -version`(供 `hyperframes`, `video-processing-automation` 使用)。
- [ ] **yt-dlp (#31/#34)**:`yt-dlp --version`(供 `youtube-transcript-collector` 使用)。
- [ ] **Heptabase CLI (#02)**:`heptabase --version` 及 Local CLI Server 連線。
- [ ] **Netlify CLI / MCP (#28)**:`netlify --version`(供 `netlify-deploy` 使用)。
- [ ] **Firebase CLI (#08)**:`npx -y firebase-tools@latest --version`。
- [ ] **Kokoro / TTS 語音合成 (#26/#32)**:MPS/CUDA/CPU 運行正常(供 `hyperframes-media`, `voxcpm2-voice-cloner` 使用)。*需 Agent 觸發。*
- [ ] **個人 API 憑證安全 (#25)**:金鑰存放於 `{{SECRETS_DIR}}/`(如 `gemini_api_key`)且排除於 Git。

### 3. 三方相容性校驗(Codex／Claude／AntiGravity 共用)
- 複查「全域 Skill (`codex_symlink/skills`)」、「LazyPack 本手冊」與「Obsidian 駕駛艙」三者:
  - 確認三 Agent 都透過原生入口讀取 `codex_symlink/core-rules.md` 與 `codex_symlink/skills` 主版本。
  - Claude 專案規則使用只含 `@AGENTS.md` 的薄 `CLAUDE.md`,不複製第二份規則。
  - 全域入口由 Item 16 的 chezmoi bootstrap 建立;chezmoi 為必要安裝。
  - 確保三者核心內容與路徑 100% 同步一致。

### 4. 沙盒限制排除
- 遇到 Claude Code 沙盒寫入/讀取限制時,**立刻將該限制路徑新增到沙盒規則(如 `settings.json` 的 permissions 或 `writable_roots`)**。特別是 **PIP、NPM、Python 及其執行與工作路徑**(如 `~/.npm/`, `~/.cache/`, Python 與 Node.js 全域二進位路徑、環境資料夾與專案工作目錄)必須完整列為例外,確保指令與相依庫安裝無礙。

### 5. 疑難排解與參考資料
- 遇到環境、連線、模組或權限問題,可參考 GitHub 公開說明:
  - [GitHub Codex Installation - lazy-pack 目錄](https://github.com/icestone0128/codex_installation/tree/main/200_Reference/lazy-pack)
  - **注意**:Codex Installation LazyPack 使用 `{{佔位符}}` 系統(如 `{{CODEX_HOME}}`、`{{OBSIDIAN_VAULT}}`),需先參考其 `README.md` 替換為本機路徑。

- **Claude 步驟與 Codex LazyPack 編號對應表**:

  | Claude 步驟 | 對應 Codex LazyPack 編號 |
  |-----------------|------------------------|
  | 步驟一 §1 Node.js | #01 必裝 Skills 與 Plugins |
  | 步驟一 §2-3 Google Drive + Obsidian | #04 建立第二大腦 |
  | 步驟一 §4 Claude Code CLI | #01 必裝 |
  | 步驟一 §5 Obsidian MCP | #02 MCP Essentials |
  | 步驟一 §6 Git/GitHub | #03 連接 GitHub |
  | 步驟一 §7 Python/uv/chezmoi/Poppler | #16 chezmoi 跨裝置同步 + #34 Python Tools |
  | 步驟二 setup.sh 全域入口 / chezmoi | #16;專案生命週期另見 #10 |
  | 步驟三 二腦對接 | #04 + #05 第二大腦設定指南 |
  | 步驟四 健檢 | #01 + #02 + 各進階模組 (#11–#38) |

---

## 五、完成回報格式

```markdown
## Claude 懶人包設定完成

- GitHub:已登入 / 待登入 / 失敗
- Obsidian:已連接 / 待設定 / 失敗
- 全域 Symlinks 與載入 (arry-assistant, project-init-sync):已完成 / 失敗
- 基礎服務連線驗證:
  - chezmoi 狀態:[通過 / 失敗]
  - GitHub CLI (gh) 驗證:[通過 / 失敗]
  - Node.js & npm:[通過 / 失敗]
  - Claude Code CLI:[通過 / 失敗]
  - Obsidian MCP (mcpvault) 連線:[通過 / 失敗]
- 全域進階相依健檢:
  - Python Tools (#34) & uv:[通過 / 失敗]
  - GPT Image Tool (生圖驗證):[通過 / 失敗]
  - Playwright (瀏覽器 #01):[通過 / 失敗]
  - PDF & Poppler (#01/#18):[通過 / 失敗]
  - Voice Reply (#37):[通過 / 失敗]
  - Voice Normalization (#36):[通過 / 失敗]
  - FFmpeg (多媒體):[通過 / 失敗]
  - yt-dlp (YouTube #31/#34):[通過 / 失敗]
  - Heptabase CLI (#02):[通過 / 失敗]
  - Netlify CLI (#28):[通過 / 失敗]
  - Firebase CLI (#08):[通過 / 失敗]
  - Kokoro / TTS 音訊 (#26/#32):[通過 / 失敗]
  - API secrets 安全 (#25):[通過 / 失敗]
- 三 Agent 相容性(Codex／Claude／AntiGravity／路徑同步):已完成 / 失敗
- 規則檔:AGENTS.md 已建立 / 已更新 / 未建立
- Git 狀態:[乾淨 / 有未提交變更]
```

---

## 附錄:關鍵自動化與同步程式碼

為讓使用者在全新第二台電腦上快速部署,本節涵蓋 repo 運行所需的關鍵自動化程式原始碼。

### 附錄一:Obsidian MCP 註冊腳本 (`200_Reference/scripts/register_mcp.py`)
自動定位 `mcpvault`,依 `--agent` 分流(預設 Claude,可選 codex / antigravity)。Claude 版優先使用官方 `claude mcp add`,失敗則安全編輯 `~/.claude.json` 的 `mcpServers`,保留其他 MCP。完整原始碼見同名檔案。

### 附錄二:環境配置一鍵建置腳本 (`200_Reference/scripts/setup.sh`)
重用 Codex LazyPack Item 16 的 `cross-device-sync` bootstrap,安裝 chezmoi、預覽備份並建立三 Agent 原生入口;互動補全 Git 全域設定、將 Obsidian MCP 註冊到 Claude Code、安全配置 Gemini Secrets、對二腦防覆寫對接、初始化本地層並執行健檢。完整原始碼見同名檔案。

### 附錄三:全域技能環境健檢腳本 (`200_Reference/scripts/healthcheck.sh`)
全唯讀健檢,涵蓋第四章所有可自動測試項目(基礎服務、Python Tools、媒體、PDF/Poppler、部署 CLI、TTS、Playwright、API secrets、三 Agent 入口 symlink),並列出需 Agent 觸發的生圖與 TTS 模型項目。完整原始碼見同名檔案。
