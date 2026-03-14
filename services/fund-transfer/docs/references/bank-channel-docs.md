# 银行渠道对接文档索引

> 本文档记录各银行/支付基础设施的公开开发者文档及技术规范，
> 供系统设计和银行渠道接入时参考。
>
> **重要说明**：所有银行的生产环境 API 访问均需建立企业客户关系后才能开通。
> 本索引记录的是公开可浏览的文档地址，不代表可直接接入。
>
> 最后更新：2026-03-14

---

## 一、美国渠道（ACH / Wire）

### 1. JP Morgan Payments Developer Portal

| 项目 | 内容 |
|------|------|
| 门户主页 | https://developer.payments.jpmorgan.com/ |
| ACH 文档 | https://developer.payments.jpmorgan.com/docs/treasury/global-payments/capabilities/global-payments/ach |
| Wire 发起指南 | https://developer.payments.jpmorgan.com/docs/treasury/global-payments/capabilities/global-payments-2/wire/how-to/initiate-wire-payment |
| 通用开发者门户 | https://developer.jpmorgan.com/ |
| 是否需要注册 | 文档可直接浏览；沙盒需注册；生产需签署 API License Agreement |
| 沙盒 | 有（注册后开通） |
| 文档质量 | ⭐⭐⭐⭐⭐ 商业银行中最高 |

**覆盖内容**：
- ACH Credit/Debit，支持次日（Standard）和当日（Same Day ACH）
- Wire Transfer（美国境内 + 国际），含完整字段说明
- RTP（Real-Time Payments，通过 The Clearing House）
- Bill Payment
- 认证方式：HMAC-SHA256 请求签名
- 提供 Postman Collection 下载

**对我们的价值**：
- 验证我们 Bank Adapter 的字段设计是否完整
- 参考 Wire 的不可撤销性处理和 IMAD/OMAD 追踪机制
- HMAC-SHA256 签名方案可直接参考用于我们的银行请求签名

---

### 2. Citibank CitiConnect Developer Portal

| 项目 | 内容 |
|------|------|
| 门户主页 | https://developer.citi.com/ |
| Payment API 概览 | https://developer.citi.com/apidocs/outgoing-payments/payments/payments-overview/ |
| API 产品列表 | https://developer.citi.com/product/ |
| TTS 沙盒 | https://tts.sandbox.developer.citi.com/citiconnect/ |
| 是否需要注册 | 部分文档公开；沙盒和完整文档需注册企业账号 |
| 沙盒 | 有 |
| 文档质量 | ⭐⭐⭐⭐ |

**覆盖内容**：
- Payment Services API：96+ 国家、130+ 币种的支付发起和状态追踪
- Account Services API：账户余额和账单查询
- OAuth 2.0 认证体系

**对我们的价值**：
- 跨境支付（SWIFT）字段参考
- 多币种支付路由设计参考

---

## 二、香港渠道（FPS / CHATS）

### 3. 恒生银行 Hang Seng Developer Portal

| 项目 | 内容 |
|------|------|
| 门户主页 | https://develop.hangseng.com/ |
| API 目录 | https://develop.hangseng.com/apis |
| 入门指南 | https://develop.hangseng.com/knowledge-article/get-started-open-banking-apis |
| 企业 FPS 说明 | https://www.hangseng.com/en-hk/business/banking-digitally/online-services-apis/ |
| 是否需要注册 | **文档完全公开可读**；沙盒需注册 |
| 沙盒 | 有（注册后获取测试证书） |
| 文档质量 | ⭐⭐⭐⭐ 香港银行中开放度最高 |

**覆盖内容**：
- FPS 收款 API：sDDA（简化直接扣账授权）、DDI（直接扣账指令）
- FPS 实时 7×24 转账
- 账户信息 API：余额查询、交易记录
- 遵循 HKMA Open API Framework Phase I-IV
- API 目前免费

**对我们的价值**：
- **香港 FPS 集成的首选参考文档**（文档无需注册）
- sDDA/DDI 机制对应我们的入金授权流程
- HKMA Open API 合规要求参考

---

### 4. HSBC 汇丰开发者门户

| 项目 | 内容 |
|------|------|
| 全球门户 | https://develop.hsbc.com/ |
| API 目录 | https://develop.hsbc.com/apis |
| 香港 FPS 收款 API | https://develop.hsbc.com/api-overview/business-collect-hong-kong |
| 企业银行 API 入门 | https://develop.hsbc.com/knowledge-article/get-started-corporate-banking-apis |
| TA Payment API | https://develop.hsbc.com/api-overview/ta-payment-api |
| 香港专属门户 | https://developer.hsbc.com.hk/ |
| 是否需要注册 | Open Banking 类立即可注册；企业银行 API 需是 HSBC 企业客户 |
| 沙盒 | 有（支持 Try It Now 和 Postman 下载） |
| 文档质量 | ⭐⭐⭐ 企业 API 文档深度有限 |

**覆盖内容**：
- Omni Collect：含 FPS QR Code 收款
- Treasury Payment API
- Open Banking API（15 个市场）
- 香港门户遵循 HKMA Open API Framework Phase I-IV

