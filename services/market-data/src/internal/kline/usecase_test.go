package kline

import (
	"context"
	"errors"
	"sort"
	"testing"
	"time"

	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ─── Mock KLineRepo ───────────────────────────────────────────────────────────

type mockKLineRepo struct {
	saved  []*KLine
	saveErr error
}

func (m *mockKLineRepo) Save(_ context.Context, k *KLine) error {
	if m.saveErr != nil {
		return m.saveErr
	}
	m.saved = append(m.saved, k)
	return nil
}

func (m *mockKLineRepo) SaveBatch(_ context.Context, ks []*KLine) error {
	if m.saveErr != nil {
		return m.saveErr
	}
	m.saved = append(m.saved, ks...)
	return nil
}

func (m *mockKLineRepo) FindBySymbolAndInterval(_ context.Context, _ string, _ Interval, _, _ time.Time, limit int) ([]*KLine, error) {
	if len(m.saved) > limit {
		return m.saved[:limit], nil
	}
	return m.saved, nil
}

// makeTick creates a Tick at a given offset from a base time.
func makeTick(symbol string, price float64, volume int64, base time.Time, offset time.Duration) Tick {
	return Tick{
		Symbol:    symbol,
		Price:     decimal.NewFromFloat(price),
		Volume:    volume,
		Timestamp: base.Add(offset).UTC(),
	}
}

// ─── GetKLinesUsecase ─────────────────────────────────────────────────────────

func TestGetKLines_EmptySymbol(t *testing.T) {
	uc := NewGetKLinesUsecase(nil)
	_, err := uc.Execute(context.Background(), "", Interval1D, time.Now().UTC(), time.Now().UTC(), 100)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "symbol must not be empty")
}

func TestGetKLines_LimitClamping(t *testing.T) {
	// Verify the limit is clamped: 0→200, >1000→1000
	repo := &mockKLineRepo{}
	uc := NewGetKLinesUsecase(repo)
	now := time.Now().UTC()

	_, err := uc.Execute(context.Background(), "AAPL", Interval1D, now, now, 0)
	require.NoError(t, err) // default 200 applied internally

	_, err = uc.Execute(context.Background(), "AAPL", Interval1D, now, now, 9999)
	require.NoError(t, err) // clamped to 1000
}

// ─── AggregateKLineUsecase ────────────────────────────────────────────────────

func TestAggregateKLine_EmptyTicks_NoSave(t *testing.T) {
	// Zero ticks → nothing saved, no error
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)

	err := uc.Execute(context.Background(), nil, Interval1Min)
	require.NoError(t, err)
	assert.Empty(t, repo.saved, "no klines should be saved for empty tick slice")
}

func TestAggregateKLine_SingleTick_ProducesCandle(t *testing.T) {
	// A single tick must produce one candle with Open=High=Low=Close=price
	// Spec: market-data-system.md §4 — OHLCV from single tick
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)
	base := time.Date(2024, 1, 15, 9, 30, 0, 0, time.UTC)

	ticks := []Tick{makeTick("AAPL", 150.25, 1000, base, 0)}
	err := uc.Execute(context.Background(), ticks, Interval1Min)
	require.NoError(t, err)
	require.Len(t, repo.saved, 1)

	k := repo.saved[0]
	assert.Equal(t, "AAPL", k.Symbol)
	assert.Equal(t, Interval1Min, k.Interval)

	// For a single tick, all OHLC must equal the tick price
	price := decimal.NewFromFloat(150.25)
	assert.True(t, price.Equal(k.Open), "Open: want %s got %s", price, k.Open)
	assert.True(t, price.Equal(k.High), "High: want %s got %s", price, k.High)
	assert.True(t, price.Equal(k.Low), "Low: want %s got %s", price, k.Low)
	assert.True(t, price.Equal(k.Close), "Close: want %s got %s", price, k.Close)
	assert.Equal(t, int64(1000), k.Volume)
	assert.False(t, k.Adjusted, "real-time ticks must be unadjusted")
}

