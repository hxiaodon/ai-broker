---
type: platform-standard
level: L3
scope: cross-domain
status: ACTIVE
created: 2026-03-18T00:00+08:00
maintainer: go-scaffold-architect
applies_to:
  - services/ams
  - services/trading-engine
  - services/market-data
  - services/fund-transfer
  - any new Go microservice
---

# DDD 战术模式、SOLID 与设计模式规范

> 本文档是平台级工程标准，为 domain engineer 在 `biz/`、`domain/` 层实现业务逻辑提供具体的 Go 写法参考。
> 配套阅读：[go-service-architecture.md](go-service-architecture.md)（DDD 分层、目录布局）

---

## 为什么需要本文档

**背景**：DDD 战术模式的违反不会触发编译错误，却会在架构层悄悄累积——Entity 带 ORM tag 导致层间泄漏，值对象被直接修改导致不变量破坏，Repository 接口返回 `*gorm.DB` 导致基础设施漏入领域层。多个 agent / 多个会话如果各自推理，同一概念（如 Value Object 的不可变性）写法会漂移。

**原则**：
- 有明确「正确/错误」边界的模式 → 写进本规范
- 高度情境依赖或 Go 自然实现的模式 → 留给当场推理

---

## Part 1：DDD 战术模式

### 1. Value Object（值对象）

**定义**：无唯一标识、按值比较、不可变的领域概念。

#### Go 实现要点

1. 用 struct 表示，**所有字段导出（exported）**，便于序列化，但**不对外暴露修改入口**
2. 相等比较用 `Equal(other T) bool` 方法，不依赖指针地址
3. 所有「修改」操作返回新实例，原实例不变
4. 构造函数校验不变量，失败返回 `error`
5. 不含任何 ORM tag、HTTP tag 或持久化相关字段

#### ✅ 正确示例

```go
// trading-engine/internal/order/domain/vo/money.go
package vo

import (
    "errors"
    "github.com/shopspring/decimal"
)

type Currency string

const (
    USD Currency = "USD"
    HKD Currency = "HKD"
)

type Money struct {
    Amount   decimal.Decimal
    Currency Currency
}

// NewMoney 构造时校验不变量
func NewMoney(amount decimal.Decimal, currency Currency) (Money, error) {
    if amount.IsNegative() {
        return Money{}, errors.New("money amount cannot be negative")
    }
    if currency == "" {
        return Money{}, errors.New("currency is required")
    }
    return Money{Amount: amount, Currency: currency}, nil
}

// Add 返回新实例，不修改原值
func (m Money) Add(other Money) (Money, error) {
    if m.Currency != other.Currency {
        return Money{}, errors.New("cannot add money with different currencies")
    }
    return Money{Amount: m.Amount.Add(other.Amount), Currency: m.Currency}, nil
}

// Equal 按值比较
func (m Money) Equal(other Money) bool {
    return m.Currency == other.Currency && m.Amount.Equal(other.Amount)
}

// IsZero 业务语义方法
func (m Money) IsZero() bool {
    return m.Amount.IsZero()
}
```

```go
// 其他典型值对象
type Symbol struct {
    Code     string // "AAPL", "00700"
    Exchange string // "NASDAQ", "HKEX"
}

type OrderStatus string

const (
    OrderStatusPending   OrderStatus = "PENDING"
    OrderStatusFilled    OrderStatus = "FILLED"
    OrderStatusCancelled OrderStatus = "CANCELLED"
)

func (s OrderStatus) IsFinal() bool {
    return s == OrderStatusFilled || s == OrderStatusCancelled
}
```

#### ❌ 错误示例

```go
// ❌ 直接修改字段——破坏不可变性
m.Amount = decimal.NewFromInt(100)

// ❌ 用 float64 表示货币金额——精度丢失
type Money struct {
    Amount   float64 // CRITICAL BUG: 违反 financial-coding-standards Rule 1
    Currency string
}

// ❌ 含 ORM tag——值对象不应知道持久化
type Money struct {
    Amount   decimal.Decimal `gorm:"column:amount"`
    Currency string          `gorm:"column:currency"`
}
```

#### 与相邻概念区别

| | Value Object | Entity |
|--|-------------|--------|
| 标识 | 无（按值比较） | 有唯一 ID |
| 可变性 | 不可变 | 可变（有生命周期） |
| 典型例子 | `Money`、`Symbol`、`Email`、`OrderStatus` | `Order`、`Account`、`Position` |

**在本项目中的典型位置**：`trading-engine/internal/order/domain/vo/`、`ams/internal/account/domain/vo/`

---

### 2. Entity（实体）

**定义**：有唯一标识、有生命周期的领域对象。标识相同则视为同一实体，即使其他字段不同。

#### Go 实现要点

