---
title: Advanced Memory Learning
updated: 2026-06-25
source: 借鏡 ECC continuous-learning-v2 instinct model + dynamic system prompt injection
status: active
applies_to: 長對話、shutdown-sync、跨專案記憶策展與高頻模式升級
---

# 進階記憶與學習策略

> 本文件記錄從 ECC 借鏡的進階記憶管理概念：Instinct 信心分數模型、動態 Context 切換模式。這些是概念級的參考，可在需要時進一步實作。

## 一、Instinct 信心分數模型

### 概念

將學到的行為模式分解為原子化的「本能」（instinct），每個本能都有：

| 屬性 | 說明 |
|------|------|
| **Trigger（觸發）** | 在什麼情況下觸發？ |
| **Action（行動）** | 該做什麼？ |
| **Confidence（信心分數）** | 0.3（試探性）→ 0.9（幾乎確定） |
| **Domain（領域）** | code-style、testing、git、debugging、workflow 等 |
| **Evidence（證據）** | 是從哪些觀察中學到的？ |
| **Scope（範圍）** | 專案級 or 全域 |

### 範例

```yaml
id: prefer-obsidian-append-not-overwrite
trigger: "修改 Obsidian vault 中的既有筆記時"
action: "預設採取補缺與追加，不覆寫既有筆記結構"
confidence: 0.9
domain: "knowledge-management"
scope: global
evidence:
  - 使用者在多個專案中反覆強調不覆寫
  - 已記錄在 core-rules.md
```

```yaml
id: check-git-status-before-commit
trigger: "準備 git commit 時"
action: "先跑 git status 確認 staged 檔案，不自動納入無關變更"
confidence: 0.85
domain: "git"
scope: global
evidence:
  - shutdown-sync skill 明確規定
  - 使用者多次糾正自動 commit 行為
```

### Arry 架構的對應

| ECC 概念 | Arry 現有對應 | 狀態 |
|---------|-------------|------|
| Instinct 儲存 | `memories/MEMORY.md` 的 User preferences 段落 | ✅ 已有，但未結構化為 instinct |
| 專案級 instinct | 各專案 `000_Agent/` 的本地記憶 | ✅ 概念已有 |
| 全域 instinct | `memories/MEMORY.md` + `core-rules.md` | ✅ 概念已有 |
| 信心分數 | ❌ 未實作 | 💡 可在記憶筆記中加入 |
| 自動擷取 | ❌ 未實作 | 💡 可在收工流程中半自動觸發 |

### 半自動實作建議

不需要完整的自動擷取系統，可以在收工（shutdown-sync）流程中加入一個可選步驟：

> **「本次 session 有沒有什麼新發現值得記住？」**
>
> 如果有，用以下格式記錄到 `memories/extensions/ad_hoc/notes/`：
> - 觸發情況
> - 學到的模式
> - 信心程度（高/中/低）
> - 適用範圍（全域/專案）

當同一個模式在 2+ 個專案中出現時，考慮升級到 `memories/MEMORY.md` 或 `core-rules.md`。

---

## 二、動態 Context 切換模式

### ECC 的做法

ECC 使用 CLI 別名在啟動時注入不同的 system prompt：

```bash
# 開發模式
alias claude-dev='claude --system-prompt "$(cat ~/.claude/contexts/dev.md)"'

# PR 審查模式
alias claude-review='claude --system-prompt "$(cat ~/.claude/contexts/review.md)"'

# 研究模式
alias claude-research='claude --system-prompt "$(cat ~/.claude/contexts/research.md)"'
```

### AntiGravity 的對應

AntiGravity 已有更優雅的機制：

| ECC 做法 | AntiGravity 對應 | 效果 |
|---------|----------------|------|
| CLI 別名注入 system prompt | **Skill 觸發機制** | AntiGravity 根據任務自動載入相關 skill |
| 手動切換 context 檔 | **AGENTS.md + 全域規則** | 專案規則自動載入 |
| 不同模式的 context 檔 | **startup-sync / shutdown-sync** | 開收工自動切換工作模式 |

### 可借鏡的概念

雖然 AntiGravity 的 skill 觸發已經覆蓋了大部分需求，但以下概念仍有參考價值：

1. **明確的工作模式意識**：開始工作前，先聲明「現在是開發模式」或「現在是研究模式」，讓 AI 調整行為
2. **模式轉換提示**：從開發切換到文件整理時，可以說「現在切換到筆記整理模式」來重新校準 AI 的工具使用偏好
3. **精簡 context 載入**：不是所有 skill 和知識文件都需要每次載入，AntiGravity 的按需觸發已經做到這點

---

## 三、記憶持久化策略比較

| 時機 | ECC 做法（Hook） | Arry 做法（Skill + 規則） |
|------|----------------|------------------------|
| Session 開始 | SessionStart Hook 載入上次 context | startup-sync 讀取 AGENTS.md + Obsidian 駕駛艙 |
| 壓縮前 | PreCompact Hook 保存重要狀態 | 手動確認重要決策已記錄到文件 |
| Session 結束 | Stop Hook 自動持久化學習 | shutdown-sync 更新 Obsidian + 可選記憶寫入 |
| 跨 session | 自動載入上次 .tmp 檔 | MEMORY.md + ad_hoc notes |

### Arry 的優勢

- **雙層記憶**：全域 `codex_symlink/memories/` + 專案本地 `000_Agent/`
- **Obsidian 備份**：`sync_backup.py` 定期同步到 Obsidian
- **人工策展**：使用者主動決定什麼值得記住，而非全自動擷取

### 可改進之處

- 收工時增加「本次 session 學到什麼？」的提示（半自動）
- 壓縮前確認重要決策不只存在 context 中（已記錄在 `context-management-strategy.md`）
- 定期回顧 ad_hoc notes，將高頻模式升級到 MEMORY.md
