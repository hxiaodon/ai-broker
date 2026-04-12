#!/bin/bash

# Market Module Integration Test Runner
# 用于运行 Market 模块的三层集成测试

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MOCK_SERVER_DIR="$PROJECT_ROOT/mock-server"
SRC_DIR="$PROJECT_ROOT/src"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_header() {
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

# 检查前置条件
check_prerequisites() {
  print_header "检查前置条件"

  # Flutter
  if ! command -v flutter &> /dev/null; then
    print_error "Flutter 未安装或不在 PATH 中"
    exit 1
  fi
  print_success "Flutter SDK found: $(flutter --version | head -1)"

  # 检查连接的设备
  if [ "$TEST_TYPE" = "e2e" ] || [ "$TEST_TYPE" = "all" ]; then
    if ! flutter devices | grep -q "connected"; then
      print_warning "未检测到连接的设备或模拟器（E2E 测试需要）"
    fi
  fi

  print_success "前置条件检查完成"
}

# 启动 Mock Server
start_mock_server() {
  if [ "$TEST_TYPE" = "state-management" ]; then
    print_warning "跳过 Mock Server（State Management 测试不需要）"
    return 0
  fi

  print_header "启动 Mock Server"

  # 检查端口
  if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_warning "端口 8080 已占用，尝试使用现有的 Mock Server"
    # 尝试健康检查
    if curl -s http://localhost:8080/health | grep -q "ok"; then
      print_success "现有 Mock Server 在线"
      return 0
    else
      print_error "现有 Mock Server 无法响应"
      exit 1
    fi
  fi

  # 检查 Mock Server 二进制
  if [ ! -f "$MOCK_SERVER_DIR/mock-server" ]; then
    print_warning "Mock Server 未编译，尝试编译..."
    cd "$MOCK_SERVER_DIR"
    if ! go build -o mock-server . 2>/dev/null; then
      print_error "Mock Server 编译失败"
      exit 1
    fi
    cd -
    print_success "Mock Server 编译成功"
  fi

  # 启动 Mock Server
  print_warning "启动 Mock Server（normal 模式）..."
  cd "$MOCK_SERVER_DIR"
  ./mock-server --strategy=normal > mock-server.log 2>&1 &
  MOCK_SERVER_PID=$!
  cd -

  # 等待 Mock Server 启动
  sleep 2

  # 验证 Mock Server
  if curl -s http://localhost:8080/health | grep -q "ok"; then
    print_success "Mock Server 启动成功 (PID: $MOCK_SERVER_PID)"
  else
    print_error "Mock Server 启动失败"
    cat "$MOCK_SERVER_DIR/mock-server.log"
    kill $MOCK_SERVER_PID 2>/dev/null || true
    exit 1
  fi
}

# 停止 Mock Server
stop_mock_server() {
  if [ -z "$MOCK_SERVER_PID" ]; then
    return 0
  fi

  print_header "清理资源"
  print_warning "停止 Mock Server (PID: $MOCK_SERVER_PID)..."

  if kill $MOCK_SERVER_PID 2>/dev/null; then
    sleep 1
    print_success "Mock Server 已停止"
  else
    print_warning "Mock Server 已停止"
  fi
}

# 运行测试
run_tests() {
  cd "$SRC_DIR"

  case "$TEST_TYPE" in
    state-management)
      print_header "运行 State Management 测试"
      flutter test integration_test/market/market_state_management_test.dart -v
      ;;
    api-integration)
      print_header "运行 API Integration 测试"
      flutter test integration_test/market/market_api_integration_test.dart -v
      ;;
    e2e)
      print_header "运行 E2E 测试"
      flutter test integration_test/market/market_e2e_app_test.dart -v
      ;;
    all)
      print_header "运行所有 Market 集成测试"
      flutter test integration_test/market/ -v
      ;;
    *)
      print_error "未知的测试类型: $TEST_TYPE"
      echo "可用类型: state-management, api-integration, e2e, all"
      exit 1
      ;;
  esac
}

# 显示使用说明
show_usage() {
  cat << EOF
使用方法: $0 [test-type] [options]

测试类型:
  state-management    运行状态管理测试（快速，无需 Mock Server）
  api-integration     运行 API 集成测试（需要 Mock Server）
  e2e                 运行 E2E 测试（需要 Mock Server + 模拟器）
  all                 运行所有测试（默认）

选项:
  --no-cleanup        不停止 Mock Server（调试用）
  --timeout=60s       设置测试超时时间
  -v, --verbose       详细输出
  -h, --help          显示此帮助信息

示例:
  $0                  # 运行所有测试
  $0 state-management # 只运行快速测试
  $0 api-integration  # 运行 API 层测试
  $0 e2e              # 运行完整用户旅程测试

EOF
}

# 主程序
main() {
  # 解析参数
  TEST_TYPE="${1:-all}"
  NO_CLEANUP=false

  # 处理帮助和其他选项
  if [ "$TEST_TYPE" = "-h" ] || [ "$TEST_TYPE" = "--help" ]; then
    show_usage
    exit 0
  fi

  # 检查是否为无效选项
  case "$TEST_TYPE" in
    state-management|api-integration|e2e|all)
      ;;
    *)
      print_error "无效的测试类型: $TEST_TYPE"
      show_usage
      exit 1
      ;;
  esac

  # 检查第二个参数
  if [ "$2" = "--no-cleanup" ]; then
    NO_CLEANUP=true
  fi

  # 设置 trap 以便在脚本退出时清理
  trap 'if [ "$NO_CLEANUP" = false ]; then stop_mock_server; fi' EXIT

  # 执行步骤
  print_header "Market 模块集成测试"
  echo "测试类型: $TEST_TYPE"
  echo

  check_prerequisites
  start_mock_server

  if run_tests; then
    print_header "✅ 所有测试通过!"
    exit 0
  else
    print_header "❌ 测试失败"
    exit 1
  fi
}

# 运行主程序
main "$@"
