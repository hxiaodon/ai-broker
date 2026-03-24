#!/bin/bash
# test/e2e/setup_test_data.sh
# 准备测试数据

set -e

MYSQL_HOST=${MYSQL_HOST:-127.0.0.1}
MYSQL_PORT=${MYSQL_PORT:-3307}
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-test}
MYSQL_DB=${MYSQL_DB:-market_data_test}

echo "==> Setting up test data..."

# 插入测试股票数据
mysql -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DB} <<EOF
-- 清理旧数据
TRUNCATE TABLE quotes;
TRUNCATE TABLE stocks;
TRUNCATE TABLE watchlist_items;

-- 插入测试股票
INSERT INTO stocks (symbol, name, name_cn, market, exchange, sector, industry) VALUES
('AAPL', 'Apple Inc.', '苹果公司', 'US', 'NASDAQ', 'Technology', 'Consumer Electronics'),
('MSFT', 'Microsoft Corporation', '微软', 'US', 'NASDAQ', 'Technology', 'Software'),
('TSLA', 'Tesla Inc.', '特斯拉', 'US', 'NASDAQ', 'Consumer Cyclical', 'Auto Manufacturers'),
('0700', 'Tencent Holdings', '腾讯控股', 'HK', 'HKEX', 'Technology', 'Internet'),
('9988', 'Alibaba Group', '阿里巴巴', 'HK', 'HKEX', 'Consumer Cyclical', 'Internet Retail');

-- 插入初始报价
INSERT INTO quotes (symbol, market, price, open_price, high_price, low_price, prev_close, volume, bid, ask, last_updated_at) VALUES
('AAPL', 'US', 150.00, 149.50, 151.00, 149.00, 149.50, 1000000, 149.95, 150.05, UTC_TIMESTAMP(6)),
('MSFT', 'US', 380.00, 378.00, 382.00, 377.50, 378.50, 800000, 379.90, 380.10, UTC_TIMESTAMP(6));

EOF

echo "✓ Test data setup complete"
