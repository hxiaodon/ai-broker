# PRD-03：行情模块

> **文档状态**: Phase 1 正式版（技术评审修订版）
> **版本**: v1.1
> **日期**: 2026-03-13
> **变更说明**: 根据 Backend、Flutter 评审意见修订：补充 WebSocket 认证协议（JWT auth消息）、K 线接口增加分页限制（max 500条/游标分页）、symbols 参数限制（max 50）、Watchlist 数据模型补充（含 UNIQUE 约束）、行情库选型确认（syncfusion_flutter_charts K线图）、访客行情切换策略

---

## 一、模块概述

### 1.1 功能范围

| 功能 | 说明 |
|------|------|
| 行情列表 | 自选股、美股（热门/涨幅榜/跌幅榜）、港股入口 |
| 股票详情 | 实时报价、K 线图、基本面、新闻、财务数据 |
| 搜索 | 支持代码、英文名、中文名、拼音首字母搜索 |
| Watchlist | 用户自选股收藏与管理 |
| 访客模式 | 延迟 15 分钟行情，需标注 "Delayed" |

### 1.2 数据源与授权

| 市场 | Phase 1 数据源 | 授权状态 |
|------|--------------|---------|
| 美股（NYSE/NASDAQ） | Polygon.io | 本周启动授权谈判 |
| 港股（HKEX） | HKEX OMD | Phase 2 |

### 1.3 访客 vs 注册用户数据权限

| 数据类型 | 访客 | 注册用户（KYC 任意状态） |
|---------|------|----------------------|
| 股票报价 | 延迟 15 分钟，必须标注 | 实时 |
| K 线历史数据 | 延迟 15 分钟 | 实时 |
| 基本面数据 | ✅ 可查看 | ✅ 可查看 |
| 新闻资讯 | ✅ 可查看 | ✅ 可查看 |
| Watchlist | ❌ 不支持（需登录） | ✅ |

---

## 二、行情列表页

### 2.1 Tab 结构

| Tab | 内容 | Phase 1 状态 |
|-----|------|------------|
| 自选（Watchlist） | 用户收藏的股票 | ✅ 可用 |
| 美股（US Stocks） | 热门 / 涨幅 / 跌幅列表 | ✅ 可用 |
| 港股（HK Stocks） | 港股行情 | ❌ 显示 "敬请期待" |
| 热门（Hot） | 平台推荐热门股 | ✅ 可用 |

### 2.2 股票列表卡片字段

| 字段 | 说明 | 显示规则 |
|------|------|---------|
| 股票代码 | 如 AAPL | 大写字母，美股 1-5 位 |
| 公司名称 | 英文简称 + 中文名 | 双行显示 |
| 当前价格 | 实时/延迟价格 | 4 位小数（美股） |
| 涨跌额 | ±X.XX | 红/绿色（按用户颜色设置） |
| 涨跌幅 | ±X.XX% | 红/绿色 |
| 成交量 | 今日成交量 | 格式化：K/M/B |

**颜色设置（用户可配置，见 PRD-08）**:
- 默认（+86）：红涨绿跌
- 默认（+852）：绿涨红跌
- 平盘（0%）：始终显示灰色

### 2.3 访客模式 Banner

行情列表页顶部固定显示：
```
🕐 行情延迟 15 分钟  [登录获取实时行情 →]
```

### 2.4 美股列表数据

**热门 Tab 数据**:
- 平台人工策划 + 算法排名（Phase 1：人工维护）
- 每日更新，至少 20 只股票
- Admin Panel 可管理热门列表

**涨幅榜 / 跌幅榜**:
- 按当日涨幅从高到低排列
- 仅显示交易量 > 100 万股的流动性标的
- 美股常规交易时段（ET 09:30-16:00）实时更新

### 2.5 港股 Tab（Phase 1）

