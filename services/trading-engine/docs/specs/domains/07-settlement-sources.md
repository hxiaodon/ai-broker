# 清结算一手资料索引 (Settlement Primary Sources)

> 本文档记录经网络搜索确认的官方一手文档，用于替代/校验训练数据中的结算知识。
> 创建时间：2026-03-25

---

## 一、美股清结算 (DTCC/NSCC)

### 核心规则文档

| 文档名称 | 内容描述 | 官方链接 | 状态 |
|---------|---------|---------|------|
| NSCC Rules & Procedures (全文) | CNS Rule 11/12/13，NSCC 最权威规则文本 | https://www.dtcc.com/~/media/Files/Downloads/legal/rules/nscc_rules.pdf | 待读取 |
| DTC Settlement Service Guide (2026-01-29) | 结算操作细节，端到端全流程，最新版本 | https://www.dtcc.com/globals/pdfs/2018/february/27/service-guide-settlement | 待读取 |
| DTC Settlement Service Guide (2023-03-28, PDF) | 上一版本，可用于对比 | https://www.dtcc.com/-/media/Files/Downloads/Operational-Resilience/DTC-Settlement-Service-Guide.pdf | 已下载(PDF不可读) |
| NSCC Fee Guide 2025/2026 | 完整费率表，含 CNS Fails Charge 新规 | https://www.dtcc.com/-/media/Files/Downloads/legal/fee-guides/nsccfeeguide.pdf | 待读取 |
| DTCC Understanding Settlement | 公开概述页（HTML，可直接读） | https://www.dtcc.com/understanding-settlement/index.html | 待读取 |
| DTCC Learning Center - CNS | CNS 产品介绍（需登录获取完整手册） | https://dtcclearning.com/products-and-services/equities-clearing/cns.html | 部分公开 |

### T+1 相关法规文档

| 文档名称 | 内容描述 | 官方链接 | 状态 |
|---------|---------|---------|------|
| SEC Rule 15c6-1 最终规则全文 | T+1 法规，含 Rule 15c6-2 / 17Ad-27 完整文本 | https://www.sec.gov/files/rules/final/2023/34-96930.pdf | 待读取 |
| SEC Rule 15c6-1 小实体合规指南 | 合规要求摘要（HTML，可直接读） | https://www.sec.gov/investment/settlement-cycle-small-entity-compliance-guide-15c6-1-15c6-2-204-2 | 待读取 |
| SEC T+1 Risk Alert (2024-03-27) | 检查重点，broker-dealer 合规要点 | https://www.sec.gov/files/risk-alert-tplus1-032724.pdf | 待读取 |
| SR-NSCC-2024-002 批准令 (Federal Register) | T+1 NSCC 规则修订完整批准文本 | https://www.federalregister.gov/documents/2024/05/08/2024-10001/ | 待读取 |
| FINRA Regulatory Notice 23-15 | FINRA T+1 指引，含 REX 系统更新 | https://www.finra.org/rules-guidance/notices/23-15 | 待读取 |
| OCC Bulletin 2024-3 | OCC 银行业 T+1 合规指引 | https://www.occ.gov/news-issuances/bulletins/2024/bulletin-2024-3.html | 待读取 |

### 2024-2025 NSCC 规则变更

| 规则编号 | 内容 | 生效时间 |
|---------|------|---------|
| SR-NSCC-2024-002 | T+1 缩短结算周期，Rule 11/Procedure VII 修订 | 2024-05-28 |
| SR-NSCC-2024-007 | 碎股（Fractional Share）纳入 CNS 清算 | 2024 |
| SR-NSCC-2024-008 | ID Net 服务退役（2024-11-15 终止） | 2024-11-15 |
| SR-NSCC-2025-013 | CNS Fails Charge 改革：取消 Long Position Fails Charge | 2025（待确认） |

---

## 二、港股清结算 (HKEX/HKSCC/CCASS)

### HKSCC 操作手册

| 文档名称 | 内容描述 | 官方链接 | 状态 |
|---------|---------|---------|------|
| HKSCC Operational Procedures 全文 | 最权威操作手册，所有 Section 合集 | https://www.hkex.com.hk/-/media/HKEX-Market/Services/Rules-and-Forms-and-Fees/Rules/HKSCC/Whole_HKSCCOP_e.pdf | 待读取(大PDF) |
| Section 9 清结算总览 | CNS + Isolated Trades 架构，角色定义 | https://www.hkex.com.hk/-/media/HKEX-Market/Services/Rules-and-Forms-and-Fees/Rules/HKSCC/Operational-Procedures/SEC09.pdf | 已下载(PDF不可读) |
| Section 10 Exchange Trades - CNS | **每日批次时间表**，CNS netting 机制，资金结算时间 | https://www.hkex.com.hk/-/media/HKEX-Market/Services/Rules-and-Forms-and-Fees/Rules/HKSCC/Operational-Procedures/SEC10.pdf | 待读取 |
| Section 12 | （待确认内容） | https://www.hkex.com.hk/-/media/HKEX-Market/Services/Rules-and-Forms-and-Fees/Rules/HKSCC/Operational-Procedures/SEC12.pdf | 待读取 |
| Section 13 Securities Settlement | 交收失败处理，取消申请，SI Linkage，无法部分交收 | https://www.hkex.com.hk/-/media/HKEX-Market/Services/Rules-and-Forms-and-Fees/Rules/HKSCC/Operational-Procedures/SEC13.pdf | 已下载(PDF不可读) |
| Section 21 Costs & Expenses | CCASS 费率明细（SI 费、存取费等） | https://www.hkex.com.hk/-/media/HKEX-Market/Services/Rules-and-Forms-and-Fees/Rules/HKSCC/Operational-Procedures/SEC21.pdf | 待读取 |
| CCASS Guide (Feb 2022) | CCASS 总体介绍指南 | https://www.hkex.com.hk/-/media/HKEX-Market/Services/Settlement-and-Depository/Securities-Admission-into-CCASS/CCASS-Guide-(Feb-2022).pdf | 待读取 |
| HKSCC OP 页面（最新更新入口） | 获取最新版 Section 的官方入口 | https://www.hkex.com.hk/Services/Rules-and-Forms-and-Fees/Rules/HKSCC/Operational-Procedures | 待读取 |

