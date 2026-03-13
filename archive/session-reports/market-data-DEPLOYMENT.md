# Market Service 部署文档

## 📋 环境要求

- **Go**: 1.21+
- **MySQL**: 8.0+
- **Redis**: 7.0+
- **Kafka**: 3.0+ (可选，用于 WebSocket 实时推送)

---

## 🚀 快速开始

### 方式一：使用启动脚本（推荐）

```bash
cd backend/market-service
./start.sh
```

脚本会自动：
1. 检查环境依赖
2. 初始化数据库
3. 更新配置文件
4. 编译项目
5. 启动服务

### 方式二：手动部署

#### 1. 安装依赖

**macOS**:
```bash
# 安装 MySQL
brew install mysql
brew services start mysql

# 安装 Redis
brew install redis
brew services start redis

# 安装 Kafka (可选)
brew install kafka
brew services start kafka
```

**Linux (Ubuntu/Debian)**:
```bash
# 安装 MySQL
sudo apt update
sudo apt install mysql-server
sudo systemctl start mysql

# 安装 Redis
sudo apt install redis-server
sudo systemctl start redis

# 安装 Kafka (可选)
# 参考: https://kafka.apache.org/quickstart
```

#### 2. 初始化数据库

```bash
# 登录 MySQL
mysql -u root -p

# 执行初始化脚本
source scripts/init.sql

# 或者直接执行
mysql -u root -p < scripts/init.sql
```

#### 3. 配置服务

编辑 `config/config.yaml`，修改以下配置：

```yaml
database:
  password: your_mysql_password  # 修改为你的 MySQL 密码

redis:
  password: ""  # 如果 Redis 有密码，填写密码

polygon:
  api_key: "YOUR_POLYGON_API_KEY_HERE"  # 替换为真实的 Polygon.io API Key
```

#### 4. 下载依赖

```bash
go mod download
```

#### 5. 编译项目

```bash
go build -o bin/market-service cmd/server/main.go
```

#### 6. 启动服务

```bash
./bin/market-service
```

服务将在 `http://localhost:8080` 启动

---

## 🧪 测试接口

### 健康检查

```bash
curl http://localhost:8080/health
```

### 获取股票列表

```bash
curl "http://localhost:8080/api/v1/market/stocks?category=us&page=1&pageSize=10"
```

### 获取股票详情

```bash
curl http://localhost:8080/api/v1/market/stocks/AAPL
```

### 搜索股票

```bash
curl "http://localhost:8080/api/v1/market/search?keyword=AAPL&limit=10"
```

### 获取热门搜索

```bash
curl "http://localhost:8080/api/v1/market/hot-searches?limit=10"
```

---

## 📊 数据库结构

已创建的表：
- `stocks` - 股票基本信息
- `quotes` - 实时行情
- `klines` - K线数据
- `watchlists` - 自选股
- `news` - 股票新闻
- `financials` - 财报数据
- `hot_searches` - 热门搜索

初始化脚本已插入测试数据（AAPL, TSLA, MSFT, GOOGL, AMZN, NVDA）

---

## 🔧 配置说明

### 数据库配置

```yaml
database:
  host: localhost
  port: 3306
  user: root
  password: your_password_here
  dbname: market_service
  max_open_conns: 100
  max_idle_conns: 10
  conn_max_lifetime: 3600
```

### Redis 配置

```yaml
redis:
  host: localhost
  port: 6379
  password: ""
  db: 0
  pool_size: 10
  min_idle_conns: 5
```

### 缓存策略

```yaml
cache:
  quote_ttl: 5          # 实时行情缓存 5 秒
  stock_info_ttl: 3600  # 股票信息缓存 1 小时
  kline_ttl: 300        # K线数据缓存 5 分钟
  hot_search_ttl: 600   # 热门搜索缓存 10 分钟
```

### Polygon.io 配置

```yaml
polygon:
  api_key: "YOUR_POLYGON_API_KEY_HERE"
  base_url: "https://api.polygon.io"
  ws_url: "wss://socket.polygon.io"
  timeout: 30
```

**获取 API Key**:
1. 访问 https://polygon.io/
2. 注册账号
3. 在 Dashboard 获取 API Key
4. Free 计划：5 requests/min
5. Starter 计划（$29/月）：100 requests/min

---

## 📝 API 文档

完整 API 文档请参考：`/docs/api/market-api-spec.md`

### 接口列表

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/market/stocks | 获取股票列表 |
| GET | /api/v1/market/stocks/:symbol | 获取股票详情 |
| GET | /api/v1/market/kline/:symbol | 获取 K 线数据 |
| GET | /api/v1/market/search | 搜索股票 |
| GET | /api/v1/market/hot-searches | 获取热门搜索 |
| GET | /api/v1/market/news/:symbol | 获取股票新闻 |
| GET | /api/v1/market/financials/:symbol | 获取财报数据 |
| POST | /api/v1/market/watchlist | 添加自选股 |
| DELETE | /api/v1/market/watchlist/:symbol | 删除自选股 |

---

## 🐛 故障排查

### 1. 数据库连接失败

```
Error: failed to connect database
```

**解决方案**:
- 检查 MySQL 是否启动：`mysql.server status` (macOS) 或 `systemctl status mysql` (Linux)
- 检查配置文件中的密码是否正确
- 检查数据库是否已创建：`SHOW DATABASES;`

### 2. Redis 连接失败

```
Error: failed to connect redis
```

**解决方案**:
- 检查 Redis 是否启动：`redis-cli ping`
- 检查 Redis 端口：`lsof -i :6379`

### 3. 编译失败

```
Error: package not found
```

**解决方案**:
```bash
go mod tidy
go mod download
```

### 4. 端口被占用

```
Error: bind: address already in use
```

**解决方案**:
```bash
# 查找占用端口的进程
lsof -i :8080

# 杀死进程
kill -9 <PID>

# 或修改配置文件中的端口
```

---

## 📈 性能优化

### 1. 数据库优化

- 已创建索引：symbol, market, timestamp
- 连接池配置：max_open_conns=100, max_idle_conns=10

### 2. 缓存策略

- 实时行情：5 秒缓存
- 股票信息：1 小时缓存
- K 线数据：5 分钟缓存

### 3. 并发控制

- Gin 框架默认支持高并发
- Redis 连接池：pool_size=10

---

## 🔐 安全建议

1. **生产环境**：
   - 修改默认密码
   - 启用 HTTPS
   - 配置防火墙规则
   - 限制 API 访问频率

2. **数据库安全**：
   - 使用独立的数据库用户
   - 限制数据库访问 IP
   - 定期备份数据

3. **API Key 管理**：
   - 不要将 API Key 提交到代码仓库
   - 使用环境变量或密钥管理服务

---

## 📞 联系方式

如有问题，请联系开发团队或查看项目文档。

---

**部署完成！** 🎉

服务地址：`http://localhost:8080`
健康检查：`http://localhost:8080/health`