**对我们的价值**：
- FPS QR Code 收款方案参考（移动端入金体验）
- 多市场 Open Banking 合规框架参考

---

### 5. 中银香港 BOCHK Open API Portal

| 项目 | 内容 |
|------|------|
| 门户主页 | https://api.bochk.com/ |
| API 索引 | https://api.bochk.com/API_index.html |
| FAQ | https://api.bochk.com/FAQ.html |
| 合作申请 | https://api.bochk.com/Partnerwithus.html |
| iGTB Open API 文档 PDF | https://igtb.bochk.com/cm_wcm/TrainingGuide/files/1238887341_2/1578f47b8b0ba7ea92472ac8e9791df6/Open_API_IADS_en_V2.pdf |
| 是否需要注册 | 部分公开；账户信息和支付类需提交企业文件 |
| 沙盒 | 有 |
| 文档质量 | ⭐⭐ FPS 直接 API 文档较弱 |

**覆盖内容**：
- 遵循 HKMA Open API Framework Phase I-III
- 产品信息 API（Phase I）：存款利率等
- 账户信息 API（IADS，Phase III）：余额、交易记录
- FPS 功能主要通过企业网银提供，API 化程度较低
- 认证：OAuth 2.0 + PKI 加密

**对我们的价值**：
- 如选择中银香港作为托管行，需直接联系对公业务团队获取完整接入文档
- iGTB Open API 服务说明 PDF 可下载参考

---

## 三、底层清算规范

### 6. Nacha ACH 开发者指南

| 项目 | 内容 |
|------|------|
| 开发者指南 | https://achdevguide.nacha.org/ |
| Operating Rules（付费） | https://nachaoperatingrulesonline.org/ |
| 文档类型 | 官方技术规范（Web） |
| 沙盒 | 无（需通过 ODFI/第三方接入） |
| 文档质量 | ⭐⭐⭐⭐⭐ ACH 权威来源 |

**覆盖内容**：
- ACH 文件格式（94字符固定宽度格式）
- SEC Code 分类（PPD、CCD、WEB 等）
- 批次（Batch）结构和数据元素说明
- Return Code 完整列表（R01-R85）
- 合规要求和时间窗口规则

**对我们的价值**：
- **ACH 集成的规范基础**，理解文件格式后才能与银行对接
- Return Code 处理是我们失败流程设计的依据（R01=余额不足、R02=账户关闭等）
- 与 moov-io/ach 开源库配合使用

---

### 7. HKICL FPS 规则文档

| 项目 | 内容 |
|------|------|
| 规则文档页 | https://fps.hkicl.com.hk/eng/fps/about_fps/scheme_documentation.php |
| HKD FPS Rules PDF（2025年6月版） | https://fps.hkicl.com.hk/files/page_file/126/10937/HKD%20FPS%20Rules_redacted%20version_Jun%202025_dist%20ver..pdf |
| RMB FPS Rules PDF（2025年2月版） | https://fps.hkicl.com.hk/files/page_file/126/10443/RMB%20FPS%20Rules_redacted%20version_Feb%202025_dist%20ver..pdf |
| HKMA FPS 官方页面 | https://www.hkma.gov.hk/eng/key-functions/international-financial-centre/financial-market-infrastructure/faster-payment-system-fps/ |
| 文档类型 | 规则 PDF（红线版，完整操作规程需成为参与行） |
| 沙盒 | 无公开沙盒 |
| 文档质量 | ⭐⭐⭐⭐ 官方合规规范 |

**覆盖内容**：
- FPS 采用 ISO 20022 消息格式
- 结算规则和参与者义务
- 支持 HKD 和 RMB 两种货币
- 实时 7×24 结算机制
- 完整技术接口规范仅对注册参与行开放

**对我们的价值**：
- 理解 FPS 合规义务（不能忽视的监管要求）
- 结算最终性（Settlement Finality）规则
- 我们实际接入需通过持牌银行（汇丰/恒生）作为 Settlement Participant，不直连 HKICL

---

### 8. Fedwire（美联储）

| 项目 | 内容 |
|------|------|
| 服务页面 | https://www.frbservices.org/financial-services/wires |
| 技术资源 | https://www.frbservices.org/resources/financial-services/wires |
| ISO 20022 迁移 FAQ | https://www.frbservices.org/resources/financial-services/wires/faq/iso-20022 |
| 美联储概述 | https://www.federalreserve.gov/paymentsystems/fedfunds_about.htm |
| 文档类型 | 监管技术规范（完整格式规范在 Swift MyStandards 平台，需注册） |
| 沙盒 | 无公开沙盒，需成为 Fed 直接参与行 |
| 文档质量 | ⭐⭐⭐ 公开部分有限 |

**覆盖内容**：
- RTGS（实时全额结算）系统
- 2025 年已完成向 ISO 20022 迁移（pacs.008、pacs.009 报文格式）
- IMAD/OMAD 追踪机制

