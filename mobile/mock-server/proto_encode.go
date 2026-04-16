package main

import (
	"encoding/binary"
	"time"
)

const (
	frameTypeSnapshot = 1
	frameTypeTick     = 2
	frameTypeDelayed  = 3

	marketUS = 1
	marketHK = 2

	marketStatusRegular    = 1
	marketStatusPreMarket  = 2
	marketStatusAfterHours = 3
	marketStatusClosed     = 4
	marketStatusHalted     = 5
)

func pbVarint(v uint64) []byte {
	var buf [10]byte
	n := binary.PutUvarint(buf[:], v)
	return buf[:n]
}

func pbTag(field, wireType int) []byte {
	return pbVarint(uint64(field<<3 | wireType))
}

func pbString(field int, s string) []byte {
	if s == "" {
		return nil
	}
	b := pbTag(field, 2)
	b = append(b, pbVarint(uint64(len(s)))...)
	return append(b, []byte(s)...)
}

func pbUint64(field int, v uint64) []byte {
	if v == 0 {
		return nil
	}
	return append(pbTag(field, 0), pbVarint(v)...)
}

func pbBool(field int, v bool) []byte {
	if !v {
		return nil
	}
	return append(pbTag(field, 0), 1)
}

func pbEmbed(field int, body []byte) []byte {
	if len(body) == 0 {
		return nil
	}
	b := pbTag(field, 2)
	b = append(b, pbVarint(uint64(len(body)))...)
	return append(b, body...)
}

func pbTimestamp(field int, t time.Time) []byte {
	var body []byte
	body = append(body, pbUint64(1, uint64(t.Unix()))...)
	body = append(body, pbUint64(2, uint64(t.Nanosecond()))...)
	return pbEmbed(field, body)
}

func encodeQuote(q map[string]interface{}, userType string) []byte {
	str := func(k string) string {
		v, _ := q[k].(string)
		return v
	}
	u64 := func(k string) uint64 {
		switch v := q[k].(type) {
		case int:
			return uint64(v)
		case int64:
			return uint64(v)
		case float64:
			return uint64(v)
		}
		return 0
	}

	var b []byte
	b = append(b, pbString(1, str("symbol"))...)

	market := uint64(marketUS)
	if str("market") == "HK" {
		market = marketHK
	}
	b = append(b, pbUint64(2, market)...)

	b = append(b, pbString(3, str("price"))...)
	b = append(b, pbString(4, str("change"))...)
	b = append(b, pbString(5, str("change_pct"))...)
	b = append(b, pbUint64(6, u64("volume"))...)
	b = append(b, pbString(7, str("bid"))...)
	b = append(b, pbString(8, str("ask"))...)
	b = append(b, pbString(9, str("open"))...)
	b = append(b, pbString(10, str("high"))...)
	b = append(b, pbString(11, str("low"))...)
	b = append(b, pbString(12, str("prev_close"))...)
	b = append(b, pbString(13, str("turnover"))...)

	ms := uint64(marketStatusRegular)
	switch str("market_status") {
	case "PRE_MARKET":
		ms = marketStatusPreMarket
	case "AFTER_HOURS":
		ms = marketStatusAfterHours
	case "CLOSED":
		ms = marketStatusClosed
	case "HALTED":
		ms = marketStatusHalted
	}
	b = append(b, pbUint64(14, ms)...)

	if v, _ := q["is_stale"].(bool); v {
		b = append(b, pbBool(15, true)...)
	}
	b = append(b, pbUint64(16, u64("stale_since_ms"))...)

	if userType == "guest" {
		b = append(b, pbBool(17, true)...)
	}

	if tsMs, ok := q["timestamp_ms"].(int64); ok {
		b = append(b, pbTimestamp(18, time.UnixMilli(tsMs).UTC())...)
	} else {
		b = append(b, pbTimestamp(18, time.Now().UTC())...)
	}

	return b
}

func encodeWsQuoteFrame(frameType int, quoteBuf []byte) []byte {
	var b []byte
	b = append(b, pbUint64(1, uint64(frameType))...)
	b = append(b, pbEmbed(2, quoteBuf)...)
	return b
}
