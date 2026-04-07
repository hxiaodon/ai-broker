package strategies

import "time"

// Strategy defines the behavior of the mock server
type Strategy interface {
	// Name returns the strategy name
	Name() string

	// ShouldRejectAuth returns true if auth should fail
	ShouldRejectAuth(token string) bool

	// ShouldDisconnect returns true if connection should be dropped
	ShouldDisconnect() bool

	// GetTickDelay returns artificial delay for tick updates
	GetTickDelay() time.Duration

	// ModifyQuote allows strategy to modify quote data
	ModifyQuote(quote map[string]interface{}) map[string]interface{}
}