```
[港股 Tab 点击]
→ 显示 "港股交易即将开放" 卡片
→ "敬请期待" + 预约提醒按钮（可选，Phase 2 实现）
```

---

## 三、股票详情页

### 3.1 页面结构

```
[头部]  代码 · 公司名 · 收藏按钮
        ↓
[价格英雄区]  当前价格（大字）· 涨跌额 · 涨跌幅
             今开/昨收/最高/最低/成交量/换手率
        ↓
[K 线图区]  时间轴切换：分时 / 日 / 周 / 月
             均线：MA5 / MA10 / MA20（可叠加）
        ↓
[内容 Tab]  K 线 | 新闻 | 基本面 | 财务
        ↓
[底部操作栏]  [买入] [卖出]  （访客显示登录引导）
```

### 3.2 价格英雄区字段

| 字段 | 规格 |
|------|------|
| 当前价格 | 4 位小数，字号最大 |
| 涨跌额 | ±X.XXXX |
| 涨跌幅 | ±X.XX% |
| 交易时段标识 | 常规 / 盘前 / 盘后 / 休市 |
| 今开 | 当日开盘价 |
| 昨收 | 前一日收盘价 |
| 最高 / 最低 | 当日最高/最低 |
| 成交量 | 当日成交量（格式化） |
| 成交额 | 当日成交额（格式化） |

### 3.3 K 线图规格

| 时间轴 | 数据点 | 刷新频率 |
|--------|--------|---------|
| 分时图 | 1 分钟 K 线，当日 | 实时（WebSocket） |
| 日线 | 1 天 1 根 K 线，近 2 年 | 每日收盘后更新 |
| 周线 | 1 周 1 根，近 5 年 | 每周收盘后更新 |
| 月线 | 1 月 1 根，全历史 | 每月收盘后更新 |

**技术要求**:
- iOS：Swift Charts（iOS 16+）
- Android：MPAndroidChart
- WebSocket 实时推送分时数据
- 手势：双指缩放调整时间范围，单指滑动查看历史，长按显示十字线 + 价格

### 3.4 基本面 Tab 数据

| 字段 | 说明 |
|------|------|
| 市值 | Market Cap |
| 市盈率（P/E） | TTM |
| 市净率（P/B） | — |
| 股息收益率 | Dividend Yield |
| 52 周最高 / 最低 | 年内区间 |
| EPS | 近 4 季度摊薄 EPS |
| 所属板块 | Sector / Industry |

### 3.5 新闻 Tab

| 规格 | 说明 |
|------|------|
| 数据源 | Polygon.io 新闻 API / Finnhub（Phase 1 方案待定） |
| 显示字段 | 标题、来源、发布时间、摘要（2 行） |
| 点击行为 | 跳转外部浏览器打开原文链接 |
| 刷新频率 | 每 5 分钟 |
| 数量 | 最近 50 条 |

### 3.6 财务 Tab

| 字段 | 说明 |
|------|------|
| 下一次财报日期 | 预计公布时间 |
| 营收（最近 4 季） | 柱状图 + 数字 |
| 净利润（最近 4 季） | 柱状图 + 数字 |
| EPS（最近 4 季） | 实际 vs 预期对比 |

### 3.7 盘前 / 盘后价格显示

| 状态 | 显示内容 |
|------|---------|
| 盘前（Pre-Market）04:00-09:30 ET | 盘前价格 + "盘前" 标签 + 相对昨收涨跌幅 |
| 常规时段（09:30-16:00 ET） | 实时价格 |
| 盘后（After-Hours）16:00-20:00 ET | 盘后价格 + "盘后" 标签 |
| 休市 | 最后收盘价 + "休市" 标签 |

---

## 四、搜索功能

### 4.1 搜索入口

- 行情列表页右上角搜索图标
- 点击进入全屏搜索页

### 4.2 搜索支持的匹配方式

