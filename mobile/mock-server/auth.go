package main

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"
)

// OTP session storage
var (
	otpSessions       = make(map[string]*OtpSession)
	otpMutex          sync.RWMutex
	biometricRegistry = make(map[string]*BiometricDevice) // device_id -> BiometricDevice
	biometricMutex    sync.RWMutex
	deviceRegistry    = make(map[string]*DeviceInfo) // device_id -> DeviceInfo
	deviceMutex       sync.RWMutex
)

type OtpSession struct {
	Phone       string
	OTP         string
	CreatedAt   time.Time
	ExpiresAt   time.Time
	Attempts    int
	MaxAttempts int
	Locked      bool
	LockedUntil time.Time
}

type OtpSendRequest struct {
	PhoneNumber string `json:"phone_number"`
}

type OtpSendResponse struct {
	RequestID         string `json:"request_id"`
	PhoneNumber       string `json:"phone_number"`
	DeliveryMethod    string `json:"delivery_method"`
	ExpiresInSeconds  int    `json:"expires_in_seconds"`
	RetryAfterSeconds int    `json:"retry_after_seconds"`
}

type OtpVerifyRequest struct {
	RequestID   string `json:"request_id"`
	OtpCode     string `json:"otp_code"`
	PhoneNumber string `json:"phone_number"`
}

type OtpVerifyResponse struct {
	Status           string                 `json:"status"`
	AccessToken      string                 `json:"access_token,omitempty"`
	RefreshToken     string                 `json:"refresh_token,omitempty"`
	ExpiresInSeconds int                    `json:"expires_in_seconds,omitempty"`
	AccountID        string                 `json:"account_id,omitempty"`
	AccountStatus    string                 `json:"account_status,omitempty"`
	RequestID        string                 `json:"request_id,omitempty"`
	DeviceInfo       map[string]interface{} `json:"device_info,omitempty"`
}

type TokenRefreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type TokenRefreshResponse struct {
	AccessToken      string `json:"access_token"`
	RefreshToken     string `json:"refresh_token"`
	ExpiresInSeconds int    `json:"expires_in_seconds"`
	DeviceStatus     string `json:"device_status"`
}

type BiometricRegisterRequest struct {
	DeviceID      string `json:"device_id"`
	BiometricType string `json:"biometric_type"`
}

type BiometricRegisterResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
}

type LogoutRequest struct {
	AccessToken string `json:"access_token"`
}

type LogoutResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
}

// BiometricDevice — registered biometric on a device
type BiometricDevice struct {
	DeviceID      string `json:"device_id"`
	BiometricType string `json:"biometric_type"` // face_id, fingerprint, etc.
	RegisteredAt   time.Time `json:"registered_at"`
	IsActive      bool   `json:"is_active"`
}

// BiometricVerifyRequest — verify biometric auth
type BiometricVerifyRequest struct {
	DeviceID      string `json:"device_id"`
	BiometricType string `json:"biometric_type"`
}

// BiometricVerifyResponse — result of biometric verification
type BiometricVerifyResponse struct {
	Success     bool   `json:"success"`
	Message     string `json:"message"`
	AccessToken string `json:"access_token,omitempty"`
}

// DeviceInfo — device registered with account
type DeviceInfo struct {
	DeviceID      string    `json:"device_id"`
	DeviceName    string    `json:"device_name"`
	Platform      string    `json:"platform"` // iOS, Android
	RegisteredAt  time.Time `json:"registered_at"`
	LastSeenAt    time.Time `json:"last_seen_at"`
	BiometricType string    `json:"biometric_type,omitempty"` // face_id, fingerprint, etc.
}

// GetDevicesResponse — list of registered devices
type GetDevicesResponse struct {
	Success bool          `json:"success"`
	Message string        `json:"message"`
	Devices []DeviceInfo `json:"devices,omitempty"`
}

func handleOtpSend(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req OtpSendRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	// Validate phone number format
	if !isValidPhoneNumber(req.PhoneNumber) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code": "INVALID_PHONE_NUMBER",
			"message":    "无效的手机号码格式",
		})
		return
	}

	// Check if account is locked
	otpMutex.RLock()
	session, exists := otpSessions[req.PhoneNumber]
	otpMutex.RUnlock()

	if exists && session.Locked && time.Now().Before(session.LockedUntil) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusTooManyRequests)
		remainingMinutes := int(session.LockedUntil.Sub(time.Now()).Minutes())
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code":          "ACCOUNT_LOCKED",
			"message":             fmt.Sprintf("账户已锁定，请在 %d 分钟后重试", remainingMinutes),
			"retry_after_seconds": remainingMinutes * 60,
		})
		return
	}

	// Generate OTP (for testing, always return "123456")
	otp := "123456"
	if currentStrategy.Name() == "error" {
		otp = "999999" // Invalid OTP for error testing
	}

	// Create session
	newSession := &OtpSession{
		Phone:       req.PhoneNumber,
		OTP:         otp,
		CreatedAt:   time.Now(),
		ExpiresAt:   time.Now().Add(5 * time.Minute),
		Attempts:    0,
		MaxAttempts: 5,
		Locked:      false,
	}

	otpMutex.Lock()
	otpSessions[req.PhoneNumber] = newSession
	otpMutex.Unlock()

	// Log for testing
	fmt.Printf("📱 OTP sent to %s: %s (expires in 5 min)\n", req.PhoneNumber, otp)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(OtpSendResponse{
		RequestID:         fmt.Sprintf("req_%d", time.Now().UnixMilli()),
		PhoneNumber:       req.PhoneNumber,
		DeliveryMethod:    "SMS",
		ExpiresInSeconds:  300,
		RetryAfterSeconds: 60,
	})
}