1. Domain struct **不含任何 ORM/DB tag**——领域层对持久化无感知
2. 单独定义 DAO struct（含 `gorm.Model` 或手动字段）做 DB 映射
3. 实现 Anti-Corruption Layer（ACL）：`ToEntity()` 和 `ToDAO()` 转换函数放在 `data/`（Infrastructure 层）
4. Entity 方法只接收和返回 domain 对象，不接触 DAO struct
5. ID 字段类型优先用 `string`（UUID），避免数据库自增 ID 泄漏到领域层

#### ✅ 正确示例

```go
// trading-engine/internal/order/domain/order.go  (Domain 层)
package domain

import (
    "time"
    "github.com/shopspring/decimal"
    "trading-engine/internal/order/domain/vo"
)

type Order struct {
    ID          string
    AccountID   string          // 跨 Aggregate 引用：只存 ID，不持有对象
    Symbol      vo.Symbol
    Side        OrderSide
    Price       decimal.Decimal
    Quantity    decimal.Decimal
    FilledQty   decimal.Decimal
    Status      vo.OrderStatus
    CreatedAt   time.Time
    UpdatedAt   time.Time
}

func (o *Order) Fill(qty decimal.Decimal, price decimal.Decimal) error {
    if o.Status.IsFinal() {
        return errors.New("cannot fill a finalized order")
    }
    newFilled := o.FilledQty.Add(qty)
    if newFilled.GreaterThan(o.Quantity) {
        return errors.New("fill quantity exceeds order quantity")
    }
    o.FilledQty = newFilled
    if o.FilledQty.Equal(o.Quantity) {
        o.Status = vo.OrderStatusFilled
    }
    o.UpdatedAt = time.Now().UTC()
    return nil
}
```

```go
// trading-engine/internal/order/infra/mysql/model.go  (Infrastructure 层)
package mysql

import "gorm.io/gorm"

// OrderGorm 是 DB 映射 struct，仅在 infra 层使用
type OrderGorm struct {
    gorm.Model
    OrderID   string `gorm:"column:order_id;uniqueIndex"`
    AccountID string `gorm:"column:account_id;index"`
    Symbol    string `gorm:"column:symbol"`
    Exchange  string `gorm:"column:exchange"`
    Side      string `gorm:"column:side"`
    Price     string `gorm:"column:price;type:decimal(18,4)"`
    Quantity  string `gorm:"column:quantity;type:decimal(18,4)"`
    FilledQty string `gorm:"column:filled_qty;type:decimal(18,4)"`
    Status    string `gorm:"column:status"`
}

// ToEntity 将 DB 记录转为 Domain 实体（ACL 转换）
func ToEntity(m *OrderGorm) (*domain.Order, error) {
    price, err := decimal.NewFromString(m.Price)
    if err != nil {
        return nil, fmt.Errorf("parse price: %w", err)
    }
    // ... 其他字段转换
    return &domain.Order{
        ID:        m.OrderID,
        AccountID: m.AccountID,
        Symbol:    vo.Symbol{Code: m.Symbol, Exchange: m.Exchange},
        Price:     price,
        // ...
    }, nil
}

// ToDAO 将 Domain 实体转为 DB struct
func ToDAO(e *domain.Order) *OrderGorm {
    return &OrderGorm{
        OrderID:   e.ID,
        AccountID: e.AccountID,
        Symbol:    e.Symbol.Code,
        Exchange:  e.Symbol.Exchange,
        Price:     e.Price.String(),
        // ...
    }
}
```

#### ❌ 错误示例

```go
// ❌ Domain Entity 直接含 ORM tag——领域层依赖基础设施
type Order struct {
    gorm.Model                               // 泄漏基础设施
    Symbol string `gorm:"column:symbol"`    // 泄漏持久化细节
    Price  float64 `json:"price"`           // float64 精度 bug + JSON tag 不属于领域层
}

// ❌ 跨 Aggregate 持有对象指针而非 ID
type Order struct {
    Account *Account // ❌ 应该是 AccountID string
}
```

**在本项目中的典型位置**：`{service}/internal/{subdomain}/domain/` 或 `{service}/internal/{subdomain}/biz/`

---

### 3. Aggregate（聚合）

**定义**：一组强一致性约束的实体和值对象的集合，由 Aggregate Root（聚合根）对外提供唯一入口。

#### Go 实现要点

1. Aggregate Root 是唯一的对外访问入口——外部代码只能调用聚合根的方法
2. 跨 Aggregate 引用：**只存 ID**（`AccountID string`），不持有对象指针
3. Aggregate 边界判断：「这条不变量必须在同一事务里原子满足吗？」→ YES 放同一 Aggregate
4. 聚合根方法负责校验并保护不变量，不允许外部绕过方法直接赋值
5. 一个 Aggregate 对应一个 Repository

#### ✅ 正确示例

