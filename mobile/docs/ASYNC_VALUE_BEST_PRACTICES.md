# AsyncValue 状态管理标准化指南

**Status**: 进行中 (In Progress)  
**优先级**: P1（架构必需补充）  
**工作量估算**: 1-2周  

---

## 现状分析

### 当前使用情况

✅ **已正确使用 AsyncValue 的地方**:
- `lib/features/market/presentation/screens/stock_detail_screen.dart` - 标准的 `.when()` 处理
- `lib/features/market/presentation/widgets/kline_chart_widget.dart` - 完整的 loading/error/data
- `lib/features/market/presentation/widgets/movers_tab.dart` - 规范使用

⚠️ **需要改进的地方**:
- 某些 provider 没有返回 Future/Stream（只返回同步值）
- UI 层中使用 `.asData?.value` 而不是 `.when()` 的地方
- 部分 notifier 中状态管理方式不一致

❌ **缺失的地方**:
- 全局错误处理（现在是分散在各个 `.when()` 中）
- AsyncValue 最佳实践文档
- 错误恢复标准（如重试、降级等）

---

## 标准模式

### 1. Provider 定义标准

```dart
// ✅ 标准: FutureProvider 形式
@riverpod
Future<List<Quote>> indexQuotes(Ref ref) async {
  final repo = ref.watch(marketRepositoryProvider);
  return repo.getIndexQuotes();
}

// ✅ 标准: StateNotifierProvider 形式
@riverpod
class WatchlistNotifier extends _$WatchlistNotifier {
  @override
  Future<List<Quote>> build() async {
    final repo = ref.watch(marketRepositoryProvider);
    return repo.getWatchlist();
  }
  
  Future<void> add({required String symbol, required String market}) async {
    // 状态更新逻辑
  }
}

// ❌ 错误: 返回同步值
@riverpod
String appVersion(Ref ref) => '1.0.0';  // 应该用 Provider 而不是 @riverpod

// ❌ 错误: 混合使用异步和同步
@riverpod
class QuoteNotifier extends _$QuoteNotifier {
  @override
  Quote build() {  // 返回同步 Quote 而不是 Future<Quote>
    return Quote.empty();
  }
}
```

### 2. UI 消费标准

```dart
// ✅ 标准模式 - 完整的 .when()
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(indexQuotesProvider);
    
    return quoteAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, stackTrace) => ErrorView(
        message: _formatError(error),
        onRetry: () => ref.invalidate(indexQuotesProvider),
      ),
      data: (quotes) => QuoteList(quotes: quotes),
    );
  }
}

// ✅ 简化模式 - .maybeWhen()（当某些分支不需要时）
final isLoading = quoteAsync.maybeWhen(
  loading: () => true,
  orElse: () => false,
);

// ⚠️ 危险模式 - .asData?.value（容易丢失状态）
final quotes = quoteAsync.asData?.value ?? [];  // 不推荐，改用 .when()

// ✅ 好的使用 - 结合 .map()
final quoteList = quoteAsync.map(
  loading: (_) => const LoadingWidget(),
  error: (err, stack) => const ErrorWidget(),
  data: (q) => QuoteWidget(quotes: q),
);
```

### 3. 错误处理标准

```dart
// ✅ 标准: 类型化的错误处理
quoteAsync.when(
  loading: () => _Loading(),
  error: (error, stack) {
    if (error is NetworkException) {
      return _NetworkError(
        message: '网络连接失败，请检查网络',
        onRetry: () => ref.invalidate(indexQuotesProvider),
      );
    } else if (error is AuthException) {
      return _AuthError(message: '认证失败，请重新登录');
    } else {
      return _GenericError(error: error);
    }
  },
  data: (quotes) => QuoteList(quotes: quotes),
);

// ❌ 错误: 忽略错误信息
error: (_, __) => const Text('出错了'),

// ❌ 错误: 信息泄露（打印技术细节）
error: (error, stack) => Text(error.toString()),  // 用户不需要看到完整 trace
```

### 4. 缓存与状态更新标准

```dart
// ✅ 标准: 手动失效缓存（用户主动刷新）
ElevatedButton(
  onPressed: () {
    ref.invalidate(indexQuotesProvider);
  },
  child: const Text('刷新'),
)

// ✅ 标准: 自动失效（依赖变化时）
@riverpod
Future<List<Quote>> quotesByMarket(Ref ref, String market) async {
  final repo = ref.watch(marketRepositoryProvider);
  return repo.getQuotesByMarket(market);  // market 变化时自动失效
}

// ✅ 标准: 带 keepAlive 的长期缓存
@Riverpod(keepAlive: true)
Future<AppConfig> appConfig(Ref ref) async {
  final repo = ref.watch(configRepositoryProvider);
  return repo.getConfig();  // 一旦加载就一直保持
}

// ✅ 标准: 自动清理（autoDispose）
@Riverpod(dependencies: [])
Future<List<Quote>> watchlist(Ref ref) async {
  // ...
  // Widget 销毁时自动清理缓存
}
```

