-- 交易系统数据库迁移
-- PostgreSQL Schema for Trading Engine

-- ============================================================
-- 订单表 (按月分区)
-- ============================================================
CREATE TABLE orders (
    id                BIGSERIAL,
    order_id          UUID NOT NULL,
    client_order_id   UUID NOT NULL,
    exchange_order_id TEXT,
    user_id           BIGINT NOT NULL,
    account_id        BIGINT NOT NULL,
    symbol            TEXT NOT NULL,
    market            TEXT NOT NULL,
    exchange          TEXT,
    side              TEXT NOT NULL,
    order_type        TEXT NOT NULL,
    time_in_force     TEXT NOT NULL DEFAULT 'DAY',
    quantity          BIGINT NOT NULL,
    price             NUMERIC(20, 8),
    stop_price        NUMERIC(20, 8),
    trail_amount      NUMERIC(20, 8),
    status            TEXT NOT NULL,
    filled_qty        BIGINT NOT NULL DEFAULT 0,
    avg_fill_price    NUMERIC(20, 8),
    remaining_qty     BIGINT NOT NULL,
    commission        NUMERIC(20, 8) NOT NULL DEFAULT 0,
    total_fees        NUMERIC(20, 8) NOT NULL DEFAULT 0,
    source            TEXT NOT NULL,
    ip_address        INET,
    device_id         TEXT,
    risk_result       JSONB,
    reject_reason     TEXT,
    idempotency_key   UUID NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    submitted_at      TIMESTAMPTZ,
    completed_at      TIMESTAMPTZ,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, created_at),
    UNIQUE (order_id, created_at),
    UNIQUE (idempotency_key, created_at)
) PARTITION BY RANGE (created_at);

-- 示例分区 (生产环境应自动创建)
CREATE TABLE orders_2026_03 PARTITION OF orders
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE orders_2026_04 PARTITION OF orders
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE INDEX idx_orders_user ON orders (user_id, created_at DESC);
CREATE INDEX idx_orders_account ON orders (account_id, status, created_at DESC);
CREATE INDEX idx_orders_symbol ON orders (symbol, market, created_at DESC);
CREATE INDEX idx_orders_active ON orders (status, created_at DESC)
    WHERE status IN ('OPEN', 'PARTIAL_FILL', 'PENDING', 'CANCEL_SENT');