```go
// trading-engine/internal/order/domain/order_aggregate.go
package domain

// Order 是聚合根，保护「累计成交量不能超过委托量」的不变量
type Order struct {
    id        string          // 小写：不允许外部直接赋值
    accountID string
    fills     []Fill          // 内部子实体，只通过聚合根方法访问
    quantity  decimal.Decimal
    filledQty decimal.Decimal
    status    vo.OrderStatus
}

// AddFill 是唯一修改成交记录的入口，内部检查不变量
func (o *Order) AddFill(fill Fill) error {
    if o.status.IsFinal() {
        return ErrOrderAlreadyFinalized
    }
    newFilled := o.filledQty.Add(fill.Quantity)
    if newFilled.GreaterThan(o.quantity) {
        return ErrFillExceedsQuantity
    }
    o.fills = append(o.fills, fill)
    o.filledQty = newFilled
    if o.filledQty.Equal(o.quantity) {
        o.status = vo.OrderStatusFilled
    }
    return nil
}

// ID 提供只读访问
func (o *Order) ID() string { return o.id }

// 跨 Aggregate 引用：持有 Account 的 ID，不持有 Account 对象
func (o *Order) AccountID() string { return o.accountID }
```

```go
// ❌ Position 和 Order 是否应在同一 Aggregate？
// 问：「Position 的持仓量必须在下单同一事务里更新吗？」
// 答：不需要——持仓在成交后由 settlement 更新，不是下单时
// → Position 和 Order 是独立 Aggregate，跨 Aggregate 只用 ID 关联
```

#### ❌ 错误示例

```go
// ❌ 直接访问聚合内部子实体并修改，绕过聚合根保护
order.Fills = append(order.Fills, fill)   // 绕过不变量检查
order.FilledQty = order.FilledQty.Add(fill.Quantity) // 不一致风险

// ❌ 持有跨 Aggregate 对象引用
type Order struct {
    Account  *Account   // ❌ 持有对象，两个 Aggregate 事务边界混淆
    Position *Position  // ❌ 同上
}
```

**在本项目中的典型位置**：`trading-engine/internal/order/domain/`、`ams/internal/account/domain/`

---

### 4. Repository（仓储）

**定义**：为 Aggregate 提供持久化抽象，隐藏存储细节。Domain 层定义接口，Infrastructure 层实现。

#### Go 实现要点

1. 接口定义在 `domain/` 或 `biz/`（Domain 层），实现在 `data/` 或 `infra/mysql/`（Infrastructure 层）
2. 接口方法按**业务操作**命名（`FindByOrderID`、`FindPendingOrders`），不是通用 CRUD
3. 接口不能返回 DB 相关类型（`*gorm.DB`、`*sql.Rows`、`*sqlx.DB`）
4. Repository 只负责**单个 Aggregate** 的持久化，不做跨 Aggregate 的联表查询
5. 复杂查询（报表、多 Aggregate 联查）通过专用 Query Service 处理，不通过 Repository

#### ✅ 正确示例

```go
// trading-engine/internal/order/domain/repo.go  (Domain 层定义接口)
package domain

import "context"

// OrderRepository 接口定义在领域层，调用方决定自己需要什么
type OrderRepository interface {
    Save(ctx context.Context, order *Order) error
    FindByID(ctx context.Context, id string) (*Order, error)
    FindByAccountID(ctx context.Context, accountID string, opts QueryOpts) ([]*Order, error)
    FindPendingBySymbol(ctx context.Context, symbol vo.Symbol) ([]*Order, error)
    // 注意：没有 Delete——订单只能取消（状态变更），不物理删除
}
```

```go
// trading-engine/internal/order/infra/mysql/order_repo.go  (Infrastructure 层实现)
package mysql

import (
    "context"
    "gorm.io/gorm"
    "trading-engine/internal/order/domain"
)

type orderRepo struct {
    db *gorm.DB
}

func NewOrderRepo(db *gorm.DB) domain.OrderRepository {
    return &orderRepo{db: db}
}

func (r *orderRepo) FindByID(ctx context.Context, id string) (*domain.Order, error) {
    var m OrderGorm
    if err := r.db.WithContext(ctx).Where("order_id = ?", id).First(&m).Error; err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, domain.ErrOrderNotFound
        }
        return nil, fmt.Errorf("find order %s: %w", id, err)
    }
    return ToEntity(&m)
}
```

#### ❌ 错误示例

```go
// ❌ 接口定义在 Infrastructure 层（依赖方向倒置）
package mysql
type OrderRepository interface { ... }

// ❌ 接口方法返回 DB 类型——基础设施泄漏到领域层
type OrderRepository interface {
    Query(ctx context.Context) *gorm.DB  // ❌ 返回 gorm.DB
}

// ❌ 用 Service 直接调用 GORM，绕过 Repository
func (s *OrderService) GetOrder(id string) (*Order, error) {
    var order OrderGorm
    s.db.Where("order_id = ?", id).First(&order) // ❌ 领域层直接含 DB 操作
}
```

**在本项目中的典型位置**：接口在 `{service}/internal/{subdomain}/domain/repo.go`；实现在 `{service}/internal/{subdomain}/infra/mysql/`

