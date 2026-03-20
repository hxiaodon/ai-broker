# Archive: v1-legacy 高保真原型

**归档日期**: 2026-03-20
**归档原因**: 不符合新 SDD 流程规范
**状态**: 仅供参考，不代表当前设计规范

---

## 背景

这批原型由 UXUE 在 SDD 流程建立之前创建，采用平铺式目录结构（所有页面集中在 `mobile/prototypes/` 根目录），与当前规范不符。

当前规范要求：

```
mobile/prototypes/{module}/hifi/   ← 各模块独立目录
    tokens.css                      ← 设计 token（颜色/间距）
    *.html                          ← 高保真页面
```

---

## 包含页面（v3-final 设计时代）

| 文件 | 模块 | 说明 |
|------|------|------|
| `login.html` | 01-auth | 登录/注册流程 |
| `kyc.html` | 02-kyc | KYC 开户流程 |
| `market.html` | 03-market | 行情首页（Watchlist / 美股 Tab）|
| `stock-detail.html` | 03-market | 股票详情页 |
| `search.html` | 03-market | 搜索页 |
| `trade.html` | 04-trading | 下单页 |
| `orders.html` | 04-trading | 委托记录 |
| `funding.html` | 05-funding | 出入金页面 |
| `portfolio.html` | 06-portfolio | 持仓/盈亏 |
| `profile.html` | 08-settings | 个人主页 |
| `settings.html` | 08-settings | 设置页 |
| `index.html` | — | 原型导航首页 |
| `CHANGELOG.md` | — | 原型历史变更记录 |

---

## 参考价值

这批原型包含完整的交互逻辑和状态机设计（盘前/盘中/盘后/HALTED 切换器、KYC 分步流程等），UXUE 创作新模块 hifi 原型时可参考其中的交互模式。

新的高保真原型由 UXUE / ui-designer 按模块在 `mobile/prototypes/{module}/hifi/` 下创建，以对应 PRD 版本为基准，包含 `tokens.css`，供 mobile-engineer 实现前阅读。
