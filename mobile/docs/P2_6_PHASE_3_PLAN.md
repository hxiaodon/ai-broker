# P2-6 Phase 3 实施计划: Widget 单元测试

**优先级**: ⭐⭐⭐⭐⭐ (高)  
**工作量估计**: 8-10 days  
**目标覆盖率**: ≥70%
**时间线**: 2026-05-05 ~ 2026-05-12

---

## 现状分析

### 已有测试
```
✅ Domain 层单元测试 (35 tests)
✅ Repository 层单元测试 (49+ tests)
✅ Notifier 层单元测试 (124 tests)
❌ Widget 层单元测试 (0 tests)
❌ UI 交互测试 (0 tests)
❌ 状态更新验证 (0 tests)

总计: 208 个测试，覆盖率 ~35%
```

### Phase 3 目标
- **新增测试**: 42-53 个 Widget 单元测试
- **覆盖率**: 提升至 ≥70%
- **重点**: 市场、自选股、交易、搜索、个人资料屏幕

---

## Phase 3 实施分解

### Part 1: 市场屏幕 (8-10 days)

#### 1.1 WatchlistTab (6-8 tests)
**文件**: `lib/features/market/presentation/widgets/watchlist_tab.dart`

**测试场景**:
- ✅ 加载状态 - 显示 loading indicator
- ✅ 空状态 - 自选股为空时显示提示
- ✅ 数据显示 - 正确显示股票列表
- ✅ 用户交互 - 点击股票项目触发回调
- ✅ 权限控制 - 认证用户显示编辑按钮，游客不显示
- ✅ 实时更新 - WebSocket 更新时价格刷新
- ✅ 错误处理 - 网络错误显示错误提示
- ✅ 重试功能 - 错误后可重试

**依赖**:
- `watchlistRepositoryProvider`
- `wsClientFactoryProvider`
- `tokenServiceProvider`
- `authProvider`

---

#### 1.2 MarketHomeScreen (8-10 tests)
**文件**: `lib/features/market/presentation/screens/market_home_screen.dart`

**测试场景**:
- ✅ 初始渲染 - 显示 5 个 Tab (自选、热门、涨幅榜、跌幅榜、港股)
- ✅ Tab 切换 - 切换 Tab 时内容更新
- ✅ 自选 Tab - 正确显示 WatchlistTab
- ✅ 热门 Tab - 显示热门股票列表
- ✅ 涨幅榜 Tab - 显示涨幅榜
- ✅ 跌幅榜 Tab - 显示跌幅榜
- ✅ 港股 Tab - 显示 "coming soon"
- ✅ 离线指示器 - 无网络时显示离线提示
- ✅ 导航 - 点击股票导航到详情页

**依赖**:
- `watchlistProvider`
- `indexQuotesProvider`
- `moversProvider`
- `authProvider`

---

#### 1.3 Index Banner (2-3 tests)
**文件**: `lib/features/market/presentation/screens/market_home_screen.dart` (私有 _IndexBanner)

**测试场景**:
- ✅ 显示指数 - 上证指数、恒生指数价格
- ✅ 指数变化 - 涨跌幅度和百分比
- ✅ 实时更新 - 指数数据刷新

---

### Part 2: 股票详情和搜索 (Days 5-8)

#### 2.1 StockDetailScreen (8-10 tests)
**文件**: `lib/features/market/presentation/screens/stock_detail_screen.dart`

**测试场景**:
- ✅ 初始加载 - 显示股票详情加载状态
- ✅ 股票信息 - 显示股票名称、价格、涨跌
- ✅ K线图表 - 显示 K 线图表
- ✅ 时间段切换 - 1m/5m/15m/1h/1d 切换
- ✅ 加入自选 - 点击加入自选按钮
- ✅ 移除自选 - 点击移除自选按钮
- ✅ 下单按钮 - 显示下单界面
- ✅ 实时报价 - WebSocket 更新价格
- ✅ 错误处理 - 股票不存在显示错误

**依赖**:
- `stockDetailProvider`
- `klineProvider`
- `watchlistProvider`
- `authProvider`

---

#### 2.2 KlineChartWidget (8-10 tests)
**文件**: `lib/features/market/presentation/widgets/kline_chart_widget.dart`

**测试场景**:
- ✅ 图表渲染 - 正确显示 K 线图表
- ✅ 加载状态 - 加载时显示 skeleton
- ✅ 时间段按钮 - 5 个时间段选择按钮
- ✅ 时间段切换 - 切换时更新图表
- ✅ 实时更新 - 新 K 线到达时刷新
- ✅ 空数据 - 没有 K 线数据时显示提示
- ✅ 错误处理 - K 线加载失败显示错误

---

#### 2.3 SearchScreen (6-8 tests)
**文件**: `lib/features/market/presentation/screens/search_screen.dart`

**测试场景**:
- ✅ 搜索框 - 输入框可以输入
- ✅ 搜索结果 - 输入后显示匹配的股票
- ✅ 历史记录 - 显示搜索历史
- ✅ 清空历史 - 清空历史记录功能
- ✅ 防抖搜索 - 快速输入时防抖生效
- ✅ 市场标志 - 显示 US/HK 市场标志
- ✅ 导航 - 点击搜索结果导航到详情页

