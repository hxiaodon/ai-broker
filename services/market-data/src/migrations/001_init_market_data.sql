-- migrations/001_init_market_data.sql
-- Market Data Service — Initial Schema
-- All timestamps in UTC. All prices use DECIMAL(20,8) — never FLOAT/DOUBLE.

-- +goose Up

-- Quotes table: latest quote snapshot per symbol
CREATE TABLE quotes (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol          VARCHAR(20)     NOT NULL,
    market          VARCHAR(5)      NOT NULL COMMENT 'US or HK',
    price           DECIMAL(20,8)   NOT NULL COMMENT 'shopspring/decimal — never float64',
    open_price      DECIMAL(20,8)   NOT NULL COMMENT 'shopspring/decimal — never float64',
    high_price      DECIMAL(20,8)   NOT NULL COMMENT 'shopspring/decimal — never float64',
    low_price       DECIMAL(20,8)   NOT NULL COMMENT 'shopspring/decimal — never float64',
    prev_close      DECIMAL(20,8)   NOT NULL COMMENT 'Previous Regular Session close; shopspring/decimal — never float64',
    volume          BIGINT          NOT NULL DEFAULT 0,
    bid             DECIMAL(20,8)   NOT NULL COMMENT 'shopspring/decimal — never float64',
    bid_size        BIGINT          NOT NULL DEFAULT 0,
    ask             DECIMAL(20,8)   NOT NULL COMMENT 'shopspring/decimal — never float64',
    ask_size        BIGINT          NOT NULL DEFAULT 0,
    last_updated_at TIMESTAMP(6)    NOT NULL COMMENT 'UTC timestamp of last feed update',
    created_at      TIMESTAMP(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at      TIMESTAMP(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX idx_quotes_symbol (symbol),
    INDEX idx_quotes_market (market)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Latest quote snapshot per symbol';

-- Market status table: current trading phase per exchange
CREATE TABLE market_status (
    id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    market     VARCHAR(5)   NOT NULL COMMENT 'US or HK',
    phase      VARCHAR(20)  NOT NULL COMMENT 'PRE_MARKET, REGULAR, LUNCH_BREAK, AFTER_HOURS, CLOSED',
    updated_at TIMESTAMP(6) NOT NULL COMMENT 'UTC',
    UNIQUE INDEX idx_market_status_market (market)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Exchange trading status';

-- K-line table: candlestick data with partitioned storage
CREATE TABLE klines (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol        VARCHAR(20)     NOT NULL,
    interval_type VARCHAR(10)     NOT NULL COMMENT '1min, 5min, 15min, 30min, 1h, 1D, 1W, 1M',
    open_price    DECIMAL(20,8)   NOT NULL COMMENT 'shopspring/decimal — never float64',
    high_price    DECIMAL(20,8)   NOT NULL COMMENT 'shopspring/decimal — never float64',
    low_price     DECIMAL(20,8)   NOT NULL COMMENT 'shopspring/decimal — never float64',
    close_price   DECIMAL(20,8)   NOT NULL COMMENT 'shopspring/decimal — never float64',
    volume        BIGINT          NOT NULL DEFAULT 0,
    start_time    TIMESTAMP(6)    NOT NULL COMMENT 'UTC — start of candle period',
    end_time      TIMESTAMP(6)    NOT NULL COMMENT 'UTC — end of candle period',
    adjusted      TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 if prices adjusted for corporate actions',
    created_at    TIMESTAMP(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    INDEX idx_klines_symbol_interval_start (symbol, interval_type, start_time),
    UNIQUE INDEX idx_klines_unique (symbol, interval_type, start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='K-line candlestick data';

-- Stocks table: searchable stock metadata
CREATE TABLE stocks (
    id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol   VARCHAR(20)  NOT NULL,
    name     VARCHAR(255) NOT NULL COMMENT 'Company name (English)',
    name_cn  VARCHAR(255) NULL COMMENT 'Company name (Chinese)',
    market   VARCHAR(5)   NOT NULL COMMENT 'US or HK',
    exchange VARCHAR(20)  NOT NULL COMMENT 'NYSE, NASDAQ, HKEX',
    sector   VARCHAR(100) NULL,
    industry VARCHAR(100) NULL,
    UNIQUE INDEX idx_stocks_symbol (symbol),
    INDEX idx_stocks_market (market),
    FULLTEXT INDEX idx_stocks_search (name, name_cn)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stock metadata for search';

-- Watchlist table: user watchlist items
CREATE TABLE watchlist_items (
    id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id    BIGINT       NOT NULL,
    symbol     VARCHAR(20)  NOT NULL,
    market     VARCHAR(5)   NOT NULL COMMENT 'US or HK',
    sort_order INT          NOT NULL DEFAULT 0,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE INDEX idx_watchlist_user_symbol (user_id, symbol),
    INDEX idx_watchlist_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='User watchlist items';

-- Outbox events table: transactional outbox for Kafka publishing
CREATE TABLE outbox_events (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    topic        VARCHAR(255)    NOT NULL,
    payload      BLOB            NOT NULL,
    status       ENUM('PENDING','PUBLISHED','FAILED') NOT NULL DEFAULT 'PENDING',
    created_at   TIMESTAMP(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    published_at TIMESTAMP(6)    NULL,
    retry_count  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    INDEX idx_outbox_status_created (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Kafka outbox events — append-only until published';

-- Audit log table: immutable, append-only, 7-year retention
CREATE TABLE audit_logs (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_type    VARCHAR(100)  NOT NULL,
    actor_id      BIGINT        NULL,
    actor_type    VARCHAR(50)   NULL COMMENT 'CUSTOMER, SYSTEM, ADMIN',
    resource_type VARCHAR(50)   NOT NULL,
    resource_id   VARCHAR(100)  NOT NULL,
    details       JSON          NULL,
    ip_address    VARCHAR(45)   NULL,
    correlation_id VARCHAR(100) NULL,
    created_at    TIMESTAMP(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    INDEX idx_audit_event_type (event_type),
    INDEX idx_audit_resource (resource_type, resource_id),
    INDEX idx_audit_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Immutable audit log — NO UPDATE/DELETE — 7-year retention';

-- Seed initial market status
INSERT INTO market_status (market, phase, updated_at) VALUES
    ('US', 'CLOSED', UTC_TIMESTAMP(6)),
    ('HK', 'CLOSED', UTC_TIMESTAMP(6));

-- +goose Down

DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS outbox_events;
DROP TABLE IF EXISTS watchlist_items;
DROP TABLE IF EXISTS stocks;
DROP TABLE IF EXISTS klines;
DROP TABLE IF EXISTS market_status;
DROP TABLE IF EXISTS quotes;