---

### 5. Domain Service（领域服务）

**定义**：封装涉及多个 Aggregate 或无法归属单一 Entity 的业务逻辑。

#### Go 实现要点

1. **无状态 struct**，不持有可变状态，可安全并发使用
2. 只接收和返回 domain 对象，不接触 Repository、Kafka、HTTP 等基础设施
3. 方法签名：`func (s *RiskService) CheckMarginRequirement(order *Order, account *Account) (*RiskResult, error)`
4. Domain Service 与 Application Service 职责严格分开（见下方区别表）

#### ✅ 正确示例

```go
// trading-engine/internal/risk/domain/service.go
package domain

// MarginCalculator 是领域服务，计算涉及多个 Aggregate 的保证金需求
// 无状态——只依赖传入的领域对象
type MarginCalculator struct{}

func NewMarginCalculator() *MarginCalculator {
    return &MarginCalculator{}
}

// Calculate 接收 domain 对象，返回 domain 对象
func (c *MarginCalculator) Calculate(
    order *Order,
    position *Position,
    account *Account,
) (*MarginRequirement, error) {
    // 纯业务逻辑：不调用 DB、不发 Kafka、不调用 HTTP
    initialMargin := order.Price.Mul(order.Quantity).Mul(decimal.NewFromFloat(0.25))
    maintenanceMargin := position.MarketValue().Mul(decimal.NewFromFloat(0.20))
    available := account.CashBalance().Sub(position.MarginUsed())

    if available.LessThan(initialMargin) {
        return nil, ErrInsufficientMargin
    }
    return &MarginRequirement{
        Initial:     initialMargin,
        Maintenance: maintenanceMargin,
    }, nil
}
```

#### ❌ 错误示例

```go
// ❌ Domain Service 直接调用 Repository——应由 Application Service 协调
func (s *RiskDomainService) CheckOrder(ctx context.Context, orderID string) error {
    order, _ := s.orderRepo.FindByID(ctx, orderID)   // ❌ 领域服务不该持有 repo
    account, _ := s.accountRepo.FindByID(ctx, order.AccountID) // ❌
    // ...
}
```

#### Domain Service vs Application Service

| | Domain Service | Application Service |
|--|----------------|---------------------|
| 位置 | `domain/service/` 或 `biz/` | `app/` 或 `service/` |
| 知道什么 | 业务规则 | 流程编排 |
| 知道 Repository？ | ❌ 否 | ✅ 是 |
| 知道 Kafka？ | ❌ 否 | ✅ 是 |
| 知道 HTTP？ | ❌ 否 | ✅ 是 |
| 典型职责 | 保证金计算、风控判断、费率计算 | 调用 repo 取数 → 调用 domain service → 保存 → 发事件 |

**在本项目中的典型位置**：`trading-engine/internal/risk/domain/service.go`、`ams/internal/kyc/domain/service.go`

---

### 6. Domain Event（领域事件）

**定义**：记录领域内发生的重要业务事实，命名用过去式。

#### Go 实现要点

1. struct 命名用**过去式**（`OrderPlaced`、`TradeSettled`、`FundsDeposited`）
2. 必含字段：`EventID string`（UUID）、`OccurredAt time.Time`（UTC）
3. 发布方式：写入 `outbox_events` 表（**与主业务在同一 DB 事务**），由 outbox worker 异步发 Kafka
4. **不**在 Aggregate 方法内直接发 Kafka——避免事务与消息不一致
5. 服务内消费：通过接口调用（见 `go-service-architecture.md` §5）；跨服务消费：Kafka topic

#### ✅ 正确示例

```go
// trading-engine/internal/order/domain/event/order_placed.go
package event

import "time"

// OrderPlaced 过去式命名，记录下单这一领域事实
type OrderPlaced struct {
    EventID   string    `json:"event_id"`   // UUID v4
    OccurredAt time.Time `json:"occurred_at"` // UTC
    OrderID   string    `json:"order_id"`
    AccountID string    `json:"account_id"`
    Symbol    string    `json:"symbol"`
    Exchange  string    `json:"exchange"`
    Side      string    `json:"side"`
    Quantity  string    `json:"quantity"`   // decimal as string
    Price     string    `json:"price"`      // decimal as string
}

func (e OrderPlaced) Topic() string { return "trading.order.placed.v1" }
```

```go
// trading-engine/internal/order/app/place_order_usecase.go  (Application 层)
package app

func (uc *PlaceOrderUsecase) Execute(ctx context.Context, cmd PlaceOrderCmd) error {
    // 1. 创建聚合根
    order, err := domain.NewOrder(cmd.toOrderParams())
    if err != nil {
        return fmt.Errorf("create order: %w", err)
    }

    // 2. 在同一事务里：保存聚合根 + 写入 outbox（Transactional Outbox 模式）
    return uc.txManager.RunInTx(ctx, func(ctx context.Context) error {
        if err := uc.orderRepo.Save(ctx, order); err != nil {
            return fmt.Errorf("save order: %w", err)
        }
        evt := event.OrderPlaced{
            EventID:    uuid.NewString(),
            OccurredAt: time.Now().UTC(),
            OrderID:    order.ID(),
            // ...
        }
        return uc.outbox.Publish(ctx, evt) // 写 outbox_events 表，同一事务
    })
    // outbox worker 异步读取并发送到 Kafka
}
```

