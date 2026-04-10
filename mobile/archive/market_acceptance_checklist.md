# Market 模块验收清单（Code Review 前）

**执行日期**: 2026-04-07  
**执行人**: [填写]  
**模块**: `lib/features/market/`

---

## 第一部分：自动化验证 ✅

### 1. 静态分析
```bash
cd mobile/src
flutter analyze --no-pub
```
- [x] 0 issues found
- **结果**: PASS (2026-04-07)

### 2. 单元测试
```bash
cd mobile/src
flutter test test/features/market/ --reporter=expanded
```
- [x] 191 tests passed
- [x] 0 tests failed
- **结果**: PASS (2026-04-07)

---

## 第二部分：功能完整性验证（需要运行 app）

### 3. 访客模式延迟标识（SEC 合规）
**测试步骤**:
1. 启动 app，不登录（访客模式）
2. 进入行情页 → 自选股 tab
3. 进入任意股票详情页

**验收标准**:
- [ ] 所有价格旁显示 "延迟 15 分钟" 标识
- [ ] 标识位置：价格右侧或下方，灰色小字
- [ ] K线图顶部也显示延迟提示

**检查文件**: 
- `lib/features/market/presentation/widgets/delayed_quote_banner.dart`
- `lib/features/market/presentation/screens/stock_detail_screen.dart`

---

### 4. WebSocket 断线自动重连
**测试步骤**:
1. 登录 app，进入行情页
2. 打开 Charles/Proxyman，启用 Breakpoint 拦截 WebSocket
3. 断开 WebSocket 连接（模拟网络中断）
4. 等待 5-10 秒
5. 恢复网络连接

**验收标准**:
- [ ] 断线后 UI 显示 "连接中断" 提示（不是白屏）
- [ ] 自动重连（无需用户手动刷新）
- [ ] 重连成功后实时数据恢复更新
- [ ] 日志显示重连次数（最多 3 次）

**检查文件**:
- `lib/features/market/application/quote_websocket_notifier.dart:164-186`

---

### 5. Stale Quote 警告
**测试步骤**:
1. 登录 app，进入行情页
2. 订阅一只股票（如 AAPL）
3. 暂停 WebSocket 推送 5 秒以上（模拟数据延迟）
4. 观察 UI 变化

**验收标准**:
- [ ] 当 `stale_since_ms >= 5000` 时，显示黄色警告 banner
- [ ] Banner 文案："行情数据可能延迟，正在重新连接..."
- [ ] 数据恢复后 banner 自动消失

**检查文件**:
- `lib/features/market/presentation/widgets/stale_quote_warning_banner.dart`
- `lib/features/market/domain/entities/quote.dart` (isStale getter)

---

### 6. 错误场景用户提示
**测试场景**:

#### 6.1 网络错误
- [ ] 飞行模式下打开行情页 → 显示 "网络连接失败，请检查网络设置"
- [ ] 提供 "重试" 按钮

#### 6.2 服务端错误
- [ ] 模拟 API 返回 500 → 显示 "服务暂时不可用，请稍后再试"
- [ ] 不显示技术错误堆栈

#### 6.3 搜索无结果
- [ ] 搜索不存在的股票代码 → 显示 "未找到相关股票"
- [ ] 不是空白页

#### 6.4 自选股为空
- [ ] 新用户首次进入自选股 tab → 显示引导文案 "添加自选股，快速查看关注的股票"
- [ ] 提供 "去搜索" 按钮

**检查文件**:
- `lib/features/market/presentation/screens/market_home_screen.dart`
- `lib/features/market/presentation/screens/search_screen.dart`

---

## 第三部分：集成测试

### 7. WebSocket 完整流程
**测试脚本**: `integration_test/market_websocket_test.dart`

```bash
cd mobile/src
flutter test integration_test/market_websocket_test.dart
```

**验收标准**:
- [ ] 连接 → 认证 → 订阅 → 接收推送 → 退订 → 关闭
- [ ] 每个步骤都有断言验证
- [ ] 测试通过

**状态**: ⚠️ 待创建集成测试文件

---

## 第四部分：性能测试

### 8. 100+ symbols 并发更新
**测试工具**: Flutter DevTools Performance

**测试步骤**:
1. 启动 app，连接 DevTools
2. 进入行情页，添加 100+ 只股票到自选股
3. 开启 WebSocket 实时推送
4. 观察 Performance 面板

