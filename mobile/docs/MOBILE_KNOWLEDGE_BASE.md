# Mobile 知识库 — 架构、可观测性、验收标准

**编译日期**: 2026-04-10  
**来源**: temp/ 目录临时文档整合  
**面向**: 后续 Mobile 功能开发、测试、Code Review

---

## I. 项目现状快速掌握

### A. 架构与代码质量基线（2026-04-10）

| 指标 | 状态 | 备注 |
|-----|------|------|
| **单元测试** | ✅ 299 通过，0 失败 | All tests passing |
| **代码检查** | ✅ 24 个警告（均可接受） | 集成测试中的 print 语句 |
| **生产路径** | ✅ 已测试覆盖 | Auth flow, Market data WebSocket, Routing |
| **P0 阻塞项** | ✅ 全部已解决 | 见下文关键解决方案 |

### B. 模块完成度（截至 2026-04-09）

| 模块 | 完成度 | 状态 | 备注 |
|------|--------|------|------|
| **Auth** | 100% | ✅ 生产就绪 | 登录/OTP/生物识别设置，E2E 测试通过 |
| **Market (行情)** | 90% | ✅ 代码完成 | 代码、单元测试、API 集成测试完成；UI 功能测试 80% |
| **KYC/Trading/Portfolio** | 0% | ⚠️ 骨架 | 路由存在，UI 暂未实现 |
| **Funding** | 0% | ⚠️ 骨架 | 路由存在，UI 暂未实现 |
| **Settings** | 0% | ⚠️ 骨架 | 路由存在，UI 暂未实现 |

### C. 生产就绪的核心流程

✅ **Auth 流程** → 登录 → OTP → 生物识别注册 → Token 存储  
✅ **行情 WebSocket** → 实时连接 → 自动重连 → 行情推送  
✅ **网络错误处理** → 统一在 remote data sources 处理 → 保留上下文（e.g., OTP 剩余尝试次数）

---

## II. 关键架构决策

### A. 网络层架构

**DioClient 正确注入**
- `DioClient.create()` 接收 `TokenService` 的 token 读/刷新回调
- `AuthInterceptor` 通过依赖注入获得回调，NOT 直接访问 TokenService
- 所有 Repository providers 使用正确注入的 DioClient 实例

**核心文件**
- `lib/core/network/dio_client.dart` — 正确的 DioClient 创建逻辑
- `lib/core/network/auth_interceptor.dart` — 回调注入方式
- `lib/core/auth/token_service.dart` — Token 生命周期回调提供者

**已删除的反模式**
- ❌ `lib/core/network/error_interceptor.dart` — 双重处理异常，已删除
- ✅ 错误处理现在仅在 remote data sources 进行

### B. 路由与守卫

**正确的守卫实现**
- 使用 `appRouterRedirect()` 函数强制执行认证边界
- 已有 100% 测试覆盖（`app_router_redirect_test.dart`）

**已删除的反模式**
- ❌ `RouteGuards` 类（未被生产路由使用）
- ❌ 相关的 `route_guards_test.dart`

**文件**
- `lib/core/routing/app_router.dart` — 生产路由逻辑

### C. 状态管理（Riverpod）

**SearchNotifier 初始化 bug — 已修复**
- 问题：async 初始化在 `build()` 方法中，导致时序 bug
- 修复：将 `_loadHotStocks()` 移至单独的初始化生命周期
- 现在：Provider 返回稳定的初始状态，再异步加载

**文件**
- `lib/features/market/application/search_notifier.dart`

---

## III. 可观测性改进（已实施）

### A. 关键基础设施（HIGH 优先级）✅

#### 1. 请求关联 ID (Correlation ID)
```dart
// lib/core/network/dio_client.dart
// 每个 HTTP 请求携带唯一 UUID：X-Request-ID 头
// 用途：关联客户端和服务端日志
```

#### 2. WebSocket 连接超时保护
```dart
// lib/features/market/data/websocket/quote_websocket_client.dart
// await _channel!.ready.timeout(Duration(seconds: 10))
// 防止弱网下无限挂起
```