#### ❌ 错误示例

```go
// ❌ 在 Aggregate 方法内直接发 Kafka——事务提交前消息可能已发出
func (o *Order) Place() error {
    o.status = vo.OrderStatusPending
    kafka.Publish("order.placed", o) // ❌ 事务可能回滚，消息已发出
    return nil
}

// ❌ 事件命名用现在式或动词——混淆「命令」和「事件」
type PlaceOrder struct{}  // ❌ 命令命名风格
type OrderPlacing struct{} // ❌ 进行时，不是事实
```

**在本项目中的典型位置**：`{service}/internal/{subdomain}/domain/event/`；outbox 表在对应服务的 DB schema

---

### 7. Factory（工厂）

**定义**：封装 Aggregate 创建的复杂逻辑，保证新创建的聚合根处于合法初始状态。

#### Go 实现要点

1. 工厂函数命名：`New{AggregateName}(...) (*AggregateName, error)`
2. 在构造函数内完成所有字段校验和初始状态设置
3. 返回完整合法的聚合根——调用方拿到后可直接使用，不需要再单独调用 validate
4. **何时需要 Factory**：创建涉及多字段联合校验、内部状态初始化（如生成 UUID、设置初始状态）
5. **何时不需要**：简单 struct 初始化，2-3 个字段无复杂约束

#### ✅ 正确示例

```go
// trading-engine/internal/order/domain/factory.go
package domain

import (
    "errors"
    "github.com/google/uuid"
    "time"
)

type OrderParams struct {
    AccountID string
    Symbol    vo.Symbol
    Side      OrderSide
    OrderType OrderType
    Quantity  decimal.Decimal
    Price     decimal.Decimal // 限价单必填，市价单为零
}

// NewOrder 工厂函数：封装聚合根创建的复杂校验和初始化
func NewOrder(params OrderParams) (*Order, error) {
    if params.AccountID == "" {
        return nil, errors.New("account ID is required")
    }
    if params.Quantity.IsNegative() || params.Quantity.IsZero() {
        return nil, errors.New("quantity must be positive")
    }
    if params.OrderType == OrderTypeLimit && params.Price.IsZero() {
        return nil, errors.New("limit order requires a price")
    }
    if params.OrderType == OrderTypeMarket && !params.Price.IsZero() {
        return nil, errors.New("market order must not have a price")
    }

    return &Order{
        id:        uuid.NewString(),           // 内部生成 ID
        accountID: params.AccountID,
        symbol:    params.Symbol,
        side:      params.Side,
        orderType: params.OrderType,
        quantity:  params.Quantity,
        price:     params.Price,
        filledQty: decimal.Zero,
        status:    vo.OrderStatusPending,      // 初始状态
        createdAt: time.Now().UTC(),
        updatedAt: time.Now().UTC(),
    }, nil
}
```

#### ❌ 错误示例

```go
// ❌ 暴露所有字段让调用方自己填——校验分散，初始状态无保证
order := &Order{
    ID:        "some-id",       // 调用方可能忘记
    Status:    "FILLED",        // 初始状态错误
    CreatedAt: time.Now(),      // 忘记 .UTC()
    // FilledQty 忘记初始化为 zero
}

// ❌ 构造函数不返回 error——无法表达创建失败
func NewOrder(accountID string, ...) *Order {
    // 校验失败时只能 panic 或 log，调用方无法处理
}
```

**在本项目中的典型位置**：`{service}/internal/{subdomain}/domain/factory.go` 或 `{subdomain}/domain/order/aggregate.go` 文件顶部

---

### 8. Specification（规格）

**定义**：将业务规则封装为可组合的对象，用于验证（下单前）或查询过滤（复杂条件）。

#### Go 实现要点

1. 泛型接口：`type Specification[T any] interface { IsSatisfiedBy(T) bool }`
2. 提供组合子：`And`、`Or`、`Not`
3. **使用场景**：3 个以上业务条件需要组合，且组合逻辑需要复用或单独测试
4. **不要滥用**：简单的 1-2 个 if 条件直接写，不需要 Specification
5. 可复用于两个场景：校验（传入 Aggregate）和过滤（传入 query 条件对象）

#### ✅ 正确示例

