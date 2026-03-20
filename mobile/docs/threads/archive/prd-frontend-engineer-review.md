# Admin Panel 技术评审报告

**评审角色**: Frontend Engineer（React Admin Panel）
**评审日期**: 2026-03-13
**评审版本**: PRD v1.0（Phase 1 正式版）
**覆盖模块**: PRD-02 KYC 审核工作台、PRD-05 出金审批、PRD-03 热门列表管理、PRD-04 订单监控

---

## 总体评估

整套 PRD 的用户端（Mobile App）接口设计完整、数据模型清晰。但 **Admin Panel 部分属于重度欠设计区域**——PRD 对 Admin UI 的功能描述停留在业务语言层面，完全缺乏对应的后端 API 规格、权限模型接口、实时性方案。这将导致 Admin Panel 前端开发阶段需要大量自行补充 API 设计，增加前后端对齐成本和延期风险。

共识别问题 **19 项**，其中 P0 级 5 项、P1 级 9 项、P2 级 5 项。

---

## 第一类：Admin Panel API 完全缺失（P0）

### 问题 1.1：KYC 审核工作台的 Admin 侧 API 全部缺失

**严重程度**: P0

**具体描述**

PRD-02 第四节详细描述了审核队列和审核工作台 UI，但对应的 Admin API 一条都没有定义。当前 PRD 中仅有用户侧 API。Admin 侧需要的接口包括：

- 获取审核队列列表（含 FIFO 排序、过滤、分页、SLA 剩余时间）
- 获取单个 KYC 申请详情（含 7 步结构化数据 + OCR 字段 + 风险信号）
- 提交审核操作（通过 / 需补件 / 拒绝）
- 查询单个申请的审核历史（`kyc_review_log`）
- 批量操作接口（批量标记补件）

**建议解决方案**

```
GET  /v1/admin/kyc/applications          # 审核队列（含过滤、分页、SLA字段）
GET  /v1/admin/kyc/applications/{id}     # 申请详情
POST /v1/admin/kyc/applications/{id}/review  # 提交审核决定
GET  /v1/admin/kyc/applications/{id}/logs    # 审核历史
POST /v1/admin/kyc/applications/batch-review # 批量操作
```

响应体中必须包含 SLA 剩余时长字段（`sla_deadline_at`、`is_sla_breached`），否则前端无法实现 SLA 预警标红逻辑。

---

### 问题 1.2：出金审批队列的 Admin API 全部缺失

**严重程度**: P0

**具体描述**

PRD-05 第八节描述了三级审批流程，但同样没有任何 Admin API 定义。Admin 需要的接口包括：

- 获取待审批队列（三级分 Tab 还是统一队列，PRD 未说明）
- 查看单笔出金详情（含 AML 筛查报告）
- L1/L2/L3 各级审批操作
- 发起 SAR

另外，`withdrawals.review_level`（0-3）与三级流转逻辑的对应关系未说明，前端无法判断"当前登录用户看到的待审批单"是哪些状态。

**建议解决方案**

```
GET  /v1/admin/funding/withdrawals              # 审批队列
GET  /v1/admin/funding/withdrawals/{id}         # 详情（含AML报告）
POST /v1/admin/funding/withdrawals/{id}/approve # 审批通过
POST /v1/admin/funding/withdrawals/{id}/reject  # 驳回
POST /v1/admin/funding/withdrawals/{id}/escalate # 升级
POST /v1/admin/funding/withdrawals/{id}/sar     # 发起SAR
```

---

### 问题 1.3：热门列表 Admin 管理接口缺失

**严重程度**: P0

**具体描述**

PRD-03 明确写道"Admin Panel 可管理热门列表"，但整个 PRD-03 的 API 规格部分只有用户侧的 `GET /v1/market/movers?type=hot`，完全没有 Admin 管理接口。

**建议解决方案**

```
GET    /v1/admin/market/hot-list          # 查看热门列表
POST   /v1/admin/market/hot-list          # 添加股票到热门
PUT    /v1/admin/market/hot-list/{symbol} # 更新排名/配置
DELETE /v1/admin/market/hot-list/{symbol} # 移除
PUT    /v1/admin/market/hot-list/reorder  # 批量排序
```

---

### 问题 1.4：SAR 发起流程无 API 定义，且无数据模型

**严重程度**: P0

**具体描述**

PRD-05 第 6.3 节和第 8.2 节提到 SAR 发起，但整个 PRD 没有任何 SAR 相关的数据模型和 API。SAR 是监管合规操作（FinCEN 30 天申报时限），前端需要表单、状态跟踪，但连数据模型都是空白。

**建议解决方案**

需要独立的 `sar_filings` 数据模型（含 `deadline_at` = 检测日 + 30 天）及完整的 SAR CRUD API。

