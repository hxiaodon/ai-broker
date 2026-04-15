# K-Line Endpoint 测试文档

## 概述

Mock Server 现已实现 `/v1/market/kline` 端点，支持获取股票的 K-线（OHLCV）数据。

## 端点

### GET /v1/market/kline

获取指定股票的蜡烛线数据。

**支持两种请求格式：**

1. **查询参数格式**
   ```
   GET /v1/market/kline?symbol=AAPL&period=1d&limit=50
   ```

2. **路径参数格式**
   ```
   GET /v1/market/kline/AAPL?period=1d&limit=50
   ```

### 请求参数

| 参数 | 类型 | 必需 | 说明 | 示例 |
|------|------|------|------|------|
| `symbol` | string | 是 | 股票代码 | `AAPL`, `TSLA`, `0700` |
| `period` | string | 否 | 时间周期（默认 `1d`） | `1min`, `5min`, `1h`, `1d`, `1w`, `1mo` |
| `limit` | int | 否 | 返回条数（默认 50） | `5`, `20`, `100` |
| `from` | string | 否 | 起始日期（ISO 8601） | `2026-01-01` |
| `to` | string | 否 | 结束日期（ISO 8601） | `2026-04-12` |
| `cursor` | string | 否 | 分页游标 | 用于获取下一页数据 |

### 响应格式

```json
{
  "symbol": "AAPL",
  "period": "1d",
  "candles": [
    {
      "t": "2026-04-11T09:41:49Z",
      "o": "175.50",
      "h": "176.80",
      "l": "173.20",
      "c": "174.48",
      "v": 52341234,
      "n": 668
    }
  ],
  "total": 50,
  "next_cursor": ""
}
```

**蜡烛线字段：**

| 字段 | 类型 | 说明 |
|------|------|------|
| `t` | string | 蜡烛线开盘时间（UTC ISO 8601） |
| `o` | string | 开盘价 |
| `h` | string | 最高价 |
| `l` | string | 最低价 |
| `c` | string | 收盘价 |
| `v` | int | 成交量 |
| `n` | int | 成交笔数 |

### 时间周期说明

| 周期 | 说明 | 默认返回条数 | 数据跨度 |
|------|------|------------|---------|
| `1min` | 1 分钟 | 390 | 过去 1 天 |
| `5min` | 5 分钟 | 78 | 过去 1 天 |
| `15min` | 15 分钟 | 26 | 过去 1 天 |
| `30min` | 30 分钟 | 13 | 过去 1 天 |
| `60min` / `1h` | 1 小时 | 24 | 过去 1 天 |
| `1d` | 日线 | 50 | 过去 50 天 |
| `1w` | 周线 | 50 | 过去 50 周 |
| `1mo` | 月线 | 50 | 过去 50 个月 |

## 测试示例

### 1. 获取 AAPL 日线数据（最近 5 根）
```bash
curl "http://localhost:8080/v1/market/kline?symbol=AAPL&period=1d&limit=5"
```

### 2. 获取 TSLA 小时线数据（最近 10 根）
```bash
curl "http://localhost:8080/v1/market/kline/TSLA?period=1h&limit=10"
```

### 3. 获取 0700（腾讯）分钟线数据（最近 20 根）
```bash
curl "http://localhost:8080/v1/market/kline/0700?period=1min&limit=20"
```

### 4. 用 jq 格式化输出
```bash
curl -s "http://localhost:8080/v1/market/kline?symbol=AAPL&period=1d&limit=2" | jq .
```

## Flutter 集成

### 1. 数据获取

在 `kline_chart_widget.dart` 中，`_klineDataProvider` 自动调用 API：

```dart
final _klineDataProvider = FutureProvider.autoDispose
    .family<List<Candle>, KlineParams>((ref, params) async {
  final repo = ref.read(marketDataRepositoryProvider);
  final result = await repo.getKline(
    symbol: params.symbol,
    period: params.period,
    from: params.from ?? _defaultFrom(params.period),
    to: params.to,
    limit: params.limit,
    cursor: params.cursor,
  );
  return result.candles;
});
```

### 2. 期间选择

用户可以点击期间选择器切换时间周期：

| 按钮 | apiPeriod | limit |
|------|-----------|-------|
| 分时 | `1min` | 390 |
| 1W | `1d` | 5 |
| 1M | `1d` | 22 |
| 3M | `1d` | 66 |
| 1Y | `1d` | 252 |
| All | `1d` | 0 (服务器决定) |

### 3. 当前 UI 状态

K-线图当前显示 **sparkline 占位符**（在 `_ChartView._SparklinePainter` 中实现），包含：
- 迷你折线图，显示收盘价趋势
- 蜡烛数信息，如 "50 根K线"
- 期间选择器

完整的 Syncfusion `CandlestickSeries` 图表仍在 TODO 中（T05 任务）。

## 数据生成策略

Mock Server 使用以下算法生成 K-line 数据：

1. **基础价格**：从 `baseQuotes` 获取股票当前报价作为参考
2. **价格游走**：使用随机游走模型，每个蜡烛相对前一个 ±2 的价格变化
3. **OHLCV**：
   - 开盘价 = 前根蜡烛收盘价
   - 收盘价 = 开盘 + 随机变化
   - 最高价 = max(开盘, 收盘) + 随机偏移
   - 最低价 = min(开盘, 收盘) - 随机偏移
   - 成交量 = 1M - 10M 随机
   - 笔数 = 100 - 1100 随机

## 故障排查

### K-线图显示 "K线数据加载失败"

**检查步骤：**

1. **确认 Mock Server 运行**
   ```bash
   curl http://localhost:8080/health
   ```
   预期返回：`{"status":"ok","strategy":"normal"}`

2. **测试 K-line 端点直接调用**
   ```bash
   curl "http://localhost:8080/v1/market/kline?symbol=AAPL&period=1d&limit=5"
   ```

3. **检查 Flutter 应用日志**
   - 查看 `AppLogger` 输出是否有 HTTP 错误
   - 检查 `KlineChartWidget` 状态是否为 `error`

4. **确认环境配置**
   - iOS 模拟器：使用 `localhost:8080`
   - Android 模拟器：使用 `10.0.2.2:8080`

### K-线图只显示一条线或数据异常

**可能原因：**
- 基础报价不正确（检查 `baseQuotes` 中是否有该股票）
- 数据生成的随机种子问题

**解决方法：**
- 重启 Mock Server
- 尝试其他股票代码

## 相关文件

- `mobile/mock-server/rest.go` — K-line 端点实现
- `mobile/mock-server/data.go` — K-line 数据生成函数
- `mobile/src/lib/features/market/presentation/widgets/kline_chart_widget.dart` — Flutter 前端
- `mobile/src/lib/features/market/data/remote/market_remote_data_source.dart` — API 层

## 参考

- [Market API Spec](../../../docs/contracts/market-api-spec.md) — 完整 API 规范
- [MOCK_SERVER_GUIDE.md](./MOCK_SERVER_GUIDE.md) — Mock Server 使用指南
- [INTEGRATION_TEST_GUIDE.md](./INTEGRATION_TEST_GUIDE.md) — 集成测试标准
