package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"
)

// ─── Seeded test data ─────────────────────────────────────────────────────────

func initSettingsSeedData() {
	deviceMutex.Lock()
	defer deviceMutex.Unlock()

	if len(deviceRegistry) > 0 {
		return // already seeded
	}

	now := time.Now().UTC()
	deviceRegistry["device-test-001"] = &DeviceInfo{
		DeviceID:   "device-test-001",
		DeviceName: "iPhone 15 Pro (测试)",
		Platform:   "iOS 18.1",
		RegisteredAt: now.Add(-30 * 24 * time.Hour),
		LastSeenAt:  now.Add(-1 * time.Hour),
	}
	deviceRegistry["device-test-002"] = &DeviceInfo{
		DeviceID:   "device-test-002",
		DeviceName: "MacBook Pro (测试)",
		Platform:   "macOS 14.3",
		RegisteredAt: now.Add(-7 * 24 * time.Hour),
		LastSeenAt:  now.Add(-48 * time.Hour),
	}
}

// ─── Profile ──────────────────────────────────────────────────────────────────

func handleGetProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"account_id":        "acc-test-001",
		"full_name":         "张三",
		"phone":             "+86 13812345678",
		"email":             "zhangsan@example.com",
		"id_number":         "110101199001011234",
		"id_type":           "ID_CARD",
		"date_of_birth":     "1990-01-01",
		"country":           "CN",
		"province":          "北京市",
		"city":              "朝阳区",
		"address":           "某街道123号",
		"employment_status": "EMPLOYED",
		"employer":          "某科技公司",
		"industry":          "IT",
		"kyc_tier":          2,
		"account_opened_at": "2024-01-15T09:30:00Z",
		"account_type":      "INDIVIDUAL",
	})
	fmt.Printf("👤 GET /v1/profile — returned mock profile\n")
}

// ─── Account Status ────────────────────────────────────────────────────────────

func handleGetAccountStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	expiresAt := time.Now().UTC().AddDate(1, 0, 0).Format(time.RFC3339)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"kyc_status":            "APPROVED",
		"aml_status":            "CLEAR",
		"w8ben_status":          "VALID",
		"w8ben_expires_at":      expiresAt,
		"withholding_tax_rate":  "10%",
		"trading_enabled":       true,
		"withdrawal_enabled":    true,
		"deposit_enabled":       true,
		"is_locked":             false,
	})
	fmt.Printf("🔍 GET /v1/profile/account-status — returned mock status\n")
}

// ─── Notification Preferences ─────────────────────────────────────────────────

// In-memory store for notification preferences
var notifPrefs = map[string]interface{}{
	"trading_enabled":               true,
	"funding_enabled":               true,
	"kyc_enabled":                   true,
	"system_announcements_enabled":  true,
	"push_enabled":                  true,
	"sms_enabled":                   false,
	"email_enabled":                 true,
}

func handleNotificationPreferences(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	switch r.Method {
	case http.MethodGet:
		json.NewEncoder(w).Encode(notifPrefs)
		fmt.Printf("🔔 GET /v1/notifications/preferences — returned prefs\n")
	case http.MethodPut:
		var req map[string]interface{}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "invalid JSON", http.StatusBadRequest)
			return
		}
		// Merge into in-memory store (security_alerts_enabled always stays true)
		for k, v := range req {
			notifPrefs[k] = v
		}
		json.NewEncoder(w).Encode(notifPrefs)
		fmt.Printf("🔔 PUT /v1/notifications/preferences — updated prefs\n")
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// ─── Devices (settings view — adds last_active_at + is_current_device) ────────

func handleSettingsDevices(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	deviceMutex.RLock()
	devices := make([]map[string]interface{}, 0, len(deviceRegistry))
	first := true
	for _, d := range deviceRegistry {
		device := map[string]interface{}{
			"device_id":        d.DeviceID,
			"device_name":      d.DeviceName,
			"platform":         d.Platform,
			"status":           "ACTIVE",
			"last_active_at":   d.LastSeenAt.Format(time.RFC3339),
			"is_current_device": first, // mark first device as "current"
		}
		devices = append(devices, device)
		first = false
	}
	deviceMutex.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"devices": devices,
	})
	fmt.Printf("📱 GET /v1/auth/devices (settings) — returned %d devices\n", len(devices))
}

// ─── Change Phone (stub) ───────────────────────────────────────────────────────

// handlePhoneChange handles OTP send (with/without phone), verify-old, and change endpoints.
func handlePhoneChange(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	// Both VERIFY_CURRENT_PHONE (no phone param) and CHANGE_PHONE (with phone param) succeed
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{"success": true})
}

// ─── Account Lock ──────────────────────────────────────────────────────────────

func handleAccountLock(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "message": "Account locked"})
	fmt.Printf("🔒 POST /v1/account/lock — account locked\n")
}

// ─── Deactivation Eligibility ──────────────────────────────────────────────────

func handleDeactivationEligibility(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	// Mock: return eligible (no positions, no balance) for test purposes
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"eligible":       true,
		"has_positions":  false,
		"has_balance":    false,
		"has_pending":    false,
		"has_open_orders": false,
	})
	fmt.Printf("🚫 GET /v1/account/deactivation/eligibility — eligible\n")
}

// handleSettingsDeleteDevice overrides the auth device handler to return
// last_active_at-aware responses.
func handleSettingsDeleteDevice(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	// Extract device ID from path /v1/auth/devices/{device_id}
	parts := strings.Split(r.URL.Path, "/")
	if len(parts) < 5 || parts[4] == "" {
		http.Error(w, "device_id required", http.StatusBadRequest)
		return
	}
	deviceID := parts[4]

	deviceMutex.Lock()
	_, exists := deviceRegistry[deviceID]
	if exists {
		delete(deviceRegistry, deviceID)
	}
	deviceMutex.Unlock()

	if !exists {
		http.Error(w, "device not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{"success": true})
	fmt.Printf("📱 DELETE /v1/auth/devices/%s — device removed\n", deviceID)
}
