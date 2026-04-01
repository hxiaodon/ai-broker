# Design System — 高保真原型

> **用途**：为所有高保真 HTML 原型提供统一的视觉语言、色彩系统、组件库和交互规范
> **维护者**：UI/UX 工程师
> **版本**：v1.0
> **最后更新**：2026-03-31

---

## 📁 文件结构

```
_design-system/
├── tokens.css          # 设计令牌（颜色、字号、圆角、间距、阴影、动效）
├── components.css      # 可复用组件（按钮、表单、卡片、列表等）
├── proto-base.css      # 高保真原型基础样式（手机外壳、视口、导航）
├── showcase.html       # Design System 可视化演示页面
└── README.md          # 本文件
```

---

## 🎨 设计决策

### 色彩主题
- **深色模式**（Gold Standard）：金融交易应用标准配置
- **涨跌颜色**：Green Up（绿=涨，红=跌）→ 符合 HK/Asian 市场惯例
- **颜色映射**：基于 Flutter `ColorTokens.greenUp`（见 `mobile/src/lib/shared/theme/color_tokens.dart`）

### 字体选择
- **衬线字体**：`-apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", sans-serif`
- **等宽字体**：`"SF Mono", "Monaco", "Inconsolata", monospace` → 用于价格、数量、数字显示，防止数字跳动

### 响应式设计
- **基准视口**：375px（iPhone 8 模拟器标准）
- **设计原则**：Mobile-First → 一次设计，适配 iOS/Android
- **Safe Area**：考虑状态栏（44px）和 Home Indicator（34px）

---

## 🎯 使用指南

### 在高保真原型中引入 Design System

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>04-Trading — 下单面板</title>

  <!-- 顺序很重要：Tokens → Components → Proto-Base -->
  <link rel="stylesheet" href="../../_design-system/tokens.css">
  <link rel="stylesheet" href="../../_design-system/components.css">
  <link rel="stylesheet" href="../../_design-system/proto-base.css">
</head>
<body>
  <!-- 你的页面内容 -->
</body>
</html>
```

### 配色用法

#### 品牌色（交互、重点）
```css
color: var(--color-primary);              /* #1A73E8 蓝色 */
background: var(--color-primary-dark);    /* #1557B0 深蓝 */
```

#### 金融语义色（涨跌）
```css
.price-up {
  color: var(--color-gain);               /* #0DC582 绿·涨 */
  background: var(--color-gain-bg);       /* #0D2A1E 绿背景 */
}

.price-down {
  color: var(--color-loss);               /* #FF4747 红·跌 */
  background: var(--color-loss-bg);       /* #2A0D0D 红背景 */
}
```

#### 背景层
```css
.bg-base { background: var(--color-bg-base); }           /* #0F1120 最深 */
.bg-card { background: var(--color-bg-elevated); }       /* #1A1C2A 卡片 */
.bg-surface { background: var(--color-bg-surface); }     /* #242638 略浅 */
```

### 排版用法

#### 标题
```html
<!-- Heading 2xl：页面标题 -->
<h1 style="font-size: var(--text-2xl); font-weight: var(--font-weight-bold);">下单</h1>

<!-- Heading lg：模块标题 -->
<h2 style="font-size: var(--text-lg); font-weight: var(--font-weight-semibold);">委托数量</h2>
```

#### 正文
```html
<!-- Body text（15px）：主要内容 -->
<p style="font-size: var(--text-base); color: var(--color-text-primary);">...</p>

<!-- Secondary（13px）：辅助信息 -->
<p style="font-size: var(--text-sm); color: var(--color-text-secondary);">...</p>
```

#### 数字/价格（等宽）
```html
<!-- 必须使用 num-mono 类，保证对齐 -->
<div class="num-mono" style="font-size: var(--text-xl); font-weight: var(--font-weight-bold);">
  $1,234.56 AAPL +2.14%
</div>
```

### 组件用法

#### 按钮
```html
<!-- 主要操作 -->
<button class="btn btn-primary">提交订单</button>

<!-- 次要操作 -->
<button class="btn btn-secondary">取消</button>

