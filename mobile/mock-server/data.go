package main

import (
	"fmt"
	"math/rand"
	"strconv"
	"time"
)

var baseQuotes = map[string]map[string]interface{}{
	"AAPL": {
		"symbol":        "AAPL",
		"name":          "Apple Inc.",
		"name_zh":       "苹果公司",
		"market":        "US",
		"market_status": "OPEN",
		"price":         "175.50",
		"change":        "2.30",
		"change_pct":    "1.33",
		"volume":        52341234,
		"turnover":      "9185456789.00",
		"high":          "176.80",
		"low":           "173.20",
		"open":          "174.00",
		"prev_close":    "173.20",
		"bid":           "175.48",
		"ask":           "175.52",
		"bid_size":      "500",
		"ask_size":      "800",
		"market_cap":    "2750000000000.00",
		"pe_ratio":      "28.5",
		"week_52_high":  "198.23",
		"week_52_low":   "164.08",
	},
	"TSLA": {
		"symbol":        "TSLA",
		"name":          "Tesla, Inc.",
		"name_zh":       "特斯拉",
		"market":        "US",
		"market_status": "OPEN",
		"price":         "242.80",
		"change":        "-5.20",
		"change_pct":    "-2.10",
		"volume":        98234567,
		"turnover":      "23845678901.00",
		"high":          "248.50",
		"low":           "241.30",
		"open":          "246.00",
		"prev_close":    "248.00",
		"bid":           "242.75",
		"ask":           "242.85",
		"bid_size":      "300",
		"ask_size":      "450",
		"market_cap":    "770000000000.00",
		"pe_ratio":      "65.2",
		"week_52_high":  "299.29",
		"week_52_low":   "138.80",
	},
	"0700": {
		"symbol":        "0700",
		"name":          "腾讯控股",
		"name_zh":       "腾讯控股",
		"market":        "HK",
		"market_status": "OPEN",
		"price":         "368.50",
		"change":        "4.20",
		"change_pct":    "1.15",
		"volume":        12345678,
		"turnover":      "4567890123.00",
		"high":          "370.00",
		"low":           "365.80",
		"open":          "366.00",
		"prev_close":    "364.30",
		"bid":           "368.40",
		"ask":           "368.60",
		"bid_size":      "1000",
		"ask_size":      "1500",
		"market_cap":    "3520000000000.00",
		"pe_ratio":      "18.3",
		"week_52_high":  "428.00",
		"week_52_low":   "245.00",
	},
	"9988": {
		"symbol":        "9988",
		"name":          "阿里巴巴-SW",
		"name_zh":       "阿里巴巴-SW",
		"market":        "HK",
		"market_status": "OPEN",
		"price":         "78.50",
		"change":        "-1.20",
		"change_pct":    "-1.51",
		"volume":        23456789,
		"turnover":      "1845678901.00",
		"high":          "79.80",
		"low":           "77.90",
		"open":          "79.20",
		"prev_close":    "79.70",
		"bid":           "78.45",
		"ask":           "78.55",
		"bid_size":      "2000",
		"ask_size":      "1800",
		"market_cap":    "1680000000000.00",
		"pe_ratio":      "12.8",
		"week_52_high":  "102.50",
		"week_52_low":   "65.20",
	},
	// ETF Index Proxies (大盘指数代理)
	"SPY": {
		"symbol":        "SPY",
		"name":          "SPDR S&P 500 ETF",
		"name_zh":       "追踪 S&P 500 指数基金",
		"market":        "US",
		"market_status": "OPEN",
		"price":         "521.44",
		"change":        "4.22",
		"change_pct":    "0.82",
		"volume":        89234567,
		"turnover":      "46567890123.00",
		"high":          "523.50",
		"low":           "519.80",
		"open":          "519.00",
		"prev_close":    "517.22",
		"bid":           "521.42",
		"ask":           "521.46",
		"bid_size":      "1500",
		"ask_size":      "2000",
		"market_cap":    "450000000000.00",
		"pe_ratio":      "22.3",
		"week_52_high":  "545.67",
		"week_52_low":   "412.89",
		"is_etf":        true,
		"tracking_name": "追踪 S&P 500",
	},
	"QQQ": {
		"symbol":        "QQQ",
		"name":          "Invesco QQQ Trust",
		"name_zh":       "追踪 Nasdaq-100 指数基金",
		"market":        "US",
		"market_status": "OPEN",
		"price":         "385.92",
		"change":        "4.82",
		"change_pct":    "1.25",
		"volume":        156234567,
		"turnover":      "60234567890.00",
		"high":          "388.30",
		"low":           "383.45",
		"open":          "382.10",
		"prev_close":    "381.10",
		"bid":           "385.90",
		"ask":           "385.94",
		"bid_size":      "2000",
		"ask_size":      "2500",
		"market_cap":    "380000000000.00",
		"pe_ratio":      "38.5",
		"week_52_high":  "442.23",
		"week_52_low":   "267.56",
		"is_etf":        true,
		"tracking_name": "追踪 Nasdaq-100",
	},
	"DIA": {
		"symbol":        "DIA",
		"name":          "SPDR Dow Jones ETF",
		"name_zh":       "追踪 DJIA 指数基金",
		"market":        "US",
		"market_status": "OPEN",
		"price":         "38192.80",
		"change":        "-171.50",
		"change_pct":    "-0.45",
		"volume":        34567890,
		"turnover":      "1321234567890.00",
		"high":          "38450.20",
		"low":           "38120.30",
		"open":          "38320.00",
		"prev_close":    "38364.30",
		"bid":           "38192.70",
		"ask":           "38192.90",
		"bid_size":      "800",
		"ask_size":      "1200",
		"market_cap":    "280000000000.00",
		"pe_ratio":      "20.8",
		"week_52_high":  "41745.89",
		"week_52_low":   "32891.23",
		"is_etf":        true,
		"tracking_name": "追踪 DJIA",
	},
}

func generateQuote(symbol, userType string) map[string]interface{} {
	base, exists := baseQuotes[symbol]
	if !exists {
		// Generate random quote for unknown symbols
		base = map[string]interface{}{
			"symbol":        symbol,
			"name":          symbol + " Inc.",
			"name_zh":       symbol,
			"market":        "US",
			"market_status": "OPEN",
			"price":         "100.00",
			"change":        "0.00",
			"change_pct":    "0.00",
			"volume":        1000000,
			"turnover":      "100000000.00",
			"high":          "101.00",
			"low":           "99.00",
			"open":          "100.00",
			"prev_close":    "100.00",
			"market_cap":    "1000000000.00",
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
	price, err := strconv.ParseFloat(priceStr, 64)
	if err != nil {
		// Fallback if parse fails
		price = 175.50
	}

	// Random tick: ±0.01 to ±0.50
	delta := (rand.Float64() - 0.5) * 1.0
	newPrice := price + delta

	tick := map[string]interface{}{
		"symbol":      symbol, // IMPORTANT: Include symbol field
		"market":      base["market"],
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
	return fmt.Sprintf("%.2f", f)
}