#### 3. 完整的日志记录
- HTTP 请求/响应/错误 → 带 correlation ID
- WebSocket 连接状态变化
- OTP 错误详情（剩余尝试次数）
- 搜索操作日志

#### 4. 错误上下文保留
```dart
// 示例：OTP 错误
// 异常包含：remainingAttempts, retryAfter
// 从 HTTP 400 响应传递给 UI，完整保留
```

#### 5. 设备内存和 WebSocket 健康监控
- WebSocket 最后 pong 时间跟踪
- 重连逻辑中的健康检查

### B. 端到端错误传播（MEDIUM 优先级）✅

| 错误类型 | 处理位置 | 日志级别 | 用户可见 |
|---------|---------|---------|---------|
| 网络不可达 | Remote DS | warning | ✅ |
| 超时 | Remote DS | warning | ✅ |
| 401 (Token 过期) | AuthInterceptor → Remote DS | info | ✅ |
| 业务错误（e.g., OTP 失败） | Remote DS | warning | ✅ |
| 未知异常 | Remote DS | error | ✅ |

### C. 日志质量提升（LOW 优先级）✅

- 所有日志使用 `AppLogger` (结构化)
- PII 字段掩码（SSN、Token、密码）
- 按优先级分类：error > warning > info > debug

---

## IV. 测试标准与验收清单

### A. Market 模块验收标准（参考）

#### 自动化验证
```bash
# 1. 静态分析
cd mobile/src && flutter analyze --no-pub
# 预期：0 issues

# 2. 单元测试
cd mobile/src && flutter test test/features/market/ --reporter=expanded
# 预期：191 tests passed, 0 failed

# 3. Lint 检查
flutter analyze lib/features/market/
# 预期：0 issues in lib code (test code prints are acceptable)
```

#### 功能测试清单
- [ ] 访客模式下，所有价格显示"延迟 15 分钟"标识
- [ ] WebSocket 断线自动重连（5 秒内）
- [ ] 搜索功能返回热股票 + 输入匹配的股票
- [ ] 自选股加载（从缓存 / 从 API）
- [ ] 股票详情页显示正确的 K 线图和实时行情

#### Mock Server 策略
```bash
# 可用策略
./start.sh guest        # 延迟数据（游客模式）
./start.sh loggedIn     # 实时数据（登录用户）
./start.sh slowNetwork  # 模拟弱网
./start.sh offline      # 离线模式
./start.sh errorRate    # 5% 错误率

# 启动
cd mobile/mock-server && ./start.sh <strategy>
# REST API: http://localhost:8080
# WebSocket: ws://localhost:8080/ws/market-data
```

### B. Code Review 清单（所有模块）

#### 必做项
- [ ] Decimal 用于所有金钱计算（never `double`）
- [ ] 所有时间戳为 UTC（never `DateTime.now()` 没有 `.toUtc()`）
- [ ] HTTP 错误不吞咽（wrap with context）
- [ ] PII 字段在日志中掩码
- [ ] 幂等性：state-changing 操作带 Idempotency-Key

#### Auth/Trading 模块额外项
- [ ] 生物识别认证是否需要（Secure Storage for tokens）
- [ ] Token 刷新逻辑是否正确（在 AuthInterceptor 中）
- [ ] Rate limiting 是否在服务端实现

#### Market/Real-time 模块额外项
- [ ] WebSocket 连接是否有超时保护
- [ ] 重连逻辑是否指数退避
- [ ] 消息顺序是否保证（单线程）

---

## V. 常见陷阱与已知限制

### A. 生产不就绪的组件 ⚠️

#### Biometric Key Manager（生物识别密钥管理）
```dart
// lib/core/auth/biometric_key_manager.dart (lines 30-33)
// Phase 1: 总是返回 null/false，NOT 生产就绪
// Phase 2 后续计划：
//   - iOS: Secure Enclave (SecKey) via Method Channel
//   - Android: Android Keystore via platform integration
```
**行动**: 不要在生产环境使用；UI 暂时接受 `stub_signature`

