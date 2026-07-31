---
title: Coding Standards
source: 借鏡 ECC (Everything Claude Code) coding-standards skill，轉化為通用版本
updated: 2026-06-26
status: active
applies_to: 所有開發類技能、新專案
---

# Coding Standards（程式碼品質守則）

本文件定義跨語言、跨專案的通用程式碼品質原則，供 AI Agent 在產生和審查程式碼時遵循。

---

## 1. 四大核心原則

### Readability First（可讀性優先）

程式碼首先是寫給人看的，其次才是給機器執行的。

- 選擇清楚的變數名稱，即使稍長也無妨
- 複雜邏輯加上簡短註解說明「為什麼」，而非「做什麼」
- 保持一致的程式碼風格（縮排、括號、空行）

### KISS（保持簡單）

> Keep It Simple, Stupid

- 優先選擇最直觀的解法
- 避免過度工程化（over-engineering）
- 如果一個函式需要超過 3 層巢狀，考慮拆分

### DRY（不重複）

> Don't Repeat Yourself

- 重複出現 2 次以上的邏輯，提取為共用函式或模組
- 但不要過度抽象——如果兩段程式碼只是表面相似但語義不同，保持獨立

### YAGNI（不要預先實作）

> You Aren't Gonna Need It

- 不要為「可能以後會用到」的功能寫程式碼
- 先滿足當前需求，需要時再擴充
- 避免建立不必要的抽象層

### 最小且清楚的變更

- 實作前先依 `agent-execution-strategy.md` 的最小解法決策梯，檢查能否不新增、重用既有能力或使用標準／平台原生功能
- 最短程式碼不是目標；目標是正確、安全、清楚、可維護的最小差異
- Bug 修復先搜尋所有 caller 與 sibling path，優先修正共同根因，不為每個症狀分別加補丁

---

## 2. 命名慣例

### 變數命名

| 原則 | 反模式 ❌ | 正確做法 ✅ |
|------|---------|-----------|
| 描述性 | `d`, `tmp`, `x` | `daysUntilExpiry`, `tempFilePath`, `userCount` |
| 意圖揭示 | `q` | `marketSearchQuery` |
| 布林值 | `flag`, `status` | `isActive`, `hasPermission`, `shouldRetry` |
| 集合 | `list`, `data` | `activeUsers`, `pendingOrders` |

### 函式命名

使用 **verb-noun** 模式：

```
fetchMarketData(marketId)    ✅
calculateTotalPrice(items)   ✅
validateUserInput(form)      ✅
sendNotification(userId)     ✅

data(id)                     ❌ 模糊
process(x)                   ❌ 太通用
doStuff()                    ❌ 無意義
```

### 常數命名

```
MAX_RETRY_COUNT = 3          ✅ SCREAMING_SNAKE_CASE
API_BASE_URL = "..."         ✅
maxRetry = 3                 ❌ 看起來像變數
```

---

## 3. 函式設計原則

### 單一職責

一個函式只做一件事：

```javascript
// ❌ 做太多事
async function processOrder(order) {
  validateOrder(order);
  calculateTax(order);
  chargePayment(order);
  sendConfirmation(order);
  updateInventory(order);
}

// ✅ 拆分為獨立步驟
async function processOrder(order) {
  const validated = await validateOrder(order);
  const withTax = calculateTax(validated);
  await chargePayment(withTax);
  await Promise.all([
    sendConfirmation(withTax),
    updateInventory(withTax),
  ]);
}
```

### 參數數量

- 理想：0-2 個參數
- 可接受：3 個參數
- 超過 3 個：使用物件參數（options object）

```javascript
// ❌ 參數太多
function createUser(name, email, age, role, department, isActive) { ... }

// ✅ 使用物件參數
function createUser({ name, email, age, role, department, isActive }) { ... }
```

### 提早返回（Early Return）

```javascript
// ❌ 深層巢狀
function getDiscount(user) {
  if (user) {
    if (user.isPremium) {
      if (user.yearsActive > 5) {
        return 0.3;
      } else {
        return 0.1;
      }
    } else {
      return 0;
    }
  }
  return 0;
}

// ✅ 提早返回
function getDiscount(user) {
  if (!user) return 0;
  if (!user.isPremium) return 0;
  if (user.yearsActive > 5) return 0.3;
  return 0.1;
}
```

---

## 4. 錯誤處理

### 原則

- 使用 try/catch 包裝可能失敗的非同步操作
- 不吞掉錯誤（catch 裡面至少要 log）
- 提供有意義的錯誤訊息
- 使用自訂錯誤類別區分錯誤類型

```javascript
// ❌ 吞掉錯誤
try { await fetchData(); } catch (e) { }

// ✅ 妥善處理
try {
  await fetchData();
} catch (error) {
  logger.error('Failed to fetch data', { error: error.message });
  throw new DataFetchError('Unable to retrieve data', { cause: error });
}
```

---

## 5. 使用時機

本文件為**可選參考模板**，在以下情境自動生效：

- 開發類技能（firebase, netlify, tool-integration 等）產生程式碼時
- `project-init-sync` 初始化新專案時，作為 `200_Reference/templates/` 的參考文件
- Code Review 子代理審查程式碼時

---

## 與其他知識文件的關係

- **agent-execution-strategy.md** 定義任務生命週期、最小解法決策梯與根因修正順序
- **verification-checklist.md** Phase 3（Lint）與 Phase 6（複雜度）檢查是否符合本文件
- **subagent-strategy.md** Code Reviewer 角色使用本文件作為審查基準
- **security-review-checklist.md** 處理安全層面的程式碼規範
