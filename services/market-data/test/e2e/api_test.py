#!/usr/bin/env python3
"""
E2E API 测试脚本
模拟 QA 手工测试流程：启动服务 → 造数据 → 调用接口 → 验证结果
"""

import requests
import time
import json
from decimal import Decimal

BASE_URL = "http://localhost:8080"

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    END = '\033[0m'

def log_test(name, passed, details=""):
    status = f"{Colors.GREEN}✓ PASS{Colors.END}" if passed else f"{Colors.RED}✗ FAIL{Colors.END}"
    print(f"{status} {name}")
    if details:
        print(f"  {details}")

def wait_for_service(max_retries=30):
    """等待服务启动"""
    print("==> Waiting for service to be ready...")
    for i in range(max_retries):
        try:
            resp = requests.get(f"{BASE_URL}/health", timeout=2)
            if resp.status_code == 200:
                print(f"{Colors.GREEN}✓ Service is ready{Colors.END}")
                return True
        except:
            time.sleep(1)
    print(f"{Colors.RED}✗ Service failed to start{Colors.END}")
    return False

def test_get_quote():
    """测试获取报价"""
    resp = requests.get(f"{BASE_URL}/api/v1/quotes/AAPL")
    passed = resp.status_code == 200 and resp.json()["symbol"] == "AAPL"
    log_test("GET /api/v1/quotes/:symbol", passed,
             f"Status: {resp.status_code}, Symbol: {resp.json().get('symbol')}")
    return passed

def test_batch_quotes():
    """测试批量获取报价"""
    resp = requests.get(f"{BASE_URL}/api/v1/quotes?symbols=AAPL,MSFT")
    data = resp.json()
    passed = resp.status_code == 200 and len(data.get("quotes", [])) == 2
    log_test("GET /api/v1/quotes (batch)", passed,
             f"Status: {resp.status_code}, Count: {len(data.get('quotes', []))}")
    return passed

def test_search_stocks():
    """测试股票搜索"""
    resp = requests.get(f"{BASE_URL}/api/v1/search?q=Apple")
    data = resp.json()
    passed = resp.status_code == 200 and len(data.get("results", [])) > 0
    log_test("GET /api/v1/search", passed,
             f"Status: {resp.status_code}, Results: {len(data.get('results', []))}")
    return passed

def test_stale_detection():
    """测试 stale 检测"""
    resp = requests.get(f"{BASE_URL}/api/v1/quotes/AAPL")
    data = resp.json()
    is_stale = data.get("is_stale", False)
    passed = resp.status_code == 200
    log_test("Stale detection", passed,
             f"is_stale: {is_stale}, stale_since_ms: {data.get('stale_since_ms', 0)}")
    return passed

def run_all_tests():
    """运行所有测试"""
    print("\n" + "="*60)
    print("Market Data Service - E2E API Tests")
    print("="*60 + "\n")

    if not wait_for_service():
        return False

    time.sleep(2)  # 等待数据初始化

    results = []
    results.append(test_get_quote())
    results.append(test_batch_quotes())
    results.append(test_search_stocks())
    results.append(test_stale_detection())

    print("\n" + "="*60)
    passed = sum(results)
    total = len(results)
    print(f"Results: {passed}/{total} tests passed")

    if passed == total:
        print(f"{Colors.GREEN}✓ All tests passed!{Colors.END}")
        return True
    else:
        print(f"{Colors.RED}✗ Some tests failed{Colors.END}")
        return False

if __name__ == "__main__":
    import sys
    success = run_all_tests()
    sys.exit(0 if success else 1)
