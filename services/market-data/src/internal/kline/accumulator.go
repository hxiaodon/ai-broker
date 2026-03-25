package kline

import (
	"context"
	"sync"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// TickAccumulator buffers incoming quote ticks per symbol in memory.
// Feed worker calls Add() on every successful quote update; KLineScheduler
// calls FlushAll() at interval boundaries to persist K-line candles.
type TickAccumulator struct {
	mu      sync.Mutex
	buffers map[string][]Tick // symbol → pending ticks
	uc      *AggregateKLineUsecase
}

// NewTickAccumulator creates a new TickAccumulator backed by the given usecase.
func NewTickAccumulator(uc *AggregateKLineUsecase) *TickAccumulator {
	return &TickAccumulator{
		buffers: make(map[string][]Tick),
		uc:      uc,
	}
}

// Add converts a domain.Quote into a Tick and appends it to the symbol's buffer.
// Called by the feed worker after every successful UpdateQuoteUsecase.Execute.
func (a *TickAccumulator) Add(q *domain.Quote) {
	tick := Tick{
		Symbol:    q.Symbol,
		Price:     q.Price,
		Volume:    q.Volume,
		Timestamp: q.LastUpdatedAt,
	}
	a.mu.Lock()
	a.buffers[q.Symbol] = append(a.buffers[q.Symbol], tick)
	a.mu.Unlock()
}

// FlushAll drains all buffered ticks, aggregates them into the given interval,
// and persists the resulting K-line candles. Called by KLineScheduler.
// Each symbol's buffer is swapped out atomically so Add() is unblocked quickly.
func (a *TickAccumulator) FlushAll(ctx context.Context, interval Interval) {
	// Snapshot and reset buffers under the lock; do DB work outside the lock.
	a.mu.Lock()
	snapshot := a.buffers
	a.buffers = make(map[string][]Tick, len(snapshot))
	a.mu.Unlock()

	for _, ticks := range snapshot {
		if len(ticks) == 0 {
			continue
		}
		if err := a.uc.Execute(ctx, ticks, interval); err != nil {
			// Best-effort: log via usecase's own error path; do not block other symbols.
			_ = err
		}
	}
}
