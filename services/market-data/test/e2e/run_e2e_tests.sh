#!/bin/bash
# test/e2e/run_e2e_tests.sh
# 完整的 E2E 测试流程：启动环境 → 造数据 → 运行测试 → 清理

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "==> Starting E2E Test Suite"
echo "Project root: $PROJECT_ROOT"

# 1. 启动测试环境
echo ""
echo "==> Step 1: Starting test environment..."
cd "$SCRIPT_DIR"
docker-compose -f docker-compose.test.yml up -d

# 2. 等待服务健康
echo ""
echo "==> Step 2: Waiting for services to be healthy..."
sleep 10

# 3. 运行数据库迁移
echo ""
echo "==> Step 3: Running database migrations..."
docker exec market-data-mysql-test mysql -uroot -ptest market_data_test < "$PROJECT_ROOT/migrations/001_init_market_data.sql" || true

# 4. 准备测试数据
echo ""
echo "==> Step 4: Setting up test data..."
bash "$SCRIPT_DIR/setup_test_data.sh"

# 5. 运行 API 测试
echo ""
echo "==> Step 5: Running API tests..."
python3 "$SCRIPT_DIR/api_test.py"

TEST_RESULT=$?

# 6. 清理（可选）
if [ "$KEEP_ENV" != "true" ]; then
    echo ""
    echo "==> Step 6: Cleaning up..."
    docker-compose -f docker-compose.test.yml down -v
else
    echo ""
    echo "==> Keeping test environment running (KEEP_ENV=true)"
fi

if [ $TEST_RESULT -eq 0 ]; then
    echo ""
    echo "✓ E2E tests passed!"
    exit 0
else
    echo ""
    echo "✗ E2E tests failed!"
    exit 1
fi