**对我们的价值**：
- Wire 不可撤销性的法律依据
- IMAD/OMAD 是 Wire 状态追踪的唯一标识，需在 fund_transfers 表记录

---

## 四、三方聚合层（可作为银行适配器的替代方案）

> 如果前期没有足够的银行商务资源，可考虑通过三方聚合商接入，
> 后期规模扩大后再直连银行。

### 9. Modern Treasury

| 项目 | 内容 |
|------|------|
| 文档主页 | https://docs.moderntreasury.com |
| API Reference | https://docs.moderntreasury.com/reference |
| OpenAPI Spec | https://github.com/Modern-Treasury/modern-treasury-openapi |
| Go SDK | https://github.com/Modern-Treasury/modern-treasury-go |
| 沙盒 | 有（test 环境） |
| 文档质量 | ⭐⭐⭐⭐⭐ |

**覆盖内容**：
- Payment Order（支付发起）：ACH、Wire、国际汇款统一抽象
- Ledger（双边记账）：账户、分录、余额管理
- Reconciliation（对账）：自动匹配、异常处理
- Expected Payment（预期收款匹配）：对应我们的入金匹配机制
- Counterparty（对手方管理）：对应银行账户绑定

**对我们的价值**：
- **Bank Adapter Layer 设计的最佳参考**：如何屏蔽不同银行的差异
- Expected Payment 概念直接对应我们的入金匹配（虚拟账号/附言匹配）
- Ledger API 设计可参考用于我们的 ledger_entries 表接口设计
- Go SDK 可直接参考接口风格

---

### 10. Plaid Transfer API

| 项目 | 内容 |
|------|------|
| Transfer 概览 | https://plaid.com/docs/transfer/ |
| API Reference | https://plaid.com/docs/api/products/transfer/ |
| 创建转账 | https://plaid.com/docs/transfer/creating-transfers/ |
| 沙盒 | 有（Dashboard 直接开通） |
| 文档质量 | ⭐⭐⭐⭐⭐ |

**覆盖内容**：
- ACH、RTP、FedNow 多轨道统一接口
- 银行账户验证（即时验证 + 微存款验证）
- 风险决策（approved/declined）
- Return Code 处理和 Webhook 事件模型
- 幂等键设计

**对我们的价值**：
- 银行账户验证流程参考（微存款验证方案）
- Transfer 风险决策逻辑参考
- Webhook 事件模型参考

---

### 11. moov-io/ach（开源 Go 库）

| 项目 | 内容 |
|------|------|
| GitHub | https://github.com/moov-io/ach |
| 文档站 | https://moov-io.github.io/ach/ |
| Go pkg | https://pkg.go.dev/github.com/moov-io/ach |
| 沙盒 | 有（Docker 镜像，本地运行 HTTP server） |
| 文档质量 | ⭐⭐⭐⭐ |

**覆盖内容**：
- Go 实现的 NACHA 格式文件读写/验证
- 支持全部 SEC Code
- 提供 REST HTTP server 可直接使用
- 本地 Docker 可模拟 ACH 文件处理

**对我们的价值**：
- **可直接集成**到我们的 Go 服务用于生成和解析 ACH 文件
- 本地沙盒用于开发阶段测试，无需真实银行账户

---

## 五、访问优先级建议

### 阶段一：系统设计阶段（现在）

无需注册即可阅读，直接用于对照系统设计：

```
1. JP Morgan ACH/Wire 文档    → 验证 Bank Adapter 字段设计
2. 恒生银行 FPS 文档          → 验证香港 FPS 集成方案
3. Modern Treasury 文档       → 参考 Ledger + 对账接口设计
4. Nacha ACH 开发者指南       → 理解 ACH Return Code 处理
5. HKICL FPS Rules PDF        → 理解 FPS 合规要求
```

### 阶段二：开发阶段

需注册沙盒账号：

```
1. Dwolla 沙盒               → 模拟 ACH Return Code 失败场景
2. Plaid 沙盒                → 模拟银行账户验证流程
3. moov-io/ach Docker        → 本地 ACH 文件处理测试
4. Modern Treasury test 环境 → 对账流程端到端测试
```

### 阶段三：上线前（需商务关系）

```
1. 确定合作托管银行（US: JP Morgan 或 Citibank）
2. 确定香港托管银行（恒生 或 汇丰）
3. 签署 API License Agreement
4. 获取生产环境 API 凭证
5. 通过银行合规审查
```

---

## 六、关键发现：我们无法直连的系统

以下系统需通过持牌中间机构接入，不能直连：

| 系统 | 原因 | 我们的接入方式 |
|------|------|-------------|
| Nacha ACH 网络 | 需成为 ODFI（发起行），需银行牌照 | 通过合作银行（JP Morgan/Citibank）接入 |
| Fedwire | 需成为美联储直接参与行 | 通过合作银行接入 |
| HKICL FPS | 需成为 FPS Settlement Participant | 通过持牌银行（汇丰/恒生）接入 |
| DTCC/NSCC | 证券清算，需成为成员机构 | 通过 Prime Broker 接入 |
