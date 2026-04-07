# Mock Server 测试指南

## 快速开始

### 1. 启动 Mock Server

```bash
cd mobile/mock-server

# 方式 1：使用启动脚本（推荐）
./start.sh normal          # 正常模式
./start.sh delayed         # 延迟模式
./start.sh unstable        # 不稳定模式
./start.sh error           # 错误模式
./start.sh guest           # 访客模式

# 方式 2：直接运行
./mock-server --strategy=normal --port=8080
```

### 2. 配置 Flutter App

修改 WebSocket URL 指向 mock server：

**临时方式**（推荐用于测试）：
```bash
# 在 mobile/src 目录下
flutter run --dart-define=WS_URL=ws://localhost:8080/ws/market-data
```

**永久方式**：
编辑 `lib/core/config/app_config.dart`：
```dart
static const String marketDataWsUrl = 
  String.fromEnvironment('WS_URL', 
    defaultValue: 'ws://localhost:8080/ws/market-data');
```

### 3. 运行 Flutter App

```bash
cd mobile/src

# iOS 模拟器
flutter run -d iPhone

# Android 模拟器（注意：使用 10.0.2.2 而不是 localhost）
flutter run -d emulator --dart-define=WS_URL=ws://10.0.2.2:8080/ws/market-data
```

---

## 验收测试流程

### 测试 1：访客模式"延迟 15 分钟"标识

**Mock Server**:
```bash
./start.sh guest
```

**Flutter App**:
1. 启动 app，**不登录**（访客模式）
2. 进入行情页 → 自选股 tab
3. 进入任意股票详情页

**验收标准**:
- [ ] 所有价格旁显示 "延迟 15 分钟" 标识
- [ ] K线图顶部显示延迟提示

---

### 测试 2：WebSocket 断线自动重连

**Mock Server**:
```bash
./start.sh unstable
```

**Flutter App**:
1. 登录 app，进入行情页
2. 观察价格实时更新
3. 等待 mock server 自动断线（30% 概率，每 5-10 秒）
4. 观察 app 行为

**验收标准**:
- [ ] 断线后 UI 显示 "连接中断" 提示（不是白屏）
- [ ] 自动重连（无需用户手动刷新）
- [ ] 重连成功后实时数据恢复更新
- [ ] 日志显示重连次数（最多 3 次）

**查看日志**:
```bash
# Flutter 日志
flutter logs

# Mock server 日志
# 会显示：💥 Strategy triggered disconnect
```

---

### 测试 3：Stale Quote 警告

**Mock Server**:
```bash
./start.sh delayed
```

**Flutter App**:
1. 登录 app，进入行情页
2. 订阅一只股票（如 AAPL）
3. 等待 6 秒（mock server 会延迟推送）
4. 观察 UI 变化

**验收标准**:
- [ ] 当 `stale_since_ms >= 5000` 时，显示黄色警告 banner
- [ ] Banner 文案："行情数据可能延迟，正在重新连接..."
- [ ] 数据恢复后 banner 自动消失

---

### 测试 4：错误场景用户提示

**Mock Server**:
```bash
./start.sh error
```

**Flutter App**:
1. 尝试登录并连接 WebSocket
2. 观察错误提示

**验收标准**:
- [ ] 显示 "Token 无效或已过期，请重新登录"
- [ ] 不显示技术错误堆栈
- [ ] 提供 "重试" 或 "重新登录" 按钮

---

### 测试 5：正常功能验证

**Mock Server**:
```bash
./start.sh normal
```

**Flutter App**:
1. 登录 app
2. 进入行情页
3. 测试所有功能

**验收标准**:
- [ ] 自选股列表正常显示
- [ ] 价格实时更新（每秒）
- [ ] 搜索功能正常
- [ ] 涨跌榜正常显示
- [ ] 股票详情页正常

---

## 调试技巧

### 查看 WebSocket 消息

使用 `wscat` 手动测试：

```bash
# 安装
npm install -g wscat

# 连接
wscat -c ws://localhost:8080/ws/market-data

# 认证
> {"action":"auth","token":"test-token"}
< {"type":"auth_success","user_type":"registered","message":"认证成功"}

# 订阅
> {"action":"subscribe","symbols":["AAPL","TSLA"]}
< {"type":"snapshot","symbol":"AAPL","data":{...}}
< {"type":"tick","symbol":"AAPL","data":{...}}
```

### 查看 REST API 响应

```bash
# 搜索
curl "http://localhost:8080/api/market/search?q=apple" | jq

# 涨跌榜
curl http://localhost:8080/api/market/movers | jq

# 股票详情
curl http://localhost:8080/api/market/detail/AAPL | jq
```

### Flutter DevTools

```bash
# 启动 DevTools
flutter pub global activate devtools
flutter pub global run devtools

# 在浏览器中打开，连接到运行中的 app
# 查看 Network tab 可以看到 WebSocket 消息
```

---

## 常见问题

### Q: Android 模拟器连接不上 localhost

**A**: Android 模拟器需要使用 `10.0.2.2` 代替 `localhost`：

```bash
flutter run --dart-define=WS_URL=ws://10.0.2.2:8080/ws/market-data
```

### Q: iOS 模拟器连接失败

**A**: 检查 `Info.plist` 是否允许本地连接：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

### Q: 端口被占用

**A**: 使用其他端口：

```bash
./start.sh normal 9090
```

然后修改 Flutter app 的 WebSocket URL。

### Q: Mock server 数据不够真实

**A**: 编辑 `data.go`，添加更多股票或修改价格波动逻辑。

---

## 性能测试

### 测试 100+ symbols 并发更新

1. 修改 `data.go`，添加 100+ 股票
2. 启动 mock server（normal 模式）
3. Flutter app 订阅所有股票
4. 打开 DevTools Performance 面板
5. 观察帧率

**验收标准**: 帧率 ≥ 55 FPS

---

## 下一步

完成功能验证后：
1. ✅ 更新 `market_acceptance_checklist.md`
2. ✅ 截图保存测试结果
3. ✅ 提交最终 code review
4. 🚀 准备集成测试