```go
// trading-engine/internal/order/domain/spec/order_spec.go
package spec

// Specification 泛型接口
type Specification[T any] interface {
    IsSatisfiedBy(T) bool
}

// WithinTradingHours 规格：当前是否在交易时段
type WithinTradingHours struct {
    clock Clock
}

func (s WithinTradingHours) IsSatisfiedBy(symbol vo.Symbol) bool {
    now := s.clock.Now().UTC()
    return isTradingHours(now, symbol.Exchange)
}

// SufficientBalance 规格：账户余额是否足以下单
type SufficientBalance struct{}

func (s SufficientBalance) IsSatisfiedBy(ctx OrderPlacementContext) bool {
    required := ctx.Order.Price.Mul(ctx.Order.Quantity)
    return ctx.Account.AvailableBalance().GreaterThanOrEqual(required)
}

// AndSpecification 组合子
type AndSpecification[T any] struct {
    specs []Specification[T]
}

func And[T any](specs ...Specification[T]) Specification[T] {
    return AndSpecification[T]{specs: specs}
}

func (a AndSpecification[T]) IsSatisfiedBy(t T) bool {
    for _, s := range a.specs {
        if !s.IsSatisfiedBy(t) {
            return false
        }
    }
    return true
}

// 使用：在 Application Service 或 Domain Service 中组合使用
canPlace := spec.And(
    spec.WithinTradingHours{clock: clock},
    spec.SufficientBalance{},
    spec.NotOnWatchlist{watchlist: watchlist},
)
if !canPlace.IsSatisfiedBy(ctx) {
    return ErrOrderNotAllowed
}
```

#### ❌ 错误示例

```go
// ❌ 过度使用 Specification——1 个简单条件不需要
type ActiveAccountSpec struct{}
func (s ActiveAccountSpec) IsSatisfiedBy(a *Account) bool {
    return a.Status == "ACTIVE"  // 直接 if a.Status == "ACTIVE" 更清晰
}

// ❌ Specification 内直接查询 DB——应只包含纯业务规则
type SufficientBalanceSpec struct {
    db *gorm.DB // ❌ Specification 不应知道基础设施
}
```

**在本项目中的典型位置**：`{service}/internal/{subdomain}/domain/spec/`

---

## Part 2：SOLID 在 Go 的落地

### SRP — 单一职责原则

**核心检测法**：用一句话描述 struct 的职责，如果句子里出现「**和（and）**」→ 可能违反 SRP。

#### ✅ 正确示例

```go
// 职责描述：「负责校验订单参数」——单一职责
type OrderValidator struct{}
func (v *OrderValidator) Validate(order *Order) error { ... }

// 职责描述：「负责计算订单手续费」——单一职责
type CommissionCalculator struct{}
func (c *CommissionCalculator) Calculate(order *Order) (decimal.Decimal, error) { ... }
```

#### ❌ 错误示例

```go
// 职责描述：「负责校验订单 AND 计算手续费 AND 提交到交易所」——违反 SRP
type OrderService struct {
    db       *gorm.DB
    exchange ExchangeClient
}

func (s *OrderService) ProcessOrder(order *Order) error {
    if err := s.validate(order); err != nil { ... }     // 校验职责
    commission := s.calculateCommission(order)          // 计算职责
    return s.exchange.Submit(order, commission)         // 提交职责
}
```

---

### OCP — 开闭原则

**Go 实现**：通过实现新 interface 扩展行为，不修改已有代码。

#### ✅ 正确示例

```go
// 接入新交易所：实现接口，不修改已有代码
type ExchangeConnector interface {
    SubmitOrder(ctx context.Context, order *Order) (*ExchangeOrderID, error)
    CancelOrder(ctx context.Context, exchangeOrderID string) error
    GetOrderStatus(ctx context.Context, exchangeOrderID string) (OrderStatus, error)
}

// 接入 NASDAQ
type NASDAQConnector struct{ ... }
func (c *NASDAQConnector) SubmitOrder(...) { ... }

// 接入 HKEX：新增 struct 实现接口，零修改已有代码
type HKEXConnector struct{ ... }
func (c *HKEXConnector) SubmitOrder(...) { ... }
```

---

### LSP — 里氏替换原则

**常见违反**：实现了接口但某个方法 panic、返回空或缩小接口契约。

#### ✅ 正确示例

```go
// 接口契约：FindByID 找不到时返回 ErrNotFound，永不 panic
type OrderRepository interface {
    FindByID(ctx context.Context, id string) (*Order, error)
}

// 所有实现都完整履行契约
type mysqlOrderRepo struct{ ... }
func (r *mysqlOrderRepo) FindByID(ctx context.Context, id string) (*Order, error) {
    // 找不到时返回 domain.ErrOrderNotFound，与契约一致
}

type inMemoryOrderRepo struct{ ... } // 测试用
func (r *inMemoryOrderRepo) FindByID(ctx context.Context, id string) (*Order, error) {
    // 同样返回 domain.ErrOrderNotFound，不是 nil, nil
}
```

#### ❌ 错误示例