| 匹配类型 | 示例 |
|---------|------|
| 股票代码（精确/前缀） | "AAPL", "AAP" |
| 英文公司名（前缀/包含） | "Apple", "App" |
| 中文公司名 | "苹果", "特斯拉" |
| 拼音首字母 | "pg"（苹果 → pínggǔo）|

### 4.3 搜索结果字段

每条结果显示：代码 · 公司名（中/英）· 当前价格 · 涨跌幅

### 4.4 搜索页默认状态

- 最近搜索（本地存储，最多 10 条，可清除）
- 热门搜索（平台配置，实时更新，带排名徽标）

### 4.5 搜索范围（Phase 1）

- 仅搜索美股标的（US Stocks）
- 港股标的不纳入搜索结果（Phase 2 开放）

### 4.6 无结果状态

```
"未找到 'XXXXX' 相关股票"
（提示：美股代码由 1-5 位字母组成）
```

---

## 五、Watchlist 自选股

### 5.1 功能规格

| 功能 | 规格 |
|------|------|
| 添加自选 | 股票详情页收藏星标，或搜索结果页长按 |
| 自选列表 | 行情列表第一 Tab，按添加时间排序 |
| 最大数量 | 200 只（Phase 1 暂不设上限，后续评估） |
| 排序 | 默认按添加时间，后续支持自定义排序（Phase 2） |
| 实时更新 | WebSocket 批量订阅自选股行情 |

### 5.2 空状态

```
[自选 Tab 空状态]
"还没有自选股"
"搜索并添加您感兴趣的股票" → [去搜索]按钮
```

### 5.3 登录态 vs 访客态

| 操作 | 访客 | 已登录 |
|------|------|-------|
| 查看自选 | 显示登录占位页 | ✅ 正常显示 |
| 添加自选 | 点击触发登录引导 | ✅ 正常添加 |

---

## 六、实时行情架构要求

### 6.1 数据流

```
Polygon.io 实时数据
    → 内部 Market Data Gateway（Go）
        → Redis Pub/Sub（短暂缓冲）
            → WebSocket Server（per-user 订阅管理）
                → 客户端（iOS/Android WebSocket）
```

### 6.2 WebSocket 协议规格

> **[v1.1 新增]** 补充 WebSocket 认证协议（P1-行情 修复）。

```json
// Step 1: 连接建立后，客户端必须在 5 秒内发送认证消息，否则服务端关闭连接
// 注册用户
{ "action": "auth", "token": "JWT" }
// 访客（或省略 token 字段）
{ "action": "auth", "token": "" }

// Step 2: 服务端响应
{
  "type": "auth_result",
  "success": true,
  "user_type": "registered" | "guest",
  "token_expires_in": 850    // 距 Token 过期秒数
}

// Step 3: Token 即将过期时（提前 2 分钟）服务端推送
{ "type": "token_expiring", "expires_in": 120 }
// 客户端刷新后重新认证
{ "action": "reauth", "token": "new-JWT" }

// Step 4: 订阅行情（认证成功后才能订阅）
{
  "action": "subscribe",
  "symbols": ["AAPL", "TSLA", "NVDA"]   // 单次最多 50 个 symbol
}

// 服务端推送（Tick 数据）
{
  "type": "quote",
  "symbol": "AAPL",
  "price": "182.5200",
  "change": "1.2400",
  "change_pct": "0.68",
  "volume": 45678900,
  "bid": "182.5100",
  "ask": "182.5300",
  "timestamp": "2026-03-13T14:30:00.123Z",
  "delayed": false           // 访客连接时为 true
}
```

**Flutter 实现**: `web_socket_channel ^3.0.3`；后台推送策略通过 `firebase_messaging ^16.1.2` FCM 承载（不依赖 WebSocket 后台保活）。

### 6.3 访客延迟实现

