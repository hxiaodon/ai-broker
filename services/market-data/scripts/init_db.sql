-- Market Service 数据库初始化脚本

-- 创建数据库
CREATE DATABASE IF NOT EXISTS market_service DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE market_service;

-- 股票表
CREATE TABLE IF NOT EXISTS stocks (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    name_cn VARCHAR(255),
    market VARCHAR(10) NOT NULL,
    market_cap VARCHAR(20),
    pe DECIMAL(10,2),
    pb DECIMAL(10,2),
    dividend_yield DECIMAL(5,2),
    week_52_high DECIMAL(10,2),
    week_52_low DECIMAL(10,2),
    avg_volume VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_market (market)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 行情表
CREATE TABLE IF NOT EXISTS quotes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    price DECIMAL(20,8) NOT NULL,
    open DECIMAL(20,8),
    high DECIMAL(20,8),
    low DECIMAL(20,8),
    volume BIGINT,
    change_amount DECIMAL(20,8),
    change_percent DECIMAL(10,4),
    timestamp BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_symbol (symbol),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- K线表
CREATE TABLE IF NOT EXISTS klines (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    `interval` VARCHAR(10) NOT NULL,
    open DECIMAL(20,8) NOT NULL,
    high DECIMAL(20,8) NOT NULL,
    low DECIMAL(20,8) NOT NULL,
    close DECIMAL(20,8) NOT NULL,
    volume BIGINT NOT NULL,
    timestamp BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_symbol_interval_timestamp (symbol, `interval`, timestamp),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 自选股表
CREATE TABLE IF NOT EXISTS watchlists (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_symbol (user_id, symbol),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 新闻表
CREATE TABLE IF NOT EXISTS news (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    news_id VARCHAR(100) NOT NULL UNIQUE,
    symbol VARCHAR(20) NOT NULL,
    title VARCHAR(500) NOT NULL,
    summary TEXT,
    source VARCHAR(100),
    url VARCHAR(500),
    publish_time BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_symbol (symbol),
    INDEX idx_publish_time (publish_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 财报表
CREATE TABLE IF NOT EXISTS financials (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    quarter VARCHAR(20) NOT NULL,
    report_date DATE NOT NULL,
    revenue VARCHAR(20),
    net_income VARCHAR(20),
    eps DECIMAL(10,4),
    revenue_growth DECIMAL(10,4),
    net_income_growth DECIMAL(10,4),
    next_earnings_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_symbol_quarter (symbol, quarter),
    INDEX idx_symbol (symbol),
    INDEX idx_report_date (report_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 热门搜索表
CREATE TABLE IF NOT EXISTS hot_searches (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    search_count INT DEFAULT 0,
    `rank` INT DEFAULT 0,
    date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_symbol_date (symbol, date),
    INDEX idx_date_rank (date, `rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 插入 Mock 数据

-- 美股数据
INSERT INTO stocks (symbol, name, name_cn, market, market_cap, pe, pb, dividend_yield, week_52_high, week_52_low, avg_volume) VALUES
('AAPL', 'Apple Inc.', '苹果公司', 'US', '2.8T', 28.50, 45.20, 0.52, 198.23, 124.17, '58234567'),
('TSLA', 'Tesla Inc.', '特斯拉', 'US', '780B', 65.30, 12.80, 0.00, 299.29, 101.81, '125678901'),
('GOOGL', 'Alphabet Inc.', '谷歌', 'US', '1.7T', 24.10, 6.50, 0.00, 151.55, 83.34, '28456789'),
('MSFT', 'Microsoft Corporation', '微软', 'US', '2.5T', 32.40, 11.20, 0.83, 384.30, 213.43, '23456789'),
('AMZN', 'Amazon.com Inc.', '亚马逊', 'US', '1.5T', 58.20, 8.90, 0.00, 178.50, 81.43, '45678901');

-- 港股数据
INSERT INTO stocks (symbol, name, name_cn, market, market_cap, pe, pb, dividend_yield, week_52_high, week_52_low, avg_volume) VALUES
('0700.HK', 'Tencent Holdings Ltd', '腾讯控股', 'HK', '3.2T', 18.50, 3.80, 0.35, 475.60, 245.20, '12345678'),
('9988.HK', 'Alibaba Group Holding Ltd', '阿里巴巴', 'HK', '1.8T', 12.30, 1.50, 0.00, 241.00, 58.00, '23456789'),
('0941.HK', 'China Mobile Ltd', '中国移动', 'HK', '1.5T', 9.80, 0.90, 5.20, 98.50, 48.90, '8901234'),
('1810.HK', 'Xiaomi Corporation', '小米集团', 'HK', '450B', 22.10, 4.20, 0.00, 35.90, 8.28, '45678901'),
('2318.HK', 'Ping An Insurance', '中国平安', 'HK', '980B', 6.50, 0.80, 4.50, 88.55, 33.00, '12345678');

-- 实时行情数据
INSERT INTO quotes (symbol, price, open, high, low, volume, change_amount, change_percent, timestamp) VALUES
('AAPL', 175.23, 172.89, 176.50, 172.10, 52341234, 2.34, 1.35, UNIX_TIMESTAMP() * 1000),
('TSLA', 245.67, 248.90, 251.20, 243.50, 89234567, -3.23, -1.30, UNIX_TIMESTAMP() * 1000),
('GOOGL', 138.45, 137.20, 139.80, 136.90, 23456789, 1.25, 0.91, UNIX_TIMESTAMP() * 1000),
('MSFT', 378.90, 375.60, 380.20, 374.80, 18901234, 3.30, 0.88, UNIX_TIMESTAMP() * 1000),
('AMZN', 152.34, 150.20, 153.90, 149.80, 34567890, 2.14, 1.42, UNIX_TIMESTAMP() * 1000),
('0700.HK', 368.20, 365.00, 372.50, 363.80, 8901234, 3.20, 0.88, UNIX_TIMESTAMP() * 1000),
('9988.HK', 78.50, 77.20, 79.80, 76.90, 12345678, 1.30, 1.68, UNIX_TIMESTAMP() * 1000),
('0941.HK', 68.90, 68.20, 69.50, 67.80, 5678901, 0.70, 1.03, UNIX_TIMESTAMP() * 1000),
('1810.HK', 18.45, 18.10, 18.90, 17.95, 23456789, 0.35, 1.93, UNIX_TIMESTAMP() * 1000),
('2318.HK', 45.60, 45.00, 46.20, 44.80, 9012345, 0.60, 1.33, UNIX_TIMESTAMP() * 1000);

-- K线数据 (最近10根1分钟K线)
INSERT INTO klines (symbol, `interval`, open, high, low, close, volume, timestamp) VALUES
('AAPL', '1m', 175.20, 175.30, 175.15, 175.23, 123456, UNIX_TIMESTAMP() * 1000 - 600000),
('AAPL', '1m', 175.23, 175.35, 175.20, 175.28, 134567, UNIX_TIMESTAMP() * 1000 - 540000),
('AAPL', '1m', 175.28, 175.40, 175.25, 175.32, 145678, UNIX_TIMESTAMP() * 1000 - 480000),
('AAPL', '1m', 175.32, 175.45, 175.30, 175.38, 156789, UNIX_TIMESTAMP() * 1000 - 420000),
('AAPL', '1m', 175.38, 175.50, 175.35, 175.42, 167890, UNIX_TIMESTAMP() * 1000 - 360000);

-- 新闻数据
INSERT INTO news (news_id, symbol, title, summary, source, url, publish_time) VALUES
('news_001', 'AAPL', 'Apple Announces New iPhone 16 with AI Features', 'Apple unveiled its latest iPhone 16 series with advanced AI capabilities...', 'TechCrunch', 'https://techcrunch.com/apple-iphone-16', UNIX_TIMESTAMP() * 1000 - 3600000),
('news_002', 'AAPL', 'Apple Stock Hits New All-Time High', 'Apple shares reached a new record high today as investors...', 'Bloomberg', 'https://bloomberg.com/apple-stock', UNIX_TIMESTAMP() * 1000 - 7200000),
('news_003', 'TSLA', 'Tesla Delivers Record Number of Vehicles in Q4', 'Tesla reported record vehicle deliveries in the fourth quarter...', 'Reuters', 'https://reuters.com/tesla-q4', UNIX_TIMESTAMP() * 1000 - 10800000),
('news_004', '0700.HK', '腾讯发布2024年Q4财报，营收超预期', '腾讯控股今日发布2024年第四季度财报，营收同比增长...', '财联社', 'https://cls.cn/tencent-q4', UNIX_TIMESTAMP() * 1000 - 14400000);

-- 财报数据
INSERT INTO financials (symbol, quarter, report_date, revenue, net_income, eps, revenue_growth, net_income_growth, next_earnings_date) VALUES
('AAPL', '2024Q4', '2024-10-31', '94.9B', '22.9B', 1.46, 6.0, 11.0, '2025-01-30'),
('AAPL', '2024Q3', '2024-07-31', '85.8B', '21.4B', 1.40, 5.0, 8.0, '2024-10-31'),
('TSLA', '2024Q4', '2024-10-23', '25.2B', '2.2B', 0.72, 8.0, 17.0, '2025-01-24'),
('0700.HK', '2024Q4', '2024-11-13', '167.2B', '59.8B', 6.33, 8.0, 47.0, '2025-03-20');

-- 热门搜索数据
INSERT INTO hot_searches (symbol, search_count, `rank`, date) VALUES
('AAPL', 15234, 1, CURDATE()),
('TSLA', 12456, 2, CURDATE()),
('0700.HK', 9876, 3, CURDATE()),
('NVDA', 8765, 4, CURDATE()),
('GOOGL', 7654, 5, CURDATE());

-- 自选股数据 (用户ID=1的测试数据)
INSERT INTO watchlists (user_id, symbol, sort_order) VALUES
(1, 'AAPL', 1),
(1, 'TSLA', 2),
(1, '0700.HK', 3),
(1, 'MSFT', 4);
