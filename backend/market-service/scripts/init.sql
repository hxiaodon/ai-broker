-- Market Service Database Schema
-- 行情服务数据库初始化脚本

-- 创建数据库
CREATE DATABASE IF NOT EXISTS market_service DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE market_service;

-- 1. 股票基本信息表
CREATE TABLE IF NOT EXISTS stocks (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL COMMENT '股票代码',
    name VARCHAR(255) NOT NULL COMMENT '公司名称',
    name_cn VARCHAR(255) DEFAULT NULL COMMENT '中文名称',
    market VARCHAR(10) NOT NULL COMMENT '市场: US/HK',
    market_cap VARCHAR(20) DEFAULT NULL COMMENT '市值',
    pe DECIMAL(10, 2) DEFAULT NULL COMMENT '市盈率',
    pb DECIMAL(10, 2) DEFAULT NULL COMMENT '市净率',
    dividend_yield DECIMAL(5, 2) DEFAULT NULL COMMENT '股息率(%)',
    week_52_high DECIMAL(10, 2) DEFAULT NULL COMMENT '52周最高价',
    week_52_low DECIMAL(10, 2) DEFAULT NULL COMMENT '52周最低价',
    avg_volume VARCHAR(20) DEFAULT NULL COMMENT '平均成交量',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_symbol (symbol),
    KEY idx_market (market),
    KEY idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='股票基本信息表';

-- 2. 实时行情表
CREATE TABLE IF NOT EXISTS quotes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL COMMENT '股票代码',
    price DECIMAL(10, 2) NOT NULL COMMENT '当前价格',
    open DECIMAL(10, 2) DEFAULT NULL COMMENT '开盘价',
    high DECIMAL(10, 2) DEFAULT NULL COMMENT '最高价',
    low DECIMAL(10, 2) DEFAULT NULL COMMENT '最低价',
    volume BIGINT DEFAULT NULL COMMENT '成交量',
    change_amount DECIMAL(10, 2) DEFAULT NULL COMMENT '涨跌额',
    change_percent DECIMAL(5, 2) DEFAULT NULL COMMENT '涨跌幅(%)',
    timestamp BIGINT NOT NULL COMMENT '行情时间戳(毫秒)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_symbol (symbol),
    KEY idx_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='实时行情表';

-- 3. K线数据表
CREATE TABLE IF NOT EXISTS klines (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL COMMENT '股票代码',
    interval VARCHAR(10) NOT NULL COMMENT '时间间隔: 1m/1d/1w/1M',
    open DECIMAL(10, 2) NOT NULL COMMENT '开盘价',
    high DECIMAL(10, 2) NOT NULL COMMENT '最高价',
    low DECIMAL(10, 2) NOT NULL COMMENT '最低价',
    close DECIMAL(10, 2) NOT NULL COMMENT '收盘价',
    volume BIGINT NOT NULL COMMENT '成交量',
    timestamp BIGINT NOT NULL COMMENT 'K线时间戳(毫秒)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_symbol_interval_timestamp (symbol, interval, timestamp),
    KEY idx_symbol_interval (symbol, interval),
    KEY idx_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='K线数据表';

-- 4. 自选股表
CREATE TABLE IF NOT EXISTS watchlists (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    symbol VARCHAR(20) NOT NULL COMMENT '股票代码',
    sort_order INT DEFAULT 0 COMMENT '排序顺序',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_symbol (user_id, symbol),
    KEY idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='自选股表';

-- 5. 股票新闻表
CREATE TABLE IF NOT EXISTS news (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    news_id VARCHAR(100) NOT NULL COMMENT '新闻ID',
    symbol VARCHAR(20) NOT NULL COMMENT '相关股票代码',
    title VARCHAR(500) NOT NULL COMMENT '新闻标题',
    summary TEXT COMMENT '新闻摘要',
    source VARCHAR(100) DEFAULT NULL COMMENT '新闻来源',
    url VARCHAR(500) DEFAULT NULL COMMENT '新闻链接',
    publish_time BIGINT NOT NULL COMMENT '发布时间戳(毫秒)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_news_id (news_id),
    KEY idx_symbol (symbol),
    KEY idx_publish_time (publish_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='股票新闻表';

-- 6. 财报数据表
CREATE TABLE IF NOT EXISTS financials (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL COMMENT '股票代码',
    quarter VARCHAR(20) NOT NULL COMMENT '财报季度: Q1 2026',
    report_date DATE NOT NULL COMMENT '财报日期',
    revenue VARCHAR(20) DEFAULT NULL COMMENT '营收',
    net_income VARCHAR(20) DEFAULT NULL COMMENT '净利润',
    eps DECIMAL(10, 2) DEFAULT NULL COMMENT '每股收益',
    revenue_growth DECIMAL(5, 2) DEFAULT NULL COMMENT '营收增长率(%)',
    net_income_growth DECIMAL(5, 2) DEFAULT NULL COMMENT '净利润增长率(%)',
    next_earnings_date DATE DEFAULT NULL COMMENT '下次财报日期',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_symbol_quarter (symbol, quarter),
    KEY idx_symbol (symbol),
    KEY idx_report_date (report_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='财报数据表';

-- 7. 热门搜索表
CREATE TABLE IF NOT EXISTS hot_searches (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL COMMENT '股票代码',
    search_count INT DEFAULT 0 COMMENT '搜索次数',
    rank INT DEFAULT 0 COMMENT '排名',
    date DATE NOT NULL COMMENT '统计日期',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_symbol_date (symbol, date),
    KEY idx_date_rank (date, rank)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='热门搜索表';

-- 插入测试数据
INSERT INTO stocks (symbol, name, name_cn, market, market_cap, pe, pb, dividend_yield, week_52_high, week_52_low, avg_volume) VALUES
('AAPL', 'Apple Inc.', '苹果', 'US', '2.8T', 28.5, 42.3, 0.52, 199.62, 164.08, '48.5M'),
('TSLA', 'Tesla Inc.', '特斯拉', 'US', '780B', 65.3, 12.5, 0.00, 299.29, 152.37, '52.1M'),
('MSFT', 'Microsoft', '微软', 'US', '2.9T', 32.1, 11.8, 0.75, 420.82, 309.45, '38.7M'),
('GOOGL', 'Alphabet', '谷歌', 'US', '1.8T', 24.8, 6.2, 0.00, 153.78, 121.46, '28.3M'),
('AMZN', 'Amazon', '亚马逊', 'US', '1.9T', 58.2, 8.9, 0.00, 201.20, 118.35, '41.5M'),
('NVDA', 'NVIDIA', '英伟达', 'US', '2.1T', 72.4, 45.6, 0.03, 974.00, 108.13, '67.8M');

INSERT INTO quotes (symbol, price, open, high, low, volume, change_amount, change_percent, timestamp) VALUES
('AAPL', 175.23, 173.50, 176.00, 172.80, 45200000, 2.34, 1.35, UNIX_TIMESTAMP() * 1000),
('TSLA', 245.67, 248.00, 250.50, 244.20, 52100000, -3.21, -1.29, UNIX_TIMESTAMP() * 1000),
('MSFT', 378.90, 376.50, 380.20, 375.80, 38700000, 5.12, 1.37, UNIX_TIMESTAMP() * 1000),
('GOOGL', 142.56, 144.00, 145.30, 141.80, 28300000, -1.89, -1.31, UNIX_TIMESTAMP() * 1000),
('AMZN', 178.34, 176.50, 179.80, 175.90, 41500000, 3.45, 1.97, UNIX_TIMESTAMP() * 1000),
('NVDA', 823.45, 815.00, 830.00, 810.50, 67800000, 12.67, 1.56, UNIX_TIMESTAMP() * 1000);

-- 创建索引优化查询性能
CREATE INDEX idx_quotes_symbol_timestamp ON quotes(symbol, timestamp DESC);
CREATE INDEX idx_klines_symbol_interval_timestamp ON klines(symbol, interval, timestamp DESC);
