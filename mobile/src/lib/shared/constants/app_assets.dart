/// Centralized asset path constants.
///
/// All asset paths in the app must be referenced via this class.
/// Never hardcode asset strings directly in widgets.
///
/// Asset delivery status:
///   ✅ = Placeholder SVG in place (replace with designer-delivered file)
///   🔴 = Critical path — needed for current feature
///   🟡 = Needed before feature ships
abstract final class AppAssets {
  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------

  /// App logo — splash screen and onboarding header. ✅ placeholder
  static const String appLogo = 'assets/logos/app-logo.svg';

  // ---------------------------------------------------------------------------
  // Navigation Tab Icons
  // All use currentColor — color controlled by NavigationBar theme.
  // ---------------------------------------------------------------------------

  static const String tabMarketOutline = 'assets/icons/nav/tab-market-outline.svg';
  static const String tabMarketFilled = 'assets/icons/nav/tab-market-filled.svg';
  static const String tabTradingOutline = 'assets/icons/nav/tab-trading-outline.svg';
  static const String tabTradingFilled = 'assets/icons/nav/tab-trading-filled.svg';
  static const String tabPortfolioOutline = 'assets/icons/nav/tab-portfolio-outline.svg';
  static const String tabPortfolioFilled = 'assets/icons/nav/tab-portfolio-filled.svg';
  static const String tabSettingsOutline = 'assets/icons/nav/tab-settings-outline.svg';
  static const String tabSettingsFilled = 'assets/icons/nav/tab-settings-filled.svg';

  /// Notification badge dot (8×8). Stack over tab icon. ✅
  static const String tabBadgeDot = 'assets/icons/nav/tab-badge-dot.svg';

  // ---------------------------------------------------------------------------
  // System Icons (24×24 viewBox)
  // ---------------------------------------------------------------------------

  static const String iconSearch = 'assets/icons/system/search.svg';
  static const String iconChevronRight = 'assets/icons/system/chevron-right.svg';
  static const String iconChevronDown = 'assets/icons/system/chevron-down.svg';
  static const String iconClose = 'assets/icons/system/close.svg';
  static const String iconCheck = 'assets/icons/system/check.svg';
  static const String iconAlert = 'assets/icons/system/alert.svg';
  static const String iconInfoCircle = 'assets/icons/system/info-circle.svg';

  // ---------------------------------------------------------------------------
  // KYC Flow Icons (24×24 viewBox)
  // ---------------------------------------------------------------------------

  static const String kycIdCard = 'assets/icons/kyc/id-card.svg';
  static const String kycDocumentUpload = 'assets/icons/kyc/document-upload.svg';
  static const String kycLocationMap = 'assets/icons/kyc/location-map.svg';
  static const String kycWallet = 'assets/icons/kyc/wallet.svg';
  static const String kycChartLine = 'assets/icons/kyc/chart-line.svg';
  static const String kycTaxDocument = 'assets/icons/kyc/tax-document.svg';
  static const String kycShieldAlert = 'assets/icons/kyc/shield-alert.svg';
  static const String kycHandshake = 'assets/icons/kyc/handshake.svg';

  /// Document scan viewfinder overlays.
  /// Use as a full-screen overlay on top of camera preview.
  static const String kycScanOverlayId = 'assets/icons/kyc/doc-scan-overlay-id.svg';
  static const String kycScanOverlayPassport = 'assets/icons/kyc/doc-scan-overlay-passport.svg';
  static const String kycScanOverlayHkid = 'assets/icons/kyc/doc-scan-overlay-hkid.svg';

  // ---------------------------------------------------------------------------
  // Trading Icons (24×24 viewBox)
  // ---------------------------------------------------------------------------

  static const String tradingArrowUp = 'assets/icons/trading/arrow-up.svg';
  static const String tradingArrowDown = 'assets/icons/trading/arrow-down.svg';
  static const String tradingCheckCircle = 'assets/icons/trading/check-circle.svg';
  static const String tradingClock = 'assets/icons/trading/clock.svg';
  static const String tradingXCircle = 'assets/icons/trading/x-circle.svg';

  // ---------------------------------------------------------------------------
  // Funding Icons (24×24 viewBox)
  // ---------------------------------------------------------------------------

  static const String fundingBank = 'assets/icons/funding/bank.svg';
  static const String fundingCreditCard = 'assets/icons/funding/credit-card.svg';
  static const String fundingDeposit = 'assets/icons/funding/arrow-down-from-bank.svg';
  static const String fundingWithdraw = 'assets/icons/funding/arrow-up-to-bank.svg';

