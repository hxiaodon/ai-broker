# Market Data Mock Server

轻量级 Go mock server，用于测试 Flutter app 的行情模块。

## 功能特性

- ✅ WebSocket 实时行情推送
- ✅ REST API（搜索、涨跌榜、股票详情）
- ✅ 5 种测试策略（正常、延迟、断线、错误、访客模式）
- ✅ 支持 US/HK 市场
- ✅ 内置 4 只股票数据（AAPL, TSLA, 0700, 9988）

## 快速开始

### 1. 启动服务器

```bash
cd mobile/mock-server

# 正常模式（默认）
go run . --strategy=normal

# 延迟模式（触发 stale quote 警告）
go run . --strategy=delayed

# 不稳定模式（随机断线，测试重连）
go run . --strategy=unstable

# 错误模式（认证失败）
go run . --strategy=error

# 访客模式（15 分钟延迟数据）
go run . --strategy=guest

# 自定义端口
go run . --port=9090 --strategy=normal
```

### 2. 测试连接

```bash
# 健康检查
curl http://localhost:8080/health

# 搜索股票
curl "http://localhost:8080/api/market/search?q=apple"

# 涨跌榜
curl http://localhost:8080/api/market/movers

# 股票详情
curl http://localhost:8080/api/market/detail/AAPL
```

### 3. WebSocket 测试

使用 `wscat` 测试 WebSocket：

```bash
# 安装 wscat
npm install -g wscat

# 连接
wscat -c ws://localhost:8080/ws/market-data

# 发送消息
> {"action":"auth","token":"test-token"}
< {"type":"auth_success","user_type":"registered","message":"认证成功"}

> {"action":"subscribe","symbols":["AAPL","TSLA"]}
< {"type":"snapshot","symbol":"AAPL","data":{...}}
< {"type":"tick","symbol":"AAPL","data":{...}}
```

## 测试策略说明

| 策略 | 行为 | 验收项 |
|------|------|--------|
| `normal` | 正常推送（每秒更新） | 基本功能 |
| `delayed` | 6 秒延迟推送（stale_since_ms > 5000） | Stale Quote 警告 banner |
| `unstable` | 随机断线（30% 概率，每 5-10 次 tick） | WebSocket 自动重连 |
| `error` | 认证失败（返回 4002） | 错误提示："Token 无效或已过期" |
| `guest` | 延迟 15 分钟数据 + delayed=true | 访客模式"延迟 15 分钟"标识 |

## 内置股票数据

| Symbol | Name | Market | 初始价格 |
|--------|------|--------|---------|
| AAPL | Apple Inc. | US | $175.50 |
| TSLA | Tesla, Inc. | US | $242.80 |
| 0700 | 腾讯控股 | HK | HK$368.50 |
| 9988 | 阿里巴巴-SW | HK | HK$78.50 |

## API 端点

### WebSocket

**端点**: `ws://localhost:8080/ws/market-data`

**消息格式**:

```json
// 认证
{"action":"auth","token":"your-token"}

// 订阅
{"action":"subscribe","symbols":["AAPL","TSLA"]}

// 退订
{"action":"unsubscribe","symbols":["AAPL"]}
```

**响应格式**:

```json
// 认证成功
{"type":"auth_success","user_type":"registered","message":"认证成功"}

// 快照
{"type":"snapshot","symbol":"AAPL","data":{...}}

// Tick 更新
{"type":"tick","symbol":"AAPL","data":{"price":"175.52","change":"0.02",...}}

// 错误
{"type":"error","code":4002,"message":"Token 无效或已过期"}
```

### REST API

#### 搜索股票
```
GET /api/market/search?q=<keyword>
```

#### 涨跌榜
```
GET /api/market/movers
```

#### 股票详情
```
GET /api/market/detail/<symbol>
```

## 配置 Flutter App

修改 `lib/core/config/app_config.dart`：

```dart
class AppConfig {
  static const String marketDataWsUrl = 'ws://localhost:8080/ws/market-data';
  static const String apiBaseUrl = 'http://localhost:8080/api';
}
```

或者使用环境变量：

```bash
flutter run --dart-define=MARKET_WS_URL=ws://localhost:8080/ws/market-data
```

## 验收清单对应

| 验收项 | 策略 | 验证方法 |
|--------|------|---------|
| 访客模式"延迟 15 分钟"标识 | `guest` | 不登录，查看价格旁标识 |
| WebSocket 断线自动重连 | `unstable` | 观察日志，确认重连成功 |
| Stale Quote 警告 | `delayed` | 等待 6 秒，查看黄色 banner |
| 错误提示 | `error` | 尝试连接，查看错误消息 |

## 日志示例

```
🚀 Mock server started on :8080 (strategy: normal)
📡 WebSocket endpoint: ws://localhost:8080/ws/market-data
🔧 Switch strategy: go run . --strategy=<name>
✅ Client connected: [::1]:54321
🔐 Auth success: [::1]:54321 (type: registered)
📊 Subscribed: [AAPL TSLA]
```

## 故障排查

### 端口被占用
```bash
# 查看占用端口的进程
lsof -i :8080

# 使用其他端口
go run . --port=9090
```

### WebSocket 连接失败
- 检查防火墙设置
- 确认 Flutter app 的 WebSocket URL 正确
- 查看服务器日志

## 扩展

### 添加新股票

编辑 `data.go`，在 `baseQuotes` 中添加：

```go
"GOOGL": {
    "symbol": "GOOGL",
    "name": "Alphabet Inc.",
    "market": "US",
    "price": "142.50",
    // ...
},
```

### 自定义策略

创建 `strategies/custom.go`：

```go
package strategies

type CustomStrategy struct{}

func (s *CustomStrategy) Name() string {
    return "custom"
}

// 实现 Strategy 接口的其他方法...
```

在 `strategy.go` 中注册：

```go
case "custom":
    return &strategies.CustomStrategy{}
```

## 生产环境注意

⚠️ 这是一个**测试工具**，不要用于生产环境：
- 无认证/授权
- 无持久化
- 无监控/告警
- 无负载均衡

## License

MIT
