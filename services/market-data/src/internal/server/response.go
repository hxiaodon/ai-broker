// Package server provides the transport layer for the market-data service.
package server

import (
	"encoding/json"
	"net/http"
	"strings"
)

// apiError is the canonical error response body (spec §1.3, §13).
// All error responses MUST use this struct — never http.Error with string concatenation.
type apiError struct {
	Error   string      `json:"error"`
	Message string      `json:"message"`
	Details interface{} `json:"details,omitempty"`
}

// writeError writes a structured JSON error response.
// httpStatus: HTTP status code (e.g. http.StatusBadRequest).
// errorCode: machine-readable error code string (e.g. "TOO_MANY_SYMBOLS").
// message: human-readable description.
// details: optional structured details; pass nil to omit.
func writeError(w http.ResponseWriter, httpStatus int, errorCode, message string, details interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(httpStatus)
	resp := apiError{
		Error:   errorCode,
		Message: message,
		Details: details,
	}
	// Best-effort encode; if it fails there is nothing safe we can do at this point.
	_ = json.NewEncoder(w).Encode(resp)
}

// writeJSON writes a success JSON response with HTTP 200 unless the writer has
// already had a status written.
func writeJSON(w http.ResponseWriter, v interface{}) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}

// isValidJWT performs a lightweight structural check on the Authorization header.
// It does NOT validate the signature — full JWT validation requires the AMS
// public key and is deferred to Phase 6 JWT middleware.
//
// TODO(Phase-6): Replace this stub with proper RS256 JWT verification using the
// AMS public key. The current implementation only checks that a Bearer token
// is present and structurally looks like a JWT (three base64url segments).
//
// Security note: tokens must not appear in server logs or URL query params;
// they are read exclusively from the Authorization header (spec §1.5).
func isValidJWT(r *http.Request) bool {
	auth := r.Header.Get("Authorization")
	if !strings.HasPrefix(auth, "Bearer ") {
		return false
	}
	token := strings.TrimPrefix(auth, "Bearer ")
	if token == "" {
		return false
	}
	// A JWT has exactly 3 dot-separated segments.
	parts := strings.Split(token, ".")
	return len(parts) == 3
}

// extractUserID reads the X-User-ID header as a placeholder for JWT claims extraction.
//
// TODO(Phase-6): Replace with proper JWT claims extraction once RS256 verification
// is in place. The real user ID comes from the "sub" claim of the validated JWT.
func extractUserID(r *http.Request) string {
	return r.Header.Get("X-User-ID")
}
