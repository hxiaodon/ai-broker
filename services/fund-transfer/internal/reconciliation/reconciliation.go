package reconciliation

import (
	"context"
	"time"

	"github.com/shopspring/decimal"
)

// ReconciliationType represents the type of reconciliation
type ReconciliationType string

const (
	ReconciliationTypeRealtime ReconciliationType = "REALTIME" // Per-transaction
	ReconciliationTypeEOD      ReconciliationType = "EOD"      // End-of-day batch
	ReconciliationTypeMonthly  ReconciliationType = "MONTHLY"  // Monthly audit
)

// ReconciliationStatus represents the status of a reconciliation
type ReconciliationStatus string

const (
	ReconciliationStatusMatched    ReconciliationStatus = "MATCHED"
	ReconciliationStatusMismatched ReconciliationStatus = "MISMATCHED"
	ReconciliationStatusPending    ReconciliationStatus = "PENDING"
	ReconciliationStatusResolved   ReconciliationStatus = "RESOLVED"
)

// Record represents a reconciliation record
type Record struct {
	RecordID           string
	TransferID         string
	Type               ReconciliationType
	Status             ReconciliationStatus
	InternalAmount     decimal.Decimal
	BankAmount         decimal.Decimal
	Difference         decimal.Decimal
	InternalTimestamp  time.Time
	BankTimestamp      time.Time
	BankReferenceID    string
	MismatchReason     string
	ResolvedBy         string
	ResolvedAt         *time.Time
	CreatedAt          time.Time
}

// Report represents a reconciliation report
type Report struct {
	ReportID         string
	Type             ReconciliationType
	StartDate        time.Time
	EndDate          time.Time
	TotalTransfers   int
	MatchedCount     int
	MismatchedCount  int
	PendingCount     int
	TotalAmount      decimal.Decimal
	MismatchedAmount decimal.Decimal
	Records          []*Record
	GeneratedAt      time.Time
}

// Engine defines the reconciliation engine interface
type Engine interface {
	// ReconcileTransaction performs real-time reconciliation for a single transaction
	ReconcileTransaction(ctx context.Context, transferID string) (*Record, error)

	// RunEODReconciliation runs end-of-day batch reconciliation
	RunEODReconciliation(ctx context.Context, date time.Time) (*Report, error)

	// RunMonthlyReconciliation runs monthly audit reconciliation
	RunMonthlyReconciliation(ctx context.Context, year int, month time.Month) (*Report, error)

	// GetRecord retrieves a reconciliation record
	GetRecord(ctx context.Context, recordID string) (*Record, error)

	// ListMismatches lists all unresolved mismatches
	ListMismatches(ctx context.Context, limit, offset int) ([]*Record, error)

	// ResolveMismatch marks a mismatch as resolved
	ResolveMismatch(ctx context.Context, recordID, resolverID, reason string) error
}

// Repository defines the reconciliation data access interface
type Repository interface {
	// CreateRecord creates a new reconciliation record
	CreateRecord(ctx context.Context, record *Record) error

	// GetRecord retrieves a record by ID
	GetRecord(ctx context.Context, recordID string) (*Record, error)

	// GetRecordByTransfer retrieves a record by transfer ID
	GetRecordByTransfer(ctx context.Context, transferID string) (*Record, error)

	// ListRecords lists records by type and status
	ListRecords(ctx context.Context, recType ReconciliationType, status ReconciliationStatus, limit, offset int) ([]*Record, error)

	// UpdateStatus updates the status of a record
	UpdateStatus(ctx context.Context, recordID string, status ReconciliationStatus, resolverID, reason string) error

	// CreateReport creates a new reconciliation report
	CreateReport(ctx context.Context, report *Report) error

	// GetReport retrieves a report by ID
	GetReport(ctx context.Context, reportID string) (*Report, error)

	// ListReports lists reports by type and date range
	ListReports(ctx context.Context, recType ReconciliationType, startDate, endDate time.Time) ([]*Report, error)
}

// Matcher defines the reconciliation matching logic
type Matcher interface {
	// Match compares internal and bank records
	Match(ctx context.Context, transferID string) (bool, string, error)

	// GetBankRecord retrieves the bank record for a transfer
	GetBankRecord(ctx context.Context, transferID string) (*BankRecord, error)
}

// BankRecord represents a bank transaction record
type BankRecord struct {
	BankReferenceID string
	Amount          decimal.Decimal
	Currency        string
	Timestamp       time.Time
	Status          string
}