- 访客 WebSocket 连接：服务端标记为 `guest=true`
- 行情推送在服务端延迟 15 分钟后发送
- 所有价格字段附加 `delayed: true` 标识
- 客户端在所有价格旁显示 "延迟" 徽标
- **[v1.1 新增] 访客 → 注册用户切换策略**: 用户登录后发送 `reauth` 消息，服务端立即切换为实时流，不断开连接；客户端对切换后首批价格进行平滑过渡（500ms 渐变动画），避免价格突然跳变

### 6.4 性能要求

| 指标 | 要求 |
|------|------|
| 行情推送延迟 | < 500ms（注册用户，P99） |
| WebSocket 连接数 | 支持 10 万并发连接 |
| 行情列表加载 | 首屏 < 1 秒 |
| K 线数据加载 | 首次 < 2 秒，切换时间轴 < 500ms |
| K 线图实现 | Flutter: `syncfusion_flutter_charts ^32.2.9`（Candlestick 支持完整，含 pinch-zoom、trackball）；备选 `financial_chart ^0.4.1` |

---

## 七、REST API 规格

### 7.1 股票快照（批量）

```
GET /v1/market/quotes?symbols=AAPL,TSLA,NVDA

约束：symbols 最多 50 个，超出返回 400 Bad Request
      {"error": "TOO_MANY_SYMBOLS", "max": 50, "provided": 51}

Response 200:
  {
    "quotes": {
      "AAPL": {
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "name_zh": "苹果公司",
        "price": "182.5200",
        "change": "1.2400",
        "change_pct": "0.68",
        "volume": 45678900,
        "market_cap": 2800000000000,
        "pe_ratio": "28.5",
        "bid": "182.51",
        "ask": "182.53",
        "delayed": false,               // true = 访客延迟行情（15min）
        "market_status": "REGULAR"      // REGULAR | PRE_MARKET | AFTER_HOURS | CLOSED
      }
    },
    "as_of": "2026-03-13T14:30:00.000Z"
  }

注：未认证请求 delayed=true，price 为 15 分钟前快照价
```

### 7.2 K 线历史数据

```
// 日/周/月 K 线（时间范围查询，max 500 根）
GET /v1/market/kline?symbol=AAPL&period=1d&from=2026-01-01&to=2026-03-13&limit=500&cursor=

// 分钟级历史 K 线（指定日期，适用于历史某一天的分钟线回放）
GET /v1/market/kline?symbol=AAPL&period=1min&date=2026-03-12

period 枚举：1min | 5min | 15min | 30min | 60min | 1d | 1w | 1mo

Response 200:
  {
    "symbol": "AAPL",
    "period": "1d",
    "candles": [
      {
        "t": "2026-03-13T00:00:00Z",   // UTC，日线取交易日开盘时刻
        "o": "181.00",
        "h": "183.50",
        "l": "180.00",
        "c": "182.52",
        "v": 45678900
      }
    ],
    "next_cursor": "eyJ0IjoiMjAyNi0wMS0wMSJ9",  // null 表示已到末尾
    "total": 52
  }

分页规则：
  - limit 最大 500，默认 100
  - cursor 为 base64 编码的时间戳游标（不透明，直接传给下一次请求）
  - 分钟级（period=1min 且含 date 参数）不支持 cursor，直接返回当日全量
  - 数据源无分钟历史时返回 404

注（Flutter）：syncfusion_flutter_charts 图表数据一次性加载，
  分批追加时调用 chart.updateDataSource(addedDataIndexes: [...])
```

### 7.3 搜索

```
GET /v1/market/search?q=apple&market=US&limit=20

limit 默认 10，最大 50

Response 200:
  {
    "results": [
      {
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "name_zh": "苹果公司",
        "price": "182.5200",
        "change_pct": "0.68",
        "market": "US",
        "delayed": false
      }
    ],
    "total": 3
  }
```

### 7.4 热门/涨跌幅榜

