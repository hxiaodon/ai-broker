# P2-6 实施计划: Unit Tests + Widget Tests

**优先级**: ⭐⭐⭐⭐⭐ (高)  
**工作量估计**: 3-4 weeks  
**目标覆盖率**: ≥70%

---

## 现状分析

### 已有的测试
```
✅ Domain 层单元测试 (35 tests)
  - SendOtpUseCase (14 tests)
  - VerifyOtpUseCase (11 tests)
  - RefreshTokenUseCase (12 tests)

✅ 错误处理单元测试 (26 tests)
  - ErrorSeverity, ErrorCategory, AppException hierarchy

✅ 集成测试 (25 tests)
  - API 集成 (10 tests)
  - E2E 测试 (15 tests)

❌ 缺失: Repository/DataSource 单元测试
❌ 缺失: Widget 测试 (UI 组件)
❌ 缺失: ViewModel/Notifier 测试
❌ 缺失: 业务逻辑测试 (Market, Portfolio)

总计: 86 个测试，覆盖率 ~30%
```

---

## Phase 1: Repository + DataSource 单元测试 (1 week)

### 目标
测试数据层，不依赖 UI 或网络

### 需要测试的 Repositories

#### 1. AuthRepository
**文件**: `lib/features/auth/data/auth_repository_impl.dart`

**单元测试**:
- [x] SendOtp 流程 (已有: SendOtpUseCase tests)
- [ ] VerifyOtp 流程 (已有: VerifyOtpUseCase tests)
- [ ] RefreshToken 流程 (已有: RefreshTokenUseCase tests)
- [ ] ClearTokens / 登出流程
- [ ] 异常处理 (网络错误、服务器错误)

**预估**: 10-12 个新测试

---

#### 2. MarketDataRepository (Market Quotes)
**文件**: `lib/features/market/data/market_data_repository_impl.dart`

**单元测试**:
- [x] getQuotes (API) - 已有缓存测试
- [ ] 单个 Symbol 获取
- [ ] 批量 Symbol 获取
- [ ] 缓存命中场景
- [ ] API 失败 → 缓存降级
- [ ] Decimal 精度保留
- [ ] 异常处理 (超时、网络等)

**预估**: 8-10 个新测试

---

#### 3. WatchlistRepository
**文件**: `lib/features/market/data/watchlist_repository_impl.dart`

**单元测试**:
- [ ] getWatchlist
- [ ] addToWatchlist (重复检查、限数检查)
- [ ] removeFromWatchlist
- [ ] reorderWatchlist
- [ ] 异常处理
- [ ] 本地存储与服务器同步

**预估**: 8-10 个新测试

---

#### 4. SearchRepository (搜索)
**文件**: `lib/features/market/data/search_repository_impl.dart`

**单元测试**:
- [ ] searchSymbols (关键词搜索)
- [ ] 搜索结果排序
- [ ] 缓存搜索历史
- [ ] 异常处理

**预估**: 6-8 个新测试

---

### Phase 1 总计
**新增测试**: 32-40 个  
**预估工作量**: 5-6 days

---

## Phase 2: Notifier + ViewModel 单元测试 (1 week)

### 目标
测试状态管理逻辑（不涉及 Widget）

### 需要测试的 Notifiers

#### 1. AuthNotifier
**文件**: `lib/features/auth/application/auth_notifier.dart`

**单元测试**:
- [ ] 初始状态 (splash → login/market based on auth)
- [ ] sendOtp 流程
- [ ] verifyOtp 流程
- [ ] 登出流程
- [ ] Token 刷新
- [ ] 错误状态处理

**预估**: 10-12 个测试

---

#### 2. WatchlistNotifier
**文件**: `lib/features/market/application/watchlist_notifier.dart`

**单元测试**:
- [ ] 初始加载
- [ ] add/remove/reorder 操作
- [ ] WebSocket 实时更新 (quote patching)
- [ ] 错误恢复
- [ ] 状态同步

**预估**: 12-15 个测试

---

#### 3. SearchNotifier
**文件**: `lib/features/market/application/search_notifier.dart`

**单元测试**:
- [ ] 搜索查询
- [ ] 搜索历史
- [ ] 延迟搜索 (debounce)
- [ ] 错误处理

**预估**: 8-10 个测试

---

#### 4. StockDetailNotifier
**文件**: `lib/features/market/application/stock_detail_notifier.dart`

**单元测试**:
- [ ] 初始加载
- [ ] WebSocket 实时更新
- [ ] K-line 数据加载
- [ ] 错误处理和重试

**预估**: 10-12 个测试

---

### Phase 2 总计
**新增测试**: 40-50 个  
**预估工作量**: 6-7 days

---

## Phase 3: Widget 测试 (1.5 weeks)

### 目标
测试关键 UI 组件的交互和状态

### 优先测试的 Widgets

#### 1. MarketHomeScreen
**文件**: `lib/features/market/presentation/screens/market_home_screen.dart`

**Widget 测试**:
- [ ] 初始渲染 (5 tabs)
- [ ] Tab 切换
- [ ] 自选股列表加载
- [ ] Index banner 显示
- [ ] 搜索导航
- [ ] 离线指示器

**预估**: 8-10 个测试

---

#### 2. WatchlistTab
**文件**: `lib/features/market/presentation/widgets/watchlist_tab.dart`

**Widget 测试**:
- [ ] 加载状态
- [ ] 错误状态
- [ ] 空列表
- [ ] Stock row 点击
- [ ] 编辑/删除

