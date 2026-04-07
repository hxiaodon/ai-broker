package strategies

import "time"

type DelayedStrategy struct{}

func (s *DelayedStrategy) Name() string {
	return "delayed"
}

func (s *DelayedStrategy) ShouldRejectAuth(token string) bool {
	return false
}

func (s *DelayedStrategy) ShouldDisconnect() bool {
	return false
}

func (s *DelayedStrategy) GetTickDelay() time.Duration {
	// Delay 6 seconds to trigger stale_since_ms >= 5000
	return 6 * time.Second
}

func (s *DelayedStrategy) ModifyQuote(quote map[string]interface{}) map[string]interface{} {
	// Set stale_since_ms to trigger warning
	quote["stale_since_ms"] = int64(6000)
	return quote
}
