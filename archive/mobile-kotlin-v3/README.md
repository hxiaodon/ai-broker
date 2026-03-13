# Brokerage Trading App - Mobile

Kotlin Multiplatform + Compose Multiplatform 跨平台券商交易应用

**当前状态**: ✅ 核心功能完成，可运行
**代码规模**: 21 个文件，~4,200 行代码
**测试覆盖**: 39 个单元测试，100% 通过

## 技术栈

- **Kotlin Multiplatform** 2.0.21 - 跨平台共享代码
- **Compose Multiplatform** 1.7.1 - 跨平台 UI
- **Navigation Compose** 2.8.0 - 页面导航
- **Ktor** 3.0.2 - HTTP + WebSocket 客户端
- **SQLDelight** 2.0.2 - 本地数据库
- **Koin** 4.0.0 - 依赖注入
- **Protobuf** - 行情数据序列化

## 项目结构

```
mobile/
├── shared/                 # 共享业务逻辑 (80% 代码)
│   ├── core/              # 基础设施 (网络/存储/加密/DI)
│   ├── domain/            # 业务领域 (auth/trading/market-data)
│   ├── data/              # 数据层 (API/WebSocket/Cache)
│   └── common/            # 工具类 (datetime/format/validation)
├── composeApp/            # 共享 UI (Compose Multiplatform)
│   ├── commonMain/
│   │   └── ui/
│   │       ├── theme/     # Design System (4 文件, 359 行)
│   │       ├── components/# UI 组件库 (4 文件, 917 行)
│   │       └── screens/   # 页面 (6 文件, 2,269 行)
│   ├── androidMain/
│   │   └── ui/
│   │       ├── navigation/# 导航系统 (3 文件, 240 行)
│   │       └── MainScreen.kt
│   └── commonTest/        # 单元测试 (3 文件, ~300 行)
├── androidApp/            # Android 壳工程
└── iosApp/                # iOS 壳工程
```

## 已实现功能

### ✅ Design System (100%)
- [x] 颜色系统 - Tailwind CSS 对齐
- [x] 字体系统 - Material 3 + 金融数据专用样式
- [x] 尺寸系统 - 8dp 网格
- [x] 主题配置 - Light/Dark 支持

### ✅ UI 组件库 (17个组件)
- [x] **Buttons** (6种): Primary, Secondary, Text, Buy, Sell, Icon
- [x] **Cards** (4种): Stock, Info, Warning, Error
- [x] **Inputs** (4种): Text, Password, Number, Search
- [x] **Navigation** (3种): TabRow, BottomNav, TopBar

### ✅ 页面实现 (6个完整页面)
- [x] **MarketScreen** - 行情页 (4个Tab: 自选/美股/港股/热门)
- [x] **OrdersScreen** - 订单页 (4个状态: 全部/待成交/已成交/已撤销)
- [x] **PortfolioScreen** - 持仓页 (资产汇总 + 持仓列表 + 分析)
- [x] **TradeScreen** - 交易下单页 (市价/限价/止损单)
- [x] **AccountScreen** - 我的页面 (个人中心 + 设置菜单)
- [x] **FundingScreen** - 出入金页面 (入金/出金 + 银行卡)

### ✅ 导航系统 (100%)
- [x] Compose Navigation 集成
- [x] 底部导航栏 (4个主Tab)
- [x] 页面跳转 (带参数传递)
- [x] 返回栈管理
- [x] 状态保存/恢复

### ✅ 单元测试 (39个测试)
- [x] 颜色系统测试 (19个)
- [x] 尺寸系统测试 (7个)
- [x] 数据模型测试 (13个)
- [x] 测试覆盖率: Design System 100%

### ✅ 基础设施
- [x] KMP 项目脚手架
- [x] Gradle 配置和依赖管理
- [x] Ktor HTTP 客户端
- [x] Ktor WebSocket 客户端（行情流）
- [x] 安全模块 (expect/actual)
  - BiometricAuth (Face ID / Fingerprint)
  - SecureStorage (Keychain / Keystore)
  - CertificatePinner
  - EncryptionUtils (AES-256-GCM)