```go
// ❌ 测试实现缩小契约——替换后行为不一致
type mockOrderRepo struct{}
func (r *mockOrderRepo) FindByID(ctx context.Context, id string) (*Order, error) {
    return nil, nil  // ❌ 应该返回 ErrNotFound，不是 nil, nil
}

// ❌ 实现方法 panic——违反接口契约
func (r *readonlyRepo) Save(ctx context.Context, order *Order) error {
    panic("read-only repository")  // ❌ 应返回 ErrReadOnly error
}
```

---

### ISP — 接口隔离原则

**规则**：接口越小越好，按**消费方**的实际需要定义。避免「胖接口」强迫实现方实现用不到的方法。

#### ✅ 正确示例

```go
// 按消费方需要拆分——三个小接口
type OrderReader interface {
    FindByID(ctx context.Context, id string) (*Order, error)
    FindByAccountID(ctx context.Context, accountID string) ([]*Order, error)
}

type OrderWriter interface {
    Save(ctx context.Context, order *Order) error
}

// OrderRepository = Reader + Writer（仅在需要两者时使用）
type OrderRepository interface {
    OrderReader
    OrderWriter
}

// 查询用例只注入 Reader
type GetOrderUsecase struct {
    repo OrderReader  // 不注入完整 Repository，只要读能力
}

// 命令用例注入完整 Repository
type PlaceOrderUsecase struct {
    repo OrderRepository
}
```

#### ❌ 错误示例

```go
// ❌ 胖接口——迫使只需要读的用例也依赖写方法
type OrderRepository interface {
    FindByID(...) (*Order, error)
    FindByAccountID(...) ([]*Order, error)
    Save(...) error
    Delete(...) error   // 查询用例永远不用这个
    BulkInsert(...) error // 测试 mock 需要实现但实际不用
}
```

---

### DIP — 依赖倒置原则

**规则**：接口定义在**调用方**（Domain/Application 层），实现在被调方（Infrastructure 层）。这是本项目已有规则（见 `go-service-architecture.md` §5），此处给出带注释的完整示例。

#### ✅ 正确示例

```go
// ✅ 接口在调用方（Domain 层）定义
// trading-engine/internal/order/domain/repo.go
package domain

// OrderRepository 接口定义在领域层——调用方说我需要什么
// Infrastructure 层实现它，但不知道这个接口的存在
type OrderRepository interface {
    Save(ctx context.Context, order *Order) error
    FindByID(ctx context.Context, id string) (*Order, error)
}

// ✅ 实现在 Infrastructure 层
// trading-engine/internal/order/infra/mysql/order_repo.go
package mysql

import "trading-engine/internal/order/domain"

// mysqlOrderRepo 实现 domain.OrderRepository
// Go 结构化类型（structural typing）：隐式实现，无需声明 "implements"
type mysqlOrderRepo struct {
    db *gorm.DB
}

// Wire 在组合根处绑定接口和实现
// wire.Bind(new(domain.OrderRepository), new(*mysql.mysqlOrderRepo))
```

---

## Part 3：设计模式与 DDD 的对应

仅收录有明确 DDD 业务场景对应的 4 个模式。

### Factory Method — Aggregate 创建

**DDD 场景**：创建 Aggregate 时需要多字段联合校验和初始状态设置。

