package compliance

import (
	"context"
	"time"

	"github.com/shopspring/decimal"
)

// CheckType represents the type of compliance check
type CheckType string

const (
	CheckTypeSameName   CheckType = "SAME_NAME"
	CheckTypeAML        CheckType = "AML"
	CheckTypeTravelRule CheckType = "TRAVEL_RULE"
	CheckTypeKYCLimit   CheckType = "KYC_LIMIT"
)

// CheckResult represents the result of a compliance check
type CheckResult struct {
	CheckType CheckType
	Passed    bool
	Reason    string
	Details   map[string]interface{}
	CheckedAt time.Time
}

// KYCTier represents the KYC verification tier
type KYCTier int

const (
	KYCTierUnverified KYCTier = 0
	KYCTier1          KYCTier = 1 // Basic: $5K single, $10K daily, $50K monthly
	KYCTier2          KYCTier = 2 // Enhanced: $50K single, $100K daily, $500K monthly
	KYCTier3          KYCTier = 3 // Premium: $500K single, $1M daily, $10M monthly
)

// KYCLimits represents the transfer limits for a KYC tier
type KYCLimits struct {
	Tier          KYCTier
	SingleLimit   decimal.Decimal
	DailyLimit    decimal.Decimal
	MonthlyLimit  decimal.Decimal
}

// GetKYCLimits returns the limits for a given tier
func GetKYCLimits(tier KYCTier) KYCLimits {
	limits := map[KYCTier]KYCLimits{
		KYCTier1: {
			Tier:         KYCTier1,
			SingleLimit:  decimal.NewFromInt(5000),
			DailyLimit:   decimal.NewFromInt(10000),
			MonthlyLimit: decimal.NewFromInt(50000),
		},
		KYCTier2: {
			Tier:         KYCTier2,
			SingleLimit:  decimal.NewFromInt(50000),
			DailyLimit:   decimal.NewFromInt(100000),
			MonthlyLimit: decimal.NewFromInt(500000),
		},
		KYCTier3: {
			Tier:         KYCTier3,
			SingleLimit:  decimal.NewFromInt(500000),
			DailyLimit:   decimal.NewFromInt(1000000),
			MonthlyLimit: decimal.NewFromInt(10000000),
		},
	}
	return limits[tier]
}

// Engine defines the compliance engine interface
type Engine interface {
	// CheckSameName verifies bank account name matches KYC name
	CheckSameName(ctx context.Context, accountID, bankAccountID string) (*CheckResult, error)

	// CheckAML screens against OFAC/UN/EU sanctions lists
	CheckAML(ctx context.Context, accountID string, amount decimal.Decimal) (*CheckResult, error)

	// CheckTravelRule verifies Travel Rule compliance for transfers >$3000
	CheckTravelRule(ctx context.Context, accountID string, amount decimal.Decimal) (*CheckResult, error)

	// CheckKYCLimits verifies transfer amount against KYC tier limits
	CheckKYCLimits(ctx context.Context, accountID string, amount decimal.Decimal) (*CheckResult, error)

	// RunAllChecks runs all compliance checks
	RunAllChecks(ctx context.Context, accountID, bankAccountID string, amount decimal.Decimal) ([]*CheckResult, error)
}

// AMLScreener defines the AML screening interface
type AMLScreener interface {
	// Screen checks if an account is on sanctions lists
	Screen(ctx context.Context, accountID string) (bool, string, error)

	// UpdateLists updates the local sanctions list cache
	UpdateLists(ctx context.Context) error
}

// SanctionsList represents a sanctions list entry
type SanctionsList struct {
	ListName    string    // OFAC, UN, EU
	EntityName  string
	EntityType  string    // INDIVIDUAL, ENTITY
	Country     string
	AddedDate   time.Time
	Description string
}