func handleOtpVerify(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req OtpVerifyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	otpMutex.RLock()
	session, exists := otpSessions[req.PhoneNumber]
	otpMutex.RUnlock()

	if !exists {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code": "REQUEST_NOT_FOUND",
			"message":    "验证码不存在或已过期",
		})
		return
	}

	// Check if account is locked
	if session.Locked && time.Now().Before(session.LockedUntil) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		remainingMinutes := int(session.LockedUntil.Sub(time.Now()).Minutes())
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code":         "OTP_MAX_ATTEMPTS_EXCEEDED",
			"message":            fmt.Sprintf("账户已锁定，请在 %d 分钟后重试", remainingMinutes),
			"remaining_attempts": 0,
			"lockout_until":      session.LockedUntil.UTC().Format(time.RFC3339),
		})
		return
	}

	// Check if OTP expired
	if time.Now().After(session.ExpiresAt) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code": "OTP_EXPIRED",
			"message":    "验证码已过期，请重新申请",
		})
		return
	}

	// Increment attempts
	session.Attempts++

	// Check if OTP is correct
	if req.OtpCode != session.OTP {
		otpMutex.Lock()
		if session.Attempts >= session.MaxAttempts {
			session.Locked = true
			session.LockedUntil = time.Now().Add(30 * time.Minute)
		}
		otpSessions[req.PhoneNumber] = session
		otpMutex.Unlock()

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		remainingAttempts := session.MaxAttempts - session.Attempts
		if remainingAttempts <= 0 {
			json.NewEncoder(w).Encode(map[string]interface{}{
				"error_code":         "OTP_MAX_ATTEMPTS_EXCEEDED",
				"message":            "验证码错误次数过多，账户已锁定 30 分钟",
				"remaining_attempts": 0,
				"lockout_until":      session.LockedUntil.UTC().Format(time.RFC3339),
			})
		} else {
			json.NewEncoder(w).Encode(map[string]interface{}{
				"error_code":         "INVALID_OTP_CODE",
				"message":            fmt.Sprintf("验证码错误，还有 %d 次尝试机会", remainingAttempts),
				"remaining_attempts": remainingAttempts,
			})
		}
		return
	}

	// OTP verified successfully
	accountID := fmt.Sprintf("acc_%s_%d", req.PhoneNumber[len(req.PhoneNumber)-4:], time.Now().Unix())
	requestID := fmt.Sprintf("req_%d", time.Now().UnixMilli())
	deviceID := r.Header.Get("X-Device-ID")
	accessToken := generateMockJWT(accountID, deviceID, 15*time.Minute)
	refreshToken := "rt_" + generateToken(32)

	// Clean up session
	otpMutex.Lock()
	delete(otpSessions, req.PhoneNumber)
	otpMutex.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(OtpVerifyResponse{
		Status:           "OTP_VERIFIED_EXISTING_USER",
		AccessToken:      accessToken,
		RefreshToken:     refreshToken,
		ExpiresInSeconds: 3600,
		AccountID:        accountID,
		AccountStatus:    "ACTIVE",
		RequestID:        requestID,
		DeviceInfo: map[string]interface{}{
			"device_id":            r.Header.Get("X-Device-ID"),
			"device_name":          "iPhone Simulator",
			"os_type":              "iOS",
			"login_time":           time.Now().UTC().Format(time.RFC3339),
			"status":               "ACTIVE",
			"is_current_device":    true,
			"biometric_registered": false,
		},
	})
}

func handleTokenRefresh(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req TokenRefreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	// For testing, always allow refresh (in production, validate token)
	if currentStrategy.Name() == "error" {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code": "REFRESH_TOKEN_EXPIRED",
			"message":    "刷新令牌已过期",
		})
		return
	}

	newAccessToken := generateMockJWT("acc-refreshed", r.Header.Get("X-Device-ID"), 15*time.Minute)
	newRefreshToken := "rt_" + generateToken(32)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(TokenRefreshResponse{
		AccessToken:      newAccessToken,
		RefreshToken:     newRefreshToken,
		ExpiresInSeconds: 3600,
		DeviceStatus:     "ACTIVE",
	})
}

