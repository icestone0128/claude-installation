---
title: Parallelization Strategy
updated: 2026-06-25
source: 借鏡 ECC parallelization 策略 + Git worktree 概念
status: active
applies_to: 可拆成獨立子任務、背景命令或隔離工作區的複雜任務
---

# 平行處理策略

> 當任務可以拆分為獨立的子任務時，善用平行處理可以大幅提升效率。本文件記錄在 AntiGravity / Codex 環境下的平行處理策略。

## 何時需要平行處理？

### ✅ 適合平行的情況

| 情況 | 平行方式 |
|------|---------|
| 多個獨立的研究任務 | 啟動多個 `research` 子代理 |
| 前端 + 後端同時開發 | 使用 `self` 子代理做獨立工作區 |
| 多檔案的批次修改（互不相依） | 定義多個子代理各自處理 |
| 長時間運行的命令（build、deploy） | 背景任務 + 繼續做其他事 |
| 需要對比多個方案 | 各方案在獨立子代理中探索 |

### ❌ 不適合平行的情況

| 情況 | 為什麼 |
|------|-------|
| 任務之間有先後相依 | A 的產出是 B 的輸入 |
| 修改同一個檔案的不同部分 | 合併衝突風險 |
| 需要頻繁同步決策 | 溝通開銷大於平行收益 |

---

## AntiGravity 的平行工具

### 1. 子代理平行

```
主代理
├── research agent A：研究 API 文件
├── research agent B：掃描程式碼庫
└── research agent C：搜尋相關範例
     ↓
三個結果同時回報，主代理彙整
```

**使用 `invoke_subagent` 一次啟動多個子代理：**
- 每個子代理有獨立的 context，不會互相干擾
- 使用 `Workspace: "branch"` 為寫入型任務建立隔離工作區

### 2. 背景任務平行

- 用 `run_command` 啟動長時間命令，設定 `WaitMsBeforeAsync` 讓它進入背景
- 繼續做其他工作，命令完成時會自動通知
- 使用 `manage_task` 檢查狀態或發送輸入

### 3. Git Worktree（進階）

> 來自 ECC 的概念。適用於需要在同一 repo 的不同 branch 上同時工作的場景。

```bash
# 建立 worktree，在不同目錄操作不同 branch
git worktree add ../feature-branch feature/new-auth
git worktree add ../bugfix-branch bugfix/login-error

# 工作完成後清理
git worktree remove ../feature-branch
```

**使用場景：**
- 同時修 bug 和開發新功能
- 在不切換 branch 的情況下比較不同版本
- 讓多個子代理在不同 worktree 上並行工作

---

## 平行任務的協調原則

### 1. 拆分原則

- **垂直拆分**（按功能）：前端/後端、模組 A/模組 B
- **水平拆分**（按步驟）：研究/實作/測試（但有先後順序）
- **最小相依**：拆分後的子任務之間盡量沒有相依

### 2. 合併策略

- 子代理完成後，主代理負責彙整和解衝突
- 有寫入的平行任務，確認不修改同一檔案
- 合併前跑一次驗證迴圈（參見 `verification-checklist.md`）

### 3. 何時停止平行

- 當子任務之間開始需要頻繁同步 → 改回序列
- 當合併衝突頻繁出現 → 重新拆分邊界
- 當整體複雜度超過平行帶來的效益 → 簡化

---

## 實務建議

- **簡單任務不平行**：啟動子代理有開銷，2 分鐘能做完的就直接做
- **先規劃再平行**：用 brainstorm 釐清任務邊界後再拆分
- **明確回報格式**：每個子代理的 prompt 都要說明期望的回報格式
- **設定提醒**：平行任務啟動後，用 `schedule` 設定提醒以免忘記檢查結果
