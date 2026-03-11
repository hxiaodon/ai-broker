# Market Service 项目文档索引

> 本文档为 AI 大模型优化的索引结构，支持按需加载相关文档

## 📋 快速导航

### 核心架构
- [系统架构设计](./docs/architecture/market-data-system.md) - 完整的系统架构、技术选型、数据流设计

### API 接口
- [HTTP API 接口](./docs/API.md) - 9 个 REST API 接口定义
- [WebSocket 实时行情](./docs/WEBSOCKET_MOCK.md) - WebSocket 协议、Protobuf 格式、Mock 数据
- [数据流架构](./docs/DATA_FLOW.md) - Kafka vs Mock 数据源切换

### 开发指南
- [数据库初始化](./scripts/init_db.sql) - MySQL Schema + Mock 数据
- [Protobuf 生成](./scripts/gen_proto.sh) - Protocol Buffers 代码生成
- [待办事项](./docs/TODO-market-service.md) - P1/P2 优先级任务

### 测试工具
- [WebSocket 测试客户端](./examples/websocket_client.html) - HTML 测试页面

---

## 🎯 按场景加载文档

### 场景 1: 理解整体架构
```
加载顺序:
1. 本文档 (README-INDEX.md)
2. docs/architecture/market-data-system.md
3. docs/DATA_FLOW.md
```

**关键概念**:
- 微服务架构 (Market Service)
- 数据源: Polygon.io API
- 存储: MySQL (未来迁移 TimescaleDB)
- 消息队列: Kafka
- 实时推送: WebSocket + Protobuf
- 认证: JWT
- 缓存: Redis

### 场景 2: 实现 HTTP API
```
加载顺序:
1. docs/API.md (接口定义)
2. internal/api/market_handler.go (Handler 实现)
3. internal/service/market_service.go (Service 层)
4. internal/repository/*_repository.go (Repository 层)
```

**已实现接口**:
- GET /api/v1/market/stocks - 股票列表
- GET /api/v1/market/stocks/:symbol - 股票详情
- GET /api/v1/market/kline/:symbol - K线数据
- GET /api/v1/market/search - 搜索股票
- GET /api/v1/market/hot-searches - 热门搜索
- GET /api/v1/market/news/:symbol - 股票新闻
- GET /api/v1/market/financials/:symbol - 财报数据
- POST /api/v1/market/watchlist - 添加自选股
- DELETE /api/v1/market/watchlist/:symbol - 删除自选股

### 场景 3: 实现 WebSocket 实时行情
```
加载顺序:
1. docs/WEBSOCKET_MOCK.md (协议说明)
2. proto/market_data.proto (Protobuf 定义)
3. internal/websocket/hub.go (Hub 实现)
4. internal/websocket/handler.go (Handler 实现)
5. internal/websocket/mock_pusher.go (Mock 推送器)
```

**消息格式**: Protocol Buffers (二进制)
**推送频率**: 每秒
**数据源**:
- 开发环境: Mock 推送器 (从数据库读取)
- 生产环境: Kafka 消费者

### 场景 4: 数据库操作
```
加载顺序:
1. scripts/init_db.sql (Schema + Mock 数据)
2. internal/model/model.go (数据模型)
3. internal/repository/*_repository.go (CRUD 操作)
```

**数据表**:
- stocks - 股票基础信息
- quotes - 实时行情
- klines - K线数据
- watchlists - 自选股
- news - 新闻
- financials - 财报
- hot_searches - 热门搜索

### 场景 5: 集成第三方数据源
```
加载顺序:
1. pkg/polygon/client.go (Polygon.io 客户端)
2. pkg/kafka/consumer.go (Kafka 消费者)
3. docs/DATA_FLOW.md (数据流架构)
```

**数据源**:
- Polygon.io API - 美股实时行情
- Kafka Topic: market.quotes - 内部消息队列

### 场景 6: 认证与安全
```
加载顺序:
1. internal/middleware/auth.go (JWT 认证)
2. internal/middleware/cors.go (CORS 跨域)
3. internal/websocket/handler.go (Origin 验证)
```

