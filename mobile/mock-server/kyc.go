package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"
)

// In-memory KYC session store (keyed by session_id)
var kycSessions = map[string]map[string]interface{}{}

// Idempotency store: key → cached HTTP response body
var kycIdempotencyStore = map[string][]byte{}
var kycIdempotencyMu sync.Mutex

// Test session ID overrides for deterministic status responses.
// Use these exact session IDs in tests to get predictable results.
// Avoids substring-matching fragility (L-03).
var kycTestSessionOverrides = map[string]map[string]interface{}{
	"kyc-test-approved-001": {
		"kyc_status":   "APPROVED",
		"current_step": 8,
	},
	"kyc-test-rejected-001": {
		"kyc_status":          "REJECTED",
		"reason_if_rejected":  "Document verification failed",
	},
	"kyc-test-needs-more-info-001": {
		"kyc_status":           "NEEDS_MORE_INFO",
		"reason_if_rejected":   "Address proof unclear",
		"needs_more_info_step": 3,
	},
}

// idempotentPost checks the Idempotency-Key header and returns cached response
// if the key was already used. Returns true if served from cache.
func idempotentPost(w http.ResponseWriter, r *http.Request, statusCode int, body []byte) bool {
	key := r.Header.Get("Idempotency-Key")
	if key == "" {
		w.WriteHeader(statusCode)
		w.Write(body)
		return false
	}
	kycIdempotencyMu.Lock()
	defer kycIdempotencyMu.Unlock()
	if cached, ok := kycIdempotencyStore[key]; ok {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(statusCode)
		w.Write(cached)
		return true
	}
	kycIdempotencyStore[key] = body
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	w.Write(body)
	return false
}

func handleKycStart(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "application/json")

	var req map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"invalid json"}`, http.StatusBadRequest)
		return
	}

	// Validate age >= 18 using calendar-correct comparison (not floating-point division).
	dobStr, _ := req["date_of_birth"].(string)
	if dobStr != "" {
		dob, err := time.Parse("2006-01-02", dobStr)
		if err == nil {
			now := time.Now().UTC()
			age := now.Year() - dob.Year()
			if now.Month() < dob.Month() ||
				(now.Month() == dob.Month() && now.Day() < dob.Day()) {
				age--
			}
			if age < 18 {
				w.WriteHeader(http.StatusBadRequest)
				fmt.Fprintf(w, `{"error":"INVALID_AGE","message":"Must be at least 18 years old"}`)
				return
			}
		}
	}

	sessionID := fmt.Sprintf("kyc-session-%d", time.Now().UnixNano())
	expiresAt := time.Now().UTC().Add(60 * 24 * time.Hour).Format(time.RFC3339)
	kycSessions[sessionID] = map[string]interface{}{
		"status":      "IN_PROGRESS",
		"currentStep": 1,
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"kyc_session_id":         sessionID,
		"current_step":           1,
		"estimated_time_minutes": 15,
		"kyc_status":             "IN_PROGRESS",
		"expires_at":             expiresAt,
	})
}

func handleKycSumsubToken(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	sessionID := r.URL.Query().Get("kyc_session_id")
	if sessionID == "" {
		sessionID = "test-session-001"
	}
	json.NewEncoder(w).Encode(map[string]interface{}{
		"access_token": fmt.Sprintf("sumsub-token-%s-%d", sessionID, time.Now().Unix()),
		"applicant_id": fmt.Sprintf("applicant-%s", sessionID),
		"ttl":          600,
	})
}

func handleKycUploadURL(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	sessionID := r.URL.Query().Get("kyc_session_id")
	docType := r.URL.Query().Get("document_type")
	docID := fmt.Sprintf("doc-%s-%s-%d", sessionID, docType, time.Now().UnixNano())
	json.NewEncoder(w).Encode(map[string]interface{}{
		"upload_url":         fmt.Sprintf("https://s3.mock.local/kyc/%s/%s", sessionID, docID),
		"document_id":        docID,
		"expiry":             3600,
		"checksum_algorithm": "SHA256",
	})
}

func handleKycConfirmUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	var req map[string]interface{}
	json.NewDecoder(r.Body).Decode(&req)
	docID, _ := req["document_id"].(string)
	if docID == "" {
		docID = fmt.Sprintf("doc-%d", time.Now().UnixNano())
	}
	json.NewEncoder(w).Encode(map[string]interface{}{
		"document_id":         docID,
		"status":              "PENDING_VERIFICATION",
		"sumsub_applicant_id": fmt.Sprintf("applicant-%d", time.Now().UnixNano()),
	})
}

func handleKycAddressProof(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	body := []byte(`{"status":"ok"}`)
	idempotentPost(w, r, http.StatusOK, body)
}

func handleKycFinancialProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	body := []byte(`{"status":"ok"}`)
	idempotentPost(w, r, http.StatusOK, body)
}

func handleKycInvestmentAssessment(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	body := []byte(`{"status":"ok"}`)
	idempotentPost(w, r, http.StatusOK, body)
}

func handleKycTaxForms(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	body := []byte(`{"status":"ok"}`)
	idempotentPost(w, r, http.StatusOK, body)
}

func handleKycAgreements(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	body := []byte(`{"status":"ok"}`)
	idempotentPost(w, r, http.StatusOK, body)
}

func handleKycSubmit(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	sessionID := r.URL.Query().Get("kyc_session_id")
	if sessionID == "" {
		sessionID = "test-session-001"
	}
	if s, ok := kycSessions[sessionID]; ok {
		s["status"] = "PENDING_REVIEW"
	}
	respBody, _ := json.Marshal(map[string]interface{}{
		"kyc_session_id":              sessionID,
		"kyc_status":                  "PENDING_REVIEW",
		"estimated_review_time_hours": 24,
	})
	idempotentPost(w, r, http.StatusAccepted, respBody)
}

func handleKycStatus(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	sessionID := r.URL.Query().Get("kyc_session_id")

	// Deterministic test session overrides — exact key match only (no substring matching).
	if override, ok := kycTestSessionOverrides[sessionID]; ok {
		resp := map[string]interface{}{"kyc_session_id": sessionID}
		for k, v := range override {
			resp[k] = v
		}
		json.NewEncoder(w).Encode(resp)
		return
	}

	// Default: return session status from store, or PENDING_REVIEW
	status := "PENDING_REVIEW"
	currentStep := 1
	if s, ok := kycSessions[sessionID]; ok {
		if st, ok := s["status"].(string); ok {
			status = st
		}
		if cs, ok := s["currentStep"].(int); ok {
			currentStep = cs
		}
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"kyc_session_id":         sessionID,
		"kyc_status":             status,
		"current_step":           currentStep,
		"estimated_time_minutes": 60,
	})
}