### SEOCH（期权清算，参考）

| 文档名称 | 内容描述 | 官方链接 | 状态 |
|---------|---------|---------|------|
| SEOCH Chapter 8 Stock Settlement | 期权行权股票交收，T+2，碎股现金结算规则 | https://www.hkex.com.hk/-/media/HKEX-Market/Services/Rules-and-Forms-and-Fees/Rules/SEOCH/Operational-Procedures/CHAP08.pdf | 待读取 |
| SEOCH Chapter 10 Money Settlement | 期权资金结算流程 | https://www.hkex.com.hk/-/media/hkex-market/services/rules-and-forms-and-fees/rules/overview/.../chap10 | 待读取 |

### 第三方参考（辅助理解）

| 文档名称 | 说明 | 链接 |
|---------|------|------|
| Clearstream HK Settlement Process | 国际托管视角的港股结算流程描述 | https://www.clearstream.com/clearstream-en/res-library/market-coverage/settlement-process-hong-kong-1281186 |

---

## 三、已发现的关键事实（需用原文校验）

> 以下内容来自搜索结果摘要，置信度高但须读取原文确认

### 美股

1. **T+1 合规日期**：2024-05-28（SEC Rule 15c6-1 修订生效）
2. **新增 Rule 15c6-2**：要求 broker-dealer 在 Trade Date 当日完成 allocation/confirmation/affirmation
3. **新增 Rule 17Ad-27**：要求中央匹配服务商（CMSP）支持 STP（直通处理）
4. **CNS netting 效率**：2022年数据，netting 将结算义务减少约 98%（从 $519T → $9T）
5. **DTC 处理窗口**：23小时/天，5天/周
6. **Night Cycle 开始时间**：Trade Date 晚上 11:30 PM ET
7. **SPP 截止时间**：Settlement Date 约 3:10 PM ET
8. **ID Net 服务已于 2024-11-15 退役**（SR-NSCC-2024-008）
9. **SR-NSCC-2025-013**：CNS Fails Charge 改革，取消 Long Position（fails to receive）的 Fails Charge

### 港股

1. **CNS 批次结算时间**（每个 Settlement Day）：
   - CNS 批次：16:45 / 17:30 / 18:15 / 19:00
   - SI 批次（含最后一批）：16:45 / 17:30 / 18:15 / 19:00 / **19:45**
2. **资金结算时间**：第 3 个批次完成后（约 2:00 PM），Intra-day Payment 查询从 2:30 PM 开放
3. **PCS（Preliminary Clearing Statement）**：每个交易日发布两批，第二批约 8:00 PM，为 CNS 接受确认
4. **Isolated Trades 不允许部分交收**（No partial delivery）
5. **CNS 下 HKSCC 通过 novation 成为结算对手方**，提供结算担保
6. **Buy-in 程序**：通常 T+2，但 HKSCC 有权要求当日结算；申请需在 12:01 PM - 8:00 PM 内提交，次一交易日执行
7. **Stock Connect 北向**：证券 T+0，资金 T+1（或 T+0 可选）
8. **结算取消**：CNS 下需向 HKSCC 申请；Isolated Trades 下需双方参与者联合申请

---

## 四、读取优先级

当 poppler 可用后，按以下顺序读取 PDF：

1. **HKSCC Section 10** — 最关键，含完整每日时间表
2. **HKSCC Section 13** — 交收失败处理逻辑
3. **NSCC Rules Rule 11** — CNS 系统完整规则
4. **SEC Rule 15c6-1 最终规则** — T+1 合规义务全文
5. **HKSCC Section 9** — CCASS 整体架构

---

## 五、读取工具说明

用marker-pdf 库，本地模型不花token,效果还好。                                                                                                         
                                                                                                                                              
  具体情况：
                                                                                                                                                       
  - 库：marker-pdf（版本 1.10.1，已装在 .venv 里）                                                                                                     
  - 模型：运行时自动从 HuggingFace 下载，缓存在 ~/Library/Caches/datalab/models/，当时下载了几个模型：                                                 
    - layout 模型（1.35G）—— 识别页面布局                                                                                                              
    - text_detection 模型（73MB）—— 检测文字区域                                                                                                       
    - ocr_error_detection 模型（258MB）—— OCR 错误检测                                                                                                 
    - table_recognition 模型 —— 表格识别                                                                                                               
  - 运行方式：强制用 CPU（torch_device: cpu），因为 M4 Pro 的 Metal GPU 在处理大批次时会崩溃（NDArray dimension length > INT_MAX） 
