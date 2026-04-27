package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"
)

// ─── In-memory state ──────────────────────────────────────────────────────────

var (
	fundingIdempotencyKeys = make(map[string]map[string]interface{}) // key -> cached response
	fundingIdempotencyMu   sync.RWMutex
	fundingBankAccounts    = initBankAccounts()
	fundingBankMu          sync.RWMutex
	fundingTransfers       = initTransfers()
	fundingTransferMu      sync.RWMutex
	fundingChallenges      = make(map[string]time.Time) // challenge -> expires_at
	fundingChallengeMu     sync.RWMutex
)

// ─── Preset data ──────────────────────────────────────────────────────────────

func initBankAccounts() []map[string]interface{} {
	now := time.Now().UTC()
	cooldownEnd := now.Add(72 * time.Hour)
	return []map[string]interface{}{
		{
			"bank_account_id":           "ba-001",
			"account_id":                "acc-demo-001",
			"account_name":              "John Smith",
			"account_number":            "****1234",
			"routing_number":            "021000021",
			"bank_name":                 "Chase Bank",
			"currency":                  "USD",
			"is_verified":               true,
			"cooldown_ends_at":          nil,
			"micro_deposit_status":      "verified",
			"remaining_verify_attempts": 5,
			"created_at":                now.Add(-30 * 24 * time.Hour).Format(time.RFC3339),
		},
		{
			"bank_account_id":           "ba-002",
			"account_id":                "acc-demo-001",
			"account_name":              "John Smith",
			"account_number":            "****5678",
			"routing_number":            "021000089",
			"bank_name":                 "Bank of America",
			"currency":                  "USD",
			"is_verified":               false,
			"cooldown_ends_at":          cooldownEnd.Format(time.RFC3339),
			"micro_deposit_status":      "pending",
			"remaining_verify_attempts": 5,
			"created_at":                now.Add(-1 * time.Hour).Format(time.RFC3339),
		},
	}
}

func initTransfers() []map[string]interface{} {
	now := time.Now().UTC()
	return []map[string]interface{}{
		{
			"transfer_id":    "txn-001",
			"account_id":     "acc-demo-001",
			"type":           "DEPOSIT",
			"status":         "COMPLETED",
			"amount":         "5000.00",
			"currency":       "USD",
			"channel":        "ACH",
			"bank_account_id": "ba-001",
			"request_id":     "idem-001",
			"failure_reason": "",
			"created_at":     now.Add(-5 * 24 * time.Hour).Format(time.RFC3339Nano),
			"updated_at":     now.Add(-3 * 24 * time.Hour).Format(time.RFC3339Nano),
			"completed_at":   now.Add(-3 * 24 * time.Hour).Format(time.RFC3339Nano),
		},
		{
			"transfer_id":    "txn-002",
			"account_id":     "acc-demo-001",
			"type":           "WITHDRAWAL",
			"status":         "COMPLETED",
			"amount":         "1000.00",
			"currency":       "USD",
			"channel":        "ACH",
			"bank_account_id": "ba-001",
			"request_id":     "idem-002",
			"failure_reason": "",
			"created_at":     now.Add(-2 * 24 * time.Hour).Format(time.RFC3339Nano),
			"updated_at":     now.Add(-1 * 24 * time.Hour).Format(time.RFC3339Nano),
			"completed_at":   now.Add(-1 * 24 * time.Hour).Format(time.RFC3339Nano),
		},
		{
			"transfer_id":    "txn-003",
			"account_id":     "acc-demo-001",
			"type":           "DEPOSIT",
			"status":         "PENDING",
			"amount":         "2500.00",
			"currency":       "USD",
			"channel":        "WIRE",
			"bank_account_id": "ba-001",
			"request_id":     "idem-003",
			"failure_reason": "",
			"created_at":     now.Add(-2 * time.Hour).Format(time.RFC3339Nano),
			"updated_at":     now.Add(-2 * time.Hour).Format(time.RFC3339Nano),
			"completed_at":   nil,
		},
	}
}

// ─── Idempotency helpers ──────────────────────────────────────────────────────

func checkFundingIdempotency(key string) (map[string]interface{}, bool) {
	fundingIdempotencyMu.RLock()
	defer fundingIdempotencyMu.RUnlock()
	resp, found := fundingIdempotencyKeys[key]
	return resp, found
}

func storeFundingIdempotency(key string, resp map[string]interface{}) {
	fundingIdempotencyMu.Lock()
	defer fundingIdempotencyMu.Unlock()
	fundingIdempotencyKeys[key] = resp
}

// ─── Balance ──────────────────────────────────────────────────────────────────

