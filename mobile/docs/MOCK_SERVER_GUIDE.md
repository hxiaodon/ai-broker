## 使用 Mock Server 运行集成测试

本指南说明如何使用增强的 mock server（包含 Auth API）运行完整的集成测试。

### 📋 前置条件

1. **Flutter SDK** >= 3.41.4
   ```bash
   flutter doctor
   ```

2. **Go 环境**（编译 mock server，可选）
   ```bash
   go version  # >= 1.20
   ```

3. **连接的设备或模拟器**
   ```bash
   flutter devices
   ```

---

## 🚀 快速开始

### 方式 1：自动运行脚本（推荐）

```bash
cd mobile
./run-integration-tests.sh
```

这个脚本会：
1. 启动 mock server（自动选择 normal 策略）
2. 验证服务健康状态
3. 运行所有集成测试
4. 自动清理资源

### 方式 2：手动步骤

#### 步骤 1：启动 Mock Server

```bash
cd mobile/mock-server

# 普通模式（正常数据）
./mock-server --strategy=normal

# 或使用特定策略
./mock-server --strategy=guest      # 15分钟延迟数据
./mock-server --strategy=delayed    # 6秒陈旧数据
./mock-server --strategy=unstable   # 30% 断线概率
./mock-server --strategy=error      # 认证错误
```

验证服务启动：
```bash
curl http://localhost:8080/health
# 输出: {"status":"ok","strategy":"normal"}
```

#### 步骤 2：运行集成测试

在另一个终端：

```bash
cd mobile/src

# 运行所有集成测试
flutter test integration_test/ --verbose

# 或运行特定模块
flutter test integration_test/auth/auth_integration_test.dart
flutter test integration_test/market/market_integration_test.dart
flutter test integration_test/cross_module/cross_module_integration_test.dart
```

---

## 📡 Mock Server API 端点

### Auth 端点

#### 1. 发送 OTP

```bash
curl -X POST http://localhost:8080/v1/auth/otp/send \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+8613812345678"
  }'
```

**响应：**
```json
{
  "success": true,
  "message": "验证码已发送，请在 5 分钟内输入",
  "session_id": "+8613812345678"
}
```

**验证码（用于测试）：** `123456`

---

#### 2. 验证 OTP

```bash
curl -X POST http://localhost:8080/v1/auth/otp/verify \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+8613812345678",
    "otp": "123456"
  }'
```

**响应（成功）：**
```json
{
  "success": true,
  "message": "登录成功",
  "access_token": "abc123...",
  "refresh_token": "def456...",
  "expires_in": 3600,
  "account_id": "acc_5678_1712000000"
}
```

**错误处理：**
- 无效 OTP：返回 `400 Bad Request`，显示剩余尝试次数
- 5 次失败后：账户锁定 30 分钟

---

#### 3. 刷新 Token

```bash
curl -X POST http://localhost:8080/v1/auth/token/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "def456..."
  }'
```

**响应：**
```json
{
  "success": true,
  "access_token": "new_token_xyz...",
  "expires_in": 3600
}
```

---

#### 4. 生物识别注册

```bash
curl -X POST http://localhost:8080/v1/auth/biometric/register \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "device_abc123",
    "biometric_type": "face_id"
  }'
```

**响应：**
```json
{
  "success": true,
  "message": "生物识别（face_id）注册成功"
}
```

---

#### 5. 登出

```bash
curl -X POST http://localhost:8080/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d '{
    "access_token": "abc123..."
  }'
```

**响应：**
```json
{
  "success": true,
  "message": "登出成功"
}
```

---

### Market 端点

所有现有的 Market API 端点继续可用：

```bash
# 搜索
curl "http://localhost:8080/v1/market/search?q=apple"

# 获取行情
curl "http://localhost:8080/v1/market/quotes?symbols=AAPL,TSLA"

# 涨跌榜
curl http://localhost:8080/v1/market/movers

# 股票详情
curl http://localhost:8080/v1/market/stocks/AAPL

# WebSocket (需要 WebSocket 客户端)
wscat -c ws://localhost:8080/ws/market-data
```

---

## 🎯 测试场景

