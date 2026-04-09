import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/data/mappers/market_mappers.dart';
import 'package:trading_app/features/market/data/remote/market_response_models.dart';
import 'package:trading_app/features/market/domain/entities/market_status.dart';

// Helper: build a minimal valid QuoteDto with sensible defaults.
QuoteDto _makeQuoteDto({
  String symbol = 'AAPL',
  String price = '182.5200',
  String change = '2.3400',
  String changePct = '1.30',
  int volume = 45200000,
  String? bid = '182.5100',
  String? ask = '182.5300',
  String prevClose = '180.1800',
  String open = '180.5000',
  String high = '183.1200',
  String low = '180.2500',
  bool delayed = false,
  String marketStatus = 'REGULAR',
  bool isStale = false,
  int staleSinceMs = 0,
  String? peRatio = '28.50',
}) =>
    QuoteDto(
      symbol: symbol,
      name: 'Apple Inc.',
      nameZh: '苹果',
      market: 'US',
      price: price,
      change: change,
      changePct: changePct,
      volume: volume,
      bid: bid,
      ask: ask,
      turnover: '8.24B',
      prevClose: prevClose,
      open: open,
      high: high,
      low: low,
      marketCap: '2.80T',
      peRatio: peRatio,
      delayed: delayed,
      marketStatus: marketStatus,
      isStale: isStale,
      staleSinceMs: staleSinceMs,
    );

