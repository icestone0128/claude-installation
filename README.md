# Claude 懶人包 (claude_installation)

Claude 版懶人包 — 讓使用者在新電腦上，快速且安全地連接 Claude Code 全域設定、GitHub、Obsidian 第二大腦，並建立「開工 / 收工 / 新專案初始化」跨 Agent 工作流程。

本 repo 與 `codex_installation`、`antigravity-installation` 為同一組跨 Agent 安裝包，三者共用同一份 `codex_symlink` 規則與技能主版本。

## 專案結構

- 治理檔：`AGENTS.md`（跨 Agent 專案規則主版本）、`CLAUDE.md`（`@AGENTS.md` 薄轉接）、`HANDOFF.md`（跨 Agent 交接）
- `100_Todo/`：任務管理（`drafts/`、`projects/`、`archive/`）
- `200_Reference/`：安裝參考、腳本、範本與文件
  - `templates/`：預設策略範本（context 管理、驗證、子代理、平行化、記憶學習、prompt 防護、安全審查、程式碼標準）
  - `scripts/`、`docs/`、`writing-samples/`、`past-work/`

## 使用方式

- **方式一：直接叫 AI 協助安裝與設定（推薦）**
  把 repo 網址貼給你的 AI Agent（Codex / Claude / AntiGravity），請它讀取內容並依安裝入口引導完成服務連接與工作流程設定。

- **方式二：手動開啟設定檔**
  依 `200_Reference/` 內的安裝參考文件逐步完成環境檢查、登入與 MCP 設定。

## 安全規則

- 嚴禁將 GitHub token、API key、密碼寫進 Markdown、`AGENTS.md`、Obsidian 對外筆記或 commit。
- commit 前務必先檢查 diff，嚴禁自動無差別提交。