### 场景 1：完整登录流程

```bash
# 1. 发送 OTP
curl -X POST http://localhost:8080/v1/auth/otp/send \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+8613812345678"}'

# 2. 验证 OTP（使用返回的验证码 123456）
curl -X POST http://localhost:8080/v1/auth/otp/verify \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+8613812345678",
    "otp": "123456"
  }'

# 3. 获取访问令牌（上一步返回）
# 使用 access_token 调用其他需要认证的 API
```

### 场景 2：访客模式（延迟数据）

```bash
# 启动 guest 策略
./mock-server --strategy=guest

# 获取行情（带延迟标识）
curl http://localhost:8080/v1/market/quotes?symbols=AAPL,TSLA
# 响应包含 "delayed": true
```

### 场景 3：陈旧数据警告

```bash
# 启动 delayed 策略（数据 6 秒未更新）
./mock-server --strategy=delayed

# 获取行情
curl http://localhost:8080/v1/market/stocks/AAPL
# 响应包含 "stale_since_ms": 6000 （> 5000 阈值）
```

### 场景 4：错误处理

```bash
# 启动 error 策略
./mock-server --strategy=error

# OTP 验证会失败
curl -X POST http://localhost:8080/v1/auth/otp/verify \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+8613812345678",
    "otp": "123456"
  }'
# 返回 400 错误
```

### 场景 5：WebSocket 连接（不稳定）

```bash
# 启动 unstable 策略（30% 断线概率）
./mock-server --strategy=unstable

# Flutter app 会遇到断线，测试自动重连逻辑
```

---

## 🔧 配置

### 修改 Mock Server 端口

```bash
./mock-server --port=9090
```

### 自定义 API 响应

编辑 `mock-server/data.go` 修改基础数据：

```go
baseQuotes := map[string]map[string]interface{}{
    "AAPL": {
        "name": "Apple Inc.",
        "price": "175.50",
        "market": "US",
        // 修改此处的数据
    },
}
```

---

## 📊 集成测试覆盖

使用 mock server 可以测试以下场景：

| 场景 | 状态 | 说明 |
|------|------|------|
| 登录流程（phone → OTP → token） | ✅ | 完全可用 |
| 登出和 token 清除 | ✅ | 完全可用 |
| Token 刷新 | ✅ | 完全可用 |
| 生物识别注册 | ✅ | 完全可用 |
| 访客模式行情 | ✅ | 完全可用 |
| 自选股操作 | ✅ | 完全可用 |
| 错误处理和重试 | ✅ | 完全可用 |
| WebSocket 实时推送 | ✅ | 基本支持（可增强） |
| 断线重连 | ⚠️ | unstable 策略部分支持 |
| 生物识别认证失败 | ⚠️ | 需在 Flutter 中模拟 |

---

## 🐛 故障排查

### Mock Server 无法启动

```bash
# 检查端口是否被占用
lsof -i :8080

# 杀死占用进程
kill -9 <PID>

# 或使用不同的端口
./mock-server --port=9090
```

### Flutter 无法连接到 Mock Server

```bash
# 在模拟器中，使用 10.0.2.2 而不是 localhost
# 在真机中，使用电脑的 IP 地址

# 检查防火墙
sudo lsof -i -P -n | grep LISTEN
```

### 集成测试超时

```bash
# 增加超时时间
flutter test integration_test/ --verbose --timeout=30m
```

---

## 📈 下一步

1. **性能测试** - 使用 `--profile` 模式测试 FPS
2. **负载测试** - 并发多个客户端连接
3. **网络模拟** - 使用 `unstable` 策略测试重连
4. **CI/CD 集成** - 在 GitHub Actions 中自动运行

---

## 📚 相关文档

- [INTEGRATION_TESTS.md](./docs/INTEGRATION_TESTS.md) - 完整测试指南
- [mock-server/README.md](./mock-server/README.md) - Mock server 详细文档
- [mock-server/TESTING.md](./mock-server/TESTING.md) - 测试用例

---

**最后更新**：2026-04-10  
**Mock Server 版本**：v2.0（包含 Auth API）  
**状态**：✅ 生产就绪