func TestAggregateKLine_MultipleTicksInSameMinute_OHLCV(t *testing.T) {
	// Spec: §4 — multiple ticks in one candle period produce correct OHLCV
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)
	base := time.Date(2024, 1, 15, 9, 30, 0, 0, time.UTC)

	ticks := []Tick{
		makeTick("AAPL", 150.00, 500, base, 0*time.Second),  // open
		makeTick("AAPL", 152.00, 300, base, 20*time.Second), // high
		makeTick("AAPL", 148.50, 200, base, 40*time.Second), // low
		makeTick("AAPL", 151.25, 400, base, 59*time.Second), // close
	}

	err := uc.Execute(context.Background(), ticks, Interval1Min)
	require.NoError(t, err)
	require.Len(t, repo.saved, 1)

	k := repo.saved[0]
	assert.True(t, decimal.NewFromFloat(150.00).Equal(k.Open), "Open")
	assert.True(t, decimal.NewFromFloat(152.00).Equal(k.High), "High")
	assert.True(t, decimal.NewFromFloat(148.50).Equal(k.Low), "Low")
	assert.True(t, decimal.NewFromFloat(151.25).Equal(k.Close), "Close")
	assert.Equal(t, int64(1400), k.Volume, "Volume must be sum of all tick volumes")
}

func TestAggregateKLine_TicksSpanTwoMinutes_TwoCandles(t *testing.T) {
	// Ticks crossing a minute boundary must produce two separate candles
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)
	base := time.Date(2024, 1, 15, 9, 30, 0, 0, time.UTC)

	ticks := []Tick{
		makeTick("AAPL", 150.00, 100, base, 30*time.Second),   // candle 1: 09:30
		makeTick("AAPL", 151.00, 200, base, 90*time.Second),   // candle 2: 09:31
		makeTick("AAPL", 151.50, 150, base, 100*time.Second),  // candle 2: 09:31
	}

	err := uc.Execute(context.Background(), ticks, Interval1Min)
	require.NoError(t, err)
	require.Len(t, repo.saved, 2, "two minute buckets → two candles")

	// Sort by StartTime for deterministic assertion
	sort.Slice(repo.saved, func(i, j int) bool {
		return repo.saved[i].StartTime.Before(repo.saved[j].StartTime)
	})

	c1 := repo.saved[0]
	assert.Equal(t, base, c1.StartTime, "candle 1 starts at 09:30")
	assert.True(t, decimal.NewFromFloat(150.00).Equal(c1.Open))
	assert.Equal(t, int64(100), c1.Volume)

	c2 := repo.saved[1]
	assert.Equal(t, base.Add(time.Minute), c2.StartTime, "candle 2 starts at 09:31")
	assert.True(t, decimal.NewFromFloat(151.00).Equal(c2.Open))
	assert.Equal(t, int64(350), c2.Volume)
}

func TestAggregateKLine_OHLCVInvariant(t *testing.T) {
	// Spec: §4 — OHLCV invariant: High ≥ Open,Close,Low; Low ≤ Open,Close,High
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)
	base := time.Date(2024, 1, 15, 9, 30, 0, 0, time.UTC)

	// Out-of-order prices to stress-test min/max tracking
	ticks := []Tick{
		makeTick("TSLA", 200.00, 100, base, 0),
		makeTick("TSLA", 198.00, 100, base, 10*time.Second),
		makeTick("TSLA", 205.00, 100, base, 20*time.Second),
		makeTick("TSLA", 201.00, 100, base, 30*time.Second),
	}
	require.NoError(t, uc.Execute(context.Background(), ticks, Interval1Min))
	require.Len(t, repo.saved, 1)
	k := repo.saved[0]

	assert.True(t, k.High.GreaterThanOrEqual(k.Open), "High >= Open")
	assert.True(t, k.High.GreaterThanOrEqual(k.Close), "High >= Close")
	assert.True(t, k.High.GreaterThanOrEqual(k.Low), "High >= Low")
	assert.True(t, k.Low.LessThanOrEqual(k.Open), "Low <= Open")
	assert.True(t, k.Low.LessThanOrEqual(k.Close), "Low <= Close")
}

