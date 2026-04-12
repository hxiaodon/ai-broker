# Market Module Integration Tests

本目录包含 Market 模块的三层集成测试框架。

## 测试架构

### 三层集成测试分类

| 层级 | 文件 | 速度 | 依赖 | 用途 |
|------|------|------|------|------|
| **State Management** | `market_state_management_test.dart` | ⚡ 快 (~30s) | 无 | Riverpod 提供者、路由、应用状态 |
| **API Integration** | `market_api_integration_test.dart` | ⚡ 快 (~8s) | Mock Server | HTTP 层、API 端点、数据结构 |
| **E2E (End-to-End)** | `market_e2e_app_test.dart` | 🐢 慢 (~15s) | Mock Server + 模拟器 | 完整用户旅程、UI 交互、数据流 |

## 快速开始

### 前置条件

```bash
# 1. Flutter SDK >= 3.41.4
flutter doctor

# 2. 连接模拟器或设备
flutter devices

# 3. (可选) Go 环境用于编译 Mock Server
go version  # >= 1.20
```

### 方式 1: 自动运行脚本（推荐）

```bash
cd /Users/huoxd/metabot-workspace/brokerage-trading-app-agents/mobile

# 运行所有三层测试
./run-integration-tests.sh

# 或只运行特定类型
./run-integration-tests.sh state-management
./run-integration-tests.sh api-integration
./run-integration-tests.sh e2e
```

### 方式 2: 手动运行

#### 步骤 1: 启动 Mock Server（API 和 E2E 测试需要）

```bash
cd mobile/mock-server

# 编译 (第一次)
go build -o mock-server .

# 启动（normal 模式 = 正常数据）
./mock-server --strategy=normal

# 验证健康状态
curl http://localhost:8080/health
# 输出: {"status":"ok","strategy":"normal"}
```

可用的策略：
- `--strategy=normal` — 正常数据（推荐测试）
- `--strategy=guest` — 15 分钟延迟数据
- `--strategy=delayed` — 6 秒陈旧数据
- `--strategy=unstable` — 30% 掉线概率
- `--strategy=error` — 认证错误模式

#### 步骤 2: 在另一个终端运行测试

```bash
cd mobile/src

# 运行状态管理测试（不需要 Mock Server）
flutter test integration_test/market/market_state_management_test.dart -v

# 运行 API 集成测试（需要 Mock Server）
flutter test integration_test/market/market_api_integration_test.dart -v

# 运行 E2E 测试（需要 Mock Server + 模拟器）
flutter test integration_test/market/market_e2e_app_test.dart -v

# 运行所有市场测试
flutter test integration_test/market/ -v
```

## 测试覆盖内容

### State Management Tests (M1-M12)

✅ **应用状态**
- M1: 游客用户查看市场首页
- M2: 认证用户查看完整功能
- M3: 自选股列表加载
- M4: 搜索屏幕加载
- M5: 股票详情屏幕渲染
- M6: 游客延迟数据指示器

✅ **性能**
- M7: 市场首页 < 3 秒加载
- M8: 搜索屏幕 < 2.5 秒加载
- M9: 股票详情 < 2.5 秒加载

✅ **UI 稳定性**
- M10: 滚动期间 UI 稳定
- M11: 导航跨屏状态一致
- M12: 重复渲染无内存泄漏

### API Integration Tests (MA1-MA18)

✅ **报价端点**
- MA1: 获取单个股票报价
- MA2: 批量获取报价
- MA3: 报价包含所有必需字段
- MA4: HK 股票报价
- MA5: US 股票报价

✅ **搜索端点**
- MA6: 按代码搜索
- MA7: 按公司名搜索
- MA8: 搜索结果有必需字段
- MA9: 空搜索处理

✅ **市场动向端点**
- MA10: 获取涨幅前列
- MA11: 获取跌幅前列
- MA12: 动向数据结构正确

✅ **股票详情端点**
- MA13: 美股详情
- MA14: 港股详情

✅ **错误处理 & 数据一致性**
- MA15: 缺少参数返回错误
- MA16: API 并发抗压
- MA17: 时间戳有效性
- MA18: 价格值验证

### E2E Tests (Journey 1-10)

✅ **完整用户旅程**
- Journey 1: 游客访问市场（15分钟延迟数据）
- Journey 2: 认证用户实时数据解锁
- Journey 3: 搜索股票并查看详情
- Journey 4: 添加自选股
- Journey 5: 移除自选股
- Journey 6: 查看市场动向（涨跌）
- Journey 7: 股票详情屏幕（图表、指标）
- Journey 8: 快速导航稳定性
- Journey 9: 认证状态转换（游客 → 认证）
- Journey 10: 实时数据更新（WebSocket 模拟）

## Mock Server API 参考

### 市场数据端点

#### 1. 获取单个报价

```bash
curl http://localhost:8080/v1/market/stocks/AAPL
```

**响应示例：**
```json
{
  "symbol": "AAPL",
  "name": "Apple Inc.",
  "price": "150.25",
  "change": "2.50",
  "change_pct": "1.69",
  "market": "US",
  "market_status": "OPEN",
  "market_cap": "2750000000000.00",
  "timestamp": "2026-04-12T09:30:00Z"
}
```

#### 2. 批量获取报价

```bash
curl "http://localhost:8080/v1/market/quotes?symbols=AAPL,TSLA,0700"
```

**响应：** 多个报价的对象

#### 3. 搜索股票

```bash
curl "http://localhost:8080/v1/market/search?q=AAPL"
```

**响应：** 搜索结果列表

#### 4. 市场动向

```bash
curl http://localhost:8080/v1/market/movers
```

**响应：**
```json
{
  "gainers": [
    {
      "symbol": "AAPL",
      "name": "Apple Inc.",
      "change_pct": "1.33"
    }
  ],
  "losers": [
    {
      "symbol": "TSLA",
      "name": "Tesla, Inc.",
      "change_pct": "-2.10"
    }
  ]
}
```

## 故障排除

### Mock Server 连接失败

```bash
# 检查 Mock Server 是否在线
curl http://localhost:8080/health

# 如果失败，确保：
# 1. Mock Server 在运行
# 2. 听取 localhost:8080
# 3. 没有端口冲突
lsof -i :8080
```

### 模拟器连接问题

```bash
# 列出设备
flutter devices

# 如果没有设备，启动一个
# iOS
open -a Simulator

# Android
emulator -avd <avd_name>
```

### 测试超时

增加超时时间：

```bash
flutter test integration_test/market/ -v --timeout=60s
```

### 特定测试失败

运行单个测试并查看完整输出：

```bash
flutter test integration_test/market/market_e2e_app_test.dart::Journey1 -v
```

## CI/CD 集成

在 GitHub Actions 或其他 CI 中运行这些测试：

```yaml
- name: Run Market Integration Tests
  run: |
    cd mobile
    # 启动 Mock Server
    ./mock-server --strategy=normal &
    sleep 2
    
    # 运行测试
    cd src
    flutter test integration_test/market/ -v
```

## 更多信息

- [通用集成测试指南](../INTEGRATION_TEST_GUIDE.md) — 三层分类详解
- [Mock Server 指南](../MOCK_SERVER_GUIDE.md) — Mock Server 使用
- [测试实践](../TESTING_PRACTICES.md) — 测试最佳实践
- [Auth 模块示例](../auth/README.md) — 参考实现