---

### 问题 1.5：订单监控的 Admin 视图 API 缺失

**严重程度**: P0

**具体描述**

PRD-00 将"订单监控"列为 Admin Panel 功能。PRD-04 的订单接口（`GET /v1/orders`）是用户侧的，只能查自己的订单，无法支持跨用户监控需求。

**建议解决方案**

```
GET /v1/admin/orders                       # 全量订单列表（含用户信息）
GET /v1/admin/orders/summary               # 实时汇总
GET /v1/admin/orders/{id}                  # 订单详情（含完整审计路径）
```

---

## 第二类：权限控制（RBAC）实现缺失（P1）

### 问题 2.1：Admin 用户身份与角色信息无 API

**严重程度**: P1

**具体描述**

PRD-02 定义了 3 个 KYC 角色，PRD-05 定义了 3 个出金角色，但 PRD 中没有任何接口返回"当前 Admin 登录用户的角色信息"。PRD-01 的登录接口响应体只有 `kyc_status`，没有 `roles` 字段。更关键的是，**Admin Panel 的登录方式（密码 or OTP）PRD 完全未定义**。

**建议解决方案**

补充独立 Admin 登录体系 + `GET /v1/admin/me` 接口返回角色和权限列表。前端基于 Permission 而非 Role 做按钮级控制。

---

### 问题 2.2：角色权限边界存在逻辑矛盾

**严重程度**: P1

**具体描述**

Compliance Officer 在 PRD-02 和 PRD-05 中均出现，职责重叠但未说明是否同一角色。若一个 KYC 申请既是 PEP 又需要拒绝（需要 Senior Reviewer），操作权限归谁，前端无法处理此交叉场景。

**建议解决方案**

PM 需要输出完整的 RBAC 权限矩阵，采用操作级别 Permission 定义（如 `kyc:approve`、`kyc:reject`、`kyc:review-pep`）。

---

### 问题 2.3：用户管理模块完全缺乏 API 规格

**严重程度**: P1

**具体描述**

PRD-00 将"用户管理"列为 Admin Panel 功能，但所有 PRD 文档中都没有用户管理相关的 Admin API（用户列表搜索、账户操作、AML 观察名单管理等）。

---

## 第三类：实时性需求与 SLA 预警实现（P1）

### 问题 3.1：审核队列实时性方案未定义

**严重程度**: P1

**具体描述**

PRD 完全没有提及 Admin Panel 是否需要 WebSocket 推送、长轮询还是纯 REST 轮询。

**建议解决方案**

Phase 1 先做 30 秒 TanStack Query `refetchInterval` 轮询 + 手动刷新按钮，Phase 2 再加 SSE。

### 问题 3.2：SLA 预警计算存在歧义

**严重程度**: P1

**具体描述**

"20 小时"是自然小时还是工作小时？PEP 申请 SLA（2-3 个工作日）与普通申请（20 小时）的预警阈值不同，前端需要区分。

**建议解决方案**

强烈建议服务端直接返回 `sla_deadline_at`（绝对时间戳）和 `is_sla_breached`（布尔值），前端只负责展示，不负责计算。

---

## 第四类：证件图片查看与 OCR 高亮对比（P1）

### 问题 4.1：证件图片安全访问机制无 API

**严重程度**: P1

**具体描述**

证件图片加密存储于对象存储，直接暴露永久 URL 会绕过 RBAC 控制，且日志中可能记录完整的图片 URL（PII 泄露）。正确方案是预签名 URL（Presigned URL），但 PRD 中完全缺失此 API。

**建议解决方案**

```
GET /v1/admin/kyc/applications/{id}/documents/{doc_type}/url
Response: { "presigned_url": "...", "expires_at": "...(15分钟有效)", "doc_type": "..." }
```

### 问题 4.2：OCR 高亮对比技术可行性存疑

**严重程度**: P1

**具体描述**

PRD 要求"OCR 识别结果高亮对比"，但 OCR 接口响应体只有结构化字段值，没有坐标（bounding box）信息，前端无法在图片上绘制高亮框。

**建议解决方案**（推荐 Phase 1 采用）

不做真正的图片高亮，改为图文对照布局：左侧显示证件图片（支持缩放旋转），右侧显示 OCR 字段与用户填写字段并排对比，差异用颜色高亮。无需修改 OCR API，实现成本低。

---

## 第五类：三级审批状态机与操作（P1）

### 问题 5.1：L1→L2→L3 流转逻辑前端无法驱动

**严重程度**: P1

**具体描述**

`withdrawals.review_level`（0-3）与 `status` 字段的关系未定义。L1 何时必须升级 L2（是所有 $50K-$200K 都要经 L2，还是 L1 自行判断）PRD 未说明。

**建议解决方案**

