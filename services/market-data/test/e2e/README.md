# E2E 自动化测试

模拟传统 QA 手工测试流程的自动化方案。

## 测试架构

```
run_e2e_tests.sh (主脚本)
  ↓
1. docker-compose up (启动测试环境)
  ├─ MySQL (测试数据库)
  ├─ Redis (缓存)
  ├─ Kafka (消息队列)
  └─ Market Data Service
  ↓
2. setup_test_data.sh (准备测试数据)
  ↓
3. api_test.py (基础 API 测试)
  ↓
4. scenarios_test.py (高级场景测试)
  ↓
5. docker-compose down (清理环境)
```

## 快速开始

```bash
# 运行完整测试
cd test/e2e
chmod +x *.sh
./run_e2e_tests.sh

# 保持环境运行（用于调试）
KEEP_ENV=true ./run_e2e_tests.sh
```

## 测试覆盖

### 基础 API 测试 (api_test.py)
- ✓ 获取单个报价
- ✓ 批量获取报价
- ✓ 股票搜索
- ✓ Stale 检测

### 场景测试 (scenarios_test.py)
- ✓ 完整报价流程（搜索→获取→验证）
- ✓ 批量操作
- ✓ 自选股管理
- ✓ 错误处理

## 扩展测试

### 添加新测试用例

编辑 `api_test.py` 或 `scenarios_test.py`：

```python
def test_new_feature():
    """测试新功能"""
    resp = requests.get(f"{BASE_URL}/api/v1/new-endpoint")
    assert resp.status_code == 200
    return True
```

### 添加测试数据

编辑 `setup_test_data.sh`：

```sql
INSERT INTO stocks (symbol, name, market) VALUES
('NEW', 'New Stock', 'US');
```

## CI/CD 集成

```yaml
# .github/workflows/e2e-test.yml
name: E2E Tests
on: [push, pull_request]
jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run E2E tests
        run: |
          cd services/market-data/test/e2e
          ./run_e2e_tests.sh
```

## 对比传统 QA 流程

| 传统手工测试 | 自动化测试 |
|------------|----------|
| 手动启动服务 | `docker-compose up` |
| 手动造测试数据 | `setup_test_data.sh` |
| Postman 调用接口 | `api_test.py` |
| 人工验证结果 | 自动断言 |
| 手动清理环境 | `docker-compose down` |

## 优势

1. **可重复** - 每次运行结果一致
2. **快速** - 几分钟完成全部测试
3. **可靠** - 自动验证，无人为错误
4. **可扩展** - 轻松添加新测试用例
5. **CI 友好** - 可集成到 CI/CD 流水线
