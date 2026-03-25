package app

import (
	"context"
	"time"

	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// MarketScheduler evaluates exchange trading phases every minute and updates
// the market_status table when the phase changes.
//
// Phase transitions (all times UTC):
//
//	US (NYSE/NASDAQ, America/New_York = UTC-5 or UTC-4 DST):
//	  PRE_MARKET   04:00–09:30 ET
//	  REGULAR      09:30–16:00 ET
//	  AFTER_HOURS  16:00–20:00 ET
//	  CLOSED       20:00–04:00 ET (next day)
//
//	HK (HKEX, Asia/Hong_Kong = UTC+8 fixed):
//	  PRE_MARKET   09:00–09:30 HKT
//	  REGULAR      09:30–12:00 HKT
//	  LUNCH_BREAK  12:00–13:00 HKT
//	  REGULAR      13:00–16:00 HKT
//	  CLOSED       all other times
//
// Note: US daylight-saving transitions are handled automatically by time.LoadLocation.
// Weekend detection: if time.Weekday() is Saturday or Sunday → CLOSED for both markets.
type MarketScheduler struct {
	statusRepo domain.MarketStatusRepo
	logger     *zap.Logger

	// cached last-seen phases to avoid redundant DB writes
	lastPhaseUS domain.TradingPhase
	lastPhaseHK domain.TradingPhase

	locET  *time.Location
	locHKT *time.Location
}

// NewMarketScheduler creates a new MarketScheduler.
// Returns an error if the required time zones cannot be loaded.
func NewMarketScheduler(statusRepo domain.MarketStatusRepo, logger *zap.Logger) (*MarketScheduler, error) {
	locET, err := time.LoadLocation("America/New_York")
	if err != nil {
		return nil, err
	}
	locHKT, err := time.LoadLocation("Asia/Hong_Kong")
	if err != nil {
		return nil, err
	}
	return &MarketScheduler{
		statusRepo: statusRepo,
		logger:     logger,
		locET:      locET,
		locHKT:     locHKT,
	}, nil
}

// Run blocks until ctx is cancelled, evaluating and persisting market phases
// once per minute (aligned to clock boundaries like KLineScheduler).
func (s *MarketScheduler) Run(ctx context.Context) error {
	s.logger.Info("market scheduler started")

	// Evaluate immediately on startup so the DB reflects the current phase.
	s.evaluate(ctx, time.Now().UTC())

	ticker := time.NewTicker(time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			s.logger.Info("market scheduler stopped")
			return ctx.Err()
		case t := <-ticker.C:
			s.evaluate(ctx, t.UTC())
		}
	}
}

func (s *MarketScheduler) evaluate(ctx context.Context, now time.Time) {
	usPhase := s.usPhase(now)
	hkPhase := s.hkPhase(now)

	if usPhase != s.lastPhaseUS {
		if err := s.statusRepo.SetStatus(ctx, &domain.MarketStatus{
			Market:    domain.MarketUS,
			Phase:     usPhase,
			UpdatedAt: now,
		}); err != nil {
			s.logger.Error("market scheduler set US status", zap.Error(err))
		} else {
			s.logger.Info("US market phase changed",
				zap.String("from", string(s.lastPhaseUS)),
				zap.String("to", string(usPhase)))
			s.lastPhaseUS = usPhase
		}
	}

	if hkPhase != s.lastPhaseHK {
		if err := s.statusRepo.SetStatus(ctx, &domain.MarketStatus{
			Market:    domain.MarketHK,
			Phase:     hkPhase,
			UpdatedAt: now,
		}); err != nil {
			s.logger.Error("market scheduler set HK status", zap.Error(err))
		} else {
			s.logger.Info("HK market phase changed",
				zap.String("from", string(s.lastPhaseHK)),
				zap.String("to", string(hkPhase)))
			s.lastPhaseHK = hkPhase
		}
	}
}

// usPhase returns the current NYSE/NASDAQ trading phase for the given UTC time.
func (s *MarketScheduler) usPhase(utc time.Time) domain.TradingPhase {
	et := utc.In(s.locET)

	// Weekends are always CLOSED.
	if et.Weekday() == time.Saturday || et.Weekday() == time.Sunday {
		return domain.PhaseClosed
	}

	h, m := et.Hour(), et.Minute()
	totalMin := h*60 + m

	switch {
	case totalMin >= 4*60 && totalMin < 9*60+30:
		return domain.PhasePreMarket
	case totalMin >= 9*60+30 && totalMin < 16*60:
		return domain.PhaseRegular
	case totalMin >= 16*60 && totalMin < 20*60:
		return domain.PhaseAfterHours
	default:
		return domain.PhaseClosed
	}
}

// hkPhase returns the current HKEX trading phase for the given UTC time.
func (s *MarketScheduler) hkPhase(utc time.Time) domain.TradingPhase {
	hkt := utc.In(s.locHKT)

	// Weekends are always CLOSED.
	if hkt.Weekday() == time.Saturday || hkt.Weekday() == time.Sunday {
		return domain.PhaseClosed
	}

	h, m := hkt.Hour(), hkt.Minute()
	totalMin := h*60 + m

	switch {
	case totalMin >= 9*60 && totalMin < 9*60+30:
		return domain.PhasePreMarket
	case totalMin >= 9*60+30 && totalMin < 12*60:
		return domain.PhaseRegular
	case totalMin >= 12*60 && totalMin < 13*60:
		return domain.PhaseLunchBreak
	case totalMin >= 13*60 && totalMin < 16*60:
		return domain.PhaseRegular
	default:
		return domain.PhaseClosed
	}
}