<!-- 危险操作 -->
<button class="btn btn-danger">删除</button>

<!-- 小尺寸 -->
<button class="btn btn-primary btn-sm">确定</button>
```

#### 表单输入
```html
<div class="form-group">
  <label class="form-label required">委托价格</label>
  <input type="number" class="form-input num-input" placeholder="0.00">
  <div class="form-hint">当前买一：$178.20</div>
</div>
```

#### 卡片
```html
<!-- 标准卡片 -->
<div class="card">
  <div class="card-title">订单确认</div>
  <div class="card-content">...</div>
</div>

<!-- 金融卡片（深色渐变） -->
<div class="card-financial">
  <div style="font-family: var(--font-mono); font-size: var(--text-2xl); font-weight: var(--font-weight-bold);">
    $12,450.00
  </div>
  <div class="card-subtitle">可用购买力</div>
</div>
```

#### 列表项
```html
<div class="list-item">
  <div class="list-item-icon">📈</div>
  <div class="list-item-content">
    <div class="list-item-title">AAPL</div>
    <div class="list-item-subtitle">Apple Inc.</div>
  </div>
  <div class="list-item-value">$178.25</div>
</div>
```

#### 警告/提示
```html
<!-- 成功 -->
<div class="alert alert-success">
  <div class="alert-icon">✓</div>
  <div class="alert-content">
    <div class="alert-title">Success</div>
    <div class="alert-message">Order submitted successfully</div>
  </div>
</div>

<!-- 错误 -->
<div class="alert alert-error">
  <div class="alert-icon">!</div>
  <div class="alert-content">
    <div class="alert-title">Error</div>
    <div class="alert-message">Insufficient balance</div>
  </div>
</div>

<!-- 风险警告 -->
<div class="alert alert-warning">
  <div class="alert-icon">⚠</div>
  <div class="alert-content">
    <div class="alert-title">Risk Alert</div>
    <div class="alert-message">Pattern Day Trading rule triggered</div>
  </div>
</div>
```

---

## 📐 间距系统

所有间距基于 **4px 倍数**：

| 令牌 | 值 | 用途 |
|------|---|----|
| `--space-1` | 4px | 极小间隔（icon & text） |
| `--space-2` | 8px | 小间隔（form group） |
| `--space-3` | 12px | 标准间隔（padding） |
| `--space-4` | 16px | 大间隔（section padding） |
| `--space-5` | 20px | 更大间隔 |
| `--space-6` | 24px | 大分隔（section gap） |
| `--space-8` | 32px | 非常大 |

```html
<!-- 示例：卡片内间隔 -->
<div class="card" style="padding: var(--space-4); gap: var(--space-3);">
  <!-- 卡片内部间隔 16px -->
</div>
```

---

## 🔄 动效规范

### 过渡时长

| 令牌 | 值 | 场景 |
|------|---|----|
| `--transition-fast` | 150ms | 按钮 hover、输入框焦点 |
| `--transition-base` | 200ms | 模态框进入、菜单展开 |
| `--transition-slow` | 300ms | 页面转场、大幅动画 |

### Easing 函数
```css
cubic-bezier(0.4, 0, 0.2, 1)  /* Material Design 标准缓动 */
```

### 示例：按钮过渡
```css
.btn {
  transition: all var(--transition-fast);
}

.btn:hover {
  background: var(--color-primary-dark);
}
```

---

## 📱 无障碍（Accessibility）

### 颜色对比度
- **文本 + 背景**：至少 4.5:1（WCAG AA）
- **验证工具**：WebAIM Contrast Checker

### 触控区域
- **最小尺寸**：44px × 44px（iOS）、48px × 48px（Android）
- **按钮**：`min-height: 48px` 已内置

### 键盘导航
- **Tab 焦点**：所有交互元素必须 focusable
- **焦点样式**：`:focus-visible` 有明确轮廓

```html
<!-- 自动应用焦点样式 -->
<button class="btn btn-primary">提交</button>
<!-- 焦点时显示蓝色 2px 轮廓 -->
```

---

## 🔍 常见场景

### 价格卡片（带涨跌）
```html
<div class="card-financial">
  <div class="card-subtitle">当前价格</div>
  <div class="num-mono" style="font-size: var(--text-3xl); font-weight: var(--font-weight-bold); color: var(--color-text-primary);">
    $178.25
  </div>
  <div class="flex gap-2" style="margin-top: var(--space-2);">
    <span class="badge" style="background: var(--color-gain-bg); color: var(--color-gain);">
      +2.14%
    </span>
    <span class="text-secondary">+3.62 (今日)</span>
  </div>
