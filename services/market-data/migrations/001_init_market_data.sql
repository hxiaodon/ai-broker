-- 行情系统数据库迁移
-- TimescaleDB Schema for Market Data

CREATE EXTENSION IF NOT EXISTS timescaledb;

-- ============================================================
-- K线表
-- ============================================================
CREATE TABLE IF NOT EXISTS klines (
    time        TIMESTAMPTZ    NOT NULL,
    symbol      TEXT           NOT NULL,
    market      TEXT           NOT NULL,
    interval    TEXT           NOT NULL,
    open        NUMERIC(20, 8) NOT NULL,
    high        NUMERIC(20, 8) NOT NULL,
    low         NUMERIC(20, 8) NOT NULL,
    close       NUMERIC(20, 8) NOT NULL,
    volume      BIGINT         NOT NULL,
    turnover    NUMERIC(30, 8) NOT NULL DEFAULT 0,
    trade_count INT            NOT NULL DEFAULT 0
);

SELECT create_hypertable('klines', 'time', chunk_time_interval => INTERVAL '1 month');

CREATE INDEX idx_klines_symbol_interval ON klines (symbol, interval, time DESC);
CREATE INDEX idx_klines_market ON klines (market, time DESC);

-- ============================================================
-- 逐笔成交表
-- ============================================================
CREATE TABLE IF NOT EXISTS trades (
    time        TIMESTAMPTZ    NOT NULL,
    symbol      TEXT           NOT NULL,
    market      TEXT           NOT NULL,
    price       NUMERIC(20, 8) NOT NULL,
    volume      BIGINT         NOT NULL,
    trade_id    TEXT,
    side        TEXT,
    conditions  TEXT[]         DEFAULT '{}'
);

SELECT create_hypertable('trades', 'time', chunk_time_interval => INTERVAL '1 day');

CREATE INDEX idx_trades_symbol ON trades (symbol, time DESC);
CREATE INDEX idx_trades_market ON trades (market, time DESC);

-- ============================================================
-- 连续聚合：自动从 1m K线生成 5m K线
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS klines_5m
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('5 minutes', time) AS time,
    symbol,
    market,
    first(open, time)  AS open,
    max(high)          AS high,
    min(low)           AS low,
    last(close, time)  AS close,
    sum(volume)        AS volume,
    sum(turnover)      AS turnover,
    sum(trade_count)   AS trade_count
FROM klines
WHERE interval = '1m'
GROUP BY time_bucket('5 minutes', time), symbol, market
WITH NO DATA;

-- 连续聚合：自动从 1m K线生成 15m K线
CREATE MATERIALIZED VIEW IF NOT EXISTS klines_15m
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('15 minutes', time) AS time,
    symbol,
    market,
    first(open, time)  AS open,
    max(high)          AS high,
    min(low)           AS low,
    last(close, time)  AS close,
    sum(volume)        AS volume,
    sum(turnover)      AS turnover,
    sum(trade_count)   AS trade_count
FROM klines
WHERE interval = '1m'
GROUP BY time_bucket('15 minutes', time), symbol, market
WITH NO DATA;

-- 连续聚合：自动从 1m K线生成 1h K线
CREATE MATERIALIZED VIEW IF NOT EXISTS klines_1h
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS time,
    symbol,
    market,
    first(open, time)  AS open,
    max(high)          AS high,
    min(low)           AS low,
    last(close, time)  AS close,
    sum(volume)        AS volume,
    sum(turnover)      AS turnover,
    sum(trade_count)   AS trade_count
FROM klines
WHERE interval = '1m'
GROUP BY time_bucket('1 hour', time), symbol, market
WITH NO DATA;

-- ============================================================
-- 连续聚合刷新策略
-- ============================================================
SELECT add_continuous_aggregate_policy('klines_5m',
    start_offset    => INTERVAL '1 hour',
    end_offset      => INTERVAL '5 minutes',
    schedule_interval => INTERVAL '5 minutes'
);

SELECT add_continuous_aggregate_policy('klines_15m',
    start_offset    => INTERVAL '2 hours',
    end_offset      => INTERVAL '15 minutes',
    schedule_interval => INTERVAL '15 minutes'
);

SELECT add_continuous_aggregate_policy('klines_1h',
    start_offset    => INTERVAL '4 hours',
    end_offset      => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour'
);

-- ============================================================
-- 数据保留策略
-- ============================================================
SELECT add_retention_policy('trades', INTERVAL '90 days');
SELECT add_retention_policy('klines', INTERVAL '10 years');

-- ============================================================
-- 压缩策略（降低存储成本）
-- ============================================================
ALTER TABLE klines SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'symbol, market, interval'
);
SELECT add_compression_policy('klines', INTERVAL '7 days');

ALTER TABLE trades SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'symbol, market'
);
SELECT add_compression_policy('trades', INTERVAL '3 days');
