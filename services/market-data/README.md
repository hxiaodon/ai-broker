# Market Service

行情服务 - 为移动端 APP 提供实时行情数据

## 技术栈

- **语言**: Go 1.21+
- **框架**: Gin (HTTP) + Gorilla WebSocket
- **数据库**: MySQL 8.0
- **缓存**: Redis 7.0
- **消息队列**: Kafka 3.0
- **数据源**: Polygon.io (实时美股行情)

## 项目结构

```
market-service/
├── cmd/
│   └── server/          # 服务入口
├── internal/
│   ├── api/             # HTTP API 处理器
│   ├── config/          # 配置管理
│   ├── model/           # 数据模型
│   ├── repository/      # 数据访问层
│   ├── service/         # 业务逻辑层
│   └── websocket/       # WebSocket 实时推送
├── pkg/
│   ├── cache/           # Redis 缓存封装
│   ├── database/        # MySQL 数据库封装
│   └── polygon/         # Polygon.io 客户端
├── scripts/
│   └── init.sql         # 数据库初始化脚本
├── config/
│   └── config.yaml      # 配置文件
├── go.mod
├── go.sum
└── README.md
```

## API 接口

详见：`docs/specs/market-api-spec.md`

### REST API

- `GET /api/v1/market/stocks` - 获取股票列表
- `GET /api/v1/market/stocks/:symbol` - 获取股票详情
- `GET /api/v1/market/kline/:symbol` - 获取 K 线数据
- `GET /api/v1/market/search` - 搜索股票
- `GET /api/v1/market/hot-searches` - 获取热门搜索
- `GET /api/v1/market/news/:symbol` - 获取股票新闻
- `GET /api/v1/market/financials/:symbol` - 获取财报数据
- `POST /api/v1/market/watchlist` - 添加自选股
- `DELETE /api/v1/market/watchlist/:symbol` - 删除自选股

### WebSocket

- `ws://host/api/v1/market/realtime` - 实时行情推送

## 快速开始

### 1. 安装依赖

```bash
go mod download
```

### 2. 配置环境变量

```bash
cp config/config.example.yaml config/config.yaml
# 编辑 config.yaml，填入数据库、Redis、Kafka 配置
```

### 3. 初始化数据库

```bash
mysql -u root -p < scripts/init.sql
```

### 4. 启动服务

```bash
go run cmd/server/main.go
```

服务将在 `http://localhost:8080` 启动

## 开发计划

### Phase 1: 基础架构（Day 1-2）
- [x] 项目初始化
- [ ] 数据库设计与初始化
- [ ] Redis 缓存封装
- [ ] Polygon.io 客户端封装
- [ ] 配置管理

### Phase 2: REST API（Day 3-4）
- [ ] 股票列表接口
- [ ] 股票详情接口
- [ ] K 线数据接口
- [ ] 搜索接口
- [ ] 自选股管理

### Phase 3: WebSocket 实时推送（Day 5）
- [ ] WebSocket 服务器
- [ ] Kafka 消息消费
- [ ] 实时行情推送

### Phase 4: 测试与优化（Day 6-7）
- [ ] 单元测试
- [ ] 集成测试
- [ ] 性能优化
- [ ] 文档完善

## 数据源说明

### Polygon.io

- **实时性**: 毫秒级延迟
- **覆盖范围**: 美股、期权、外汇、加密货币
- **API 限制**:
  - Free: 5 requests/min
  - Starter ($29/mo): 100 requests/min
  - Developer ($99/mo): 1000 requests/min
- **WebSocket**: 支持实时行情推送

**占位符配置**:
```yaml
polygon:
  api_key: "YOUR_POLYGON_API_KEY_HERE"
  base_url: "https://api.polygon.io"
  ws_url: "wss://socket.polygon.io"
```

## 环境要求

- Go 1.21+
- MySQL 8.0+
- Redis 7.0+
- Kafka 3.0+

## License

MIT
