// Package observability provides a structured JSON logger with PII masking.
package observability

import (
	"strings"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// piiFields lists field names that must be masked before logging.
// Never log: SSN, HKID, bank account numbers, card numbers, passwords, tokens.
var piiFields = map[string]bool{
	"ssn":            true,
	"hkid":           true,
	"passport":       true,
	"bank_account":   true,
	"card_number":    true,
	"password":       true,
	"token":          true,
	"access_token":   true,
	"refresh_token":  true,
	"secret":         true,
}

// MaskField returns "[REDACTED]" if the key is a known PII field, otherwise the original value.
func MaskField(key, value string) string {
	if piiFields[strings.ToLower(key)] {
		return "[REDACTED]"
	}
	return value
}

// NewLogger creates a production Zap logger configured for JSON output.
func NewLogger() (*zap.Logger, error) {
	cfg := zap.Config{
		Level:       zap.NewAtomicLevelAt(zap.InfoLevel),
		Development: false,
		Encoding:    "json",
		EncoderConfig: zapcore.EncoderConfig{
			TimeKey:        "ts",
			LevelKey:       "level",
			NameKey:        "logger",
			CallerKey:      "caller",
			MessageKey:     "msg",
			StacktraceKey:  "stacktrace",
			LineEnding:     zapcore.DefaultLineEnding,
			EncodeLevel:    zapcore.LowercaseLevelEncoder,
			EncodeTime:     zapcore.ISO8601TimeEncoder,
			EncodeDuration: zapcore.SecondsDurationEncoder,
			EncodeCaller:   zapcore.ShortCallerEncoder,
		},
		OutputPaths:      []string{"stdout"},
		ErrorOutputPaths: []string{"stderr"},
	}
	return cfg.Build()
}