func handleFundingBalance(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"account_id":           "acc-demo-001",
		"currency":             "USD",
		"total_balance":        "12450.00",
		"available_balance":    "12450.00",
		"unsettled_amount":     "0.00",
		"withdrawable_balance": "11450.00",
		"updated_at":           time.Now().UTC().Format(time.RFC3339),
	})
}

// ─── Deposit ──────────────────────────────────────────────────────────────────

func handleFundingDeposit(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	idempotencyKey := r.Header.Get("Idempotency-Key")
	if idempotencyKey == "" {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code": "MISSING_HEADER",
			"message":    "缺少 Idempotency-Key header",
		})
		return
	}

	// Return cached response on replay
	if cached, found := checkFundingIdempotency(idempotencyKey); found {
		fmt.Printf("💰 Deposit replay: key=%s\n", idempotencyKey)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(cached)
		return
	}

	var body map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	now := time.Now().UTC()
	transferID := fmt.Sprintf("dep-%d", now.UnixMilli())
	resp := map[string]interface{}{
		"transfer_id":     transferID,
		"account_id":      "acc-demo-001",
		"type":            "DEPOSIT",
		"status":          "PENDING",
		"amount":          body["amount"],
		"currency":        "USD",
		"channel":         body["channel"],
		"bank_account_id": body["bank_account_id"],
		"request_id":      idempotencyKey,
		"failure_reason":  "",
		"created_at":      now.Format(time.RFC3339Nano),
		"updated_at":      now.Format(time.RFC3339Nano),
		"completed_at":    nil,
	}

	storeFundingIdempotency(idempotencyKey, resp)
	fundingTransferMu.Lock()
	fundingTransfers = append(fundingTransfers, resp)
	fundingTransferMu.Unlock()

	fmt.Printf("💰 Deposit submitted: id=%s amount=%v\n", transferID, body["amount"])
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(resp)
}

// ─── Withdrawal ───────────────────────────────────────────────────────────────

func handleFundingWithdrawal(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	idempotencyKey := r.Header.Get("Idempotency-Key")
	if idempotencyKey == "" {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code": "MISSING_HEADER",
			"message":    "缺少 Idempotency-Key header",
		})
		return
	}

	// Require biometric headers
	bioToken := r.Header.Get("X-Biometric-Token")
	if bioToken == "" {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code": "MISSING_BIO_HEADERS",
			"message":    "出金需要生物识别认证",
		})
		return
	}

	if cached, found := checkFundingIdempotency(idempotencyKey); found {
		fmt.Printf("💸 Withdrawal replay: key=%s\n", idempotencyKey)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(cached)
		return
	}

	var body map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	now := time.Now().UTC()
	transferID := fmt.Sprintf("wth-%d", now.UnixMilli())
	resp := map[string]interface{}{
		"transfer_id":     transferID,
		"account_id":      "acc-demo-001",
		"type":            "WITHDRAWAL",
		"status":          "PENDING",
		"amount":          body["amount"],
		"currency":        "USD",
		"channel":         body["channel"],
		"bank_account_id": body["bank_account_id"],
		"request_id":      idempotencyKey,
		"failure_reason":  "",
		"created_at":      now.Format(time.RFC3339Nano),
		"updated_at":      now.Format(time.RFC3339Nano),
		"completed_at":    nil,
	}

	storeFundingIdempotency(idempotencyKey, resp)
	fundingTransferMu.Lock()
	fundingTransfers = append(fundingTransfers, resp)
	fundingTransferMu.Unlock()

	fmt.Printf("💸 Withdrawal submitted: id=%s amount=%v\n", transferID, body["amount"])
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(resp)
}

// ─── Transfer History ─────────────────────────────────────────────────────────

func handleFundingHistory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	fundingTransferMu.RLock()
	transfers := fundingTransfers
	fundingTransferMu.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"transfers": transfers,
		"total":     len(transfers),
	})
}

// ─── Bank Accounts ────────────────────────────────────────────────────────────

func handleFundingBankAccounts(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		fundingBankMu.RLock()
		accounts := fundingBankAccounts
		fundingBankMu.RUnlock()
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"bank_accounts": accounts,
		})
	case http.MethodPost:
		handleAddBankAccount(w, r)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func handleAddBankAccount(w http.ResponseWriter, r *http.Request) {
	idempotencyKey := r.Header.Get("Idempotency-Key")
	if idempotencyKey == "" {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code": "MISSING_HEADER",
			"message":    "缺少 Idempotency-Key header",
		})
		return
	}

	if cached, found := checkFundingIdempotency(idempotencyKey); found {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(cached)
		return
	}

	var body map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	now := time.Now().UTC()
	cooldownEnd := now.Add(3 * 24 * time.Hour)
	accountNum, _ := body["account_number"].(string)
	masked := "****"
	if len(accountNum) >= 4 {
		masked = "****" + accountNum[len(accountNum)-4:]
	}

	bankID := fmt.Sprintf("ba-%d", now.UnixMilli())
	newAccount := map[string]interface{}{
		"bank_account_id":           bankID,
		"account_id":                "acc-demo-001",
		"account_name":              body["account_name"],
		"account_number":            masked,
		"routing_number":            body["routing_number"],
		"bank_name":                 body["bank_name"],
		"currency":                  "USD",
		"is_verified":               false,
		"cooldown_ends_at":          cooldownEnd.Format(time.RFC3339),
		"micro_deposit_status":      "pending",
		"remaining_verify_attempts": 5,
		"created_at":                now.Format(time.RFC3339),
	}

	storeFundingIdempotency(idempotencyKey, newAccount)
	fundingBankMu.Lock()
	fundingBankAccounts = append(fundingBankAccounts, newAccount)
	fundingBankMu.Unlock()

	fmt.Printf("🏦 Bank account bound: id=%s bank=%v\n", bankID, body["bank_name"])
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(newAccount)
}

