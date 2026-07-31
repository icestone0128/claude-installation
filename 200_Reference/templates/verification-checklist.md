---
title: Verification Checklist
updated: 2026-06-25
source: 借鏡 ECC (Everything Claude Code) verification-loop + eval-harness，轉化為通用版本
status: active
applies_to: 功能開發、bug 修復、重構、部署、PR 與重大文件或規則變更
---

# 驗證迴圈清單

> 完成功能開發、重構或重大變更後，依序跑過以下檢查再收工或提 PR。不需要每次全跑——依變更規模選擇適用的階段。

## 驗證階段

### Phase 1：Build 驗證

確認專案可以正常建置。

```bash
# JavaScript / TypeScript
npm run build 2>&1 | tail -20

# Python
python -m py_compile main.py

# 靜態網站
# 確認 HTML 檔案可正常開啟
```

> ⛔ 如果 build 失敗，先修再繼續。

### Phase 2：Type Check（如適用）

```bash
# TypeScript
npx tsc --noEmit 2>&1 | head -30

# Python
pyright . 2>&1 | head -30
# 或
mypy . 2>&1 | head -30
```

### Phase 3：Lint Check（如適用）

```bash
# JavaScript / TypeScript
npm run lint 2>&1 | head -30

# Python
ruff check . 2>&1 | head -30
```

### Phase 4：Test Suite（如適用）

```bash
# 跑測試並看覆蓋率
npm run test -- --coverage 2>&1 | tail -50

# Python
pytest --cov . 2>&1 | tail -50
```

**報告格式：**
- 總測試數：X
- 通過：X
- 失敗：X
- 覆蓋率：X%（目標 80%）

### Phase 5：安全與敏感資料檢查

```bash
# 確認沒有 commit API key、密碼等
git diff --cached | grep -iE "(api_key|password|secret|token)" || echo "✅ 無敏感資料"

# 確認 .gitignore 有效
git status --porcelain | head -20
```

**深度安全審查**（適用於 API 端點、認證邏輯、使用者輸入處理等變更）：
- 參考 `knowledge/security-review-checklist.md` 進行完整的注入防護、輸入驗證、錯誤脫敏審查
- 參考 `knowledge/prompt-defense-baseline.md` 確認 AI Agent 層面的安全防線

### Phase 6：範圍與複雜度檢查

在正確性與安全檢查通過後，依 `agent-execution-strategy.md` 檢查本次變更：

- 沒有新增可避免的 dependency、抽象層、wrapper、設定或檔案
- 沒有重做專案內、標準函式庫或平台已提供的能力
- 沒有未使用的 reference、變數、dead code 或只服務單一實作的預留層
- 縮小 diff 不會犧牲可讀性、正確性、安全性、測試或使用者明確需求

---

## 品質門檻

### 收工前必查（每次）

- [ ] Git 狀態乾淨或只有預期的未提交變更
- [ ] 沒有未儲存的重要決策只存在 context 裡（應記錄到文件）
- [ ] 沒有 API key、密碼、token 在 staged 檔案中
- [ ] 相關的 AGENTS.md / 專案駕駛艙已更新（如有固定規則變更）

### PR 前必查（提交功能時）

- [ ] Phase 1 Build 通過
- [ ] Phase 2 Type Check 通過（如適用）
- [ ] Phase 3 Lint 通過（如適用）
- [ ] Phase 4 Test 通過，覆蓋率符合目標（如適用）
- [ ] Phase 5 安全檢查通過
- [ ] Phase 6 範圍與複雜度檢查通過
- [ ] Commit message 清晰描述變更
- [ ] 只 commit 相關檔案，不納入無關變更

### 重構後必查

- [ ] 所有原有功能仍正常運作
- [ ] 沒有引入新的 type error 或 lint warning
- [ ] 相關文件（README、AGENTS.md）已同步更新

---

## 依變更規模選擇

| 變更規模 | 建議跑的階段 |
|---------|------------|
| 文件修改（README、AGENTS.md） | 收工必查 |
| 小型 bug 修復 | Phase 1 + Phase 6 + 收工必查 |
| 新功能開發 | Phase 1-4 + Phase 6 + PR 必查 |
| 重大重構 | Phase 1-6 + 重構必查 |
| 安全相關變更 | Phase 1-6（全跑） |

---

## Eval-Driven Development（進階概念）

> 來自 ECC 的 Eval Harness 概念。適用於需要高可靠度的 AI 輔助開發場景。

### 核心理念

把 eval 當成「AI 開發的 unit test」——在實作前定義預期行為。

### 三種評估器

1. **Code-Based（確定性）** — 用 grep、test、build 指令驗證
2. **Model-Based（AI 評估）** — 讓 AI 評估開放式輸出的品質
3. **Human（人工審查）** — 標記需要人工確認的高風險變更

### 可靠度指標（參考用）

- **pass@1**：第一次嘗試成功率
- **pass@3**：3 次嘗試中至少 1 次成功
- **pass^3**：3 次嘗試全部成功（高可靠度要求）

> 💡 這些指標在一般專案中不需要精確追蹤，但有助於理解「AI 輔助開發的可靠度」概念。