**安全措施**:
- JWT Bearer Token 认证
- CORS 白名单
- WebSocket Origin 验证
- Decimal 精度处理 (避免浮点误差)

---

## 🔧 技术栈

### 后端框架
- **Web**: Gin (HTTP Router)
- **ORM**: GORM
- **WebSocket**: gorilla/websocket
- **序列化**: Protocol Buffers

### 数据存储
- **数据库**: MySQL (生产环境计划迁移 TimescaleDB)
- **缓存**: Redis
- **消息队列**: Kafka

### 第三方服务
- **行情数据**: Polygon.io API
- **精度计算**: shopspring/decimal

### 开发工具
- **Go**: 1.21+
- **Protobuf**: protoc v7.34.0
- **包管理**: Go Modules

---

## 📊 项目结构

```
market-service/
├── cmd/server/          # 服务入口
├── internal/
│   ├── api/            # HTTP Handler
│   ├── service/        # 业务逻辑层
│   ├── repository/     # 数据访问层
│   ├── model/          # 数据模型
│   ├── middleware/     # 中间件 (Auth, CORS)
│   ├── websocket/      # WebSocket 实现
│   └── config/         # 配置管理
├── pkg/
│   ├── polygon/        # Polygon.io 客户端
│   ├── kafka/          # Kafka 消费者
│   ├── cache/          # Redis 缓存
│   └── database/       # 数据库连接
├── proto/              # Protobuf 定义
├── scripts/            # 脚本 (数据库初始化、代码生成)
├── docs/               # 文档
└── examples/           # 示例代码
```

---

## 🚀 快速开始

### 1. 初始化数据库
```bash
mysql -u root -p < scripts/init_db.sql
```

### 2. 配置文件
```yaml
# config/config.yaml
database:
  host: localhost
  port: 3306
  user: root
  password: your_password
  dbname: market_db

kafka:
  brokers: []  # 留空使用 Mock 推送器
```

### 3. 启动服务
```bash
go run cmd/server/main.go
```

### 4. 测试 WebSocket
打开 `examples/websocket_client.html`

---

## 📝 开发状态

### ✅ 已完成
- [x] 9 个 HTTP API 接口
- [x] 1 个 WebSocket 实时行情接口
- [x] JWT 认证中间件
- [x] CORS 跨域处理
- [x] Decimal 精度处理
- [x] Polygon.io 客户端实现
- [x] Repository 层完整实现
- [x] WebSocket Protobuf 格式
- [x] Mock 数据推送器
- [x] Kafka 消费者框架

### 🔄 进行中 (P1)
- [ ] 迁移到 TimescaleDB
- [ ] K线聚合逻辑
- [ ] WebSocket 错误处理优化

### 📋 计划中 (P2)
- [ ] Redis 缓存实现
- [ ] 监控和日志
- [ ] 单元测试
- [ ] 配置管理优化

详见: [docs/TODO-market-service.md](./docs/TODO-market-service.md)

---

## 💡 AI 大模型使用建议

### 按需加载策略
1. **首次理解**: 只读本文档 + architecture/market-data-system.md
2. **具体开发**: 根据场景加载对应的 2-3 个文件
3. **深入调试**: 再加载相关的实现代码

### 关键文件优先级
- **P0 (必读)**: README-INDEX.md, market-data-system.md
- **P1 (常用)**: API.md, WEBSOCKET_MOCK.md, DATA_FLOW.md
- **P2 (按需)**: 具体实现代码、测试工具

### 搜索关键词
- 架构设计 → `market-data-system.md`
- HTTP 接口 → `API.md` + `market_handler.go`
- WebSocket → `WEBSOCKET_MOCK.md` + `hub.go`
- 数据库 → `init_db.sql` + `*_repository.go`
- 认证 → `auth.go`
- 数据源 → `DATA_FLOW.md` + `polygon/client.go`

---

## 📞 联系方式

- 项目路径: `/Users/huoxd/metabot-workspace/brokerage-trading-app-agents/backend/market-service`
- 文档更新: 2026-03-08
