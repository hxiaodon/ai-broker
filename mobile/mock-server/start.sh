#!/bin/bash
# Mock Server 快速启动脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

STRATEGY="${1:-normal}"
PORT="${2:-8080}"

echo "🚀 Starting mock server..."
echo "   Strategy: $STRATEGY"
echo "   Port: $PORT"
echo ""

# Build if binary doesn't exist
if [ ! -f "mock-server" ]; then
    echo "📦 Building mock-server..."
    go build -o mock-server .
fi

# Start server
./mock-server --strategy="$STRATEGY" --port="$PORT"