</div>
```

### 操作确认弹窗
```html
<div class="modal-overlay">
  <div class="modal">
    <div class="modal-title">确认下单</div>
    <div class="modal-content">
      <div class="card" style="margin-bottom: var(--space-4);">
        <div class="list-item">
          <div class="list-item-content">
            <div class="list-item-title">AAPL</div>
          </div>
          <div class="list-item-value">买入 100 股</div>
        </div>
      </div>
    </div>
    <button class="btn btn-primary" style="margin-bottom: var(--space-2);">确认</button>
    <button class="btn btn-secondary">取消</button>
  </div>
</div>
```

### 风险提示（与下单关联）
```html
<div class="alert alert-warning">
  <div class="alert-icon">⚠</div>
  <div class="alert-content">
    <div class="alert-title">Pattern Day Trader 规则</div>
    <div class="alert-message">
      您的账户净资产为 $18,000，不满足 PDT 规则最低 $25,000 要求。
      继续此操作可能限制后续交易。
    </div>
  </div>
</div>
```

---

## 🛠 开发工作流

### 1. 创建新页面
```bash
# 在对应模块下创建 hifi/ 目录
mkdir -p mobile/prototypes/04-trading/hifi

# 创建 HTML 文件，引入 Design System
touch mobile/prototypes/04-trading/hifi/order-entry.html
```

### 2. 链接 CSS
```html
<link rel="stylesheet" href="../../_design-system/tokens.css">
<link rel="stylesheet" href="../../_design-system/components.css">
<link rel="stylesheet" href="../../_design-system/proto-base.css">
```

### 3. 验证
- 在浏览器中打开 HTML，检查样式是否正确应用
- 参考 `showcase.html` 了解所有可用组件
- 使用浏览器开发者工具检查颜色变量是否被正确继承

---

## 🔄 维护和更新

### 何时更新 Design System
- ✅ 新增复用组件（如分页器、时间选择器）
- ✅ 颜色、字号、间距微调（保持一致性）
- ✅ 新的交互模式或动效规范

### 何时创建页面特定样式
- ✅ 特殊布局（如网格、瀑布流）
- ✅ 独特的动画序列
- ✅ 金融场景特定的视觉优化

**原则**：Design System 是通用基础，页面特定样式应最小化。

---

## 📊 Design System 检查清单

每次新增原型时，检查以下项目：

- [ ] 所有颜色都来自 `tokens.css` 变量（无硬编码 hex 值）
- [ ] 所有字号都来自 `--text-*` 变量
- [ ] 所有间距都是 4px 倍数
- [ ] 所有按钮最小高度 ≥ 48px
- [ ] 所有交互元素都有 hover/active 状态
- [ ] 颜色对比度 ≥ 4.5:1
- [ ] 金融数据都使用等宽字体（`.num-mono`）
- [ ] 页面宽度限制在 375px 视口内
- [ ] 响应式 scrollbar 样式应用正确
- [ ] 所有浮层（modal/sheet）都有背景遮罩

---

## 📚 相关资源

- **Flutter ColorTokens**：`mobile/src/lib/shared/theme/color_tokens.dart`
- **低保真原型**：`mobile/docs/prd/prototypes/`
- **WCAG 2.1 无障碍标准**：https://www.w3.org/WAI/WCAG21/quickref/
- **Material Design 动效**：https://material.io/design/motion/speed.html

---

## ✍️ 更新日志

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-03-31 | 初版：tokens + components + proto-base + showcase |

---

**维护者**：UI/UX 工程师
**最后审查**：2026-03-31
