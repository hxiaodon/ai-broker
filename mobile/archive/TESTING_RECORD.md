# Market 模块功能验收测试记录

**测试日期**: 2026-04-07  
**测试人**: [填写]  
**Mock Server**: ✅ 运行中 (PID: 14024)

---

## 测试环境

- Mock Server: `http://localhost:8080`
- WebSocket: `ws://localhost:8080/ws/market-data`
- Flutter App: [待启动]

---

## 测试 1：访客模式"延迟 15 分钟"标识

### 准备
```bash
# 切换 mock server 策略
cd mobile/mock-server
kill $(cat /tmp/mock-server.pid)
./start.sh guest
```

### 测试步骤
1. [ ] 启动 Flutter app（不登录）
2. [ ] 进入行情页 → 自选股 tab
3. [ ] 点击任意股票进入详情页

### 验收标准
- [ ] 所有价格旁显示 "延迟 15 分钟" 标识
- [ ] 标识位置：价格右侧或下方，灰色小字
- [ ] K线图顶部也显示延迟提示

### 截图
- [ ] 自选股列表截图
- [ ] 股票详情页截图

### 结果
- [ ] ✅ 通过
- [ ] ❌ 失败（原因：_____________）

---

## 测试 2：WebSocket 断线自动重连

### 准备
```bash
cd mobile/mock-server
kill $(cat /tmp/mock-server.pid)
./start.sh unstable
```

### 测试步骤
1. [ ] 登录 Flutter app
2. [ ] 进入行情页，观察价格实时更新
3. [ ] 等待 mock server 自动断线（观察日志）
4. [ ] 观察 app 重连行为

### 验收标准
- [ ] 断线后 UI 显示 "连接中断" 提示（不是白屏）
- [ ] 自动重连（无需用户手动刷新）
- [ ] 重连成功后实时数据恢复更新
- [ ] Flutter 日志显示重连次数（最多 3 次）

### 日志检查
```bash
# Mock server 日志
tail -f /tmp/mock-server.log | grep "disconnect"

# Flutter 日志
flutter logs | grep "reconnect"
```

### 截图
- [ ] 断线提示截图
- [ ] 重连成功截图

### 结果
- [ ] ✅ 通过
- [ ] ❌ 失败（原因：_____________）

---

## 测试 3：Stale Quote 警告

### 准备
```bash
cd mobile/mock-server
kill $(cat /tmp/mock-server.pid)
./start.sh delayed
```

### 测试步骤
1. [ ] 登录 Flutter app
2. [ ] 进入行情页，订阅股票（如 AAPL）
3. [ ] 等待 6 秒（mock server 延迟推送）
4. [ ] 观察 UI 变化

### 验收标准
- [ ] 当 `stale_since_ms >= 5000` 时，显示黄色警告 banner
- [ ] Banner 文案："行情数据可能延迟，正在重新连接..."
- [ ] 数据恢复后 banner 自动消失

### 截图
- [ ] Stale warning banner 截图

### 结果
- [ ] ✅ 通过
- [ ] ❌ 失败（原因：_____________）

---

## 测试 4：错误场景用户提示

### 准备
```bash
cd mobile/mock-server
kill $(cat /tmp/mock-server.pid)
./start.sh error
```

### 测试步骤
1. [ ] 尝试登录并连接 WebSocket
2. [ ] 观察错误提示

### 验收标准
- [ ] 显示 "Token 无效或已过期，请重新登录"
- [ ] 不显示技术错误堆栈
- [ ] 提供 "重试" 或 "重新登录" 按钮

### 截图
- [ ] 错误提示截图

### 结果
- [ ] ✅ 通过
- [ ] ❌ 失败（原因：_____________）

---

## 测试 5：正常功能验证

### 准备
```bash
cd mobile/mock-server
kill $(cat /tmp/mock-server.pid)
./start.sh normal
```

### 测试步骤
1. [ ] 登录 Flutter app
2. [ ] 进入行情页
3. [ ] 测试所有功能

### 验收标准
- [ ] 自选股列表正常显示
- [ ] 价格实时更新（每秒）
- [ ] 搜索功能正常
- [ ] 涨跌榜正常显示
- [ ] 股票详情页正常

### 截图
- [ ] 行情首页截图
- [ ] 搜索页截图
- [ ] 股票详情页截图

### 结果
- [ ] ✅ 通过
- [ ] ❌ 失败（原因：_____________）

---

## 总结

### 通过项
- [ ] 测试 1：访客模式标识
- [ ] 测试 2：自动重连
- [ ] 测试 3：Stale Quote 警告
- [ ] 测试 4：错误提示
- [ ] 测试 5：正常功能

### 失败项
（列出失败的测试和原因）

### 下一步
- [ ] 修复失败项
- [ ] 更新验收清单
- [ ] 提交最终 code review
- [ ] 准备集成测试

---

**签字确认**:
- 测试工程师: ____________ 日期: ______
