-- migrations/003_add_quote_fields.sql
-- Add missing fields to quotes table (P2-03)

-- +goose Up

ALTER TABLE quotes
    ADD COLUMN name VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'Company name (English)' AFTER market,
    ADD COLUMN name_zh VARCHAR(255) NULL COMMENT 'Company name (Chinese)' AFTER name,
    ADD COLUMN turnover DECIMAL(20,8) NOT NULL DEFAULT 0 COMMENT 'Daily turnover amount' AFTER volume,
    ADD COLUMN market_cap DECIMAL(20,8) NOT NULL DEFAULT 0 COMMENT 'Market capitalization' AFTER ask_size,
    ADD COLUMN pe_ratio DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT 'P/E ratio (TTM)' AFTER market_cap,
    ADD COLUMN market_status VARCHAR(20) NOT NULL DEFAULT 'CLOSED' COMMENT 'PRE_MARKET, REGULAR, LUNCH_BREAK, AFTER_HOURS, CLOSED' AFTER pe_ratio,
    ADD COLUMN `delayed` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = 15-min delayed, 0 = real-time' AFTER market_status;

-- +goose Down

ALTER TABLE quotes
    DROP COLUMN `delayed`,
    DROP COLUMN market_status,
    DROP COLUMN pe_ratio,
    DROP COLUMN market_cap,
    DROP COLUMN turnover,
    DROP COLUMN name_zh,
    DROP COLUMN name;
