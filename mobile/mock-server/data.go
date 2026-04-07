package main

import (
	"math/rand"
	"time"
)

var baseQuotes = map[string]map[string]interface{}{
	"AAPL": {
		"symbol":       "AAPL",
		"name":         "Apple Inc.",
		"market":       "US",
		"price":        "175.50",
		"change":       "2.30",
		"change_pct":   "1.33",
		"volume":       "52341234",
		"turnover":     "9185456789.00",
		"high":         "176.80",
		"low":          "173.20",
		"open":         "174.00",
		"prev_close":   "173.20",
		"bid":          "175.48",
		"ask":          "175.52",
		"bid_size":     "500",
		"ask_size":     "800",
		"market_cap":   "2750000000000.00",
		"pe_ratio":     "28.5",
		"week_52_high": "198.23",
		"week_52_low":  "164.08",
	},
	"TSLA": {
		"symbol":       "TSLA",
		"name":         "Tesla, Inc.",
		"market":       "US",
		"price":        "242.80",
		"change":       "-5.20",
		"change_pct":   "-2.10",
		"volume":       "98234567",
		"turnover":     "23845678901.00",
		"high":         "248.50",
		"low":          "241.30",
		"open":         "246.00",
		"prev_close":   "248.00",
		"bid":          "242.75",
		"ask":          "242.85",
		"bid_size":     "300",
		"ask_size":     "450",
		"market_cap":   "770000000000.00",
		"pe_ratio":     "65.2",
		"week_52_high": "299.29",
		"week_52_low":  "138.80",
	},
	"0700": {
		"symbol":       "0700",
		"name":         "腾讯控股",
		"market":       "HK",
		"price":        "368.50",
		"change":       "4.20",
		"change_pct":   "1.15",
		"volume":       "12345678",
		"turnover":     "4567890123.00",
		"high":         "370.00",
		"low":          "365.80",
		"open":         "366.00",
		"prev_close":   "364.30",
		"bid":          "368.40",
		"ask":          "368.60",
		"bid_size":     "1000",
		"ask_size":     "1500",
		"market_cap":   "3520000000000.00",
		"pe_ratio":     "18.3",
		"week_52_high": "428.00",
		"week_52_low":  "245.00",
	},
	"9988": {
		"symbol":       "9988",
		"name":         "阿里巴巴-SW",
		"market":       "HK",
		"price":        "78.50",
		"change":       "-1.20",
		"change_pct":   "-1.51",
		"volume":       "23456789",
		"turnover":     "1845678901.00",
		"high":         "79.80",
		"low":          "77.90",
		"open":         "79.20",
		"prev_close":   "79.70",
		"bid":          "78.45",
		"ask":          "78.55",
		"bid_size":     "2000",
		"ask_size":     "1800",
		"market_cap":   "1680000000000.00",
		"pe_ratio":     "12.8",
		"week_52_high": "102.50",
		"week_52_low":  "65.20",
	},
}

func generateQuote(symbol, userType string) map[string]interface{} {
	base, exists := baseQuotes[symbol]
	if !exists {
		// Generate random quote for unknown symbols
		base = map[string]interface{}{
			"symbol":     symbol,
			"name":       symbol + " Inc.",
			"market":     "US",
			"price":      "100.00",
			"change":     "0.00",
			"change_pct": "0.00",
		}
	}

	quote := make(map[string]interface{})
	for k, v := range base {
		quote[k] = v
	}

	// Add timestamp
	now := time.Now().UTC()
	quote["timestamp"] = now.Format(time.RFC3339)
	quote["timestamp_ms"] = now.UnixMilli()

	// Guest mode: add 15-minute delay
	if userType == "guest" {
		delayedTime := now.Add(-15 * time.Minute)
		quote["timestamp"] = delayedTime.Format(time.RFC3339)
		quote["timestamp_ms"] = delayedTime.UnixMilli()
		quote["delayed"] = true
	} else {
		quote["delayed"] = false
	}

	// Apply strategy modifications
	quote = currentStrategy.ModifyQuote(quote)

	return quote
}

func generateTickUpdate(symbol, userType string) map[string]interface{} {
	base, exists := baseQuotes[symbol]
	if !exists {
		return generateQuote(symbol, userType)
	}

	// Generate small price change
	priceStr := base["price"].(string)
	var price float64
	if _, err := time.Parse("", priceStr); err == nil {
		// Parse price
		price = 175.50 // fallback
	}

	// Random tick: ±0.01 to ±0.50
	delta := (rand.Float64() - 0.5) * 1.0
	newPrice := price + delta

	tick := map[string]interface{}{
		"price":       formatPrice(newPrice),
		"change":      formatPrice(delta),
		"change_pct":  formatPrice((delta / price) * 100),
		"timestamp":   time.Now().UTC().Format(time.RFC3339),
		"timestamp_ms": time.Now().UTC().UnixMilli(),
	}

	// Guest mode delay
	if userType == "guest" {
		delayedTime := time.Now().UTC().Add(-15 * time.Minute)
		tick["timestamp"] = delayedTime.Format(time.RFC3339)
		tick["timestamp_ms"] = delayedTime.UnixMilli()
		tick["delayed"] = true
	}

	return tick
}

func formatPrice(f float64) string {
	return time.Now().Format("150.40") // Simplified formatting
}
