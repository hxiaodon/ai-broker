package strategies

import "time"

type GuestStrategy struct{}

func (s *GuestStrategy) Name() string {
	return "guest"
}

func (s *GuestStrategy) ShouldRejectAuth(token string) bool {
	return false
}

func (s *GuestStrategy) ShouldDisconnect() bool {
	return false
}

func (s *GuestStrategy) GetTickDelay() time.Duration {
	return 0
}

func (s *GuestStrategy) ModifyQuote(quote map[string]interface{}) map[string]interface{} {
	// Force delayed flag for guest mode testing
	quote["delayed"] = true

	// Set timestamp to 15 minutes ago
	delayedTime := time.Now().UTC().Add(-15 * time.Minute)
	quote["timestamp"] = delayedTime.Format(time.RFC3339)
	quote["timestamp_ms"] = delayedTime.UnixMilli()

	return quote
}