---

## 实施计划

### Phase 1: 审计现有代码 (2-3 天)

```bash
# 1. 扫描所有不符合标准的 provider
grep -r "@riverpod\|@Riverpod" lib --include="*.dart" > audit.txt

# 2. 检查所有 UI 中非标准的 AsyncValue 消费
grep -r "\.asData\|\.maybeMap" lib --include="*.dart" | grep -v "\.when"

# 3. 检查缺少错误处理的 .when()
grep -rn "\.when(" lib --include="*.dart" | wc -l
```

### Phase 2: 标准化 Providers (4-5 天)

**任务 1: 同步转异步**
- 任何返回值的 provider 都应该是 FutureProvider（如果需要缓存）或普通 Provider
- 避免 @riverpod 返回同步值

**任务 2: 错误类型统一**
- 所有 provider 的错误都应该是已定义的异常类型
- 不应该抛出泛型 Exception

**任务 3: 缓存策略**
- 用户数据：autoDispose（用户退出时清理）
- 应用配置：keepAlive（全局配置）
- 市场数据：30s TTL 或 autoDispose

### Phase 3: 标准化 UI 消费 (4-5 天)

**任务 1: 替换所有 .asData?.value**
```dart
// 前
final quotes = quoteAsync.asData?.value ?? [];

// 后
final quotes = quoteAsync.maybeWhen(
  data: (q) => q,
  orElse: () => [],
);
```

**任务 2: 错误处理一致化**
```dart
// 对所有错误使用类型检查 + 用户友好的消息
error: (error, stack) {
  final message = switch (error) {
    NetworkException(:var message) => '网络错误: $message',
    AuthException(:var message) => '认证失败: $message',
    BusinessException(:var errorCode) => '业务错误 ($errorCode)',
    _ => '未知错误，请稍后重试',
  };
  return ErrorView(message: message, onRetry: onRetry);
}
```

**任务 3: 加载状态优化**
```dart
// 使用统一的加载骨架
loading: () => const _ListSkeleton(count: 5),

// 或使用全局加载组件
loading: () => const LoadingIndicator(),
```

### Phase 4: 文档 & 最佳实践 (2-3 天)

- 创建 `docs/ASYNC_VALUE_BEST_PRACTICES.md`
- 在 CLAUDE.md 中添加 AsyncValue 规范
- 创建 Lint 规则（custom_lint）来检测违规

---

## 检查清单

### Provider 层
- [ ] 所有 FutureProvider 都明确返回 Future<T>
- [ ] 所有 StateNotifier 都覆盖 build() 并返回异步值或初始值
- [ ] 没有 @riverpod 返回同步值（除非是 Provider）
- [ ] 所有 provider 都定义了清晰的缓存策略（keepAlive/autoDispose）

### UI 层
- [ ] 所有异步 provider 消费都使用 `.when()` 或 `.maybeWhen()`
- [ ] 没有 `.asData?.value` 的不安全访问
- [ ] 所有 error 分支都实现了错误类型检查
- [ ] 所有 loading 分支都显示适当的加载指示器

### 错误处理
- [ ] 没有泛型 Exception（所有都用 AppException 子类）
- [ ] 错误消息都是用户友好的（中文、无技术细节）
- [ ] 支持重试的错误都有 onRetry 回调
- [ ] 关键错误都记录到日志

### 文档
- [ ] 新的 ASYNC_VALUE_BEST_PRACTICES.md 已创建
- [ ] CLAUDE.md 已更新（添加 AsyncValue 规范部分）
- [ ] 所有公共 provider 都有使用示例
- [ ] 错误处理指南已文档化

---

## 预期收益

| 收益 | 描述 |
|------|------|
| **代码一致性** | 所有异步操作遵循统一模式，新人更容易理解 |
| **类型安全** | AsyncValue 强制处理 loading/error/data，减少 null 相关 bug |
| **错误透明性** | 清晰的错误消息和恢复选项提升用户体验 |
| **可维护性** | 标准化的缓存策略和失效逻辑，易于修改 |
| **测试友好** | AsyncValue 使 mock 和测试变得简单 |

---

## 参考资源

- Riverpod 官方文档: https://riverpod.dev/docs/essentials/first_request
- AsyncValue 文档: https://riverpod.dev/docs/essentials/managing_state
- 本项目 P0-2 缓存实现（参考）: `lib/features/market/data/quote_cache_repository_impl.dart`
- 本项目 stock_detail 屏幕（参考）: `lib/features/market/presentation/screens/stock_detail_screen.dart`

---

**所有者**: Mobile Engineer  
**完成日期**: TBD  
**验收标准**: 所有 provider/UI 都符合本指南规范，通过 lint 检查
