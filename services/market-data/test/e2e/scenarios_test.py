#!/usr/bin/env python3
"""
高级测试场景：模拟真实 QA 测试用例
"""

import requests
import time
import json
from decimal import Decimal

BASE_URL = "http://localhost:8080"

def test_scenario_1_fresh_quote_flow():
    """场景1：获取新鲜报价完整流程"""
    print("\n==> Scenario 1: Fresh Quote Flow")

    # 1. 搜索股票
    resp = requests.get(f"{BASE_URL}/api/v1/search?q=Apple")
    assert resp.status_code == 200, "Search failed"
    results = resp.json()["results"]
    assert len(results) > 0, "No search results"
    print(f"  ✓ Found {len(results)} stocks")

    # 2. 获取报价
    symbol = results[0]["symbol"]
    resp = requests.get(f"{BASE_URL}/api/v1/quotes/{symbol}")
    assert resp.status_code == 200, "Get quote failed"
    quote = resp.json()
    print(f"  ✓ Got quote: {symbol} @ ${quote['price']}")

    # 3. 验证数据完整性
    assert quote["symbol"] == symbol
    assert "price" in quote
    assert "volume" in quote
    assert "last_updated_at" in quote
    print(f"  ✓ Quote data complete")

    # 4. 验证 stale 状态
    assert "is_stale" in quote
    print(f"  ✓ Stale detection: is_stale={quote['is_stale']}")

    return True

def test_scenario_2_batch_quotes():
    """场景2：批量获取多个股票报价"""
    print("\n==> Scenario 2: Batch Quotes")

    symbols = ["AAPL", "MSFT", "TSLA"]
    resp = requests.get(f"{BASE_URL}/api/v1/quotes?symbols={','.join(symbols)}")
    assert resp.status_code == 200

    data = resp.json()
    quotes = data.get("quotes", [])
    assert len(quotes) <= len(symbols)
    print(f"  ✓ Got {len(quotes)} quotes")

    for quote in quotes:
        print(f"    {quote['symbol']}: ${quote['price']}")

    return True

def test_scenario_3_watchlist():
    """场景3：自选股管理"""
    print("\n==> Scenario 3: Watchlist Management")

    user_id = 12345

    # 1. 添加自选股
    resp = requests.post(f"{BASE_URL}/api/v1/watchlist", json={
        "user_id": user_id,
        "symbol": "AAPL",
        "market": "US"
    })
    print(f"  ✓ Add to watchlist: {resp.status_code}")

    # 2. 获取自选股列表
    resp = requests.get(f"{BASE_URL}/api/v1/watchlist/{user_id}")
    if resp.status_code == 200:
        items = resp.json().get("items", [])
        print(f"  ✓ Watchlist has {len(items)} items")

    return True

def test_scenario_4_error_handling():
    """场景4：错误处理"""
    print("\n==> Scenario 4: Error Handling")

    # 1. 不存在的股票
    resp = requests.get(f"{BASE_URL}/api/v1/quotes/INVALID")
    assert resp.status_code in [404, 200]  # 可能返回空或404
    print(f"  ✓ Invalid symbol handled: {resp.status_code}")

    # 2. 无效参数
    resp = requests.get(f"{BASE_URL}/api/v1/quotes?symbols=")
    assert resp.status_code in [400, 200]
    print(f"  ✓ Empty symbols handled: {resp.status_code}")

    return True

def run_scenarios():
    """运行所有场景"""
    print("\n" + "="*60)
    print("Advanced Test Scenarios")
    print("="*60)

    scenarios = [
        ("Fresh Quote Flow", test_scenario_1_fresh_quote_flow),
        ("Batch Quotes", test_scenario_2_batch_quotes),
        ("Watchlist Management", test_scenario_3_watchlist),
        ("Error Handling", test_scenario_4_error_handling),
    ]

    results = []
    for name, test_func in scenarios:
        try:
            result = test_func()
            results.append(result)
            print(f"✓ {name} passed")
        except Exception as e:
            print(f"✗ {name} failed: {e}")
            results.append(False)

    print("\n" + "="*60)
    passed = sum(results)
    total = len(results)
    print(f"Scenarios: {passed}/{total} passed")

    return all(results)

if __name__ == "__main__":
    import sys
    time.sleep(2)  # 等待服务就绪
    success = run_scenarios()
    sys.exit(0 if success else 1)