#### SSL/TLS 证书钉扎（Certificate Pinning）
```dart
// lib/core/security/ssl_pinning_config.dart (lines 23-26)
// Phase 1: PLACEHOLDER_*_PIN 占位符值
// SPKI 提取逻辑是近似的（哈希全部 cert DER，非真实 SPKI 字段）
```
**行动**: 生产前替换为真实指纹，使用 ASN.1 解析器提取真实 SPKI 字段

### B. 骨架模块（UI 未实现）

这些模块的路由已建立，但 UI 还是 `_Placeholder('Tab Name')`：
- KYC
- Trading
- Portfolio  
- Settings

**行动**: 按优先级实现；H5 WebView 方案参考 `docs/specs/shared/h5-vs-native-decision.md`

### C. 集成测试分离

- 单元测试：`test/` 目录，99% 绿色，不依赖 localhost
- 集成测试：`integration_test/` 目录，需要 Mock Server 或真实 API
- **重要**: 仅提交通过的单元测试；集成测试用于 CI/CD 验证

---

## VI. 文件导航速查

### 核心文件（必读）

| 目的 | 文件 |
|------|------|
| Network 层架构 | `lib/core/network/dio_client.dart` |
| Auth 流程 | `lib/features/auth/` |
| 行情 WebSocket | `lib/features/market/data/websocket/quote_websocket_client.dart` |
| 路由与守卫 | `lib/core/routing/app_router.dart` |
| 日志 | `lib/core/logger/app_logger.dart` |
| Riverpod 提供者 | `lib/core/providers/` |

### 测试文件

| 目的 | 文件 |
|------|------|
| Auth 端到端 | `integration_test/auth_flow_test.dart` |
| 路由逻辑 | `test/core/routing/app_router_redirect_test.dart` |
| 市场数据 | `test/features/market/` (191 tests) |

### 设计与规范

| 文件 | 用途 |
|------|------|
| `mobile/CLAUDE.md` | 域级指南 |
| `docs/prd/` | 产品需求文档 (8 个模块) |
| `docs/specs/shared/` | 技术架构、JSBridge 等 |
| `prototypes/` | 交互式 HTML 原型 |

---

## VII. 后续功能开发流程

### 新功能推荐流程

1. **PM 审批** → PRD 确认（见 `docs/prd/`）
2. **UI 设计** → HTML 高保真原型（见 `prototypes/`）
3. **Mobile 工程师** → Flutter 实现
   - 必读：PRD + 高保真原型 + tech-spec
   - 遵循：Decimal for money, UTC for timestamps, Riverpod patterns
4. **Code Review** → 使用本文档的检查清单
5. **测试** → 单元测试（必须通过）+ 集成测试（推荐）
6. **合并** → 到 main 分支

### 常见问题快查

**Q: 如何添加新的 Riverpod provider？**  
A: 见 `lib/core/providers/`；使用 `@riverpod` 注解，必须有单元测试

**Q: 如何处理网络错误？**  
A: 在 remote data source 中捕获 `DioException`，映射到 domain exception，保留上下文

**Q: 如何添加日志？**  
A: 使用 `AppLogger.info/warning/error()`；PII 字段要掩码

**Q: Mock Server 如何启动？**  
A: 见本文档第 IV.A 部分

---

## VIII. 贡献者笔记

本文档整合自以下临时文档（已在 `mobile/temp/` 归档）：

- `REVIEW_CLOSURE_2026-04-10.md` — P0 项目闭合、测试状态
- `OBSERVABILITY_FINAL_REPORT.md` — 可观测性改进 20/20 项
- `OBSERVABILITY_IMPROVEMENTS_PLAN.md` — 可观测性计划详情
- `MARKET_MODULE_SUMMARY.md` — 行情模块完成度、验收
- `FINAL_ACCEPTANCE_REPORT.md` — 行情模块 Code Review 结果
- `market_acceptance_checklist.md` — 行情模块验收清单
- `TESTING_RECORD.md` — 功能测试记录（手工验收）

**更新者**: Mobile 工程师 (Claude)  
**上次更新**: 2026-04-10  
**下次审查**: 2026-05-10（或当新功能模块完成时）
