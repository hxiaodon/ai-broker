# 支付网络技术原理

> 本文档解释 ACH、Wire、FPS 等支付网络的运营主体、技术本质和接入方式，
> 帮助工程师在设计 Bank Adapter Layer 前建立正确的认知模型。

---

## 一、支付渠道在出入金中的角色

ACH 和 Wire 是资金在用户银行账户和券商托管账户之间传输的"公路"，不同公路有不同的速度和成本。

```
用户银行账户
      │
      │  通过 ACH 或 Wire 传输资金
      ▼
券商托管账户（Omnibus Account）
      │
      │  内部记账
      ▼
用户虚拟资金账户（可交易）
```

### 入金（用户 → 券商）

| 渠道 | 模式 | 到账时间 | 费用 | 适用场景 |
|------|------|---------|------|---------|
| ACH | Pull（券商拉款） | T+1～T+3 | $0～$3 | 日常普通入金 |
| Wire | Push（用户主动转） | 当日 | $15～$30 | 大额/紧急入金 |

### 出金（券商 → 用户）

| 渠道 | 模式 | 到账时间 | 费用 | 适用场景 |
|------|------|---------|------|---------|
| ACH | Push（券商推款） | T+1～T+3 | 极低或免费 | 常规提款 |
| Wire | Push（券商发起） | 当日 | $15～$30 | 大额紧急提款 |

### ACH 与 Wire 的本质区别

```
ACH（Pull 为主）：
  券商主动去用户银行账户"拉"钱
  用户只需在 APP 授权一次
  批量处理，非实时

Wire（Push 为主）：
  用户主动去自己银行网银/柜台
  填写券商托管账户信息发起转账
  实时全额结算（RTGS），到账后不可撤销
```

---

## 二、ACH 和 Wire 不是某家银行专属

**ACH 和 Wire 是美国全国性支付基础设施，与具体银行无关。**

```
ACH / Wire ≈ 高速公路网络

JP Morgan ≈ 其中一个入口
Citibank  ≈ 另一个入口
SVB       ≈ 又一个入口

路是同一条路，入口不同而已
```

用户不需要在 JP Morgan 开户。他在任何美国银行（Chase、Wells Fargo、BoA）的账户，都可以通过 ACH 网络转账到我们在 JP Morgan 的托管账户。

我们研究 JP Morgan 文档，是因为他们的 API 文档质量最高，不代表 ACH/Wire 只能通过 JP Morgan 使用。

---

## 三、运营主体

### 美国

```
┌─────────────────────────────────────────────┐
│              美联储（Fed）                   │
│   ├─ FedACH      ACH 清算运营商之一          │
│   ├─ Fedwire     Wire 实时全额结算系统        │
│   └─ FedNow      实时支付网络（2023年上线）   │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│         The Clearing House（私营）           │
│   ├─ EPN         ACH 清算运营商之二          │
│   ├─ CHIPS       大额美元银行间清算           │
│   └─ RTP         实时支付网络（2017年上线）   │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│              Nacha（非营利协会）              │
│   └─ 制定 ACH 网络运营规则                   │
│      认证 ODFI/RDFI 资质                     │
│      不直接处理资金，只制定规则               │
└─────────────────────────────────────────────┘
```

### 香港（对应关系）

| 香港 | 美国对应 | 说明 |
|------|---------|------|
| HKICL（香港银行同业结算） | Nacha + The Clearing House | 运营 FPS 和 CHATS |
| FPS（转数快） | RTP / FedNow | 实时支付，7×24 |
| CHATS | Fedwire | 大额实时结算 |

---

## 四、技术本质：不是普通 Web 接口

这是最容易产生误解的地方。

### ACH：文件交换，不是实时 API

```
ACH 的本质是"文件交换"，不是实时 API 调用

流程：
  券商/银行
    → 生成 NACHA 格式文件
    → 上传给清算所（FedACH 或 EPN）
    → 清算所批量处理
    → 返回结果文件（含 Return Code）

NACHA 文件格式：
  1970 年代设计
  94 字符固定宽度，每行一条记录
  示例：
  101 021000021 0210000210601021200A094101BANK OF AMERICA    YOUR COMPANY NAME
  5200YOUR COMPANY         0000000000PPDPAYROLL         060102060102   1021000020000001

文件传输协议：
  ├─ SFTP（最常见的传统方式）
  ├─ AS2（EDI 标准）
  └─ REST API（现代银行的封装层，如 JP Morgan）
       底层仍是文件逻辑，API 只是帮你生成和提交文件
```

### Wire：专用金融网络，不走公共互联网

