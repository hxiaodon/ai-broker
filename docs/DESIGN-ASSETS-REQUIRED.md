# 设计资源需求清单 (Design Assets Manifest)

**目的**: 列举从高保真HTML原型到Flutter实现所需的所有设计资源 (logo、icon、插画等)

**基于原型版本**: `mobile/prototypes/` (v3-final)

**优先级标记**:
- 🔴 **CRITICAL**: 必须有，影响启动和核心功能
- 🟡 **HIGH**: 需要有，影响用户体验
- 🟢 **MEDIUM**: 可选，增强视觉表现
- ⚪ **NICE-TO-HAVE**: 可暂时用系统icon替代

---

## ⚠️ 前置决策（必须先确认，再开始任何图标设计）

### 决策 1：图标风格

**必须在交付前锁定，否则所有图标可能返工。**

| 选项 | 描述 | 适用场景 |
|------|------|---------|
| **Outlined (描边)** | 线条构成，轻盈感 | 现代金融App主流（如Robinhood、富途） |
| **Filled (实心)** | 实心填充，厚重感 | 传统券商、信息密度高的场景 |
| **Duotone** | 双色，主色+辅助色 | 品牌感强，视觉层次丰富 |

> **建议**: Outlined 为基础风格，选中状态切换为 Filled，与 Bottom Nav 的 outline→filled 状态变化一致。

### 决策 2：深色模式支持策略

| 选项 | 工作量 | 描述 |
|------|------|------|
| **A. 全量双主题** | 高 | 所有颜色令牌提供 light/dark 两套值 |
| **B. 仅图标用 `currentColor`** | 中 | SVG图标不硬编码颜色，由Flutter主题控制 |
| **C. 暂不支持深色模式** | 低 | MVP阶段，后续迭代 |

> **建议**: B方案。所有SVG图标使用 `currentColor` 而非硬编码色值，Flutter侧通过 `ThemeData` 控制颜色，最小化交付工作量，同时保留扩展能力。

### 决策 3：动效资源格式

| 选项 | 格式 | Flutter 支持 |
|------|------|------------|
| **Lottie** | `.json` | `lottie` package |
| **Rive** | `.riv` | `rive` package（已在 pubspec.yaml） |
| **静态图** | SVG/PNG | 无需额外依赖 |

> **建议**: 关键状态反馈（订单成功/失败、KYC结果）使用 Rive（项目已有依赖）；加载态用系统组件。

---

## 一、核心品牌资源

### 1.1 应用Logo 🔴

**用途**:
- 冷启动屏幕 (Splash Screen) — `01-auth/hifi/index.html`
- 应用图标 (App Icon) — iOS 应用市场、Android 应用市场、设备主屏
- 品牌水印 — 可选，某些页面/弹窗

**当前原型**: 蓝色方形 + 📈 emoji (占位符)

**需求**:
```
AppLogo/
├── app-logo.svg                  # 矢量源文件 (推荐 AI 设计)
├── app-icon-ios/
│   ├── Icon-20.png              # Notification (20x20 @1x)
│   ├── Icon-20@2x.png           # Notification (40x40 @2x)
│   ├── Icon-20@3x.png           # Notification (60x60 @3x)
│   ├── Icon-29.png              # Settings (29x29 @1x)
│   ├── Icon-29@2x.png           # Settings (58x58 @2x)
│   ├── Icon-29@3x.png           # Settings (87x87 @3x)
│   ├── Icon-40.png              # Spotlight (40x40 @1x)
│   ├── Icon-40@2x.png           # Spotlight (80x80 @2x)
│   ├── Icon-40@3x.png           # Spotlight (120x120 @3x)
│   ├── Icon-60@2x.png           # iPhone app icon (120x120 @2x)
│   ├── Icon-60@3x.png           # iPhone app icon (180x180 @3x)
│   ├── Icon-76.png              # iPad app icon (76x76 @1x)
│   ├── Icon-76@2x.png           # iPad app icon (152x152 @2x)
│   ├── Icon-83.5@2x.png         # iPad Pro app icon (167x167 @2x)
│   └── Icon-1024.png            # App Store (1024x1024)
└── app-icon-android/
    ├── ic_launcher.png          # mdpi (48x48)
    ├── ic_launcher-hdpi.png     # hdpi (72x72)
    ├── ic_launcher-xhdpi.png    # xhdpi (96x96)
    ├── ic_launcher-xxhdpi.png   # xxhdpi (144x144)
    ├── ic_launcher-xxxhdpi.png  # xxxhdpi (192x192)
    ├── ic_launcher_foreground.png        # 自适应图标前景 (108x108 safe zone: 72x72)
    ├── ic_launcher_background.xml        # 自适应图标背景色 (需提供具体色值)
    ├── ic_launcher_background.png        # 自适应图标背景图 (可选，如有渐变)
    └── ic_launcher_monochrome.png        # Android 13+ 主题图标 (108x108，单色)
```

