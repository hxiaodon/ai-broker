/// Centralized route name constants.
///
/// Use these constants (not raw strings) when calling [context.go()] or
/// [context.push()] to prevent typos and enable refactoring safety.
library;

class RouteNames {
  RouteNames._();

  // Auth
  static const authSplash = '/';
  static const authLogin = '/auth/login';
  static const authOtp = '/auth/otp';
  static const authBiometricSetup = '/auth/biometric-setup';
  static const authBiometricLogin = '/auth/biometric-login';
  static const authDevices = '/auth/devices';

  // Main tab shell
  static const market = '/market';
  static const trading = '/trading';
  static const portfolio = '/portfolio';
  static const funding = '/funding';
  static const settings = '/settings';

  // Market sub-routes
  static const stockDetail = '/market/stock/:symbol';
  static const search = '/market/search';
  static const watchlist = '/market/watchlist';

  // Trading sub-routes
  static const orderEntry = '/trading/order';
  static const tradingOrderConfirm = '/trading/order/confirm';
  static const tradingOrders = '/trading/orders';
  static const orderDetail = '/trading/orders/:orderId';
  static const tradeConfirm = '/trading/confirm';

  // Portfolio sub-routes
  static const positionDetail = '/portfolio/position/:symbol';

  // Funding sub-routes
  static const deposit = '/funding/deposit';
  static const withdraw = '/funding/withdraw';
  static const bankAccountBind = '/funding/bank/bind';
  static const fundingMicroDeposit = '/funding/bank/:bankId/micro-deposit';

  // KYC (typically launched modally from auth or settings)
  static const kycRoot = '/kyc';
  static const kycStep1 = '/kyc/personal-info';
  static const kycStep2 = '/kyc/documents';
  static const kycStep3 = '/kyc/address';
  static const kycStep4 = '/kyc/employment';
  static const kycStep5 = '/kyc/investment-profile';
  static const kycStep6 = '/kyc/risk-disclosure';
  static const kycStep7 = '/kyc/agreement';

  // Settings sub-routes
  static const securitySettings = '/settings/security';
  static const notificationSettings = '/settings/notifications';
  static const colorSchemeSettings = '/settings/color-scheme';
  static const profile = '/settings/profile';
  static const helpCenter = '/settings/help';
}
