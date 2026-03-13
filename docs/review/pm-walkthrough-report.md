# PM 走查报告：用户生命周期全链路点击行为验证

> **日期**: 2026-03-12
> **走查方式**: 按新用户从首次打开 App 到日常交易的完整生命周期，逐页验证跳转链接、状态传递、边界条件
> **原型版本**: v1.4 (含 PM profile.html 精简)
> **走查结论**: 发现 **5 项 P1 功能缺陷** + **3 项 P2 体验问题**，需修复后方可进入开发

---

## 走查路径

```
login.html → [注册] → kyc.html (Step 1-7 → 审核) → [通过]
     ↓                                                    ↓
[游客模式]                                          funding.html (首次入金)
     ↓                                                    ↓
market.html → search.html → stock-detail.html → trade.html → orders.html
                                                              ↓
                                                        portfolio.html → profile.html → settings.html
```

---

## 走查结果

### 通过项

| 阶段 | 验证内容 | 结果 |
|------|---------|------|
| 登录 | Landing → OTP 登录 → 路由选择 (新用户/审核中/已通过) | ✅ |
| 注册 | Landing → "注册新账户" → OTP (注册模式) → kyc.html | ✅ |
| KYC | Step 1-7 流转、`?status=review` 路由、`?resume=1` 断点续传 | ✅ |
| KYC 结果 | 审核通过→入金引导、需补材料→重新上传、审核拒绝→原因说明 | ✅ |
| 行情 | 股票列表→个股详情、Tab 切换、港股"即将上线"、搜索入口 | ✅ |
| 游客延迟 | 延迟 Banner、价格延迟徽标、交易按钮替换为登录引导 | ✅ |
| 交易 | 买入/卖出主题切换、订单类型、滑动确认→Face ID 弹窗→成功页→自动跳订单 | ✅ |
| 订单 | 订单详情时间轴、撤单确认 Sheet、Tab 筛选 (全部/待成交/已成交/已撤销) | ✅ |
| 出入金 | 入金/出金流程、银行卡管理、出金 Face ID 确认、HKD 灰化 | ✅ |
| 个人中心 | 资金管理入口、设置入口、帮助/客服/关于 | ✅ |

---

## 发现的问题

### P1 — 功能缺陷（影响核心流程）

#### #1 orders.html "已过期" Tab 筛选失效

- **文件**: `orders.html` 第 260 行
- **现象**: 点击"已过期"Tab，所有订单全部隐藏，看不到任何内容
- **原因**: `statusMap` 对象缺少 `expired` 键。当 `tab === 'expired'` 时走 `else` 分支，`statusMap['expired']` 为 `undefined`，所有 `data-status` 都不等于 `undefined`，全部被 hidden
- **修复**: 在 statusMap 中添加 `expired: 'expired'`

```js
// 当前 (Bug)
const statusMap = { all: null, pending: 'pending', filled: 'filled', cancelled: 'cancelled' };

// 修复后
const statusMap = { all: null, pending: 'pending', filled: 'filled', cancelled: 'cancelled', expired: 'expired' };
```

#### #2 search.html 游客模式参数丢失

- **文件**: `search.html` 第 159 行
- **现象**: 游客从行情页 (`market.html?guest=1`) 点搜索图标进入搜索页，搜索到股票后点击进入详情页，延迟标识消失，交易按钮恢复可用
- **原因**: 搜索结果链接 `stock-detail.html?symbol=${stock.symbol}` 没有传递 `guest=1` 参数
- **影响**: 游客绕过了延迟提示和登录拦截，可能误以为看到了实时行情，且看到交易按钮但点击后无法下单（因为没有账号）
- **修复**: 检测 URL 中的 `guest=1` 参数，传递给搜索结果链接

#### #3 trade.html 返回链接丢失 symbol 参数

- **文件**: `trade.html` 第 223 行
- **现象**: 用户从 TSLA 下单页点返回，看到的是 AAPL 的个股详情（stock-detail.html 默认数据）
- **原因**: 返回按钮 `href="stock-detail.html"` 硬编码无参数
- **修复**: 动态设置返回链接为 `stock-detail.html?symbol=${symbol}`

#### #4 stock-detail.html 返回按钮丢失游客状态

- **文件**: `stock-detail.html` 第 20 行
- **现象**: 游客在个股详情页点返回，回到行情页后延迟提示消失
- **原因**: 返回按钮 `href="market.html"` 硬编码，未携带 `?guest=1`
- **修复**: 游客模式下动态修改返回链接为 `market.html?guest=1`

#### #5 portfolio.html 持仓股票无个股详情入口

- **文件**: `portfolio.html` 第 58-97 行
- **现象**: 用户看到持仓的 AAPL/TSLA，想查看 K 线、新闻或财报，但股票名称不可点击，只有买入/卖出按钮
- **影响**: 用户必须返回行情页重新搜索才能看到持仓股票的详情，路径断裂
- **修复**: 股票名称区域添加链接到 `stock-detail.html?symbol=XXX`

---

### P2 — 体验问题

#### #6 游客模式底部 Tab 未拦截

- **文件**: `market.html` 第 67-84 行
- **现象**: 游客模式下点击底部"订单""持仓""我的"Tab 可正常进入，看到已登录用户的 mock 数据（订单列表、持仓明细、个人信息）
- **建议**: 游客模式下订单/持仓/我的 Tab 点击应弹出登录提示，而非直接进入
- **注意**: 仅对 `market.html` 游客模式下的底部导航生效，不影响已登录用户

#### #7 settings.html 退出登录后未跳转

- **文件**: `settings.html` 退出登录按钮逻辑
- **现象**: 点击"退出登录"后 toast 提示"已退出登录"，但停留在设置页面
- **建议**: 退出登录后应跳转到 `login.html` 着陆页

#### #8 funding.html 返回按钮硬编码

- **文件**: `funding.html` 第 34 行
- **现象**: 从 `portfolio.html` 的"入金"按钮进入 funding.html，点返回却跳到 profile.html 而非 portfolio.html
- **建议**: 返回按钮改用 `history.back()` 或 `javascript:history.back()` 代替硬编码 `href="profile.html"`

---

## 修复优先级

| 优先级 | 问题 | 预计工作量 |
|--------|------|-----------|
| P1 | #1 订单过期筛选 | 1 行代码 |
| P1 | #2 搜索游客参数 | 5 行代码 |
| P1 | #3 交易返回链接 | 3 行代码 |
| P1 | #4 详情返回游客 | 3 行代码 |
| P1 | #5 持仓详情入口 | 10 行代码 |
| P2 | #6 游客 Tab 拦截 | 15 行代码 |
| P2 | #7 退出登录跳转 | 2 行代码 |
| P2 | #8 返回按钮硬编码 | 1 行代码 |

**总计**: 约 40 行代码修改，预计 0.5 个工作日

---

**文档版本**: v1.0
**编制日期**: 2026-03-12
