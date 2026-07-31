---
title: Context Management Strategy
updated: 2026-06-25
source: 借鏡 ECC (Everything Claude Code) 知識架構，轉化為 AntiGravity / Codex 適用版本
status: active
applies_to: 長對話、工具選型、MCP 管理、研究轉實作與工作模式切換
---

# Context Window 管理策略

> AI agent 的上下文窗口（context window）是有限資源。管理不善會導致回應品質下降、token 浪費、長 session 無法維持。本文件記錄經過驗證的管理策略。

## MCP 精選管理原則

### 經驗法則

- **設定中可保留 20-30 個 MCP**（供需要時啟用）
- **日常只啟用 10 個以下**
- **Tools 總數保持 80 個以下**
- 每個 MCP 啟用都會佔用 context window，即使你沒有使用它

### 目前啟用狀態

| MCP 名稱 | 狀態 | 用途 |
|----------|------|------|
| firebase | 啟用 | Firebase 專案操作 |
| notebooklm | 啟用 | NotebookLM 筆記本管理 |
| obsidian | 啟用 | Obsidian vault 讀寫 |

> ✅ 目前 3 個 MCP 已是精簡狀態，表現良好。新增 MCP 前應評估 context 成本。

### 新增 MCP 前的檢查清單

1. **是否有 CLI 替代？** — 如果工具有 CLI（如 `gh`、`firebase`、`netlify`），優先用 CLI + skill 包裝，不用 MCP
2. **使用頻率如何？** — 偶爾才用的工具，用完即停用
3. **暴露的 tools 有多少？** — tools 數量越多，context 佔用越大
4. **是否可以只在特定專案啟用？** — 避免全域啟用偶爾使用的 MCP

### CLI vs MCP 取捨決策

| 因素 | 選 CLI | 選 MCP |
|------|--------|--------|
| Context 成本 | 低（按需呼叫） | 高（常駐佔用） |
| 操作複雜度 | 需要記住指令 | AI 自動選擇 |
| Token 使用 | 較省 | 較耗 |
| 適合場景 | 成熟 CLI、操作固定 | 需要靈活探索、多步驟互動 |

**實例：**
- ✅ `gh` CLI 替代 GitHub MCP → 用 skill 包裝 `gh pr create`、`gh issue list`
- ✅ `firebase` CLI 替代部分 Firebase MCP → 用 `npx firebase deploy` 替代
- ❌ Obsidian MCP 不宜替代 → vault 互動需要靈活讀寫

---

## 策略性上下文壓縮

### 為什麼不依賴自動壓縮？

自動壓縮（auto-compact）在 token 超量時觸發，但：

- 可能在任務中途觸發，遺失重要上下文
- 不考慮邏輯任務邊界
- 可能中斷多步驟操作

### 最佳壓縮時機

在以下**邏輯斷點**主動請求壓縮效果最好：

1. **探索完成，開始執行** — 研究和規劃的 context 已經不需要了，保留結論和計畫即可
2. **里程碑完成** — 一個功能或任務完成後，清理已完成的探索 context
3. **切換任務** — 從 A 任務轉到 B 任務前，清除 A 的細節 context
4. **session 品質下降** — 回應變慢、變不精準時，通常是 context 壓力的信號

### 實務建議

- **長 session（超過 1 小時）** — 至少在 2-3 個邏輯斷點做一次壓縮
- **多階段任務（研究 → 規劃 → 實作 → 測試）** — 每個階段轉換時考慮壓縮
- **壓縮前** — 確認重要決策和結論已記錄在文件中（而不只存在 context 裡）

---

## 工作模式與 Context 配置

### 依工作模式調整啟用的工具

| 工作模式 | 需要的 MCP | 可停用的 |
|---------|-----------|---------|
| 開發 coding | firebase（按需）| notebooklm |
| 筆記整理 | obsidian | firebase |
| NotebookLM 操作 | notebooklm | firebase |
| 一般對話 | 無 MCP | 全部可停用 |

### Session 品質信號

出現以下情況時，考慮壓縮或開新 session：

- AI 開始重複已回答過的問題
- 回應變得冗長但不精確
- AI 忘記 session 早期的決策
- 工具呼叫變慢或頻繁失敗

---

## 定期檢視

- **每月一次**：檢視啟用中的 MCP 數量，停用近期未使用的
- **新增工具時**：先評估 CLI vs MCP，記錄決策到 `tool-list.md`
- **長 session 後**：回顧壓縮時機是否恰當，持續優化