### ✅ 工具类
- [x] 金融计算 (BigDecimal 封装)
- [x] 日期时间处理 (UTC + 交易时段判断)
- [x] 输入验证 (股票代码/价格/数量)
- [x] 格式化工具 (价格/百分比/掩码)

## 构建项目

### Android
```bash
./gradlew :androidApp:assembleDebug
```
**状态**: ✅ BUILD SUCCESSFUL

### iOS
```bash
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
```
**状态**: ✅ BUILD SUCCESSFUL

### 运行测试
```bash
./gradlew :composeApp:testDebugUnitTest
```
**结果**: ✅ 39/39 PASSED (100%)

## 功能演示

### 1. 启动应用
应用启动后默认显示**行情页**，底部有4个Tab导航。

### 2. 浏览行情
- 切换Tab查看不同市场（自选/美股/港股/热门）
- 查看股票列表（代码、名称、价格、涨跌、市值、PE、成交量）
- 点击股票进入详情页（待实现）

### 3. 查看持仓
- 点击底部"持仓"Tab
- 查看资产汇总（总资产、今日盈亏、可用资金）
- 查看持仓列表和盈亏情况
- 点击"买入/卖出"按钮进入交易页

### 4. 交易下单
- 选择订单类型（市价/限价/止损）
- 输入价格和数量
- 查看成本汇总和风险提示
- 点击"确认买入/卖出"提交订单

### 5. 查看订单
- 点击底部"订单"Tab
- 切换状态Tab查看不同订单
- 对待成交订单进行修改或撤单

### 6. 个人中心
- 点击底部"我的"Tab
- 访问出入金、设置、帮助等功能

## 下一步计划

### 高优先级 (P0)
- [ ] **StockDetailScreen** - 股票详情页（K线图、实时报价）
- [ ] **WebSocket 实时数据** - 连接 market-data 服务
- [ ] **Protobuf 集成** - 复用 `services/market-data/proto/market_data.proto`

### 中优先级 (P1)
- [ ] OrderDetailScreen - 订单详情页
- [ ] SearchScreen - 搜索页面
- [ ] SettingsScreen - 设置页面
- [ ] HelpScreen - 帮助页面
- [ ] Authentication - 登录/注册流程
- [ ] KYC Flow - 身份认证流程

### 低优先级 (P2)
- [ ] Notifications - 推送通知
- [ ] Biometric Auth - 生物识别集成
- [ ] Dark Mode - 深色模式完善
- [ ] Localization - 多语言支持
- [ ] Accessibility - 无障碍优化

## 项目文档

| 文档 | 说明 |
|------|------|
| `FINAL_IMPLEMENTATION_SUMMARY.md` | 完整实施总结 |
| `NAVIGATION_SUMMARY.md` | 导航系统总结 |
| `TEST_SUMMARY.md` | 测试报告 |
| `screens/README.md` | 目录结构文档 |
| `README.md` | 项目说明（本文档） |

## 技术文档

详细技术方案请参考 MetaMemory 文档：
- 文档 ID: `da8f4f35-9410-411c-87a8-74b1585e570d`
- 标题: 券商交易App移动端技术方案 - Kotlin Multiplatform + Compose Multiplatform

## 开发规范

### 金融计算
- ❌ 禁止使用 `Double` 或 `Float` 进行金融计算
- ✅ 必须使用 `BigDecimal`
- 美股价格：4 位小数
- 港股价格：3 位小数
- 金额：2 位小数

### 时间处理
- 所有时间戳存储为 UTC
- 仅在显示层转换为本地时区
- 使用 `kotlinx.datetime.Instant`

### 安全
- 敏感数据使用 `SecureStorage` 存储
- API 调用使用证书锁定
- 交易操作需要生物识别验证

## License

Proprietary - All rights reserved