```
Fedwire：
  ├─ 通过 FedLine 专线连接（不走公共互联网）
  ├─ 物理专用网络，类似银行内网
  ├─ 报文格式：ISO 20022（2025年迁移完成）
  │            pacs.008（客户信贷转账）
  │            pacs.009（金融机构信贷转账）
  └─ 接入方式：FedLine Direct / FedLine Advantage
               需要专用硬件 + 数字证书

SWIFT（国际 Wire）：
  ├─ SWIFT 专用金融网络（不走公共互联网）
  ├─ 报文格式：MT 系列（传统）/ ISO 20022（新）
  └─ 接入需要 SWIFT BIC 代码（银行识别码）
     每家银行唯一标识
```

---

## 五、我们实际的接入方式

**我们不直接碰底层协议，通过合作银行封装的 API 调用。**

```
底层（我们不接触）：
  NACHA 文件 / Fedwire 专线 / SWIFT 网络
        │
        │  由合作银行封装
        ▼
中间层（我们实际调用）：
  合作银行提供的 API
  ├─ REST API（JP Morgan、Citibank 等现代银行）
  ├─ SOAP/XML（部分传统银行）
  └─ SFTP 文件接口（部分银行仍沿用）
        │
        ▼
我们的 Bank Adapter Layer（Go）
  走 HTTPS（公共互联网 + TLS）
  附加 HMAC-SHA256 签名、mTLS 等安全层
```

### 完整技术栈

```
用户手机
   │ HTTPS
   ▼
API Gateway
   │ gRPC（内网）
   ▼
Fund Transfer Service（Go）
   │ HTTPS + HMAC 签名（公共互联网）
   ▼
合作银行 REST API（JP Morgan / 汇丰）
   │ 专用金融网络（FedLine / SWIFT / HKICL）
   ▼
ACH 网络 / Fedwire / FPS
   │
   ▼
用户的任意银行账户
```

### 类比

```
快递行业类比：

顺丰内部网络（航空 + 车队 + 仓库）
≈ ACH/Fedwire 专用网络

电商平台调用顺丰 REST API
≈ 我们调用 JP Morgan REST API

电商不直接开飞机
≈ 我们不直连 Fedwire 专线

顺丰 API 内部再调度自己的网络
≈ JP Morgan API 内部再走 Fedwire

我们只管调 API，不管底层怎么传输
```

---

## 六、ACH 特有的业务风险：延迟 Return

Wire 到账即最终结算，不可撤销。ACH 则存在延迟失败的风险：

```
ACH 入金的"垫资"风险：

用户发起 ACH 入金 $5,000
    │
    ▼
我们立即给用户显示可用余额 $5,000
用户开始买股票
    │
T+2 后收到银行 Return Code R01（账户余额不足）
    │
    ▼
用户已用这 $5,000 买了股票！
我们实际上垫付了这笔钱  ← 重大风险

常见 Return Code：
  R01 = 账户余额不足
  R02 = 账户已关闭
  R03 = 账户不存在
  R10 = 账户持有人拒绝授权
  R29 = 企业未授权

处理方案：
  方案A（保守）：ACH 到账确认后才解冻余额，T+1～T+3 才可交易
  方案B（激进）：接入 Plaid/银行 Instant Verification 确认余额充足
                后提前解冻（Robinhood 的做法，限额 $1,000）
  方案C（分层）：新用户用方案A；信用良好的老用户用方案B
```

---

## 七、我们无法直连的系统

以下系统需通过持牌中间机构接入：

| 系统 | 接入要求 | 我们的方式 |
|------|---------|----------|
| Nacha ACH 网络 | 需成为 ODFI（发起存款金融机构），须有银行牌照 | 通过合作银行（JP Morgan/Citibank）接入 |
| Fedwire | 需成为美联储直接参与行 | 通过合作银行接入 |
| HKICL FPS | 需成为 FPS Settlement Participant | 通过持牌银行（汇丰/恒生）接入 |
| SWIFT 网络 | 需成为 SWIFT 成员，有 BIC 代码 | 通过合作银行的 SWIFT 接入 |

---

## 八、Bank Adapter Layer 设计含义

以上认知直接影响我们的系统架构：

```
Bank Adapter Layer 需要处理的差异：

渠道差异：
  ACH   → 文件逻辑，批量，有 Return Code，T+1～T+3
  Wire  → 实时，不可撤销，当日结算
  FPS   → 实时，ISO 20022 消息，7×24

银行差异：
  JP Morgan → REST API，HMAC-SHA256 签名
  Citibank  → REST API，OAuth 2.0
  汇丰香港  → REST API，HKMA Open API 框架
  恒生      → REST API，PKI 证书认证

Adapter 模式（每个银行+渠道一个 Adapter）：

type BankAdapter interface {
    SubmitDeposit(ctx, req) (BankRef, error)
    SubmitWithdrawal(ctx, req) (BankRef, error)
    GetTransferStatus(ctx, bankRef) (Status, error)
    ParseCallback(payload) (CallbackEvent, error)
}

实现：
  ACHAdapter（JP Morgan ACH）
  WireAdapter（JP Morgan Wire）
  FPSAdapter（汇丰 FPS）
  CHATSAdapter（汇丰 CHATS）
```
