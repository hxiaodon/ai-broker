package transfer

import (
	"context"
	"time"

	"github.com/shopspring/decimal"
)

// TransferType represents the type of fund transfer
type TransferType string

const (
	TransferTypeDeposit    TransferType = "DEPOSIT"
	TransferTypeWithdrawal TransferType = "WITHDRAWAL"
)

// TransferStatus represents the current status of a transfer
type TransferStatus string

const (
	TransferStatusPending          TransferStatus = "PENDING"
	TransferStatusComplianceCheck  TransferStatus = "COMPLIANCE_CHECK"
	TransferStatusBalanceCheck     TransferStatus = "BALANCE_CHECK"
	TransferStatusSettlementCheck  TransferStatus = "SETTLEMENT_CHECK"
	TransferStatusApproval         TransferStatus = "APPROVAL"
	TransferStatusBankProcessing   TransferStatus = "BANK_PROCESSING"
	TransferStatusConfirmed        TransferStatus = "CONFIRMED"
	TransferStatusLedgerUpdated    TransferStatus = "LEDGER_UPDATED"
	TransferStatusCompleted        TransferStatus = "COMPLETED"
	TransferStatusFailed           TransferStatus = "FAILED"
	TransferStatusRejected         TransferStatus = "REJECTED"
)

// BankChannel represents the bank transfer channel
type BankChannel string

const (
	BankChannelACH   BankChannel = "ACH"    // US, 3-5 days
	BankChannelWire  BankChannel = "WIRE"   // US, same day
	BankChannelFPS   BankChannel = "FPS"    // HK, real-time
	BankChannelCHATS BankChannel = "CHATS"  // HK, same day
	BankChannelSWIFT BankChannel = "SWIFT"  // International, 3-5 days
)

// Currency represents supported currencies
type Currency string

const (
	CurrencyUSD Currency = "USD"
	CurrencyHKD Currency = "HKD"
)

// Transfer represents a fund transfer
type Transfer struct {
	TransferID    string
	AccountID     string
	Type          TransferType
	Status        TransferStatus
	Amount        decimal.Decimal
	Currency      Currency
	Channel       BankChannel
	BankAccountID string
	RequestID     string // idempotency key
	FailureReason string
	CreatedAt     time.Time
	UpdatedAt     time.Time
	CompletedAt   *time.Time
}

// InitiateDepositRequest represents a deposit initiation request
type InitiateDepositRequest struct {
	AccountID     string
	Amount        decimal.Decimal
	Currency      Currency
	BankAccountID string
	Channel       BankChannel
	RequestID     string
}

// InitiateWithdrawalRequest represents a withdrawal initiation request
type InitiateWithdrawalRequest struct {
	AccountID     string
	Amount        decimal.Decimal
	Currency      Currency
	BankAccountID string
	Channel       BankChannel
	RequestID     string
}

// ApproveWithdrawalRequest represents a withdrawal approval request
type ApproveWithdrawalRequest struct {
	TransferID string
	ApproverID string
	Approved   bool
	Reason     string
}

// Service defines the fund transfer service interface
type Service interface {
	// Deposit operations
	InitiateDeposit(ctx context.Context, req *InitiateDepositRequest) (*Transfer, error)
	GetDeposit(ctx context.Context, transferID string) (*Transfer, error)
	ListDeposits(ctx context.Context, accountID string, limit, offset int) ([]*Transfer, error)

	// Withdrawal operations
	InitiateWithdrawal(ctx context.Context, req *InitiateWithdrawalRequest) (*Transfer, error)
	ApproveWithdrawal(ctx context.Context, req *ApproveWithdrawalRequest) (*Transfer, error)
	GetWithdrawal(ctx context.Context, transferID string) (*Transfer, error)
	ListWithdrawals(ctx context.Context, accountID string, limit, offset int) ([]*Transfer, error)

	// Status updates (called by bank adapters)
	UpdateStatus(ctx context.Context, transferID string, status TransferStatus, reason string) error
}

// Repository defines the transfer data access interface
type Repository interface {
	Create(ctx context.Context, transfer *Transfer) error
	GetByID(ctx context.Context, transferID string) (*Transfer, error)
	GetByRequestID(ctx context.Context, requestID string) (*Transfer, error)
	ListByAccount(ctx context.Context, accountID string, transferType TransferType, limit, offset int) ([]*Transfer, error)
	UpdateStatus(ctx context.Context, transferID string, status TransferStatus, reason string) error
	UpdateCompletedAt(ctx context.Context, transferID string, completedAt time.Time) error
}

// StateMachine defines valid state transitions
type StateMachine struct {
	validTransitions map[TransferStatus][]TransferStatus
}

// NewStateMachine creates a new state machine
func NewStateMachine() *StateMachine {
	return &StateMachine{
		validTransitions: map[TransferStatus][]TransferStatus{
			TransferStatusPending: {
				TransferStatusComplianceCheck,
				TransferStatusBalanceCheck,
				TransferStatusFailed,
			},
			TransferStatusComplianceCheck: {
				TransferStatusBalanceCheck,
				TransferStatusBankProcessing,
				TransferStatusFailed,
				TransferStatusRejected,
			},
			TransferStatusBalanceCheck: {
				TransferStatusSettlementCheck,
				TransferStatusComplianceCheck,
				TransferStatusFailed,
				TransferStatusRejected,
			},
			TransferStatusSettlementCheck: {
				TransferStatusComplianceCheck,
				TransferStatusApproval,
				TransferStatusFailed,
				TransferStatusRejected,
			},
			TransferStatusApproval: {
				TransferStatusBankProcessing,
				TransferStatusRejected,
			},
			TransferStatusBankProcessing: {
				TransferStatusConfirmed,
				TransferStatusFailed,
			},
			TransferStatusConfirmed: {
				TransferStatusLedgerUpdated,
				TransferStatusFailed,
			},
			TransferStatusLedgerUpdated: {
				TransferStatusCompleted,
			},
		},
	}
}

// CanTransition checks if a state transition is valid
func (sm *StateMachine) CanTransition(from, to TransferStatus) bool {
	validNextStates, ok := sm.validTransitions[from]
	if !ok {
		return false
	}
	for _, state := range validNextStates {
		if state == to {
			return true
		}
	}
	return false
}
