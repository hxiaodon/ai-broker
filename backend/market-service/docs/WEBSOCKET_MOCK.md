# WebSocket Mock 数据使用指南

## 概述

WebSocket 接口提供实时行情推送，使用 **Protocol Buffers** 二进制格式传输，Mock 数据从数据库读取并模拟价格波动。

## 连接地址

```
ws://localhost:8080/api/v1/market/realtime
```

## 认证

需要在 HTTP 请求头中携带 JWT token（通过 HTTP 接口登录获取）：

```
Authorization: Bearer <your_jwt_token>
```

## 消息协议

### 数据格式

**生产环境**: Protocol Buffers (二进制)
**兼容模式**: 同时支持 JSON（用于调试）

### Protobuf 定义

```protobuf
// proto/market_data.proto

message Quote {
  string symbol = 1;
  string price = 4;
  string change = 5;
  string change_percent = 6;
  int64 volume = 7;
  int64 timestamp = 8;
}

message SubscribeRequest {
  repeated string symbols = 1;
}

message SubscribeResponse {
  string action = 1;
  repeated string symbols = 2;
  int64 time = 3;
}
```

### 1. 客户端 → 服务端

#### 订阅股票
```json
{
  "type": "subscribe",
  "symbols": ["AAPL", "TSLA", "GOOGL"]
}
```

#### 取消订阅
```json
{
  "type": "unsubscribe",
  "symbols": ["AAPL"]
}
```

#### 心跳
```json
{
  "type": "ping"
}
```

### 2. 服务端 → 客户端

#### 欢迎消息
```json
{
  "type": "welcome",
  "data": {
    "message": "Connected to Market Service WebSocket",
    "clientId": "uuid"
  },
  "time": 1234567890
}
```

#### 订阅确认
```json
{
  "type": "ack",
  "action": "subscribe",
  "symbols": ["AAPL", "TSLA"],
  "time": 1234567890
}
```

#### 实时行情（每秒推送）
```json
{
  "type": "quote",
  "symbol": "AAPL",
  "data": {
    "symbol": "AAPL",
    "price": "175.23",
    "change": "2.15",
    "changePercent": "1.24",
    "volume": 45678900,
    "timestamp": 1234567890
  },
  "time": 1234567890
}
```

#### 心跳响应
```json
{
  "type": "pong",
  "time": 1234567890
}
```

## Mock 数据说明

### 数据来源
- 从 `quotes` 表读取最新 10 只股票的行情数据
- 包含 init_db.sql 中的 5 只美股 + 5 只港股

### 模拟逻辑
- **推送频率**: 每秒推送一次
- **价格波动**: 在当前价格基础上 ±0.5% 随机波动
- **成交量**: 在当前成交量基础上随机增加 0-1000
- **只推送已订阅**: 只向订阅了该股票的客户端推送

### Mock 股票列表
- AAPL (苹果)
- TSLA (特斯拉)
- GOOGL (谷歌)
- MSFT (微软)
- AMZN (亚马逊)
- 0700.HK (腾讯)
- 9988.HK (阿里巴巴)
- 0941.HK (中国移动)
- 1810.HK (小米)
- 2318.HK (中国平安)

## 测试步骤

### 1. 启动服务
```bash
cd backend/market-service
mysql -u root -p < scripts/init_db.sql
go run cmd/server/main.go
```

### 2. 使用测试客户端
打开 `examples/websocket_client.html` 在浏览器中测试

### 3. 使用 wscat 测试
```bash
npm install -g wscat
wscat -c ws://localhost:8080/api/v1/market/realtime

# 订阅
> {"type":"subscribe","symbols":["AAPL","TSLA"]}

# 等待接收实时行情...
```

## 注意事项

1. **Origin 验证**: 默认只允许以下来源连接
   - https://app.broker.com
   - https://www.broker.com
   - http://localhost:3000
   - http://localhost:8080

2. **连接超时**: 60 秒无活动自动断开

3. **心跳机制**: 服务端每 30 秒发送 ping，客户端需响应 pong

4. **生产环境**: 需要关闭 Mock 推送器，使用 Kafka 消费真实行情数据
