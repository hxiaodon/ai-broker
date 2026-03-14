# 低保真原型索引

> **原型类型**：低保真线框稿（Lo-Fi Wireframes）
> **产出方**：产品经理
> **交付目标**：UIUX 工程师（在此基础上产出高保真 HTML）
> **更新日期**：2026-03-14

---

## 原型目录结构

```
prototypes/
├── _shared/
│   ├── proto-base.css      ← 低保真基础样式（灰度线框）
│   └── proto-router.js     ← 页面跳转 + 状态切换工具
├── 01-auth/
│   └── index.html          ← 冷启动·OTP登录·生物识别·设备管理
├── 02-kyc/
│   └── index.html          ← 7步开户全流程·OCR·W-8BEN·审核状态
├── 03-market/
│   ├── index.html          ← 行情首页·Watchlist·大盘指数
│   ├── stock-detail.html   ← 股票详情·K线·持仓快速查看
│   └── search.html         ← 搜索·历史·热门股
├── 04-trading/
│   ├── order-entry.html    ← 下单面板·市价单/限价单·盘前盘后
│   ├── order-confirm.html  ← 订单确认·生物识别·成功/失败
│   └── order-list.html     ← 订单列表·筛选·撤单
├── 05-funding/
│   ├── index.html          ← 资金中心·余额·银行卡·近期流水
│   ├── deposit.html        ← 入金流程 (ACH/Wire)
│   ├── withdraw.html       ← 出金流程·可提现金·审批状态
│   └── bank-bind.html      ← 银行卡绑定·微存款验证
├── 06-portfolio/
│   ├── index.html          ← 资产总览·持仓列表·资金明细
│   └── position-detail.html← 单只持仓详情·成本基础·盈亏
├── 07-cross-module/
│   └── index.html          ← 消息通知·全局错误状态
└── 08-settings-profile/
    ├── index.html          ← 个人中心·快捷功能·菜单
    ├── settings.html       ← 安全设置·生物识别·设备管理
    └── profile.html        ← 个人资料·税务信息·投资者画像
```

---

## 原型与 PRD 对照表

| 原型文件 | 对应 PRD | 覆盖的关键流程 |
|----------|---------|--------------|
| `01-auth/index.html` | [PRD-01](../01-auth.md) | OTP 登录、生物识别登录/设置、访客模式、设备管理 |
| `02-kyc/index.html` | [PRD-02](../02-kyc.md) | 7 步开户（基本信息→证件→地址→财务→经验→税务→签署）、审核状态 |
| `03-market/index.html` | [PRD-03](../03-market.md) | 行情首页、Watchlist 分组、大盘指数 |
| `03-market/stock-detail.html` | [PRD-03](../03-market.md) | 股票详情、K 线时段切换、个人持仓快速查看 |
| `03-market/search.html` | [PRD-03](../03-market.md) | 全局搜索、历史记录、热门股 |
| `04-trading/order-entry.html` | [PRD-04](../04-trading.md) | 买入/卖出切换、市价单/限价单、数量、TIF、购买力 |
| `04-trading/order-confirm.html` | [PRD-04](../04-trading.md) | 订单确认、Face ID 验证、成功/失败状态 |
| `04-trading/order-list.html` | [PRD-04](../04-trading.md) | 待成交/已成交/已撤销筛选、撤单操作 |
| `05-funding/index.html` | [PRD-05](../05-funding.md) | 资金概览、银行卡列表、近期流水 |
| `05-funding/deposit.html` | [PRD-05](../05-funding.md) | ACH/Wire 入金 3 步流程 |
| `05-funding/withdraw.html` | [PRD-05](../05-funding.md) | 出金流程、可提现金计算、自动/人工审批 |
| `05-funding/bank-bind.html` | [PRD-05](../05-funding.md) | 银行卡绑定、微存款验证 |
| `06-portfolio/index.html` | [PRD-06](../06-portfolio.md) | 资产总览、持仓列表、资金明细、历史盈亏 |
| `06-portfolio/position-detail.html` | [PRD-06](../06-portfolio.md) | 单只持仓详情、成本基础 |
| `07-cross-module/index.html` | [PRD-07](../07-cross-module.md) | 消息通知分类、全局错误状态（4 种） |
| `08-settings-profile/index.html` | [PRD-08](../08-settings-profile.md) | 个人中心、快捷入口、菜单导航 |
| `08-settings-profile/settings.html` | [PRD-08](../08-settings-profile.md) | 安全设置、生物识别 Toggle、登录历史 |
| `08-settings-profile/profile.html` | [PRD-08](../08-settings-profile.md) | 个人资料、税务信息、投资者画像 |

---

## 低保真原型约定

### 体现了什么
- 页面整体结构与信息层级
- 所有关键状态：空态 / 加载中 / 正常 / 错误 / 成功
- 页面间跳转逻辑（可点击）
- 业务判断节点（条件分支、表单校验提示、合规说明）
- 核心操作入口位置

### 未体现（留给 UIUX 工程师）
- 精确像素尺寸与品牌色彩
- 真实图标（当前用文字标签替代）
- 动效与转场
- 高保真视觉风格（字体、阴影、渐变）

### 原型注释规范
- 黄色背景文字块（`.proto-note`）= PM 对业务规则的说明，供 UIUX 工程师理解业务意图
- 页面顶部链接（`.proto-nav`）= 原型间导航（不是真实 App 导航，仅供演示）

---

## 高保真原型位置

高保真原型由 UIUX 工程师基于本低保真稿产出，位于：

```
mobile/prototypes/        ← 高保真原型（v3-final）
```

UIUX 工程师可参考 `mobile/docs/design/` 下的设计规范文档。

---

## 版本记录

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-03-14 | 初版：覆盖全部 8 个 PRD 模块，共 18 个页面 |