func handleBiometricRegister(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req BiometricRegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	if currentStrategy.Name() == "error" {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(BiometricRegisterResponse{
			Success: false,
			Message: "生物识别注册失败，请重试",
		})
		return
	}

	// Register biometric for this device
	bioDevice := &BiometricDevice{
		DeviceID:      req.DeviceID,
		BiometricType: req.BiometricType,
		RegisteredAt:  time.Now(),
		IsActive:      true,
	}

	biometricMutex.Lock()
	biometricRegistry[req.DeviceID] = bioDevice
	biometricMutex.Unlock()

	// Also register the device itself
	deviceInfo := &DeviceInfo{
		DeviceID:      req.DeviceID,
		DeviceName:    fmt.Sprintf("Device-%s", req.DeviceID[:8]),
		Platform:      "iOS", // default, would be passed in real app
		RegisteredAt:  time.Now(),
		LastSeenAt:    time.Now(),
		BiometricType: req.BiometricType,
	}

	deviceMutex.Lock()
	deviceRegistry[req.DeviceID] = deviceInfo
	deviceMutex.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(BiometricRegisterResponse{
		Success: true,
		Message: fmt.Sprintf("生物识别（%s）注册成功", req.BiometricType),
	})
	fmt.Printf("👆 Biometric registered: device %s (%s)\n", req.DeviceID, req.BiometricType)
}

func handleLogout(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req LogoutRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	// For testing, always allow logout
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(LogoutResponse{
		Success: true,
		Message: "登出成功",
	})
	fmt.Printf("🚪 User logged out\n")
}

// handleBiometricVerify — verify biometric authentication
func handleBiometricVerify(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req BiometricVerifyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	if currentStrategy.Name() == "error" {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(BiometricVerifyResponse{
			Success: false,
			Message: "生物识别验证失败",
		})
		return
	}

	// Check if biometric is registered for this device
	biometricMutex.RLock()
	device, exists := biometricRegistry[req.DeviceID]
	biometricMutex.RUnlock()

	if !exists || !device.IsActive {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(BiometricVerifyResponse{
			Success: false,
			Message: "设备未注册生物识别",
		})
		return
	}

	if device.BiometricType != req.BiometricType {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(BiometricVerifyResponse{
			Success: false,
			Message: "生物识别类型不匹配",
		})
		return
	}

	// Biometric verified successfully
	accessToken := generateToken(24)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(BiometricVerifyResponse{
		Success:     true,
		Message:     "生物识别验证成功",
		AccessToken: accessToken,
	})
	fmt.Printf("✅ Biometric verified for device %s (%s)\n", req.DeviceID, req.BiometricType)
}

// handleGetDevices — get list of registered devices
func handleGetDevices(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	deviceMutex.RLock()
	devices := make([]DeviceInfo, 0, len(deviceRegistry))
	for _, device := range deviceRegistry {
		devices = append(devices, *device)
	}
	deviceMutex.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(GetDevicesResponse{
		Success: true,
		Message: fmt.Sprintf("获取 %d 个设备信息成功", len(devices)),
		Devices: devices,
	})
	fmt.Printf("📱 Retrieved %d registered devices\n", len(devices))
}

// handleDeleteDevice — delete a registered device
func handleDeleteDevice(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract device_id from URL path: /v1/auth/devices/{device_id}
	pathSegments := strings.Split(r.URL.Path, "/")
	if len(pathSegments) < 5 {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"success": false,
			"message": "设备 ID 不正确",
		})
		return
	}

	deviceID := pathSegments[4]

	deviceMutex.Lock()
	_, exists := deviceRegistry[deviceID]
	if exists {
		delete(deviceRegistry, deviceID)
	}
	deviceMutex.Unlock()

	if !exists {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"success": false,
			"message": "设备不存在",
		})
		return
	}

	// Also remove biometric if registered
	biometricMutex.Lock()
	delete(biometricRegistry, deviceID)
	biometricMutex.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": fmt.Sprintf("设备 %s 已删除", deviceID),
	})
	fmt.Printf("🗑️  Device deleted: %s\n", deviceID)
}

// Helper functions

func isValidPhoneNumber(phone string) bool {
	// Support +86 mainland China (11 digits) and +852 Hong Kong (8 digits)
	if strings.HasPrefix(phone, "+86") {
		digits := strings.TrimPrefix(phone, "+86")
		return len(digits) == 11
	} else if strings.HasPrefix(phone, "+852") {
		digits := strings.TrimPrefix(phone, "+852")
		return len(digits) == 8
	} else if len(phone) == 11 && strings.HasPrefix(phone, "1") {
		// Chinese mainland without +86 prefix
		return true
	}
	return false
}

func generateToken(length int) string {
	b := make([]byte, length)
	rand.Read(b)
	return fmt.Sprintf("%x", b)
}

func generateMockJWT(accountID, deviceID string, ttl time.Duration) string {
	now := time.Now().UTC()
	header := map[string]interface{}{
		"alg": "RS256",
		"typ": "JWT",
	}
	payload := map[string]interface{}{
		"sub":        accountID,
		"account_id": accountID,
		"device_id":  deviceID,
		"iat":        now.Unix(),
		"exp":        now.Add(ttl).Unix(),
		"jti":        "jwt-" + generateToken(8),
	}
	headerBytes, _ := json.Marshal(header)
	payloadBytes, _ := json.Marshal(payload)
	return base64.RawURLEncoding.EncodeToString(headerBytes) + "." +
		base64.RawURLEncoding.EncodeToString(payloadBytes) + ".mock-signature"
}
