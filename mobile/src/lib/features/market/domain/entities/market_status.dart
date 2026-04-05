/// Market status enumeration for US and HK exchanges.
/// Values map 1:1 to the market_status field in market-api-spec §1.4.
enum MarketStatus {
  /// Regular trading hours (NYSE/NASDAQ 9:30–16:00 ET; HKEX 9:30–16:00 HKT).
  regular,

  /// Pre-market trading session (US only).
  preMarket,

  /// After-hours trading session (US only).
  afterHours,

  /// Market closed for the day.
  closed,

  /// Symbol temporarily halted — buy/sell buttons must be disabled.
  halted;

  /// Parse the string value returned by the API.
  /// Unknown values fall back to [closed] as a safe default.
  static MarketStatus fromApi(String value) => switch (value) {
        'REGULAR' => MarketStatus.regular,
        'PRE_MARKET' => MarketStatus.preMarket,
        'AFTER_HOURS' => MarketStatus.afterHours,
        'CLOSED' => MarketStatus.closed,
        'HALTED' => MarketStatus.halted,
        _ => MarketStatus.closed,
      };

  /// Whether trading is currently active for this status.
  bool get isTradingActive =>
      this == MarketStatus.regular ||
      this == MarketStatus.preMarket ||
      this == MarketStatus.afterHours;
}