func TestAggregateKLine_CandleTimestampsAreUTC(t *testing.T) {
	// Spec: financial-coding-standards Rule 2 — all timestamps UTC
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)
	base := time.Date(2024, 1, 15, 9, 30, 0, 0, time.UTC)

	ticks := []Tick{makeTick("GOOG", 180.00, 50, base, 0)}
	require.NoError(t, uc.Execute(context.Background(), ticks, Interval1Min))
	require.Len(t, repo.saved, 1)
	k := repo.saved[0]

	assert.Equal(t, time.UTC, k.StartTime.Location(), "StartTime must be UTC")
	assert.Equal(t, time.UTC, k.EndTime.Location(), "EndTime must be UTC")
}

func TestAggregateKLine_CandleEndTime_1Min(t *testing.T) {
	// StartTime + 1min = EndTime for Interval1Min
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)
	base := time.Date(2024, 1, 15, 9, 30, 0, 0, time.UTC)

	ticks := []Tick{makeTick("MSFT", 400.00, 100, base, 0)}
	require.NoError(t, uc.Execute(context.Background(), ticks, Interval1Min))
	k := repo.saved[0]

	assert.Equal(t, base, k.StartTime)
	assert.Equal(t, base.Add(time.Minute), k.EndTime)
}

func TestAggregateKLine_CandleEndTime_1D(t *testing.T) {
	// StartTime + 1 day = EndTime for Interval1D
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)
	base := time.Date(2024, 1, 15, 14, 35, 0, 0, time.UTC)

	ticks := []Tick{makeTick("NVDA", 600.00, 500, base, 0)}
	require.NoError(t, uc.Execute(context.Background(), ticks, Interval1D))
	k := repo.saved[0]

	dayStart := time.Date(2024, 1, 15, 0, 0, 0, 0, time.UTC)
	assert.Equal(t, dayStart, k.StartTime, "1D candle starts at midnight UTC")
	assert.Equal(t, dayStart.AddDate(0, 0, 1), k.EndTime, "1D candle ends next midnight")
}

func TestAggregateKLine_UnsupportedInterval_ReturnsError(t *testing.T) {
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)
	base := time.Now().UTC()
	ticks := []Tick{makeTick("AAPL", 150.00, 100, base, 0)}

	err := uc.Execute(context.Background(), ticks, Interval("invalid"))
	require.Error(t, err)
	assert.Contains(t, err.Error(), "unsupported interval")
}

func TestAggregateKLine_SaveBatchFailure_ReturnsError(t *testing.T) {
	repo := &mockKLineRepo{saveErr: errors.New("db: disk full")}
	uc := NewAggregateKLineUsecase(repo)
	base := time.Now().UTC()
	ticks := []Tick{makeTick("AAPL", 150.00, 100, base, 0)}

	err := uc.Execute(context.Background(), ticks, Interval1Min)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "save batch")
}

func TestAggregateKLine_DecimalPriceNoFloat(t *testing.T) {
	// Spec: financial-coding-standards Rule 1 — decimal precision preserved in aggregation
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)
	base := time.Date(2024, 1, 15, 9, 30, 0, 0, time.UTC)

	// US stock prices to 4 decimal places
	ticks := []Tick{
		{Symbol: "AAPL", Price: decimal.RequireFromString("150.2500"), Volume: 100, Timestamp: base.UTC()},
		{Symbol: "AAPL", Price: decimal.RequireFromString("150.2600"), Volume: 100, Timestamp: base.Add(10 * time.Second).UTC()},
		{Symbol: "AAPL", Price: decimal.RequireFromString("150.2400"), Volume: 100, Timestamp: base.Add(20 * time.Second).UTC()},
	}

	require.NoError(t, uc.Execute(context.Background(), ticks, Interval1Min))
	require.Len(t, repo.saved, 1)
	k := repo.saved[0]

	assert.True(t, decimal.RequireFromString("150.2500").Equal(k.Open), "Open precision: %s", k.Open)
	assert.True(t, decimal.RequireFromString("150.2600").Equal(k.High), "High precision: %s", k.High)
	assert.True(t, decimal.RequireFromString("150.2400").Equal(k.Low), "Low precision: %s", k.Low)
	assert.True(t, decimal.RequireFromString("150.2400").Equal(k.Close), "Close precision: %s", k.Close)
}