  // ---------------------------------------------------------------------------
  // Market Icons (24×24 viewBox)
  // ---------------------------------------------------------------------------

  static const String marketCandlestick = 'assets/icons/market/chart-candlestick.svg';
  static const String marketTrendUp = 'assets/icons/market/trend-up.svg';
  static const String marketTrendDown = 'assets/icons/market/trend-down.svg';
  static const String marketStar = 'assets/icons/market/star.svg';
  static const String marketStarFilled = 'assets/icons/market/star-filled.svg';

  /// Exchange badge chips (variable width, 18px height).
  static const String badgeNyse = 'assets/icons/market/badge-nyse.svg';
  static const String badgeNasdaq = 'assets/icons/market/badge-nasdaq.svg';
  static const String badgeHkex = 'assets/icons/market/badge-hkex.svg';

  /// Market flag icons (20×14).
  static const String flagUs = 'assets/icons/market/flag-us.svg';
  static const String flagHk = 'assets/icons/market/flag-hk.svg';

  // ---------------------------------------------------------------------------
  // Account / Settings Icons (24×24 viewBox)
  // ---------------------------------------------------------------------------

  static const String accountUser = 'assets/icons/account/user.svg';
  static const String accountShieldCheck = 'assets/icons/account/shield-check.svg';
  static const String accountBell = 'assets/icons/account/bell.svg';
  static const String accountLanguage = 'assets/icons/account/language.svg';
  static const String accountMoon = 'assets/icons/account/moon.svg';
  static const String accountSun = 'assets/icons/account/sun.svg';
  static const String accountEdit = 'assets/icons/account/edit.svg';
  static const String accountTrash = 'assets/icons/account/trash.svg';

  // ---------------------------------------------------------------------------
  // Illustrations (240×160 placeholder, replace with designer SVG/PNG)
  // ---------------------------------------------------------------------------

  static const String illusOnboardingMarket = 'assets/illustrations/onboarding/market.svg';
  static const String illusOnboardingTrade = 'assets/illustrations/onboarding/trade.svg';
  static const String illusOnboardingPortfolio = 'assets/illustrations/onboarding/portfolio.svg';

  static const String illusEmptyOrders = 'assets/illustrations/empty-states/no-orders.svg';
  static const String illusEmptyHoldings = 'assets/illustrations/empty-states/no-holdings.svg';
  static const String illusEmptyNotifications = 'assets/illustrations/empty-states/no-notifications.svg';
  static const String illusEmptyWatchlist = 'assets/illustrations/empty-states/no-watchlist.svg';
  static const String illusEmptySearch = 'assets/illustrations/empty-states/no-search-result.svg';

  static const String illusKycReviewing = 'assets/illustrations/kyc-status/reviewing.svg';
  static const String illusKycApproved = 'assets/illustrations/kyc-status/approved.svg';
  static const String illusKycRejected = 'assets/illustrations/kyc-status/rejected.svg';

  static const String illusSuccess = 'assets/illustrations/result-states/success-checkmark.svg';
  static const String illusError = 'assets/illustrations/result-states/error-alert.svg';

  // ---------------------------------------------------------------------------
  // Motion / Rive Animations (.riv)
  // Placeholder files present; replace with .riv from designer.
  // ---------------------------------------------------------------------------

  /// Order submission success animation (play once, ~1.5s).
  static const String motionOrderSuccess = 'assets/motion/order-success.riv';

  /// Order submission failure animation (play once, ~1.0s).
  static const String motionOrderFailed = 'assets/motion/order-failed.riv';

  /// KYC under-review looping animation.
  static const String motionKycReviewing = 'assets/motion/kyc-reviewing.riv';

  /// KYC approved celebration animation (play once, ~2.0s).
  static const String motionKycApproved = 'assets/motion/kyc-approved.riv';

  /// Biometric scanning loop animation.
  static const String motionBiometricScan = 'assets/motion/biometric-scan.riv';

  /// Global loading spinner loop animation.
  static const String motionLoadingSpinner = 'assets/motion/loading-spinner.riv';

  // ---------------------------------------------------------------------------
  // Avatars
  // ---------------------------------------------------------------------------

  /// Default avatar for users who haven't set a profile photo. ✅
  static const String avatarPlaceholder = 'assets/avatars/avatar-placeholder.svg';

  // ---------------------------------------------------------------------------
  // Stock
  // ---------------------------------------------------------------------------

  /// Fallback when stock logo URL fails to load. ✅
  static const String stockLogoPlaceholder = 'assets/stock/stock-logo-placeholder.svg';
}
