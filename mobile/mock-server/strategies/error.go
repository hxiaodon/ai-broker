package strategies

import "time"

type ErrorStrategy struct{}

func (s *ErrorStrategy) Name() string {
	return "error"
}

func (s *ErrorStrategy) ShouldRejectAuth(token string) bool {
	// Always reject auth to test error handling
	return true
}

func (s *ErrorStrategy) ShouldDisconnect() bool {
	return false
}

func (s *ErrorStrategy) GetTickDelay() time.Duration {
	return 0
}

func (s *ErrorStrategy) ModifyQuote(quote map[string]interface{}) map[string]interface{} {
	return quote
}