**验收标准**:
- [ ] 帧率 ≥ 55 FPS（目标 60 FPS）
- [ ] UI 线程 CPU 占用 < 80%
- [ ] 无明显卡顿或掉帧

**检查点**:
- `ListView.builder` 使用了 `itemExtent` 优化
- `StockRowTile` 使用了 `const` 构造函数
- 价格更新使用了 `shouldRebuild` 优化

---

### 9. 内存泄漏检测
**测试工具**: Flutter DevTools Memory

**测试步骤**:
1. 启动 app，连接 DevTools
2. 进入行情页 → 退出 → 进入 → 退出（重复 10 次）
3. 观察 Memory 面板

**验收标准**:
- [ ] 内存占用稳定（不持续增长）
- [ ] 退出页面后 `QuoteWebSocketNotifier` 被正确 dispose
- [ ] 无 `StreamController` 泄漏

**检查文件**:
- `lib/features/market/application/quote_websocket_notifier.dart` (dispose 方法)

---

## 第五部分：安全审查

### 10. Security Engineer Review
**审查重点**:
- [ ] WebSocket 认证：JWT token 正确传递
- [ ] 证书固定：Dio 配置了 SPKI pinning
- [ ] 敏感数据：日志中无 token 泄漏
- [ ] 输入验证：搜索关键词做了 XSS 防护

**审查人**: `security-engineer` agent  
**状态**: ⚠️ 待提交

---

## 第六部分：代码审查

### 11. Code Reviewer Review
**审查重点**:
- [ ] 代码风格符合 `very_good_analysis`
- [ ] 所有 public API 有文档注释
- [ ] 错误处理完整（无 `catch (_)` 吞异常）
- [ ] 金额计算使用 `Decimal`（无 `double`）
- [ ] 时间戳使用 UTC（无 `DateTime.now()` 直接使用）

**审查人**: `code-reviewer` agent  
**状态**: ⚠️ 待提交

---

## 验收结论

### 当前状态
- ✅ 自动化验证：2/2 通过
- ✅ Mock Server：已创建并验证（commit 2905d66）
- ⚠️ 功能验证：0/5 完成（需要运行 app）
- ⚠️ 集成测试：待创建
- ⚠️ 性能测试：待执行
- ✅ 代码审查：已完成并修复所有问题（commit 122689d）

### Code Review 结果
**审查日期**: 2026-04-07  
**审查人**: code-reviewer agent  
**结论**: ✅ APPROVED（修复后）

**已修复问题**:
1. MAJOR: DateTime.now() 未使用 .toUtc() → 已修复（3 处）
2. MINOR: ValidationException const 阻止字符串插值 → 已修复
3. MINOR: 缺少 cachedAtMs UTC 文档注释 → 已添加

**审查亮点**:
- 完美使用 Decimal 处理金额
- WebSocket 错误处理健壮
- 资源清理正确（无内存泄漏）
- 文档注释完整

### Mock Server 验收结果
**测试日期**: 2026-04-07  
**测试方式**: API 自动化测试  
**结论**: ✅ PASS

**已验证**:
- ✅ REST API（搜索、涨跌榜、详情）
- ✅ 5 种策略（normal, guest, delayed, unstable, error）
- ✅ Guest 策略：delayed=true, 时间戳-15分钟
- ✅ Delayed 策略：stale_since_ms=6000
- ✅ 数据格式完整（price, change, delayed, stale_since_ms）

**详细报告**: 见 `MOCK_SERVER_ACCEPTANCE.md`

### 下一步行动
1. **立即执行**：功能验证（3-6 项）— 需要在模拟器/真机上运行 app
2. **创建集成测试**：`integration_test/market_websocket_test.dart`
3. **性能测试**：使用 DevTools 验证帧率和内存
4. **提交审查**：触发 `security-engineer` 和 `code-reviewer`

### 阻塞项
- [ ] 无后端环境（WebSocket 服务未部署）→ 需要 mock server 或等待后端就绪
- [ ] 无真实市场数据源 → 可以用 mock 数据验证 UI 逻辑

---

**签字确认**:
- 开发工程师: ____________ 日期: ______
- Code Reviewer: ____________ 日期: ______
- Security Engineer: ____________ 日期: ______