> **Android 自适应图标说明**: `ic_launcher_background.xml` 中填写的背景色必须与品牌主色保持一致，请设计团队确认具体色值（当前原型主色 `#1A73E8`）。`ic_launcher_monochrome.png` 用于 Android 13+ 的主题图标功能，需要提供纯白/透明单色版本。

---

## 二、导航栏图标 (Bottom Navigation) 🔴

**用途**: 主应用的4个标签页底部导航

**位置**: 所有主屏幕页面 (`03-market/hifi/index.html`, `04-trading/`, `06-portfolio/`, `08-settings-profile/`)

**当前原型**: Emoji 占位符
```
📈 行情 (Market)
📝 交易 (Trading)
💼 持仓 (Portfolio)
⚙️ 我的 (Settings/My Account)
```

**需求**:
```
NavTabIcons/
├── tab-market-outline.svg        # 未选中状态
├── tab-market-filled.svg         # 选中状态
├── tab-trading-outline.svg
├── tab-trading-filled.svg
├── tab-portfolio-outline.svg
├── tab-portfolio-filled.svg
├── tab-settings-outline.svg
├── tab-settings-filled.svg
├── tab-badge-dot.svg             # 通知红点 (8x8，用于叠加在任意tab上)
└── _variants/
    ├── ic_market_24.png          # 导出光栅版 (24x24 @1x)
    ├── ic_market_24@2x.png       # @2x (48x48)
    ├── ic_market_24@3x.png       # @3x (72x72)
    └── ...其他tab icon
```

**尺寸参考**:
- SVG: 24x24 viewBox (内容区 20x20)
- PNG: 24x24 @1x, 48x48 @2x, 72x72 @3x (iOS)
- Android: 24dp (equates 24x24 @mdpi, 36x36 @hdpi, 48x48 @xhdpi)

