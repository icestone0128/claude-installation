# claude_installation - AGENTS.md

## 專案入口

專案名稱：claude_installation
專案用途：Claude 版懶人包 — 服務連接與工作流程設定的公開安裝專案
主要工作目錄：{{CLAUDE_SETUP_REPO}}
GitHub repo：https://github.com/icestone0128/claude-installation
預設 branch：main

## Obsidian 對應筆記

Obsidian vault：{{OBSIDIAN_VAULT}}
專案駕駛艙：{{OBSIDIAN_PROJECTS}}/claude_installation/專案工作流程.md

## 部署狀態

- GitHub Pages：未啟用
- Firebase：未使用
- Netlify：未使用
- 部署目標：無（純文件／安裝包專案）

## 工作規則

- 回應使用繁體中文。
- 涉及檔案操作時回報完整產出位置。
- 使用 zsh 語法。
- 開工時讀本檔、讀 `HANDOFF.md`、讀 Obsidian 駕駛艙、檢查 Git 狀態。
- 收工時更新 Obsidian 駕駛艙與 `HANDOFF.md`，必要時更新本檔，檢查 diff 後只提交相關檔案。
- 不把每日流水帳寫進本檔。

## 開工 / 收工 / 新專案

- **開工**：讀本檔、`HANDOFF.md`、Obsidian 駕駛艙與 Git 狀態，再由當前 Agent 的全域 `startup-sync` 執行共用 chezmoi checkpoint：
  `cross-device-sync/scripts/session-sync-checkpoint.sh --phase startup --sync-root <SYNC_ROOT> --update`；不自動 pull、commit、push 或部署。
- **收工**：建立或更新大寫 `HANDOFF.md`（只保留 Current state、Next action、Blockers、Last verified），更新 Obsidian 駕駛艙，再執行共用 checkpoint：
  `cross-device-sync/scripts/session-sync-checkpoint.sh --phase shutdown --sync-root <SYNC_ROOT>`。
- **新專案初始化**：套用全域 `project-init-sync`（LazyPack Item 10）標準。

## 工具路徑解析

AI Agent（Codex / Claude / AntiGravity）呼叫 CLI 工具時，優先使用以下路徑：

- `{{CODEX_HOME}}/python-tools/bin/`：三 Agent 共用的 Python 工具（教學檔案處理等）。
- `~/.local/share/agent-tools/python-tools/bin/`：中立入口 bridge。
- `{{LOCAL_BIN}}/`：使用者本地工具。

這些路徑使用 `~/` 相對表示法，可攜且跨使用者通用。

## Arry 助手雙層資料層

- **全域核心層**：Google Drive `codex_symlink`（`core-rules.md`、`skills/`、`memories/`、`knowledge/`、`workflows/`），三 Agent 以原生入口共用同一份主版本。
- **專案本地層**：本專案 `100_Todo/`、`200_Reference/`；需要專案專屬技能或記憶時才建立 `000_Agent/skills/`、`000_Agent/memories/`。
- **Obsidian 知識/駕駛艙層**：`專案庫/claude_installation/專案工作流程.md`。
- Arry 助手 Obsidian 同步範圍：`knowledge/` 完整同步；`memories/` 只同步根目錄第一層檔案，不同步 memories 子資料夾。

## 三 Agent 共用專案契約

- Codex、Claude 與 AntiGravity 共用本檔 `AGENTS.md` 作為唯一專案規則主版本；根目錄 `CLAUDE.md` 只保留 `@AGENTS.md` 引用，不複製第二份規則。
- 三個 Agent 共用相同專案腳本、輸入輸出契約、安全邊界與驗證標準；若 runtime 真有差異，只在同一入口以 `--agent auto|codex|claude|antigravity` 或等價參數分流。
- 當前環境沒有某 Agent 的原生 CLI 時，應明確回報未安裝並保留可重跑步驟，不得排除該 Agent 或偽稱已執行。

## 不要做

- 不要 commit API key、token、密碼、Firebase Admin 憑證、OAuth secret。
- 不要 commit 個人記憶、私密草稿或個人流水帳。
- 不要自動納入無關 git 變更。
- 不要在 repo 內存放不必要的個人或敏感資料。
