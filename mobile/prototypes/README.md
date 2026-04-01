# 高保真 HTML 原型

> **用途**：交互可运行的高保真 HTML 原型，用于设计评审、PM 需求确认、工程师视觉参考
> **产出方**：UI/UX 工程师
> **消费方**：PM（需求确认）、Mobile Engineer（Flutter 实现参考）、Product Team（演示）
> **更新日期**：2026-03-31

---

## 📁 目录结构

```
mobile/prototypes/
├── _design-system/              ← Design System（颜色、排版、组件库）
│   ├── tokens.css               # 设计令牌
│   ├── components.css           # 可复用组件
│   ├── proto-base.css           # 基础样式（手机外壳、视口）
│   ├── showcase.html            # Design System 演示
│   └── README.md                # 使用指南
├── _shared/
│   └── proto-router.js          # 页面导航、状态切换工具
├── 01-auth/
│   └── hifi/
│       └── index.html           # 认证流程（OTP、生物识别）
├── 02-kyc/
│   └── hifi/
│       └── index.html           # KYC 开户 7 步流程
├── 03-market/
│   └── hifi/
│       ├── index.html           # 行情首页（Watchlist、大盘指数）
│       ├── stock-detail.html    # 股票详情（K线、价格）
│       └── search.html          # 搜索页
├── 04-trading/
│   └── hifi/
│       ├── order-entry.html     # 下单面板
│       ├── order-confirm.html   # 订单确认
│       └── order-list.html      # 订单列表
├── 05-funding/
│   └── hifi/
│       ├── index.html           # 资金中心
│       ├── deposit.html         # 入金流程
│       ├── withdraw.html        # 出金流程
│       └── bank-bind.html       # 银行卡绑定
├── 06-portfolio/
│   └── hifi/
│       ├── index.html           # 资产总览
│       └── position-detail.html # 单只持仓详情
├── 07-cross-module/
│   └── hifi/
│       └── index.html           # 消息、全局错误状态
├── 08-settings-profile/
│   └── hifi/
│       ├── index.html           # 个人中心
│       ├── settings.html        # 安全设置
│       └── profile.html         # 个人资料
└── README.md                    # 本文件
```

---

## 🎯 交付标准

### 每个功能模块必须包含

#### 1. hifi/index.html（或多个页面）
- ✅ 基于 Design System tokens 和组件
- ✅ 真实视觉还原：颜色、字号、图标、间距
- ✅ **所有关键状态覆盖**：空态 / 加载中 / 正常数据 / 错误 / 成功
- ✅ 关键交互可运行：页面跳转、弹窗、抽屉、Tab 切换
- ✅ 响应式：375px 视口内无横向溢出

#### 2. 内嵌设计注释（HTML 注释）
用于工程师理解交互意图和动效需求

```html
<!-- [DESIGN] 订单确认弹窗
     动效：从底部滑入，duration 300ms, easing ease-out
     关闭方式：点击遮罩层 OR 滑动下拉 OR 点击取消按钮
     Flutter 实现参考：showModalBottomSheet + DraggableScrollableSheet
     生物识别：Face ID / Touch ID 验证
-->
```

#### 3. 状态切换控制器（开发辅助）
提供页面顶部的 Dev 工具栏，方便工程师快速预览各状态

```html
<!-- [DEV] 状态预览切换器 — 生产环境不需要此控件 -->
<div class="dev-toolbar">
  <div class="dev-toolbar-title">State Preview</div>
  <button class="dev-state-btn active" data-state="normal">正常</button>
  <button class="dev-state-btn" data-state="loading">加载中</button>
  <button class="dev-state-btn" data-state="empty">空态</button>
  <button class="dev-state-btn" data-state="error">错误</button>
</div>

<div data-state="normal" style="display: block;"><!-- 正常状态 --></div>
<div data-state="loading" style="display: none;"><!-- 加载中 --></div>
<div data-state="empty" style="display: none;"><!-- 空态 --></div>
<div data-state="error" style="display: none;"><!-- 错误 --></div>
```

---

## 📋 质量标准

| 维度 | 要求 | 验证方法 |
|------|------|---------|
| **视觉还原** | 颜色、字号、间距严格使用 Design System tokens，无硬编码 hex 值 | 浏览器开发者工具检查 computed styles |
| **状态覆盖** | 每个界面的所有可能状态均有对应视觉 | 逐一预览状态切换器 |
| **交互完整性** | 主流程可点击跑通，无死链 | 手动测试页面导航 |
| **代码可读性** | class 命名语义化（不用 a1, b2），结构清晰，注释充分 | Code review |
| **无障碍** | `aria-label` 完整、颜色对比度 ≥ 4.5:1、触控区域 ≥ 44px | WebAIM Contrast Checker + 键盘导航测试 |
| **移动端适配** | 375px 视口下无横向溢出，关键元素不被截断 | 浏览器 DevTools 375px 视口模拟 |
| **性能** | 首屏加载 < 1s（无网络请求，仅 HTML/CSS/JS） | Chrome DevTools Performance |
| **文档** | 内嵌设计注释清晰、开发工具易用 | 工程师能否独立理解意图 |