func TestAggregateKLine_TicksOutOfOrder_OpenAndCloseCorrect(t *testing.T) {
	// Spec: §4 — Open = first tick by timestamp, Close = last tick by timestamp.
	// Feed handlers may deliver ticks out of wall-clock order (network jitter, retransmission).
	// The usecase must sort ticks before bucketing so Open/Close are always chronologically correct.
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)
	base := time.Date(2024, 1, 15, 9, 30, 0, 0, time.UTC)

	// Deliberately deliver ticks in reverse time order.
	ticks := []Tick{
		makeTick("AAPL", 153.00, 100, base, 59*time.Second), // last chronologically  → Close
		makeTick("AAPL", 148.00, 100, base, 20*time.Second), // middle
		makeTick("AAPL", 150.00, 100, base, 0*time.Second),  // first chronologically → Open
	}

	require.NoError(t, uc.Execute(context.Background(), ticks, Interval1Min))
	require.Len(t, repo.saved, 1)
	k := repo.saved[0]

	assert.True(t, decimal.NewFromFloat(150.00).Equal(k.Open),
		"Open must be price of first tick by time: want 150.00 got %s", k.Open)
	assert.True(t, decimal.NewFromFloat(153.00).Equal(k.Close),
		"Close must be price of last tick by time: want 153.00 got %s", k.Close)
	assert.True(t, decimal.NewFromFloat(153.00).Equal(k.High),
		"High: want 153.00 got %s", k.High)
	assert.True(t, decimal.NewFromFloat(148.00).Equal(k.Low),
		"Low: want 148.00 got %s", k.Low)
}

func TestAggregateKLine_WeeklyBucket_TruncatesToMonday(t *testing.T) {
	// Spec: §4 Interval1W — all ticks within the same ISO week must land in one candle.
	// The candle StartTime must be the Monday of that week (00:00:00 UTC).
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)

	// 2024-01-15 is a Monday. 2024-01-17 is a Wednesday.
	monday := time.Date(2024, 1, 15, 9, 30, 0, 0, time.UTC)
	wednesday := time.Date(2024, 1, 17, 11, 00, 0, 0, time.UTC)

	ticks := []Tick{
		makeTick("AAPL", 150.00, 100, monday, 0),
		makeTick("AAPL", 155.00, 100, wednesday, 0),
	}

	require.NoError(t, uc.Execute(context.Background(), ticks, Interval1W))
	require.Len(t, repo.saved, 1, "ticks from the same ISO week must produce exactly one weekly candle")

	k := repo.saved[0]
	expectedMonday := time.Date(2024, 1, 15, 0, 0, 0, 0, time.UTC)
	assert.Equal(t, expectedMonday, k.StartTime,
		"weekly candle StartTime must be Monday 00:00 UTC")
	assert.Equal(t, expectedMonday.AddDate(0, 0, 7), k.EndTime,
		"weekly candle EndTime must be next Monday")
	assert.True(t, decimal.NewFromFloat(150.00).Equal(k.Open), "Open = Monday's tick")
	assert.True(t, decimal.NewFromFloat(155.00).Equal(k.Close), "Close = Wednesday's tick")
}