-- ============================================================
-- 成交明细表
-- ============================================================
CREATE TABLE executions (
    id                BIGSERIAL PRIMARY KEY,
    execution_id      UUID UNIQUE NOT NULL,
    order_id          UUID NOT NULL,
    user_id           BIGINT NOT NULL,
    account_id        BIGINT NOT NULL,
    symbol            TEXT NOT NULL,
    market            TEXT NOT NULL,
    side              TEXT NOT NULL,
    quantity          BIGINT NOT NULL,
    price             NUMERIC(20, 8) NOT NULL,
    commission        NUMERIC(20, 8) NOT NULL DEFAULT 0,
    sec_fee           NUMERIC(20, 8) NOT NULL DEFAULT 0,
    taf               NUMERIC(20, 8) NOT NULL DEFAULT 0,
    exchange_fee      NUMERIC(20, 8) NOT NULL DEFAULT 0,
    stamp_duty        NUMERIC(20, 8) NOT NULL DEFAULT 0,
    trading_levy      NUMERIC(20, 8) NOT NULL DEFAULT 0,
    trading_fee       NUMERIC(20, 8) NOT NULL DEFAULT 0,
    platform_fee      NUMERIC(20, 8) NOT NULL DEFAULT 0,
    total_fees        NUMERIC(20, 8) NOT NULL DEFAULT 0,
    net_amount        NUMERIC(20, 8) NOT NULL,
    settlement_date   DATE NOT NULL,
    settled           BOOLEAN NOT NULL DEFAULT FALSE,
    settled_at        TIMESTAMPTZ,
    exchange_exec_id  TEXT,
    venue             TEXT,
    executed_at       TIMESTAMPTZ NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_exec_order ON executions (order_id);
CREATE INDEX idx_exec_account ON executions (account_id, executed_at DESC);
CREATE INDEX idx_exec_settlement ON executions (settlement_date, settled) WHERE settled = FALSE;
CREATE INDEX idx_exec_symbol ON executions (symbol, market, executed_at DESC);

-- ============================================================
-- 持仓表
-- ============================================================
CREATE TABLE positions (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    account_id      BIGINT NOT NULL,
    symbol          TEXT NOT NULL,
    market          TEXT NOT NULL,
    quantity        BIGINT NOT NULL DEFAULT 0,
    avg_cost_basis  NUMERIC(20, 8) NOT NULL DEFAULT 0,
    realized_pnl    NUMERIC(20, 8) NOT NULL DEFAULT 0,
    settled_qty     BIGINT NOT NULL DEFAULT 0,
    unsettled_qty   BIGINT NOT NULL DEFAULT 0,
    first_trade_at  TIMESTAMPTZ,
    last_trade_at   TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version         INT NOT NULL DEFAULT 0,
    UNIQUE (account_id, symbol, market)
);

CREATE INDEX idx_positions_user ON positions (user_id);
CREATE INDEX idx_positions_symbol ON positions (symbol, market);
CREATE INDEX idx_positions_nonzero ON positions (account_id)
    WHERE quantity != 0;

-- ============================================================
-- 订单事件表 (Event Sourcing, Append-Only)
-- ============================================================
CREATE TABLE order_events (
    id          BIGSERIAL PRIMARY KEY,
    event_id    UUID UNIQUE NOT NULL,
    order_id    UUID NOT NULL,
    event_type  TEXT NOT NULL,
    event_data  JSONB NOT NULL,
    sequence    INT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_order_events_order ON order_events (order_id, sequence);
CREATE INDEX idx_order_events_type ON order_events (event_type, created_at DESC);

-- ============================================================
-- 保证金快照表
-- ============================================================
CREATE TABLE margin_snapshots (
    id                  BIGSERIAL PRIMARY KEY,
    account_id          BIGINT NOT NULL,
    total_equity        NUMERIC(20, 8) NOT NULL,
    initial_margin      NUMERIC(20, 8) NOT NULL,
    maintenance_margin  NUMERIC(20, 8) NOT NULL,
    available_margin    NUMERIC(20, 8) NOT NULL,
    margin_usage_pct    NUMERIC(10, 4) NOT NULL,
    margin_call_amount  NUMERIC(20, 8) NOT NULL DEFAULT 0,
    margin_call_status  TEXT NOT NULL DEFAULT 'NONE',
    calculated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_margin_account ON margin_snapshots (account_id, calculated_at DESC);
CREATE INDEX idx_margin_call ON margin_snapshots (margin_call_status)
    WHERE margin_call_status != 'NONE';

-- ============================================================
-- 日内交易计数表 (PDT 规则)
-- ============================================================
CREATE TABLE day_trade_counts (
    id          BIGSERIAL PRIMARY KEY,
    account_id  BIGINT NOT NULL,
    trade_date  DATE NOT NULL,
    symbol      TEXT NOT NULL,
    count       INT NOT NULL DEFAULT 1,
    UNIQUE (account_id, trade_date, symbol)
);

CREATE INDEX idx_day_trades_account ON day_trade_counts (account_id, trade_date DESC);

-- ============================================================
-- 手续费配置表
-- ============================================================
CREATE TABLE fee_configs (
    id                   BIGSERIAL PRIMARY KEY,
    market               TEXT NOT NULL,
    name                 TEXT NOT NULL,
    rate_type            TEXT NOT NULL,  -- 'PER_SHARE' / 'PERCENTAGE' / 'FLAT'
    rate                 NUMERIC(20, 8) NOT NULL,
    min_amount           NUMERIC(20, 8),
    applies_to           TEXT,           -- 'BUY' / 'SELL' / 'BOTH'
    effective_from       DATE NOT NULL,
    effective_to         DATE,
    UNIQUE (market, name, effective_from)
);

-- 美股费用初始数据
INSERT INTO fee_configs (market, name, rate_type, rate, applies_to, effective_from) VALUES
    ('US', 'SEC_FEE', 'PERCENTAGE', 0.0000278, 'SELL', '2026-01-01'),
    ('US', 'FINRA_TAF', 'PER_SHARE', 0.000166, 'SELL', '2026-01-01'),
    ('US', 'EXCHANGE_FEE', 'PER_SHARE', 0.003, 'BOTH', '2026-01-01'),
    ('US', 'COMMISSION', 'PER_SHARE', 0.005, 'BOTH', '2026-01-01');

-- 港股费用初始数据
INSERT INTO fee_configs (market, name, rate_type, rate, min_amount, applies_to, effective_from) VALUES
    ('HK', 'COMMISSION', 'PERCENTAGE', 0.0003, 3.00, 'BOTH', '2026-01-01'),
    ('HK', 'STAMP_DUTY', 'PERCENTAGE', 0.0013, NULL, 'BOTH', '2026-01-01'),
    ('HK', 'TRADING_LEVY', 'PERCENTAGE', 0.000027, NULL, 'BOTH', '2026-01-01'),
    ('HK', 'TRADING_FEE', 'PERCENTAGE', 0.0000565, NULL, 'BOTH', '2026-01-01'),
    ('HK', 'PLATFORM_FEE', 'FLAT', 0.50, NULL, 'BOTH', '2026-01-01');

-- ============================================================
-- 公司行动表
-- ============================================================
CREATE TABLE corporate_actions (
    id                  BIGSERIAL PRIMARY KEY,
    action_type         TEXT NOT NULL,
    symbol              TEXT NOT NULL,
    market              TEXT NOT NULL,
    record_date         DATE NOT NULL,
    ex_date             DATE NOT NULL,
    pay_date            DATE,
    dividend_per_share  NUMERIC(20, 8),
    dividend_currency   TEXT,
    split_ratio         INT,
    description         TEXT,
    status              TEXT NOT NULL DEFAULT 'PENDING',
    processed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_corp_actions_date ON corporate_actions (ex_date, status);
CREATE INDEX idx_corp_actions_symbol ON corporate_actions (symbol, market);
