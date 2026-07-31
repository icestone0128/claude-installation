---
title: Security Review Checklist
source: 借鏡 ECC (Everything Claude Code) security-review skill + security-reviewer agent，轉化為通用版本
updated: 2026-06-26
status: active
applies_to: 開發類技能、部署流程、PR 審查
---

# Security Review Checklist（安全審查清單）

本文件提供深度安全審查的具體檢查項目，與 `verification-checklist.md` Phase 5 交叉引用使用。

---

## 1. Secrets 管理

### 反模式（❌ 不要這樣做）

```javascript
// 硬編碼 API key
const API_KEY = "sk-abc123def456";
const DB_URL = "postgres://admin:password@db.example.com:5432/mydb";
```

### 正確做法（✅）

```javascript
// 使用環境變數
const API_KEY = process.env.API_KEY;
// 或使用本機 secrets 目錄
// ~/.codex/secrets/api_key (權限 600)
```

### 檢查清單

- [ ] 程式碼中無硬編碼的 API keys、tokens、passwords
- [ ] `.env` 檔案已加入 `.gitignore`
- [ ] 敏感變數使用環境變數或 secrets 目錄載入
- [ ] CI/CD pipeline 中的 secrets 使用 GitHub Secrets 或等效機制
- [ ] 舊的、已洩漏的 key 已撤銷並更換

---

## 2. 注入防護（Injection Prevention）

### 2.1 SQL Injection

**反模式** ❌：
```javascript
const query = `SELECT * FROM users WHERE id = '${userId}'`;
```

**正確做法** ✅：
```javascript
// Parameterized queries
const query = 'SELECT * FROM users WHERE id = $1';
const result = await db.query(query, [userId]);

// 或使用 ORM
const user = await prisma.user.findUnique({ where: { id: userId } });
```

### 2.2 XSS (Cross-Site Scripting)

- [ ] 使用者輸入在渲染前進行 sanitization
- [ ] 使用框架的自動 escaping（React JSX、Vue template）
- [ ] 避免 `dangerouslySetInnerHTML` / `v-html`，除非內容已清潔
- [ ] Content Security Policy (CSP) header 已設定

### 2.3 Command Injection

**反模式** ❌：
```javascript
exec(`git log --author="${userInput}"`);
```

**正確做法** ✅：
```javascript
execFile('git', ['log', `--author=${userInput}`]);
```

---

## 3. 輸入驗證（Input Validation）

### Schema Validation 框架

```typescript
import { z } from 'zod';

const UserInput = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
  name: z.string().min(1).max(100).trim(),
});

// 驗證
const result = UserInput.safeParse(rawInput);
if (!result.success) {
  return { error: result.error.flatten() };
}
```

### 檢查清單

- [ ] 所有 API 端點的輸入使用 schema validation
- [ ] 數值型欄位有合理的最小/最大值限制
- [ ] 字串型欄位有長度限制
- [ ] 列舉型欄位使用白名單驗證

---

## 4. 檔案上傳限制

| 檢查項目 | 建議值 |
|---------|--------|
| 檔案大小上限 | 依用途設定（一般 5-10MB） |
| 允許的 MIME 類型 | 白名單制（如 `image/jpeg`, `image/png`, `application/pdf`） |
| 副檔名驗證 | 白名單制（驗證 MIME + 副檔名一致） |
| 儲存路徑 | 不使用使用者提供的檔名；重新命名為 UUID |
| 防毒掃描 | 大型應用應加入 virus scan |

---

## 5. 錯誤處理脫敏

### 反模式 ❌：

```javascript
app.use((err, req, res, next) => {
  res.status(500).json({
    error: err.message,
    stack: err.stack,          // ❌ 暴露 stack trace
    query: req.query,          // ❌ 暴露請求參數
    dbConnection: process.env.DB_URL  // ❌ 暴露連線資訊
  });
});
```

### 正確做法 ✅：

```javascript
app.use((err, req, res, next) => {
  // 詳細錯誤只記錄到 server log
  logger.error('Request error', {
    error: err.message,
    stack: err.stack,
    requestId: req.id
  });

  // 回傳通用錯誤訊息
  res.status(500).json({
    error: '操作失敗，請重試',
    requestId: req.id  // 供使用者回報時追蹤
  });
});
```

---

## 6. CSRF 防護

- [ ] 狀態變更操作（POST/PUT/DELETE）使用 CSRF token
- [ ] Cookie 設定 `SameSite=Strict` 或 `SameSite=Lax`
- [ ] 跨來源請求使用 CORS 白名單（非 `*`）

---

## 7. 認證與授權

- [ ] 密碼使用 bcrypt/argon2 雜湊，不使用 MD5/SHA1
- [ ] JWT token 設定合理的過期時間
- [ ] API 端點有適當的權限檢查（不只靠前端隱藏按鈕）
- [ ] 敏感操作需要重新驗證身份

---

## 8. 使用時機

| 情境 | 是否觸發本清單 |
|------|-------------|
| 新增 API 端點 | ✅ |
| 處理使用者輸入 | ✅ |
| 部署到生產環境 | ✅ |
| 修改認證/授權邏輯 | ✅ |
| 純 UI 樣式調整 | ❌ |
| 文件更新 | ❌ |
| 內部工具腳本 | ⚠️ 視情況（是否處理敏感資料） |

---

## 與其他知識文件的關係

- **verification-checklist.md** Phase 5（Safety）引用本文件進行深度安全掃描
- **prompt-defense-baseline.md** 處理 AI Agent 層面的安全防線
- **subagent-strategy.md** 中的 Security Reviewer 角色模板使用本清單
