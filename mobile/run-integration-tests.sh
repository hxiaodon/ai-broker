#!/bin/bash
set -e

# Integration Test Runner with Mock Server
# Runs Flutter integration tests against mock server

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MOBILE_DIR="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$MOBILE_DIR/src"
MOCK_SERVER_DIR="$MOBILE_DIR/mock-server"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "==================== Flutter Integration Tests ===================="
echo "🚀 Starting integration tests with mock server..."
echo ""

# Start mock server
echo "📡 Starting mock server on localhost:8080..."
cd "$MOCK_SERVER_DIR"
./mock-server --strategy=normal &
MOCK_PID=$!
echo "✅ Mock server started (PID: $MOCK_PID)"
sleep 2

# Verify mock server is running
echo ""
echo "🔍 Verifying mock server is running..."
if curl -s http://localhost:8080/health | grep -q "ok"; then
    echo "✅ Mock server health check passed"
else
    echo "❌ Mock server health check failed"
    kill $MOCK_PID
    exit 1
fi

# Function to cleanup mock server on exit
cleanup() {
    echo ""
    echo "🛑 Cleaning up..."
    kill $MOCK_PID 2>/dev/null || true
    wait $MOCK_PID 2>/dev/null || true
    echo "✅ Mock server stopped"
}
trap cleanup EXIT

# Change to Flutter project directory
cd "$SRC_DIR"

echo ""
echo "🧪 Running integration tests..."
echo "================================"
echo ""

# Run integration tests
# Note: This requires a connected device or emulator
flutter test integration_test/ \
    --reporter=expanded \
    --verbose \
    2>&1

TEST_RESULT=$?

echo ""
echo "================================"
if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ All integration tests passed!${NC}"
else
    echo -e "${RED}❌ Some integration tests failed${NC}"
fi

exit $TEST_RESULT