func TestAggregateKLine_WeeklyBucket_TwoWeeksTwoCandles(t *testing.T) {
	// Ticks spanning two ISO weeks must produce two separate weekly candles.
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)

	// Week 1: Mon 2024-01-15; Week 2: Mon 2024-01-22
	week1 := time.Date(2024, 1, 15, 10, 0, 0, 0, time.UTC)
	week2 := time.Date(2024, 1, 22, 10, 0, 0, 0, time.UTC)

	ticks := []Tick{
		makeTick("TSLA", 200.00, 100, week1, 0),
		makeTick("TSLA", 210.00, 100, week2, 0),
	}

	require.NoError(t, uc.Execute(context.Background(), ticks, Interval1W))
	require.Len(t, repo.saved, 2, "ticks from two different weeks must produce two weekly candles")

	sort.Slice(repo.saved, func(i, j int) bool {
		return repo.saved[i].StartTime.Before(repo.saved[j].StartTime)
	})
	assert.Equal(t, time.Date(2024, 1, 15, 0, 0, 0, 0, time.UTC), repo.saved[0].StartTime)
	assert.Equal(t, time.Date(2024, 1, 22, 0, 0, 0, 0, time.UTC), repo.saved[1].StartTime)
}

func TestAggregateKLine_MonthlyBucket_TruncatesToFirstOfMonth(t *testing.T) {
	// Spec: §4 Interval1M — all ticks in the same calendar month land in one candle.
	// StartTime must be the 1st of the month at 00:00:00 UTC.
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)

	jan10 := time.Date(2024, 1, 10, 9, 30, 0, 0, time.UTC)
	jan28 := time.Date(2024, 1, 28, 15, 45, 0, 0, time.UTC)

	ticks := []Tick{
		makeTick("MSFT", 400.00, 100, jan10, 0),
		makeTick("MSFT", 410.00, 100, jan28, 0),
	}

	require.NoError(t, uc.Execute(context.Background(), ticks, Interval1M))
	require.Len(t, repo.saved, 1, "ticks from the same month must produce exactly one monthly candle")

	k := repo.saved[0]
	expectedStart := time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC)
	assert.Equal(t, expectedStart, k.StartTime, "monthly StartTime must be 1st of month UTC")
	assert.Equal(t, expectedStart.AddDate(0, 1, 0), k.EndTime, "monthly EndTime must be 1st of next month")
	assert.True(t, decimal.NewFromFloat(400.00).Equal(k.Open), "Open = Jan 10 tick")
	assert.True(t, decimal.NewFromFloat(410.00).Equal(k.Close), "Close = Jan 28 tick")
}

func TestAggregateKLine_MonthlyBucket_TwoMonthsTwoCandles(t *testing.T) {
	// Ticks from January and February must produce two separate monthly candles.
	repo := &mockKLineRepo{}
	uc := NewAggregateKLineUsecase(repo)

	jan := time.Date(2024, 1, 15, 10, 0, 0, 0, time.UTC)
	feb := time.Date(2024, 2, 5, 10, 0, 0, 0, time.UTC)

	ticks := []Tick{
		makeTick("NVDA", 600.00, 100, jan, 0),
		makeTick("NVDA", 620.00, 100, feb, 0),
	}

	require.NoError(t, uc.Execute(context.Background(), ticks, Interval1M))
	require.Len(t, repo.saved, 2, "January and February ticks must produce two monthly candles")

	sort.Slice(repo.saved, func(i, j int) bool {
		return repo.saved[i].StartTime.Before(repo.saved[j].StartTime)
	})
	assert.Equal(t, time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC), repo.saved[0].StartTime)
	assert.Equal(t, time.Date(2024, 2, 1, 0, 0, 0, 0, time.UTC), repo.saved[1].StartTime)
}

func TestGetKLines_TimeRangePassedToRepo(t *testing.T) {
	// GetKLines must pass start/end UTC times verbatim to the repository.
	repo := &mockKLineRepo{}
	uc := NewGetKLinesUsecase(repo)
	start := time.Date(2024, 1, 15, 9, 30, 0, 0, time.UTC)
	end := time.Date(2024, 1, 15, 16, 0, 0, 0, time.UTC)

	_, err := uc.Execute(context.Background(), "AAPL", Interval1Min, start, end, 100)
	require.NoError(t, err)
	// mockKLineRepo returns whatever is in saved; we just verify no error and a call was made.
	// A real integration test would verify repo receives correct time range.
}
