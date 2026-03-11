package bank

import (
	"context"
	"time"

	"github.com/shopspring/decimal"
)

// Channel represents the bank transfer channel
type Channel string

const (
	ChannelACH   Channel = "ACH"    // US, 3-5 days, $0-3 fee
	ChannelWire  Channel = "WIRE"   // US, same day, $15-30 fee
	ChannelFPS   Channel = "FPS"    // HK, real-time, HK$0-5 fee
	ChannelCHATS Channel = "CHATS"  // HK, same day, HK$10-50 fee
	ChannelSWIFT Channel = "SWIFT"  // International, 3-5 days, $30-50 fee
)

// Currency represents supported currencies
type Currency string

const (
	CurrencyUSD Currency = "USD"
	CurrencyHKD Currency = "HKD"
)

// TransferStatus represents the status of a bank transfer
type TransferStatus string

const (
	TransferStatusPending   TransferStatus = "PENDING"
	TransferStatusProcessing TransferStatus = "PROCESSING"
	TransferStatusCompleted TransferStatus = "COMPLETED"
	TransferStatusFailed    TransferStatus = "FAILED"
)

// Account represents a bank account
type Account struct {
	BankAccountID string
	AccountID     string
	AccountName   string
	AccountNumber string
	RoutingNumber string // US: ABA routing, HK: bank code
	SwiftCode     string
	BankName      string
	Currency      Currency
	IsVerified    bool
	CreatedAt     time.Time
}

// TransferRequest represents a bank transfer request
type TransferRequest struct {
	TransferID    string
	AccountID     string
	BankAccountID string
	Amount        decimal.Decimal
	Currency      Currency
	Channel       Channel
	Description   string
}

// TransferResponse represents a bank transfer response
type TransferResponse struct {
	TransferID      string
	BankReferenceID string
	Status          TransferStatus
	EstimatedTime   time.Duration
	Fee             decimal.Decimal
	Message         string
}

// Adapter defines the bank adapter interface
type Adapter interface {
	// InitiateDeposit initiates a deposit from bank to brokerage
	InitiateDeposit(ctx context.Context, req *TransferRequest) (*TransferResponse, error)

	// InitiateWithdrawal initiates a withdrawal from brokerage to bank
	InitiateWithdrawal(ctx context.Context, req *TransferRequest) (*TransferResponse, error)

	// GetTransferStatus queries the status of a transfer
	GetTransferStatus(ctx context.Context, transferID string) (*TransferResponse, error)

	// VerifyAccount verifies a bank account (micro-deposits or instant verification)
	VerifyAccount(ctx context.Context, bankAccountID string) error

	// GetChannelInfo returns information about a channel
	GetChannelInfo(ctx context.Context, channel Channel) (*ChannelInfo, error)
}

// ChannelInfo represents information about a bank channel
type ChannelInfo struct {
	Channel       Channel
	Currency      Currency
	EstimatedTime time.Duration
	Fee           decimal.Decimal
	SingleLimit   decimal.Decimal
	DailyLimit    decimal.Decimal
	Available     bool
}

// Repository defines the bank account data access interface
type Repository interface {
	// CreateAccount creates a new bank account
	CreateAccount(ctx context.Context, account *Account) error

	// GetAccount retrieves a bank account by ID
	GetAccount(ctx context.Context, bankAccountID string) (*Account, error)

	// ListAccounts lists bank accounts for an account
	ListAccounts(ctx context.Context, accountID string) ([]*Account, error)

	// UpdateVerificationStatus updates the verification status
	UpdateVerificationStatus(ctx context.Context, bankAccountID string, verified bool) error

	// DeleteAccount deletes a bank account
	DeleteAccount(ctx context.Context, bankAccountID string) error
}
