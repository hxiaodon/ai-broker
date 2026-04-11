# 集成测试实践指南

本文档补充 [INTEGRATION_TEST_GUIDE.md](./INTEGRATION_TEST_GUIDE.md)，提供实践经验、故障排查和合规性验证。

## 概述

三种测试类型已在 [INTEGRATION_TEST_GUIDE.md](./INTEGRATION_TEST_GUIDE.md) 中定义。本文档强调：

- 如何在真实项目中应用这些标准
- 手动测试清单（集成测试的补充）
- CI/CD 集成
- 故障排查

---

## 📋 Auth 模块测试覆盖

### ✅ 已通过的自动化测试

- **状态管理**: 15 tests - App renders correctly in different auth states
- **API集成**: 8 tests - OTP flow, biometric, device management, lockout
- **E2E**: 5 journeys - Complete user flows from UI to app state

**总计**: 28/28 tests passing ✅

### ⚠️ 需要手动测试的场景

这些场景无法在集成测试中有效模拟：

#### 生物识别
- [ ] Face ID/Touch ID 在真实设备上工作
- [ ] 生物识别失败后正确显示错误
- [ ] 注册新生物识别后立即可用

#### 短信 OTP
- [ ] OTP 在 10 秒内接收
- [ ] OTP 自动填充（iOS：系统提示，Android：Smart Auth）
- [ ] 过期 OTP 显示"已过期"消息

#### 账户锁定
- [ ] 5 次错误尝试后锁定 30 分钟
- [ ] 30 分钟后账户自动解锁
- [ ] 锁定期间显示倒计时

#### 多设备推送
- [ ] 新设备登录后，旧设备 30 秒内收到推送
- [ ] 推送包含设备名称和位置
- [ ] 用户可批准或拒绝

---

## 📊 Market 模块测试覆盖

### ✅ 自动化测试

- **状态管理**: Market data loading, watchlist operations
- **API集成**: Quote fetching, search, WebSocket connection
- **E2E**: Real user flows with market data

### ⚠️ 手动测试

#### WebSocket 实时更新
- [ ] 行情每 1-2 秒更新一次
- [ ] 网络切换时数据不中断（WiFi → 4G）
- [ ] 断线后自动重连（< 5 秒）

#### 性能
- [ ] 100+ 自选股列表滑动流畅（> 55 FPS）
- [ ] K-线图切换响应 < 1 秒
- [ ] 搜索响应 < 500 ms

#### 延迟数据标识
- [ ] 数据 ≥ 5 秒未更新时显示"延迟"标志
- [ ] 访客模式显示 15 分钟延迟
- [ ] 盘后显示"盘后行情"标识

---

## 🔐 交叉模块测试

### ✅ 自动化测试

- **访客限制**: 交易按钮禁用，自选股只读
- **Token 管理**: 自动刷新，过期重新登录
- **状态转换**: 访客 → 认证 → 登出

### ⚠️ 手动测试

#### 访客升级认证
- [ ] 访客自选股在登录后自动导入到用户账号
- [ ] 登录后行情源从延迟改为实时
- [ ] 之前的市场浏览历史保留

#### Token 过期重新登录
- [ ] Token 过期时 WebSocket 自动重连
- [ ] 显示"已断开连接"并提示重新登录
- [ ] 登录后恢复之前的 WebSocket 连接

---

## 🛠️ 故障排查

### 问题 1: Mock Server 无法启动

**错误**: `Address already in use`

**解决**:
```bash
# 查看占用的进程
lsof -i :8080

# 杀死进程
kill -9 <PID>

# 或使用不同的端口
go run . --port=9090
```

### 问题 2: Flutter 连接 Mock Server 超时

**错误**: `Connection timed out`

**原因**: 
- 模拟器使用 `localhost` 而不是 `10.0.2.2` (Android)
- 真机使用 `localhost` 而不是电脑 IP

**解决**:
```dart
// Android 模拟器
const API_URL = 'http://10.0.2.2:8080';

// iOS 模拟器或真机
const API_URL = 'http://<your-ip>:8080';
```

### 问题 3: E2E 测试找不到 UI 元素

**错误**: `Expected: at least one matching candidate`

**原因**: App 的 UI 结构与测试假设不符

**解决**:
1. 运行测试并观察错误消息中的"Possible finders"
2. 使用建议的 finder 更新测试
3. 如果 UI 是自定义 widget，使用 `find.byType(CustomWidget)` 或 `find.byKey()`

### 问题 4: 集成测试超时

**错误**: `Timeout after X seconds`

**解决**:
```bash
# 增加超时时间
flutter test integration_test/ --timeout=30m

# 或检查 Mock Server 性能
go run . --strategy=delayed  # 模拟慢服务器
```

---

## 📈 CI/CD 集成

### GitHub Actions 工作流

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  integration-test:
    runs-on: macos-latest  # 支持 iOS 模拟器
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.4'
      
      - name: Start Mock Server
        run: |
          cd mobile/mock-server
          go run . --strategy=normal &
          sleep 2  # 等待服务器启动
      
      - name: Run Integration Tests
        run: |
          cd mobile/src
          flutter test integration_test/ --verbose
```

### 阶段式测试策略

**PR 检查** (快速反馈):
```bash
# 仅运行状态管理测试 (~30s)
flutter test integration_test/**/*/state_management_test.dart
```

**合并前** (完整验证):
```bash
# 运行状态管理 + API 测试 (~30s)
flutter test integration_test/**/*/state_management_test.dart
flutter test integration_test/**/*/api_integration_test.dart
```

**发布前** (完整测试):
```bash
# 运行所有测试 (~60s)
flutter test integration_test/
```

---

## 🎯 PRD 合规性验证清单

### Auth 模块

- [ ] 登录流程 ≤ 3 步（phone → OTP → verify）
- [ ] Face ID 启动到进入主界面 ≤ 2 秒
- [ ] OTP 送达 ≤ 10 秒
- [ ] 所有错误消息中文显示
- [ ] 账号自动解锁 30 分钟
- [ ] 5 次错误尝试后锁定

### Market 模块

- [ ] 行情加载 ≤ 1 秒
- [ ] K-线切换 ≤ 1 秒
- [ ] WebSocket 断线自动重连
- [ ] 陈旧行情警告（≥ 5s）
- [ ] 所有错误消息中文显示

### 交叉模块

- [ ] Token 不暴露在 URL 中
- [ ] WebSocket 认证握手 5s 超时
- [ ] Token 自动刷新期间 WebSocket 保持连接

---

## 📚 相关文档

- [INTEGRATION_TEST_GUIDE.md](./INTEGRATION_TEST_GUIDE.md) - 测试分类标准
- [MOCK_SERVER_GUIDE.md](./MOCK_SERVER_GUIDE.md) - Mock Server 使用
- [mobile/CLAUDE.md](../CLAUDE.md) - 移动端项目指南
- [auth/README.md](../src/integration_test/auth/README.md) - Auth 模块示例

---

**最后更新**: 2026-04-11  
**适用版本**: Flutter 3.41.4+  
**维护者**: Mobile Team
