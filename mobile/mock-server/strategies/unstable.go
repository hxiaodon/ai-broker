package strategies

import (
	"math/rand"
	"time"
)

type UnstableStrategy struct {
	tickCount int
}

func (s *UnstableStrategy) Name() string {
	return "unstable"
}

func (s *UnstableStrategy) ShouldRejectAuth(token string) bool {
	return false
}

func (s *UnstableStrategy) ShouldDisconnect() bool {
	s.tickCount++
	// Disconnect every 5-10 ticks (30% chance)
	if s.tickCount > 5 && rand.Float64() < 0.3 {
		s.tickCount = 0
		return true
	}
	return false
}

func (s *UnstableStrategy) GetTickDelay() time.Duration {
	return 0
}

func (s *UnstableStrategy) ModifyQuote(quote map[string]interface{}) map[string]interface{} {
	return quote
}
