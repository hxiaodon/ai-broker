package ledger

import (
	"context"
	"time"

	"github.com/shopspring/decimal"
)

// AccountType represents the type of account in double-entry bookkeeping
type AccountType string

const (
	AccountTypeAsset     AccountType = "ASSET"     // 资产（券商银行账户）
	AccountTypeLiability AccountType = "LIABILITY" // 负债（用户券商账户）
	AccountTypeBank      AccountType = "BANK"      // 银行账户
	AccountTypeFee       AccountType = "FEE"       // 手续费收入
)

// Currency represents supported currencies
type Currency string

const (
	CurrencyUSD Currency = "USD"
	CurrencyHKD Currency = "HKD"
)

// Entry represents a single ledger entry
type Entry struct {
	EntryID      string
	TransferID   string
	AccountType  AccountType
	AccountID    string
	Debit        decimal.Decimal
	Credit       decimal.Decimal
	Currency     Currency
	ExchangeRate decimal.Decimal // if currency conversion
	Description  string
	CreatedAt    time.Time
}

// Transaction represents a complete double-entry transaction
type Transaction struct {
	TransactionID string
	TransferID    string
	Entries       []*Entry
	Description   string
	CreatedAt     time.Time
}

// Balance represents an account balance
type Balance struct {
	AccountID        string
	Currency         Currency
	TotalBalance     decimal.Decimal
	AvailableBalance decimal.Decimal // total - unsettled
	UnsettledAmount  decimal.Decimal
	UpdatedAt        time.Time
}

// Engine defines the ledger engine interface
type Engine interface {
	// RecordDeposit records a deposit transaction
	// Debit: Brokerage Bank Account (ASSET)
	// Credit: User Brokerage Account (LIABILITY)
	RecordDeposit(ctx context.Context, transferID, accountID string, amount decimal.Decimal, currency Currency) error

	// RecordWithdrawal records a withdrawal transaction
	// Debit: User Brokerage Account (LIABILITY)
	// Debit: Fee Income (FEE)
	// Credit: Brokerage Bank Account (ASSET)
	RecordWithdrawal(ctx context.Context, transferID, accountID string, amount, fee decimal.Decimal, currency Currency) error

	// GetBalance retrieves the current balance for an account
	GetBalance(ctx context.Context, accountID string, currency Currency) (*Balance, error)

	// GetEntries retrieves ledger entries for a transfer
	GetEntries(ctx context.Context, transferID string) ([]*Entry, error)

	// ListEntries retrieves ledger entries for an account
	ListEntries(ctx context.Context, accountID string, limit, offset int) ([]*Entry, error)
}

// Repository defines the ledger data access interface
type Repository interface {
	// CreateTransaction creates a new transaction with multiple entries
	CreateTransaction(ctx context.Context, tx *Transaction) error

	// GetEntriesByTransfer retrieves entries by transfer ID
	GetEntriesByTransfer(ctx context.Context, transferID string) ([]*Entry, error)

	// GetEntriesByAccount retrieves entries by account ID
	GetEntriesByAccount(ctx context.Context, accountID string, limit, offset int) ([]*Entry, error)

	// GetBalance retrieves the current balance
	GetBalance(ctx context.Context, accountID string, currency Currency) (*Balance, error)

	// UpdateBalance updates the account balance
	UpdateBalance(ctx context.Context, accountID string, currency Currency, amount decimal.Decimal) error
}

// Validator validates ledger transactions
type Validator interface {
	// ValidateTransaction ensures the transaction is balanced (debits = credits)
	ValidateTransaction(tx *Transaction) error

	// ValidateBalance ensures balance is non-negative
	ValidateBalance(balance decimal.Decimal) error
}
