/// API endpoint constants.
///
/// All base URLs use environment-aware constants.
/// Override at runtime via --dart-define for different environments.
library;

class ApiConstants {
  ApiConstants._();

  // Base URLs — injected via --dart-define=API_BASE_URL=https://...
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-staging.trading.example.com',
  );

  static const wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://ws-staging.trading.example.com',
  );

  // API version prefix
  static const apiV1 = '/api/v1';

  // Auth endpoints
  static const authSendOtp = '$apiV1/auth/otp/send';
  static const authVerifyOtp = '$apiV1/auth/otp/verify';
  static const authRefreshToken = '$apiV1/auth/token/refresh';
  static const authLogout = '$apiV1/auth/logout';

  // KYC endpoints
  static const kycSubmit = '$apiV1/kyc/submit';
  static const kycDocumentUpload = '$apiV1/kyc/documents';
  static const kycStatus = '$apiV1/kyc/status';

  // Market data endpoints
  static const marketQuotes = '$apiV1/market/quotes';
  static const marketCandles = '$apiV1/market/candles';
  static const marketSearch = '$apiV1/market/search';
  static const marketWatchlist = '$apiV1/market/watchlist';

  // Trading endpoints
  static const ordersSubmit = '$apiV1/orders';
  static const ordersHistory = '$apiV1/orders/history';
  static const ordersCancel = '$apiV1/orders/{orderId}/cancel';

  // Portfolio endpoints
  static const portfolio = '$apiV1/portfolio';
  static const positions = '$apiV1/portfolio/positions';
  static const pnl = '$apiV1/portfolio/pnl';

  // Funding endpoints
  static const deposit = '$apiV1/funding/deposit';
  static const withdraw = '$apiV1/funding/withdraw';
  static const bankAccounts = '$apiV1/funding/bank-accounts';
  static const fundingHistory = '$apiV1/funding/history';

  // Idempotency header name
  static const idempotencyKeyHeader = 'Idempotency-Key';

  // WebSocket channels
  static const wsQuoteChannel = 'quote';
  static const wsOrderChannel = 'order';
}