**预估**: 6-8 个测试

---

#### 3. StockDetailScreen
**文件**: `lib/features/market/presentation/screens/stock_detail_screen.dart`

**Widget 测试**:
- [ ] 初始加载
- [ ] 价格更新
- [ ] K-line 显示
- [ ] 加入自选
- [ ] 下单按钮 (若已实现)

**预估**: 8-10 个测试

---

#### 4. KlineChartWidget
**文件**: `lib/features/market/presentation/widgets/kline_chart_widget.dart`

**Widget 测试**:
- [ ] 图表渲染
- [ ] 加载状态
- [ ] 时间段切换 (1m/5m/15m/1h/1d)
- [ ] 实时数据更新

**预估**: 8-10 个测试

---

#### 5. AuthFlow Screens
**文件**: `lib/features/auth/presentation/screens/`

**Widget 测试**:
- [ ] LoginScreen: 手机输入、验证
- [ ] OtpInputScreen: OTP 输入、验证
- [ ] BiometricSetupScreen: 指纹/Face ID
- [ ] SplashScreen: 自动跳转

**预估**: 12-15 个测试

---

### Phase 3 总计
**新增测试**: 42-53 个  
**预估工作量**: 8-10 days

---

## Phase 4: 集成 + 覆盖率优化 (3-5 days)

### 目标
- 完整的端到端测试覆盖
- 达到 ≥70% 代码覆盖率

### 工作项
- [ ] 运行 `flutter test --coverage`
- [ ] 生成覆盖率报告
- [ ] 识别未覆盖的关键代码
- [ ] 补充缺失的测试
- [ ] 文档化测试最佳实践

---

## 总工作量统计

| Phase | 工作 | 新增测试 | 工作量 |
|-------|------|---------|--------|
| 1 | Repository 单元测试 | 32-40 | 5-6d |
| 2 | Notifier 单元测试 | 40-50 | 6-7d |
| 3 | Widget 测试 | 42-53 | 8-10d |
| 4 | 集成 + 覆盖率 | 0-10 | 3-5d |
| **总计** | | **114-153** | **22-28d (4-5.5 weeks)** |

### 预期结果
```
✅ 单元测试: 72-90 个 (+36 existing)
✅ Widget 测试: 42-53 个
✅ 总测试数: 200-230+ 个
✅ 覆盖率: ≥70%
✅ 总工作量: 4-5 weeks
```

---

## 测试框架和工具

### 已配置的工具
- ✅ `flutter_test` — 基础测试框架
- ✅ `mocktail` — Mock 库
- ✅ `integration_test` — 集成测试
- ✅ `fake_async` — 时间控制

### 需要考虑的额外工具
- [ ] `alchemist` — Widget 快照测试 (可选)
- [ ] `golden_toolkit` — Golden 文件管理 (可选)
- [ ] `test_utils` — 测试辅助库 (可选)

---

## 最佳实践

### 1. 单元测试结构
```dart
group('RepositoryName', () {
  group('method name', () {
    // 3个section: Happy Path / Edge Cases / Error Handling
    
    test('description', () {
      // Arrange
      // Act
      // Assert
    });
  });
});
```

### 2. Widget 测试结构
```dart
void main() {
  group('WidgetName', () {
    late MockDependency mockDep;
    
    setUp(() {
      mockDep = MockDependency();
    });
    
    testWidgets('description', (tester) async {
      // Arrange: pumpWidget + setup mocks
      // Act: interact with widget
      // Assert: verify state/UI
    });
  });
}
```

### 3. 命名规约
- 单元测试: `{name}_test.dart`
- Widget 测试: `{name}_widget_test.dart`
- Fixtures/Helpers: `{name}_test_helper.dart`

---

## 验收标准

### 代码层面
- ✅ 所有新增测试 PASS
- ✅ 覆盖率 ≥70%
- ✅ 0 个 lint 警告
- ✅ 测试执行时间 < 2 minutes (full suite)

### 文档层面
- ✅ 测试最佳实践指南
- ✅ Mock 数据说明
- ✅ 测试执行命令文档

### 过程层面
- ✅ 分阶段完成（每周一个 phase）
- ✅ CI/CD 集成验证
- ✅ 代码审查通过

---

## 实施时间表

| Week | Phase | 目标 | 新增测试 |
|------|-------|------|----------|
| 2026-04-21 | 1 | Repository 单元测试 | 32-40 |
| 2026-04-28 | 2 | Notifier 单元测试 | 40-50 |
| 2026-05-05 | 3 | Widget 测试 (Part 1) | 20-25 |
| 2026-05-12 | 3 + 4 | Widget 测试 (Part 2) + 覆盖率 | 22-28 + 0-10 |

**预期完成日期**: 2026-05-19

---

## 相关文档

- [ASYNC_VALUE_BEST_PRACTICES.md](./ASYNC_VALUE_BEST_PRACTICES.md) — 状态管理标准
- [INTEGRATION_TEST_GUIDE.md](./INTEGRATION_TEST_GUIDE.md) — 集成测试指南
- [TESTING_PRACTICES.md](./TESTING_PRACTICES.md) — 测试最佳实践
- [mobile/CLAUDE.md](../mobile/CLAUDE.md) — 三层测试分类

---

**创建日期**: 2026-04-14  
**下次更新**: 2026-04-21 (Phase 1 进度评估)
