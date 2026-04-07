package strategies

import "time"

type NormalStrategy struct{}

func (s *NormalStrategy) Name() string {
	return "normal"
}

func (s *NormalStrategy) ShouldRejectAuth(token string) bool {
	return false
}

func (s *NormalStrategy) ShouldDisconnect() bool {
	return false
}

func (s *NormalStrategy) GetTickDelay() time.Duration {
	return 0
}

func (s *NormalStrategy) ModifyQuote(quote map[string]interface{}) map[string]interface{} {
	// No modifications
	return quote
}