**依赖**:
- `searchProvider`
- `authProvider`

---

### Part 3: 认证和个人资料 (Days 9-10)

#### 3.1 LoginScreen (4-5 tests)
**文件**: `lib/features/auth/presentation/screens/login_screen.dart`

**测试场景**:
- ✅ 手机输入 - 国家码 + 手机号输入
- ✅ 发送 OTP - 点击发送 OTP 按钮
- ✅ 表单验证 - 手机号格式验证
- ✅ 错误处理 - 无效手机号显示错误
- ✅ 游客模式 - 游客模式跳过登录

---

#### 3.2 OtpInputScreen (4-5 tests)
**文件**: `lib/features/auth/presentation/screens/otp_input_screen.dart`

**测试场景**:
- ✅ OTP 输入 - 6 位数字输入
- ✅ 自动焦点 - 输入满 6 位自动验证
- ✅ 倒计时 - 显示重新发送倒计时
- ✅ 错误处理 - 错误 OTP 显示提示
- ✅ 重新发送 - 重新发送 OTP 功能

---

#### 3.3 BiometricSetupScreen (3-4 tests)
**文件**: `lib/features/auth/presentation/screens/biometric_setup_screen.dart`

**测试场景**:
- ✅ 指纹提示 - 显示指纹识别提示
- ✅ Face ID 提示 - 显示面部识别提示
- ✅ 启用按钮 - 启用生物识别按钮
- ✅ 跳过按钮 - 跳过设置按钮

---

## 测试框架和工具

### 已配置
- ✅ `flutter_test` — 基础测试框架
- ✅ `mocktail` — Mock 库
- ✅ `flutter_riverpod` — 状态管理

### 测试方法论

#### 1. Provider 覆盖
```dart
ProviderScope(
  overrides: [
    // 覆盖认证状态
    authProvider.overrideWithValue(
      const AuthState.authenticated(...),
    ),
    // 覆盖数据源
    watchlistRepositoryProvider.overrideWith((_) => mockRepo),
  ],
  child: MaterialApp(
    home: YourWidget(),
  ),
)
```

#### 2. 异步操作处理
```dart
// 加载数据
await tester.pumpAndSettle();

// 等待特定文本
await tester.waitFor(find.text('Loading...'));

// 交互后等待
await tester.tap(find.byIcon(Icons.edit));
await tester.pumpAndSettle();
```

#### 3. 事件模拟
```dart
// 点击
await tester.tap(find.text('Button'));

// 输入
await tester.enterText(find.byType(TextField), 'text');

// WebSocket 更新
wsStream.add(WsQuoteUpdate(...));
```

---

## 验收标准

### 代码层面
- ✅ 所有新增测试 PASS
- ✅ 覆盖率 ≥70%
- ✅ 0 个 lint 警告
- ✅ 测试执行时间 < 2 minutes (full suite)

### 文档层面
- ✅ Widget 测试指南
- ✅ Mock 数据说明
- ✅ 常见问题解答

### 过程层面
- ✅ Part 1 完成 (WatchlistTab + MarketHomeScreen)
- ✅ Part 2 完成 (StockDetailScreen + SearchScreen)
- ✅ Part 3 完成 (AuthFlow)
- ✅ CI/CD 验证
- ✅ 代码审查通过

---

## 风险和缓解

### 风险 1: Provider 复杂性
**问题**: Widget 测试需要覆盖许多 Riverpod Provider  
**缓解**: 创建 Helper 函数简化 override 代码

### 风险 2: 异步竞态条件
**问题**: Widget 更新可能不同步  
**缓解**: 使用 `pumpAndSettle()` 和显式等待

### 风险 3: 自定义 Widget 测试
**问题**: 自定义组件可能难以测试  
**缓解**: 将复杂逻辑提取到 Notifier，Widget 纯展示

---

## 下一步行动

### 本周 (Week of 2026-04-14)
- [ ] 完成 Part 1: WatchlistTab 和 MarketHomeScreen
- [ ] 修复 Provider override 导入问题
- [ ] 创建测试 Helper 工具库

### 下周 (Week of 2026-04-21)
- [ ] 完成 Part 2: StockDetailScreen 和 SearchScreen
- [ ] 运行覆盖率报告
- [ ] 识别覆盖率空白区

### Week of 2026-04-28
- [ ] 完成 Part 3: AuthFlow Screens
- [ ] Phase 4: 集成 + 覆盖率优化
- [ ] 达成 ≥70% 目标

---

## 相关文档

- [P2_6_PHASE_1_COMPLETION_REPORT.md](./P2_6_PHASE_1_COMPLETION_REPORT.md) — Repository 测试
- [P2_6_PHASE_2_COMPLETION_REPORT.md](./P2_6_PHASE_2_COMPLETION_REPORT.md) — Notifier 测试
- [ASYNC_VALUE_BEST_PRACTICES.md](./ASYNC_VALUE_BEST_PRACTICES.md) — 状态管理标准
- [TESTING_PRACTICES.md](./TESTING_PRACTICES.md) — 测试最佳实践

---

**创建日期**: 2026-04-14  
**预计完成**: 2026-05-12  
**状态**: 规划中 📋