---

## 🚀 使用指南

### 本地预览

1. 用 HTTP 服务器启动（跨域限制）
```bash
cd mobile/prototypes
python3 -m http.server 8000
# 访问 http://localhost:8000/_design-system/showcase.html
```

2. 或使用 VS Code Live Server 插件
- 右键 `showcase.html` → "Open with Live Server"

### 浏览器兼容性

- ✅ Chrome / Edge 90+（主要开发环境）
- ✅ Safari 14+（iOS 预览）
- ✅ Firefox 88+（备用浏览器）

### 移动设备预览

1. **iPhone**：在 Safari 中打开本地 IP 地址
   ```bash
   # 获取本地 IP
   ifconfig | grep "inet " | grep -v 127.0.0.1
   # 在 iPhone Safari 中访问 http://<YOUR_IP>:8000/...
   ```

2. **Android**：Chrome 中同样操作

### 截图/分享

- **生成 PDF**：浏览器 Print → "保存为 PDF"
- **截图 PNG**：DevTools → More tools → Screenshots → Capture node screenshot

---

## 🔧 工程师工作流

### 1. 查看高保真原型
```
mobile/prototypes/04-trading/hifi/order-entry.html
```

### 2. 对照 Design System
- 颜色：查看 `_design-system/tokens.css` 中的变量名
- 排版：查看 `--text-*` 和 `--font-weight-*` 变量
- 间距：所有 padding/gap 都是 `--space-*` 的倍数

### 3. 参考 Flutter 映射
```dart
// 示例：颜色映射
--color-primary (#1A73E8) → ColorTokens.primary → ThemeData.primaryColor
--color-gain (#0DC582) → ColorTokens.priceUp → Theme.extension<TradingColors>()?.priceUp
```

### 4. 查看内嵌注释
HTML 中的 `<!-- [DESIGN] ... -->` 注释包含：
- 动效规范（duration、easing）
- 交互逻辑（何时显示/隐藏）
- Flutter Widget 参考实现

---

## 🎨 金融场景特定规范

### 信息层级
- 最关键数据（价格、盈亏、订单状态）无需滚动即可看到
- 次要信息（成交量、开盘价等）可收起或滚动查看
- 风险提示（保证金不足、PDT 规则）醒目展示

### 涨跌颜色
- **绿**（`--color-gain`）= 上涨 / 盈利
- **红**（`--color-loss`）= 下跌 / 亏损
- **中立灰**（`--color-neutral`）= 持平

> ⚠️ **重要**：这是 HK/Asian 市场惯例（greenUp），与 Western convention 相反。

### 数字显示（等宽字体）
```html
<!-- 所有数字必须用等宽字体，防止数字变化时布局抖动 -->
<div class="num-mono">$1,234.56 AAPL +2.14%</div>
```

### 交易安全 UX
- **下单确认**：独立确认步骤，不可单击直接成交
- **生物识别**：Face ID / Touch ID 验证（涉及资金操作）
- **风险提示**：用 `--color-warning` 醒目展示（PDT、保证金、价格偏离）
- **资金操作**：页面顶部显示警示色条或特殊样式

---

## 📚 相关链接

| 资源 | 链接 |
|------|------|
| Design System | `_design-system/README.md` |
| 组件展示 | `_design-system/showcase.html` |
| 低保真原型 | `../docs/prd/prototypes/` |
| Flutter 实现 | `src/lib/` |
| Color Tokens | `src/lib/shared/theme/color_tokens.dart` |

---

## ✍️ 常见问题

### Q: 为什么原型中的按钮不能真的提交订单？
A: 原型是静态 HTML，没有后端连接。工程师需要把原型的结构和交互逻辑迁移到 Flutter。按钮可以切换状态（loading, success, error），但不执行实际操作。

### Q: 如何修改原型中的数据？
A: 直接编辑 HTML 文件中的文本内容（价格、数量等）。对于动态数据，在 `<script>` 中修改初始值。

### Q: 为什么某些页面缺少某个功能？
A: 高保真原型覆盖了低保真原型中的所有页面。如果发现缺失，请检查对应的低保真原型（`../docs/prd/prototypes/`）。

### Q: 如何在手机上预览？
A: 用 HTTP 服务器启动，然后在手机浏览器中访问本地 IP + 端口 + 文件路径。

---

## 📝 版本记录

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-03-31 | 初版：Design System + 目录结构 |

---

**维护者**：UI/UX 工程师
**最后更新**：2026-03-31