void main() {
  setUpAll(() {
    AppLogger.init();
  });

  // ───────────────────────────────────────────────────────────────────────────
  // QuoteDto → Quote
  // ───────────────────────────────────────────────────────────────────────────
  group('QuoteDtoMapper.toDomain', () {
    test('converts all price strings to Decimal', () {
      final quote = _makeQuoteDto().toDomain();

      expect(quote.price, Decimal.parse('182.5200'));
      expect(quote.change, Decimal.parse('2.3400'));
      expect(quote.changePct, Decimal.parse('1.30'));
      expect(quote.prevClose, Decimal.parse('180.1800'));
      expect(quote.open, Decimal.parse('180.5000'));
      expect(quote.high, Decimal.parse('183.1200'));
      expect(quote.low, Decimal.parse('180.2500'));
    });

    test('converts bid/ask strings to Decimal', () {
      final quote = _makeQuoteDto(bid: '182.5100', ask: '182.5300').toDomain();
      expect(quote.bid, Decimal.parse('182.5100'));
      expect(quote.ask, Decimal.parse('182.5300'));
    });

    test('nullable bid/ask — null when absent (market closed)', () {
      final quote = _makeQuoteDto(bid: null, ask: null).toDomain();
      expect(quote.bid, isNull);
      expect(quote.ask, isNull);
    });

    test('converts marketStatus string to enum', () {
      expect(_makeQuoteDto(marketStatus: 'REGULAR').toDomain().marketStatus,
          MarketStatus.regular);
      expect(_makeQuoteDto(marketStatus: 'PRE_MARKET').toDomain().marketStatus,
          MarketStatus.preMarket);
      expect(_makeQuoteDto(marketStatus: 'AFTER_HOURS').toDomain().marketStatus,
          MarketStatus.afterHours);
      expect(_makeQuoteDto(marketStatus: 'CLOSED').toDomain().marketStatus,
          MarketStatus.closed);
      expect(_makeQuoteDto(marketStatus: 'HALTED').toDomain().marketStatus,
          MarketStatus.halted);
    });

    test('preserves isStale and staleSinceMs', () {
      final quote =
          _makeQuoteDto(isStale: true, staleSinceMs: 3500).toDomain();
      expect(quote.isStale, isTrue);
      expect(quote.staleSinceMs, 3500);
    });

    test('nullable peRatio propagated to domain', () {
      expect(_makeQuoteDto(peRatio: null).toDomain().peRatio, isNull);
      expect(_makeQuoteDto(peRatio: '28.50').toDomain().peRatio, '28.50');
    });

    test('negative change parsed correctly', () {
      final quote = _makeQuoteDto(change: '-3.2100', changePct: '-1.31').toDomain();
      expect(quote.change, Decimal.parse('-3.2100'));
      expect(quote.changePct, Decimal.parse('-1.31'));
    });

    test('invalid price string returns Decimal.zero and logs warning', () {
      // _d() logs a warning and returns Decimal.zero for invalid strings.
      // This prevents crashes on malformed API data.
      final quote = _makeQuoteDto(price: 'N/A').toDomain();
      expect(quote.price, Decimal.zero);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Quote.showStaleWarning  (domain computed property)
  // ───────────────────────────────────────────────────────────────────────────
  group('Quote.showStaleWarning', () {
    test('false when isStale=false regardless of staleSinceMs', () {
      expect(
        _makeQuoteDto(isStale: false, staleSinceMs: 9999).toDomain().showStaleWarning,
        isFalse,
      );
    });

    test('false when isStale=true but staleSinceMs < 5000', () {
      expect(
        _makeQuoteDto(isStale: true, staleSinceMs: 4999).toDomain().showStaleWarning,
        isFalse,
      );
    });

    test('true when isStale=true and staleSinceMs == 5000 (boundary)', () {
      expect(
        _makeQuoteDto(isStale: true, staleSinceMs: 5000).toDomain().showStaleWarning,
        isTrue,
      );
    });

    test('true when isStale=true and staleSinceMs > 5000', () {
      expect(
        _makeQuoteDto(isStale: true, staleSinceMs: 30000).toDomain().showStaleWarning,
        isTrue,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // CandleDto → Candle
  // ───────────────────────────────────────────────────────────────────────────
  group('CandleDtoMapper.toDomain', () {
    const dto = CandleDto(
      t: '2026-03-13T14:30:00.000Z',
      o: '181.5000',
      h: '181.8800',
      l: '181.4200',
      c: '181.7500',
      v: 1250300,
      n: 8420,
    );

    test('parses timestamp to UTC DateTime', () {
      final candle = dto.toDomain();
      expect(candle.t, DateTime.utc(2026, 3, 13, 14, 30, 0));
      expect(candle.t.isUtc, isTrue);
    });

    test('converts OHLC strings to Decimal', () {
      final candle = dto.toDomain();
      expect(candle.o, Decimal.parse('181.5000'));
      expect(candle.h, Decimal.parse('181.8800'));
      expect(candle.l, Decimal.parse('181.4200'));
      expect(candle.c, Decimal.parse('181.7500'));
    });

    test('preserves int fields v and n', () {
      final candle = dto.toDomain();
      expect(candle.v, 1250300);
      expect(candle.n, 8420);
    });

    test('list mapper converts all candles', () {
      final candles = [dto, dto].toDomainList();
      expect(candles, hasLength(2));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // SearchResultDto → SearchResult
  // ───────────────────────────────────────────────────────────────────────────
  group('SearchResultDtoMapper.toDomain', () {
    const dto = SearchResultDto(
      symbol: 'AAPL',
      name: 'Apple Inc.',
      nameZh: '苹果',
      market: 'US',
      price: '182.5200',
      changePct: '1.30',
      delayed: true,
    );

    test('converts price and changePct to Decimal', () {
      final result = dto.toDomain();
      expect(result.price, Decimal.parse('182.5200'));
      expect(result.changePct, Decimal.parse('1.30'));
    });

    test('preserves string and bool fields', () {
      final result = dto.toDomain();
      expect(result.symbol, 'AAPL');
      expect(result.nameZh, '苹果');
      expect(result.delayed, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // MoverItemDto → MoverItem
  // ───────────────────────────────────────────────────────────────────────────
  group('MoverItemDtoMapper.toDomain', () {
    const dto = MoverItemDto(
      rank: 1,
      symbol: 'NVDA',
      name: 'NVIDIA Corporation',
      nameZh: '英伟达',
      price: '865.2100',
      change: '52.3300',
      changePct: '6.44',
      volume: 38500000,
      turnover: '33.31B',
      marketStatus: 'REGULAR',
    );

    test('converts price/change/changePct to Decimal', () {
      final item = dto.toDomain();
      expect(item.price, Decimal.parse('865.2100'));
      expect(item.change, Decimal.parse('52.3300'));
      expect(item.changePct, Decimal.parse('6.44'));
    });

    test('converts marketStatus string to enum', () {
      expect(dto.toDomain().marketStatus, MarketStatus.regular);
    });

    test('preserves rank and int fields', () {
      final item = dto.toDomain();
      expect(item.rank, 1);
      expect(item.volume, 38500000);
      expect(item.turnover, '33.31B');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // StockDetailDto → StockDetail
  // ───────────────────────────────────────────────────────────────────────────
  group('StockDetailDtoMapper.toDomain', () {
    final dto = StockDetailDto(
      symbol: 'AAPL',
      name: 'Apple Inc.',
      nameZh: '苹果',
      market: 'US',
      price: '182.5200',
      change: '2.3400',
      changePct: '1.30',
      open: '180.5000',
      high: '183.1200',
      low: '180.2500',
      prevClose: '180.1800',
      volume: 45200000,
      turnover: '8.24B',
      bid: '182.5100',
      ask: '182.5300',
      delayed: false,
      marketStatus: 'REGULAR',
      session: 'Regular Trading Hours',
      marketCap: '2.80T',
      peRatio: '28.50',
      pbRatio: '42.30',
      dividendYield: '0.52',
      sharesOutstanding: 15204137000,
      avgVolume: 48500000,
      week52High: '199.6200',
      week52Low: '164.0800',
      turnoverRate: '0.30',
      exchange: 'NASDAQ',
      sector: 'Technology',
      asOf: '2026-03-13T14:30:00.000Z',
    );

    test('converts fundamental Decimal fields', () {
      final detail = dto.toDomain();
      expect(detail.week52High, Decimal.parse('199.6200'));
      expect(detail.week52Low, Decimal.parse('164.0800'));
      expect(detail.turnoverRate, Decimal.parse('0.30'));
    });

    test('parses asOf timestamp to UTC DateTime', () {
      final detail = dto.toDomain();
      expect(detail.asOf, DateTime.utc(2026, 3, 13, 14, 30, 0));
      expect(detail.asOf.isUtc, isTrue);
    });

    test('showStaleWarning reflects isStale + staleSinceMs threshold', () {
      final staleDto = StockDetailDto(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        nameZh: '苹果',
        market: 'US',
        price: '182.5200',
        change: '2.3400',
        changePct: '1.30',
        open: '180.5000',
        high: '183.1200',
        low: '180.2500',
        prevClose: '180.1800',
        volume: 45200000,
        turnover: '8.24B',
        delayed: false,
        marketStatus: 'REGULAR',
        session: 'Regular Trading Hours',
        marketCap: '2.80T',
        peRatio: '28.50',
        pbRatio: '42.30',
        dividendYield: '0.52',
        sharesOutstanding: 15204137000,
        avgVolume: 48500000,
        week52High: '199.6200',
        week52Low: '164.0800',
        turnoverRate: '0.30',
        exchange: 'NASDAQ',
        sector: 'Technology',
        asOf: '2026-03-13T14:30:00.000Z',
        isStale: true,
        staleSinceMs: 5000,
      );
      expect(staleDto.toDomain().showStaleWarning, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // WatchlistResponseDto → Watchlist  (ordered List<Quote>)
  // ───────────────────────────────────────────────────────────────────────────
  group('WatchlistResponseDtoMapper.toDomain', () {
    QuoteDto q(String symbol, String price) => QuoteDto(
          symbol: symbol,
          name: '$symbol Inc.',
          nameZh: symbol,
          market: 'US',
          price: price,
          change: '0.0000',
          changePct: '0.00',
          volume: 1000000,
          turnover: '1.00B',
          prevClose: price,
          open: price,
          high: price,
          low: price,
          marketCap: '1.00T',
          delayed: false,
          marketStatus: 'REGULAR',
        );

    test('returns quotes in symbols list order', () {
      final dto = WatchlistResponseDto(
        symbols: ['TSLA', 'AAPL', 'NVDA'],
        quotes: {
          'AAPL': q('AAPL', '182.5200'),
          'NVDA': q('NVDA', '865.2100'),
          'TSLA': q('TSLA', '241.3800'),
        },
        asOf: '2026-03-13T14:30:00.000Z',
      );

      final watchlist = dto.toDomain();
      expect(watchlist.map((q) => q.symbol).toList(), ['TSLA', 'AAPL', 'NVDA']);
    });

    test('skips symbols missing from quotes map', () {
      final dto = WatchlistResponseDto(
        symbols: ['AAPL', 'MISSING'],
        quotes: {'AAPL': q('AAPL', '182.5200')},
        asOf: '2026-03-13T14:30:00.000Z',
      );

      final watchlist = dto.toDomain();
      expect(watchlist, hasLength(1));
      expect(watchlist.first.symbol, 'AAPL');
    });

    test('empty symbols list returns empty watchlist', () {
      final dto = WatchlistResponseDto(
        symbols: [],
        quotes: {},
        asOf: '2026-03-13T14:30:00.000Z',
      );
      expect(dto.toDomain(), isEmpty);
    });
  });
}