func handleFundingBankAccountByID(w http.ResponseWriter, r *http.Request) {
	// Extract bankID from path: /api/v1/bank-accounts/{id}/...
	path := strings.TrimPrefix(r.URL.Path, "/api/v1/bank-accounts/")
	parts := strings.SplitN(path, "/", 2)
	bankID := parts[0]
	subPath := ""
	if len(parts) > 1 {
		subPath = parts[1]
	}

	switch {
	case subPath == "verify-micro-deposit" && r.Method == http.MethodPost:
		handleVerifyMicroDeposit(w, r, bankID)
	case subPath == "" && r.Method == http.MethodDelete:
		handleDeleteBankAccount(w, r, bankID)
	default:
		http.Error(w, "Not found", http.StatusNotFound)
	}
}

func handleDeleteBankAccount(w http.ResponseWriter, r *http.Request, bankID string) {
	fundingBankMu.Lock()
	defer fundingBankMu.Unlock()
	updated := []map[string]interface{}{}
	for _, a := range fundingBankAccounts {
		if a["bank_account_id"] != bankID {
			updated = append(updated, a)
		}
	}
	fundingBankAccounts = updated
	fmt.Printf("🗑️  Bank account deleted: id=%s\n", bankID)
	w.WriteHeader(http.StatusNoContent)
}

func handleVerifyMicroDeposit(w http.ResponseWriter, r *http.Request, bankID string) {
	var body map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Mock: accept $0.15 + $0.23 as correct amounts
	amount1, _ := body["amount_1"].(string)
	amount2, _ := body["amount_2"].(string)
	correct := (amount1 == "0.15" || amount1 == "0.14" || amount1 == "0.16") &&
		(amount2 == "0.23" || amount2 == "0.22" || amount2 == "0.24")

	fundingBankMu.Lock()
	defer fundingBankMu.Unlock()

	var updated map[string]interface{}
	for i, a := range fundingBankAccounts {
		if a["bank_account_id"] == bankID {
			if correct {
				fundingBankAccounts[i]["is_verified"] = true
				fundingBankAccounts[i]["micro_deposit_status"] = "verified"
				fundingBankAccounts[i]["cooldown_ends_at"] = time.Now().UTC().Add(3 * 24 * time.Hour).Format(time.RFC3339)
			} else {
				remaining, _ := fundingBankAccounts[i]["remaining_verify_attempts"].(int)
				if remaining > 0 {
					fundingBankAccounts[i]["remaining_verify_attempts"] = remaining - 1
				}
				if remaining <= 1 {
					fundingBankAccounts[i]["micro_deposit_status"] = "failed"
				} else {
					fundingBankAccounts[i]["micro_deposit_status"] = "verifying"
				}
			}
			updated = fundingBankAccounts[i]
			break
		}
	}

	if updated == nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code": "NOT_FOUND",
			"message":    "银行卡不存在",
		})
		return
	}

	if !correct {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnprocessableEntity)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code":                "MICRO_DEPOSIT_MISMATCH",
			"message":                   "金额不匹配，请重新输入",
			"remaining_verify_attempts": updated["remaining_verify_attempts"],
		})
		return
	}

	fmt.Printf("✅ Micro-deposit verified: bankId=%s\n", bankID)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updated)
}

// ─── Bio Challenge for Fund Withdrawal ───────────────────────────────────────

func handleFundingBioChallenge(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	challenge := generateHex(32)
	expiresAt := time.Now().UTC().Add(30 * time.Second)

	fundingChallengeMu.Lock()
	fundingChallenges[challenge] = expiresAt
	fundingChallengeMu.Unlock()

	fmt.Printf("🔐 Fund bio challenge issued: %s...\n", challenge[:16])
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"challenge":  challenge,
		"expires_at": expiresAt.Format(time.RFC3339),
	})
}
