#!/bin/bash
# Flutter App 测试启动脚本（连接到 mock server）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 检查 mock server 是否运行
if ! curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "❌ Mock server 未运行！"
    echo "请先启动 mock server："
    echo "  cd ../mock-server"
    echo "  ./start.sh normal"
    exit 1
fi

STRATEGY=$(curl -s http://localhost:8080/health | grep -o '"strategy":"[^"]*"' | cut -d'"' -f4)
echo "✅ Mock server 运行中 (strategy: $STRATEGY)"
echo ""

# 检查设备
DEVICE="${1:-}"
if [ -z "$DEVICE" ]; then
    echo "📱 可用设备："
    flutter devices
    echo ""
    echo "使用方式："
    echo "  ./run-with-mock.sh <device-id>"
    echo "  ./run-with-mock.sh iPhone        # iOS 模拟器"
    echo "  ./run-with-mock.sh emulator      # Android 模拟器"
    exit 0
fi

# 根据设备类型设置 WebSocket URL
if [[ "$DEVICE" == *"emulator"* ]] || [[ "$DEVICE" == *"android"* ]]; then
    WS_URL="ws://10.0.2.2:8080/ws/market-data"
    echo "🤖 Android 模拟器 → 使用 10.0.2.2"
else
    WS_URL="ws://localhost:8080/ws/market-data"
    echo "📱 iOS 模拟器/真机 → 使用 localhost"
fi

echo "🚀 启动 Flutter app..."
echo "   Device: $DEVICE"
echo "   WebSocket: $WS_URL"
echo ""

flutter run -d "$DEVICE" --dart-define=MARKET_WS_URL="$WS_URL"