**设计指引**:
- **选中状态**: 品牌蓝 (#1A73E8) + Filled 实心
- **未选中状态**: 中性灰 (#8A8D9F) + Outlined 描边
- **风格**: 所有图标必须统一（见前置决策 1）
- **Badge**: 红点直径 8dp，叠加在图标右上角；数字角标最大显示 `99+`
- **SVG颜色**: 所有 SVG 使用 `currentColor`，禁止硬编码色值（见前置决策 2）

---

## 三、系统UI图标 (System Icons) 🟡

这些图标在原型中以内联SVG定义，需要导出为独立icon set供Flutter使用。

> **全局要求**: 所有SVG图标 `fill` 或 `stroke` 必须使用 `currentColor`，不得硬编码任何颜色值。

### 3.1 基础操作图标

| 图标名称 | 用途 | 当前实现 | 尺寸 |
|---------|------|---------|------|
| search | 搜索 (03-market, 08-settings) | `<path>` inline SVG | 20x20 |
| chevron-right | 列表项右箭头 | inline SVG | 16x16 |
| chevron-down | 下拉箭头 | inline SVG | 16x16 |
| close / x-mark | 关闭对话框 | inline SVG | 16x16 |
| check | 勾选 / 完成 | inline SVG | 16x16 |
| alert / warning | ⚠️ 警告 | inline SVG | 16x16 |
| info-circle | ℹ️ 信息 | inline SVG | 16x16 |

### 3.2 KYC 流程相关图标 🟡

| 图标 | 位置 | 描述 |
|------|------|------|
| id-card | `02-kyc/step-1-personal.html` | 身份验证 |
| document-upload | `02-kyc/step-2-document.html` | 文件上传 |
| location-map | `02-kyc/step-3-address.html` | 地址验证 |
| wallet | `02-kyc/step-4-finance.html` | 财务信息 |
| chart-line | `02-kyc/step-5-investment.html` | 投资经验 |
| tax-document | `02-kyc/step-6-tax.html` | 税务身份 |
| shield-alert | `02-kyc/step-7-disclosure.html` | 风险披露 |
| handshake | `02-kyc/step-8-agreement.html` | 协议同意 |

**KYC 专项补充 — 文档扫描取景框 overlay** 🔴

身份证/护照拍照步骤需要相机取景框 overlay，这是一个独立视觉资产：

```
KYCAssets/
├── doc-scan-overlay-id.svg       # 身份证取景框 (横向矩形，含四角标记)
├── doc-scan-overlay-passport.svg # 护照取景框 (竖向矩形，含四角标记)
└── doc-scan-overlay-hkid.svg     # 香港身份证取景框
```

设计规范：
- 取景框四角使用品牌蓝 `#1A73E8` 角标，非实心边框
- 取景框内部透明，外部用半透明黑色蒙层（`rgba(0,0,0,0.5)`）
- 尺寸比例参考实体证件（身份证 85.6mm × 54mm，HKID 85.6mm × 54mm）

### 3.3 交易流程相关图标 🟡

| 图标 | 位置 | 描述 |
|------|------|------|
| arrow-up | `04-trading/order-entry.html` | 买入 (BUY) |
| arrow-down | `04-trading/order-entry.html` | 卖出 (SELL) |
| check-circle | `04-trading/order-confirm.html` | 订单确认 |
| clock | `04-trading/order-list.html` | 待处理订单 |
| x-circle | `04-trading/order-list.html` | 已取消订单 |

### 3.4 资金流程相关图标 🟡

| 图标 | 位置 | 描述 |
|------|------|------|
| bank | `05-funding/bank-bind.html` | 银行账户 |
| credit-card | `05-funding/index.html` | 信用卡 / 支付方式 |
| arrow-down-from-bank | `05-funding/deposit.html` | 入金/充值 |
| arrow-up-to-bank | `05-funding/withdraw.html` | 出金/取款 |

### 3.5 账户/设置相关图标 🟡

| 图标 | 位置 | 描述 |
|------|------|------|
| user / profile | `08-settings-profile/profile.html` | 个人资料 |
| shield-check | `08-settings-profile/settings.html` | 安全设置 |
| bell | `07-cross-module/notifications.html` | 通知 |
| language | `08-settings-profile/settings.html` | 语言设置 |
| moon / sun | `08-settings-profile/settings.html` | 深色/浅色模式 |
| edit / pencil | 编辑操作 | 编辑文本/信息 |
| trash / delete | 删除操作 | 删除项目 |

**导出清单** (SVG + PNG 多尺寸):
```
SystemIcons/
├── search.svg
├── chevron-right.svg
├── close.svg
├── check.svg
├── alert.svg
├── id-card.svg
├── ... (所有图标)
└── _png-exports/
    ├── 16x16/     # 小图标
    ├── 20x20/     # 常规
    ├── 24x24/     # 按钮图标
    └── 32x32/     # 大图标
```

---

## 四、市场数据相关资源 🟡

### 4.1 行情图标

| 图标 | 用途 | 位置 |
|------|------|------|
| chart-candlestick | K线图 | `03-market/stock-detail.html` |
| trend-up | 上升趋势 | `03-market/index.html` |
| trend-down | 下降趋势 | `03-market/index.html` |
| star | 加入收藏 | `03-market/stock-detail.html` |
| star-filled | 已收藏 | `03-market/stock-detail.html` |

### 4.2 交易所标识 🔴

行情列表和股票详情页需要区分 US/HK 市场，以下资产必须提供：

```
ExchangeBadges/
├── badge-nyse.svg                # NYSE 标识 (用于股票列表行)
├── badge-nasdaq.svg              # NASDAQ 标识
├── badge-hkex.svg                # HKEX/港交所 标识
├── flag-us.svg                   # 🇺🇸 美国国旗图标 (16x16)
└── flag-hk.svg                   # 🇭🇰 香港旗帜图标 (16x16)
```

设计规范：
- 交易所标识：胶囊形背景 + 简写文字（如 `NASDAQ`），宽度自适应，高度 16-18dp
- 国旗图标：方形或圆角方形，16x16dp，用于行情列表市场切换 Tab

### 4.3 个股 Logo 占位图 🟡

行情列表和持仓页显示个股 logo，实际数据来自行情服务，需要提供：

```
StockAssets/
├── stock-logo-placeholder.svg    # 加载中 / 无logo时的通用占位图
└── stock-logo-error.svg          # 加载失败时的 fallback (可与 placeholder 共用)
```

设计规范：
- 圆形或圆角方形，尺寸 36x36dp（列表）/ 48x48dp（详情页）
- 使用股票代码首字母 + 中性底色作为 fallback

---

## 五、插画/占位符图 (Illustrations) 🟢

### 5.1 Onboarding 引导插画 🟡

首次登录或功能引导页（如行情引导、开户引导）需要插画：

| 场景 | 描述 |
|------|------|
| onboarding-market | 行情功能引导 |
| onboarding-trade | 交易功能引导 |
| onboarding-portfolio | 持仓功能引导 |

### 5.2 空状态插画 (Empty States)

| 场景 | 位置 | 描述 |
|------|------|------|
| no-orders | `04-trading/order-list.html` (如果为空) | 无订单 |
| no-holdings | `06-portfolio/index.html` (初始状态) | 无持仓 |
| no-notifications | `07-cross-module/notifications.html` | 无通知 |
| no-watchlist | `03-market/index.html` (初始状态) | 无自选股 |
| no-search-result | 搜索结果为空 | 无搜索结果 |

### 5.3 KYC状态插画

| 插画 | 位置 | 描述 |
|------|------|------|
| kyc-pending | `02-kyc/kyc-review-status.html` | 审核中 |
| kyc-approved | `02-kyc/kyc-review-status.html` | 审核通过 |
| kyc-rejected | `02-kyc/kyc-review-status.html` | 审核被拒 |

### 5.4 结果状态插画

| 插画 | 用途 |
|------|------|
| success-checkmark | 操作成功 |
| error-alert | 操作失败 |

---

## 六、动效资源 (Motion Assets) 🟡

> **格式**: 使用 Rive (`.riv`)，项目 `pubspec.yaml` 已有 `rive` 依赖（见前置决策 3）。

| 动效 | 场景 | 触发时机 | 时长建议 |
|------|------|---------|---------|
| order-success | 订单提交成功 | 收到成功响应后 | 1.5s |
| order-failed | 订单提交失败 | 收到失败响应后 | 1.0s |
| kyc-reviewing | KYC 审核中状态 | 进入审核中页面 | 循环 |
| kyc-approved | KYC 审核通过 | 收到通过通知 | 2.0s |
| biometric-scan | 生物识别认证中 | 触发 FaceID/指纹 | 循环，直到完成 |
| loading-spinner | 全局加载 | 网络请求中 | 循环 |

```
MotionAssets/
├── order-success.riv
├── order-failed.riv
├── kyc-reviewing.riv
├── kyc-approved.riv
├── biometric-scan.riv
└── loading-spinner.riv
```

---

## 七、头像占位符 (Avatar Placeholder) 🟡

**位置**:
- `06-portfolio/index.html` (个人头像)
- `08-settings-profile/profile.html` (个人资料)

**需求**:
```
Avatar/
├── avatar-placeholder.svg        # 通用占位符 (用户未设头像)
├── avatar-default-male.png       # 默认男性头像
├── avatar-default-female.png     # 默认女性头像
```

**尺寸**:
- 1x: 48x48 px
- 2x: 96x96 px
- 3x: 144x144 px

---

## 八、品牌色/主题资源

### 8.1 现有令牌 ✅

**现有**: `mobile/prototypes/_design-system/tokens.css`

包含:
- 颜色令牌 (primary, gain/loss, neutral, etc.)
- 字号系统
- 圆角半径
- 间距系统
- 阴影
- 过渡/动效

✅ 已映射到 `mobile/src/lib/shared/theme/color_tokens.dart` (Dart 实现)

### 8.2 待补充：Dark Mode 令牌 🟡

当前 `tokens.css` 仅有 Light Mode 值。若采用前置决策 2 的 B 方案（`currentColor`），需额外提供：

```
tokens-dark.css / tokens.json (dark theme section)
```

包含每个语义色在 Dark Mode 下的对应值，例如：
```json
{
  "color": {
    "background": { "light": "#FFFFFF", "dark": "#0D0D0D" },
    "surface":    { "light": "#F5F5F5", "dark": "#1A1A1A" },
    "primary":    { "light": "#1A73E8", "dark": "#4DA3FF" },
    "gain":       { "light": "#0F9D58", "dark": "#34C77B" },
    "loss":       { "light": "#D93025", "dark": "#FF6B6B" }
  }
}
```

### 8.3 tokens.json 交付 🔴

`tokens.json` 是工程集成的**必须交付物**，非可选项。

格式参考 [Style Dictionary](https://amzn.github.io/style-dictionary/)，结构：
```json
{
  "color": { ... },
  "spacing": { ... },
  "radius": { ... },
  "typography": { ... },
  "shadow": { ... }
}
```

---

## 九、交付格式规范

### 格式

| 资源类型 | 推荐格式 | 备选格式 |
|---------|---------|---------|
| Logo / 品牌 | SVG (AI/EPS) | PNG (高分辨率) |
| 图标集 | SVG (`currentColor`) | PNG (多尺寸) |
| 插画 | SVG | PNG (高分辨率) |
| 头像 | PNG | JPEG |
| 动效 | `.riv` (Rive) | Lottie `.json` |
| 设计令牌 | `tokens.json` | CSS Custom Properties |

### 交付包结构

```
design-assets/
├── ASSETS-README.md
├── app-logo/
│   ├── app-logo.svg
│   ├── app-icon-ios.zip          # 含所有iOS尺寸 (见第一节完整清单)
│   └── app-icon-android.zip      # 含 adaptive + monochrome
├── nav-icons/
│   ├── nav-tabs.svg
│   └── png-exports/
├── system-icons/
│   ├── icon-set.svg
│   └── png-exports/
├── kyc-assets/
│   ├── kyc-icons/
│   └── doc-scan-overlays/        # 取景框 overlay
├── trading-icons/
├── funding-icons/
├── market-assets/
│   ├── exchange-badges/          # NYSE, NASDAQ, HKEX
│   ├── flags/                    # 🇺🇸 🇭🇰
│   └── stock-logo-placeholder.svg
├── illustrations/
│   ├── onboarding/
│   ├── empty-states/
│   └── kyc-status/
├── motion/                       # Rive 动效文件
├── avatars/
└── tokens.json                   # 🔴 必须交付
```

### SVG 导出规范

- 所有颜色使用 `currentColor`，禁止硬编码色值
- 清理路径，移除冗余节点
- 使用相对路径
- 删除编辑器元数据 (Figma, Adobe 特有属性)
- 标准化 viewBox (e.g., `0 0 24 24`)
- 文件名全小写 kebab-case

### PNG 导出规范

- iOS: @1x, @2x, @3x
- Android: mdpi (1x), hdpi (1.5x), xhdpi (2x), xxhdpi (3x), xxxhdpi (4x)
- 优化文件大小 (TinyPNG, ImageOptim)

---

## 十、集成到 Flutter 项目

### 步骤

1. **解压资源包** → `mobile/src/assets/`
   ```
   mobile/src/assets/
   ├── logos/app-logo.svg
   ├── icons/nav/
   │   ├── market-outline.svg
   │   ├── market-filled.svg
   │   └── ...
   ├── icons/system/
   │   ├── search.svg
   │   ├── check.svg
   │   └── ...
   ├── icons/market/
   │   ├── badge-nyse.svg
   │   ├── badge-nasdaq.svg
   │   ├── badge-hkex.svg
   │   ├── flag-us.svg
   │   └── flag-hk.svg
   ├── illustrations/
   │   ├── onboarding/
   │   ├── empty-states/
   │   └── kyc-status/
   ├── motion/
   │   ├── order-success.riv
   │   └── ...
   └── avatars/
   ```

2. **声明资源** → `pubspec.yaml`
   ```yaml
   flutter:
     assets:
       - assets/logos/
       - assets/icons/
       - assets/illustrations/
       - assets/motion/
       - assets/avatars/
   ```

3. **在 Dart 中使用**
   ```dart
   // SVG (via flutter_svg)
   SvgPicture.asset(
     'assets/icons/nav/market-outline.svg',
     colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
   )

   // Rive 动效
   RiveAnimation.asset('assets/motion/order-success.riv')

   // PNG
   Image.asset('assets/logos/app-logo.png')
   ```

4. **更新现有占位符** (见 `mobile/src/lib/shared/widgets/`)

---

## 十一、优先级和交付时间表

| 优先级 | 资源 | 截止日期 | 备注 |
|-------|------|---------|------|
| 🔴 P0 | 前置决策 1/2/3 确认 | **第0周** | 先决条件，不确认不开始设计 |
| 🔴 P0 | App Logo + App Icon (完整iOS/Android尺寸) | **第1周** | 含 monochrome 版本 |
| 🔴 P0 | Nav Tab Icons (4个，含 badge-dot) | **第1周** | 启动屏幕、底部导航 |
| 🔴 P0 | System Icons (基础操作 + 3.1节) | **第1周** | UI 交互基础 |
| 🔴 P0 | `tokens.json` (含 dark theme 值) | **第1周** | 工程集成必需 |
| 🟡 P1 | 交易所标识 + 国旗图标 | **第2周** | 行情列表必需 |
| 🟡 P1 | KYC 流程图标 + 文档扫描 overlay | **第2周** | KYC 实现 |
| 🟡 P1 | Trading 图标 + Funding 图标 | **第2周** | 交易/资金功能 |
| 🟡 P1 | Rive 动效 (order-success/failed, kyc-status) | **第2周** | 关键状态反馈 |
| 🟢 P2 | 空状态插画 + KYC 状态插画 | **第3周** | 视觉完善 |
| 🟢 P2 | Onboarding 插画 | **第3周** | 首次使用体验 |
| ⚪ P3 | 头像占位图、biometric 动效 | **第4周** | 锦上添花 |

---

## 十二、联系设计团队

请向 UI/UX 设计师提供本清单，优先对齐以下内容：

1. ✅ **前置决策确认** — 图标风格、Dark Mode 方案、动效格式（第0周必须）
2. ✉️ **设计资源包** — Figma 导出、Zip 包、或 GitHub 链接
3. 📋 **tokens.json 交付** — 包含 light/dark 双主题值
4. 🔍 **设计评审周期** — 建议每周一次，确保 Flutter 实现与设计一致

---

**备注**: 本清单基于 v3-final 高保真原型，最后更新 2026-04-02。若原型更新，需重新审视图标和插画需求。