见 [Part 1 §7 Factory](#7-factory工厂)。

---

### Proxy — Repository 缓存层

**DDD 场景**：为热点 Aggregate（如实时持仓、账户余额）增加 Redis 缓存，不修改业务代码。

```go
// trading-engine/internal/account/infra/cache/account_repo_cache.go
package cache

import "trading-engine/internal/account/domain"

// accountRepoCache 实现相同的 domain.AccountRepository 接口
type accountRepoCache struct {
    redis  RedisClient
    mysql  domain.AccountRepository // 被代理的真实实现
    ttl    time.Duration
}

func NewAccountRepoCache(redis RedisClient, mysql domain.AccountRepository) domain.AccountRepository {
    return &accountRepoCache{redis: redis, mysql: mysql, ttl: 30 * time.Second}
}

func (c *accountRepoCache) FindByID(ctx context.Context, id string) (*domain.Account, error) {
    // 先查 Redis
    cached, err := c.redis.Get(ctx, cacheKey(id))
    if err == nil {
        return deserialize(cached)
    }
    // Cache miss：查 MySQL
    account, err := c.mysql.FindByID(ctx, id)
    if err != nil {
        return nil, err
    }
    // 写回 Redis（异步，不阻塞主流程）
    go c.redis.Set(ctx, cacheKey(id), serialize(account), c.ttl)
    return account, nil
}

// Wire 注入：应用层注入 cache proxy，对 Application Service 透明
// wire.Bind(new(domain.AccountRepository), new(*cache.accountRepoCache))
```

---

### Observer — Domain Event 发布

**DDD 场景**：Aggregate 状态变更后，多个下游关注方需要响应（通知、审计、持仓更新等）。

```go
// Outbox worker 作为 subject，多个 Kafka consumer 作为 observer
// （具体实现见 kafka-topology.md 的 Transactional Outbox 章节）

// 发布侧（Application Service）：只写 outbox，不关心有多少 observer
outbox.Publish(ctx, event.OrderFilled{...})

// 消费侧 A（settlement consumer）：监听 trading.order.filled.v1
// 消费侧 B（notification consumer）：监听同一 topic，独立 consumer group
// 消费侧 C（audit consumer）：监听同一 topic，独立 consumer group

// 新增 observer：只需新增 Kafka consumer group，发布侧零修改
```

---

### Strategy — 可替换业务规则

**DDD 场景**：不同市场、不同账户类型需要不同的规则（手续费、风控、交易规则）。

```go
// trading-engine/internal/commission/domain/strategy.go
package domain

// CommissionStrategy 手续费计算策略接口
type CommissionStrategy interface {
    Calculate(order *Order) (decimal.Decimal, error)
}

// USStockCommission 美股手续费规则
type USStockCommission struct {
    perShareRate decimal.Decimal
    minCommission decimal.Decimal
}

func (s USStockCommission) Calculate(order *Order) (decimal.Decimal, error) {
    commission := s.perShareRate.Mul(order.Quantity)
    if commission.LessThan(s.minCommission) {
        return s.minCommission, nil
    }
    return commission, nil
}

// HKStockCommission 港股手续费规则（包含印花税、交易所费等）
type HKStockCommission struct {
    commissionRate decimal.Decimal
    stampDutyRate  decimal.Decimal
}

func (s HKStockCommission) Calculate(order *Order) (decimal.Decimal, error) {
    tradeValue := order.Price.Mul(order.Quantity)
    commission := tradeValue.Mul(s.commissionRate)
    stampDuty := tradeValue.Mul(s.stampDutyRate).RoundUp(0) // 向上取整到整港元
    return commission.Add(stampDuty), nil
}

// Application Service：运行时注入对应策略
type PlaceOrderUsecase struct {
    commissionStrategy CommissionStrategy // 运行时注入
}
```

---

## Part 4：决策指南

### 快速查阅表

| 业务场景 | 推荐模式 | 反模式（Anti-pattern） |
|---------|---------|----------------------|
| 表达金额、状态、标的等领域概念 | Value Object | 裸 `string` / `int` / `float64` |
| 有唯一标识的业务对象 | Entity + ACL 转换 | Entity 含 `gorm.Model` ORM tag |
| 多个 Entity 共享不变量 | Aggregate（聚合根保护） | 把所有逻辑放一个巨大 Service |
| DB / Redis 访问 | Repository 接口（Domain 定义） | Service 直接调用 `gorm.DB` |
| 跨多个 Aggregate 的业务规则 | Domain Service（无状态） | 在 Application Service 里硬编码业务逻辑 |
| Aggregate 状态变更后通知下游 | Domain Event + Transactional Outbox | 在 Aggregate 方法内直接发 Kafka |
| 复杂 Aggregate 创建（多字段校验） | Factory 函数 | 暴露所有字段的 struct literal |
| 3+ 个业务条件需要组合复用 | Specification | 深层嵌套 if-else |
| 热点数据加缓存 | Proxy（实现同一接口） | Service 层手写缓存逻辑 |
| 不同市场 / 账户类型的不同规则 | Strategy（接口 + 运行时注入） | switch-case 枚举所有场景 |
| 接入新交易所 / 新支付渠道 | OCP：实现新接口，不修改旧代码 | 在已有 Service 里加 if/switch |

### 何时 **不** 需要 DDD 战术模式

以下场景用 DDD 模式会过度复杂：

- **CRUD 管理接口**（如后台配置参数）：直接 Repository + DTO，无需 Aggregate
- **报表/查询接口**：用独立 Query Service，不用 Aggregate Repository
- **简单校验**（1-2 个字段）：直接写 if，不需要 Specification
- **无任何业务规则的数据中转**：如 Market Data 服务的行情推送，无领域逻辑，不需要 DDD 层

---

## 参考来源

| 来源 | 内容 |
|------|------|
| [ompluscator.com](https://ompluscator.com/article/golang/) — Practical DDD 系列 | DDD 8 个战术模式，含 Go 正确/错误代码对比 |
| [ompluscator.com](https://ompluscator.com/article/golang/) — Practical SOLID 系列 | SOLID 5 条 Go 落地，含反例 |
| [refactoring.guru/design-patterns/go](https://refactoring.guru/design-patterns/go) | GoF 模式 Go 实现，用于筛选 4 个值得规范的模式 |
| `docs/specs/platform/go-service-architecture.md` | DDD 分层、目录布局、跨子域通信 |
| `docs/specs/platform/kafka-topology.md` | Transactional Outbox、Kafka topic 规范 |
| `.claude/rules/financial-coding-standards.md` | decimal 类型、UTC 时间戳、审计日志规则 |
