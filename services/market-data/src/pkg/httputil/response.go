// Package httputil provides shared HTTP utilities for handlers.
package httputil

import (
	"encoding/json"
	"net/http"
	"strings"
)

// APIError is the canonical error response body (spec §1.3, §13).
type APIError struct {
	Error   string      `json:"error"`
	Message string      `json:"message"`
	Details interface{} `json:"details,omitempty"`
}

// WriteError writes a structured JSON error response.
func WriteError(w http.ResponseWriter, httpStatus int, errorCode, message string, details interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(httpStatus)
	_ = json.NewEncoder(w).Encode(APIError{
		Error:   errorCode,
		Message: message,
		Details: details,
	})
}

// WriteJSON writes a success JSON response with HTTP 200.
func WriteJSON(w http.ResponseWriter, v interface{}) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}

// IsValidJWT performs a lightweight structural check on the Authorization header.
// WARNING: This stub only checks that the token has 3 dot-separated segments.
// It does NOT verify the RS256 signature or validate claims (exp, iss, etc.).
// TODO(Phase-6): integrate AMS RS256 public key — MUST NOT be deployed to production with this stub.
func IsValidJWT(r *http.Request) bool {
	auth := r.Header.Get("Authorization")
	if !strings.HasPrefix(auth, "Bearer ") {
		return false
	}
	token := strings.TrimPrefix(auth, "Bearer ")
	parts := strings.Split(token, ".")
	return len(parts) == 3
}

// ExtractUserID reads the X-User-ID header as a placeholder for JWT claims extraction.
// TODO(Phase-6): Replace with proper JWT claims extraction from validated token.
func ExtractUserID(r *http.Request) string {
	return r.Header.Get("X-User-ID")
}
