/// Application-level constants.
library;

class AppConstants {
  AppConstants._();

  // App identity
  static const appName = 'Trading App';
  static const bundleId = 'com.brokerage.trading.trading_app';

  // Token management
  static const accessTokenTtlMinutes = 15;
  static const refreshTokenTtlDays = 7;
  static const tokenRefreshBufferSeconds = 30;

  // Security
  static const maxLoginAttempts = 5;
  static const loginLockoutMinutes = 5;
  static const biometricKeyAlias = 'trading_app.biometric_key';

  // Fund transfer limits (per compliance rules)
  static const autoApproveWithdrawalLimitUsd = 50000;
  static const autoApproveWithdrawalLimitHkd = 400000;
  static const manualReviewWithdrawalLimitUsd = 200000;
  static const manualReviewWithdrawalLimitHkd = 1500000;

  // Bank account cool-down (days before a new account can be used for withdrawal)
  static const bankAccountCoolDownDays = 3;
  static const bankAccountExtendedCoolDownDays = 7;
  static const maxBankAccountsPerUser = 5;

  // Market data
  static const quoteThrottleMs = 100; // Max 10 fps for watchlist updates
  static const webSocketReconnectDelayMs = 2000;
  static const webSocketMaxReconnectAttempts = 5;

  // UI
  static const defaultAnimationDurationMs = 200;
  static const skeletonShimmerDurationMs = 1200;

  // Decimal precision (per financial-coding-standards)
  static const usPriceDecimalPlaces = 4;
  static const hkPriceDecimalPlaces = 3;
  static const commissionDecimalPlaces = 2;
  static const fxRateDecimalPlaces = 6;
  static const amountDecimalPlaces = 2;

  // AML thresholds (USD)
  static const ctrThresholdUsd = 10000;
  static const ctrThresholdHkd = 120000;
  static const travelRuleThresholdUsd = 3000;
  static const travelRuleThresholdHkd = 8000;
}