PM 需要输出完整的出金审批状态机图。建议将审批状态拆分为更细粒度的枚举（`L1_REVIEWING`、`L2_REVIEWING`、`L3_REVIEWING`），而不是依赖整数字段。

### 问题 5.2：审批操作缺少幂等性保障

**严重程度**: P1

Admin 审批 API 应同样支持 `Idempotency-Key`，避免网络超时重试导致重复审批记录写入。

---

## 第六类：工作台布局与组件选型（P2）

### 问题 6.1：单页布局方案未规范化

**严重程度**: P2

PRD-02 要求"Reviewer 可在单页面完成查看+操作"，但此密集信息页面（7步KYC数据+证件图片+操作区+审核历史）若设计方案不规范，容易出现内容溢出、操作区被遮挡等问题。

**建议解决方案**

三栏固定布局（左侧审核队列/中间申请详情/右侧操作区），三栏各自独立滚动，操作区使用 `position: sticky`，确保 Reviewer 始终可见操作按钮。

### 问题 6.2：关键组件选型未明确

**严重程度**: P2

证件图片查看器（AntD `Image` 不支持旋转）、AML 报告展示方式（Modal vs Drawer）、审核历史时间轴数据格式，需要在开发前出组件选型 ADR。

---

## 第七类：合规与系统功能遗漏（P1/P2）

### 问题 7.1：W-8BEN 到期管理的 Admin 提醒缺少实现路径（P1）

PRD 提到"Admin 工作台提醒"，但 Admin Panel 中无对应页面或模块，后端如何推送提醒也未说明。需要在 Admin Panel 增加"合规预警"模块。

### 问题 7.2：审计日志查询功能缺失（P2）

各模块都有审计日志（合规要求保留 7 年），但 Admin Panel 没有审计日志查询页面。监管检查时是刚需，建议 Phase 1 最小化实现（按用户/时间/事件类型搜索 + CSV 导出）。

### 问题 7.3：系统看板完全缺失（P2）

PRD-00 将"系统看板"列为功能，但没有任何描述。需要补充监控指标清单、数据 API（推荐后端提供聚合好的 `/v1/admin/system/metrics`）、刷新策略。

---

## 问题优先级汇总

| 编号 | 问题描述 | 严重程度 | 阻塞状态 |
|------|---------|---------|---------|
| 1.1 | KYC 审核队列及工作台 Admin API 全部缺失 | **P0** | 阻塞开发 |
| 1.2 | 出金审批队列 Admin API 全部缺失 | **P0** | 阻塞开发 |
| 1.3 | 热门列表管理 Admin API 缺失 | **P0** | 阻塞开发 |
| 1.4 | SAR 发起无 API 且无数据模型 | **P0** | 阻塞开发 |
| 1.5 | 订单监控 Admin 视图 API 缺失 | **P0** | 阻塞开发 |
| 2.1 | Admin 登录及角色信息接口缺失 | P1 | 阻塞开发 |
| 2.2 | RBAC 角色权限边界存在逻辑矛盾 | P1 | 影响设计 |
| 2.3 | 用户管理 Admin API 完全缺失 | P1 | 阻塞开发 |
| 3.1 | 审核队列实时性方案未定义 | P1 | 影响架构 |
| 3.2 | SLA 预警计算逻辑歧义 | P1 | 影响实现 |
| 4.1 | 证件图片安全访问（Presigned URL）API 缺失 | P1 | 阻塞开发 |
| 4.2 | OCR 高亮对比技术方案不可行 | P1 | 影响功能 |
| 5.1 | 三级审批状态机流转逻辑不完整 | P1 | 影响实现 |
| 5.2 | 审批操作幂等性未定义 | P1 | 影响健壮性 |
| 7.1 | W-8BEN 到期 Admin 提醒无实现路径 | P1 | 影响合规 |
| 6.1 | KYC 工作台单页布局方案未规范 | P2 | 影响体验 |
| 6.2 | 关键组件选型未明确 | P2 | 影响开发效率 |
| 7.2 | 审计日志查询功能缺失（合规刚需）| P2 | 影响合规 |
| 7.3 | 系统看板指标和数据源未定义 | P2 | 影响功能 |

## 给 PM 的行动建议（Sprint 0 前完成）

1. **补充 Admin API 规格文档**（PRD-Admin-01）：覆盖 KYC 审核、出金审批、热门列表管理、SAR、订单监控、用户管理的完整接口
2. **输出 RBAC 权限矩阵**：每个角色对应哪些操作权限
3. **确认 SLA 时间计算标准**：由服务端返回绝对时间戳（推荐）
4. **确认 OCR 高亮实现方案**：建议采用图文对照简化方案
5. **补充 Admin Panel 登录方式**：推荐独立的 Admin 账户体系（安全隔离更清晰）
