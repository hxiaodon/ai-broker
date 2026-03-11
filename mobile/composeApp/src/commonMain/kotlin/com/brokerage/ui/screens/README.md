# UI Screens 目录结构

> 基于产品设计文档 v2.0 调整后的目录结构

## 目录映射

### 主要 Tab（4个）

```
composeApp/ui/screens/
├── market/          # Tab 1: 行情
│   ├── MarketScreen.kt           # 行情列表页（自选/美股/港股/热门）
│   ├── SearchScreen.kt           # 搜索页
│   └── StockDetailScreen.kt      # 股票详情页
│
├── orders/          # Tab 2: 订单
│   ├── OrdersScreen.kt           # 订单列表页
│   └── OrderDetailSheet.kt       # 订单详情弹窗
│
├── portfolio/       # Tab 3: 持仓
│   ├── PortfolioScreen.kt        # 持仓列表页
│   └── AnalysisTab.kt            # 持仓分析 Tab
│
└── account/         # Tab 4: 我的
    ├── AccountScreen.kt          # 个人信息页
    ├── FundingScreen.kt          # 出入金页（从独立 Tab 移至此处）
    └── SettingsScreen.kt         # 设置页
```

### 辅助页面

```
├── auth/            # 登录/注册
│   ├── LoginScreen.kt            # 登录页
│   └── RegisterScreen.kt         # 注册页
│
├── kyc/             # KYC 认证流程（7步）
│   ├── IdentityScreen.kt         # 1. 身份信息
│   ├── DocumentUploadScreen.kt   # 2. 证件上传
│   ├── FaceRecognitionScreen.kt  # 3. 人脸识别
│   ├── AddressProofScreen.kt     # 4. 地址证明
│   ├── InvestorAssessmentScreen.kt # 5. 投资者评估
│   ├── RiskDisclosureScreen.kt   # 6. 风险披露
│   └── AgreementScreen.kt        # 7. 协议签署
│
└── trade/           # 交易下单（从股票详情页进入）
    └── TradeScreen.kt            # 交易下单页
```

## HTML 原型映射

| HTML 文件 | Compose Screen | 说明 |
|-----------|----------------|------|
| `index.html` | `MainScreen.kt` | 主页面（Tab 导航容器） |
| `login.html` | `auth/LoginScreen.kt` | 登录页 |
| `market.html` | `market/MarketScreen.kt` | 行情列表页 |
| `search.html` | `market/SearchScreen.kt` | 搜索页 |
| `stock-detail.html` | `market/StockDetailScreen.kt` | 股票详情页 |
| `trade.html` | `trade/TradeScreen.kt` | 交易下单页 |
| `orders.html` | `orders/OrdersScreen.kt` | 订单列表页 |
| `portfolio.html` | `portfolio/PortfolioScreen.kt` | 持仓页 |
| `funding.html` | `account/FundingScreen.kt` | 出入金页 |

## 设计调整说明

### 从设计文档 v1.0 到 v2.0 的变化

1. **"交易" Tab → "订单" Tab**
   - 原来的 `trading/` 目录已删除
   - 新增 `orders/` 目录专注订单管理
   - 快速下单入口移至股票详情页

2. **出入金降级**
   - 从独立 Tab 降级为"我的" Tab 下的子页面
   - 原来的 `fund/` 目录已删除
   - 移至 `account/FundingScreen.kt`

3. **新增 KYC 流程**
   - 新增 `kyc/` 目录，包含 7 个认证步骤
   - 符合监管要求（SEC/SFC）

4. **搜索功能独立**
   - 从行情页分离出独立的搜索页
   - 支持全局搜索（代码/名称/拼音）

## 下一步实现顺序

1. ✅ 调整目录结构
2. ⏳ 实现 Design System Token（颜色/字体/间距）
3. ⏳ 实现核心 UI 组件（Button/Card/Input）
4. ⏳ 实现第一个完整页面（MarketScreen）
5. ⏳ 逐步实现其他页面