```
GET /v1/market/movers?type=gainers|losers|hot&market=US&limit=20

limit 最大 50

Response 200:
  {
    "type": "gainers",
    "market": "US",
    "items": [
      {
        "symbol": "NVDA",
        "name": "NVIDIA Corp.",
        "price": "875.00",
        "change_pct": "5.23",
        "volume": 89234567
      }
    ],
    "as_of": "2026-03-13T14:30:00Z"
  }
```

### 7.5 Watchlist 管理

```
GET /v1/watchlist
Response 200:
  {
    "symbols": ["AAPL", "TSLA", "NVDA"],
    "quotes": { ... }   // 同 7.1 格式，一次返回全部行情
  }

POST /v1/watchlist
Body: { "symbol": "AAPL" }
// 幂等：INSERT ... ON CONFLICT (user_id, symbol) DO NOTHING
// symbol 不存在时返回 404；已在自选列表则返回 200（非 409）
Response 200: { "symbol": "AAPL", "added_at": "2026-03-13T14:30:00Z" }

DELETE /v1/watchlist/{symbol}
// symbol 不在列表时返回 200（幂等删除）
Response 200: { "symbol": "AAPL", "removed": true }

约束：
  - 每用户最多 100 支自选股，超出返回 400 WATCHLIST_FULL
  - 访客不可使用（401）；注册用户 KYC 前可用
```

---

## 八、交易时段展示规则

| 时段 | ET 时间 | 显示标签 | 可买卖 |
|------|--------|---------|-------|
| 盘前（Pre-Market） | 04:00-09:30 | "盘前" 橙色标签 | ✅（限价单） |
| 常规（Regular） | 09:30-16:00 | 无标签（默认态） | ✅（所有订单类型） |
| 盘后（After-Hours） | 16:00-20:00 | "盘后" 橙色标签 | ✅（限价单） |
| 休市（Closed） | 其余时间 | "休市" 灰色标签 | ❌ |

**注**：盘前/盘后交易需用户首次进入时确认风险声明。

---

## 九、数据模型

### 9.1 自选股表

```sql
CREATE TABLE user_watchlist (
    user_id     UUID        NOT NULL REFERENCES users(id),
    symbol      VARCHAR(10) NOT NULL,
    added_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sort_order  INT         NOT NULL DEFAULT 0,       -- 用于自定义排序
    PRIMARY KEY (user_id, symbol)
);

CREATE INDEX idx_watchlist_user ON user_watchlist (user_id, sort_order);

-- 添加自选（幂等）
INSERT INTO user_watchlist (user_id, symbol, sort_order)
VALUES ($1, $2, (SELECT COALESCE(MAX(sort_order),0)+1 FROM user_watchlist WHERE user_id=$1))
ON CONFLICT (user_id, symbol) DO NOTHING;

-- 约束：每用户上限 100 条，应用层检查（INSERT 前 COUNT）
```

### 9.2 行情缓存（Redis）

```
Key 格式：
  quote:{symbol}              // Hash，字段同 7.1 response
  quote:{symbol}:ts           // 最后更新时间戳 (unix ms)
  kline:{symbol}:{period}     // ZSet，score=unix_sec, member=JSON candle

TTL：
  实时行情：60s（数据源推送时刷新）
  延迟行情（访客）：1200s（15min 对应）
  K 线缓存：300s（5min）
```

---

## 十、验收标准

| 场景 | 标准 |
|------|------|
| 行情实时性 | 注册用户行情延迟 < 500ms（P99） |
| 访客延迟标识 | 100% 的延迟价格均有 "Delayed" 标识 |
| K 线可交互 | 双指缩放、长按十字线功能正常 |
| 搜索响应 | < 300ms 返回结果 |
| 自选同步 | 多设备自选股实时同步 |
| 港股占位 | HK Tab 显示 "敬请期待"，不报错 |
| symbols 上限 | 超过 50 个 symbols 返回 400 |
| K 线分页 | max 500 根，cursor 正确翻页 |
