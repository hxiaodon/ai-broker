import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/market/data/remote/market_response_models.dart';

// JSON examples taken verbatim from market-api-spec §3.4, §4.4, §5.4, §6.4,
// §7.4, §10.4 to ensure the DTOs stay in sync with the authoritative spec.

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // QuoteDto
  // ───────────────────────────────────────────────────────────────────────────
  group('QuoteDto.fromJson', () {
    const quoteJson = {
      'symbol': 'AAPL',
      'name': 'Apple Inc.',
      'name_zh': '苹果',
      'market': 'US',
      'price': '182.5200',
      'change': '2.3400',
      'change_pct': '1.30',
      'volume': 45200000,
      'bid': '182.5100',
      'ask': '182.5300',
      'turnover': '8.24B',
      'prev_close': '180.1800',
      'open': '180.5000',
      'high': '183.1200',
      'low': '180.2500',
      'market_cap': '2.80T',
      'pe_ratio': '28.50',
      'delayed': false,
      'market_status': 'REGULAR',
    };

    test('parses all required fields', () {
      final dto = QuoteDto.fromJson(quoteJson);

      expect(dto.symbol, 'AAPL');
      expect(dto.name, 'Apple Inc.');
      expect(dto.nameZh, '苹果');
      expect(dto.market, 'US');
      expect(dto.price, '182.5200');
      expect(dto.change, '2.3400');
      expect(dto.changePct, '1.30');
      expect(dto.volume, 45200000);
      expect(dto.bid, '182.5100');
      expect(dto.ask, '182.5300');
      expect(dto.turnover, '8.24B');
      expect(dto.prevClose, '180.1800');
      expect(dto.open, '180.5000');
      expect(dto.high, '183.1200');
      expect(dto.low, '180.2500');
      expect(dto.marketCap, '2.80T');
      expect(dto.peRatio, '28.50');
      expect(dto.delayed, isFalse);
      expect(dto.marketStatus, 'REGULAR');
    });

    test('defaults is_stale=false when absent (§1.7 spec example omits it)', () {
      final dto = QuoteDto.fromJson(quoteJson);
      expect(dto.isStale, isFalse);
      expect(dto.staleSinceMs, 0);
    });

    test('parses is_stale and stale_since_ms when present', () {
      final json = Map<String, dynamic>.from(quoteJson)
        ..['is_stale'] = true
        ..['stale_since_ms'] = 6200;
      final dto = QuoteDto.fromJson(json);
      expect(dto.isStale, isTrue);
      expect(dto.staleSinceMs, 6200);
    });

    test('bid and ask are nullable — absent when market closed', () {
      final json = Map<String, dynamic>.from(quoteJson)
        ..remove('bid')
        ..remove('ask');
      final dto = QuoteDto.fromJson(json);
      expect(dto.bid, isNull);
      expect(dto.ask, isNull);
    });

    test('pe_ratio is nullable — absent for loss-making stocks', () {
      final json = Map<String, dynamic>.from(quoteJson)..remove('pe_ratio');
      final dto = QuoteDto.fromJson(json);
      expect(dto.peRatio, isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // QuotesResponseDto
  // ───────────────────────────────────────────────────────────────────────────
  group('QuotesResponseDto.fromJson', () {
    test('parses quotes map keyed by symbol', () {
      final json = {
        'quotes': {
          'AAPL': {
            'symbol': 'AAPL',
            'name': 'Apple Inc.',
            'name_zh': '苹果',
            'market': 'US',
            'price': '182.5200',
            'change': '2.3400',
            'change_pct': '1.30',
            'volume': 45200000,
            'bid': '182.5100',
            'ask': '182.5300',
            'turnover': '8.24B',
            'prev_close': '180.1800',
            'open': '180.5000',
            'high': '183.1200',
            'low': '180.2500',
            'market_cap': '2.80T',
            'delayed': false,
            'market_status': 'REGULAR',
          }
        },
        'as_of': '2026-03-13T14:30:00.000Z',
      };

      final dto = QuotesResponseDto.fromJson(json);
      expect(dto.quotes, hasLength(1));
      expect(dto.quotes['AAPL']?.symbol, 'AAPL');
      expect(dto.asOf, '2026-03-13T14:30:00.000Z');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // CandleDto
  // ───────────────────────────────────────────────────────────────────────────
  group('CandleDto.fromJson', () {
    const candleJson = {
      't': '2026-03-13T14:30:00.000Z',
      'o': '181.5000',
      'h': '181.8800',
      'l': '181.4200',
      'c': '181.7500',
      'v': 1250300,
      'n': 8420,
    };

    test('parses all OHLCV fields', () {
      final dto = CandleDto.fromJson(candleJson);
      expect(dto.t, '2026-03-13T14:30:00.000Z');
      expect(dto.o, '181.5000');
      expect(dto.h, '181.8800');
      expect(dto.l, '181.4200');
      expect(dto.c, '181.7500');
      expect(dto.v, 1250300);
      expect(dto.n, 8420);
    });
  });

  group('KlineResponseDto.fromJson', () {
    test('parses candles array and next_cursor', () {
      final json = {
        'symbol': 'AAPL',
        'period': '1d',
        'candles': [
          {
            't': '2026-01-02T14:30:00.000Z',
            'o': '185.0000',
            'h': '187.2500',
            'l': '184.1300',
            'c': '186.8800',
            'v': 48320000,
            'n': 312450,
          }
        ],
        'next_cursor': 'eyJsYXN0X3QiOiIyMDI2LTAxLTAyVDE0OjMwOjAwWiJ9',
        'total': 1,
      };

      final dto = KlineResponseDto.fromJson(json);
      expect(dto.symbol, 'AAPL');
      expect(dto.period, '1d');
      expect(dto.candles, hasLength(1));
      expect(dto.nextCursor, isNotNull);
      expect(dto.total, 1);
    });

    test('next_cursor is null on last page (1min mode)', () {
      final json = {
        'symbol': 'AAPL',
        'period': '1min',
        'candles': [],
        'next_cursor': null,
        'total': 0,
      };
      final dto = KlineResponseDto.fromJson(json);
      expect(dto.nextCursor, isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // SearchResultDto
  // ───────────────────────────────────────────────────────────────────────────
  group('SearchResultDto.fromJson', () {
    test('parses search result fields (§5.4)', () {
      final json = {
        'symbol': 'AAPL',
        'name': 'Apple Inc.',
        'name_zh': '苹果',
        'market': 'US',
        'price': '182.5200',
        'change_pct': '1.30',
        'delayed': true,
      };

      final dto = SearchResultDto.fromJson(json);
      expect(dto.symbol, 'AAPL');
      expect(dto.name, 'Apple Inc.');
      expect(dto.nameZh, '苹果');
      expect(dto.market, 'US');
      expect(dto.price, '182.5200');
      expect(dto.changePct, '1.30');
      expect(dto.delayed, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // MoverItemDto
  // ───────────────────────────────────────────────────────────────────────────
  group('MoverItemDto.fromJson', () {
    test('parses mover item fields (§6.4)', () {
      final json = {
        'rank': 1,
        'symbol': 'NVDA',
        'name': 'NVIDIA Corporation',
        'name_zh': '英伟达',
        'price': '865.2100',
        'change': '52.3300',
        'change_pct': '6.44',
        'volume': 38500000,
        'turnover': '33.31B',
        'market_status': 'REGULAR',
      };

      final dto = MoverItemDto.fromJson(json);
      expect(dto.rank, 1);
      expect(dto.symbol, 'NVDA');
      expect(dto.changePct, '6.44');
      expect(dto.marketStatus, 'REGULAR');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // StockDetailDto
  // ───────────────────────────────────────────────────────────────────────────
  group('StockDetailDto.fromJson', () {
    // Full example from market-api-spec §7.4
    final stockDetailJson = {
      'symbol': 'AAPL',
      'name': 'Apple Inc.',
      'name_zh': '苹果',
      'market': 'US',
      'price': '182.5200',
      'change': '2.3400',
      'change_pct': '1.30',
      'open': '180.5000',
      'high': '183.1200',
      'low': '180.2500',
      'prev_close': '180.1800',
      'volume': 45200000,
      'turnover': '8.24B',
      'bid': '182.5100',
      'ask': '182.5300',
      'delayed': false,
      'market_status': 'REGULAR',
      'session': 'Regular Trading Hours',
      'market_cap': '2.80T',
      'pe_ratio': '28.50',
      'pb_ratio': '42.30',
      'dividend_yield': '0.52',
      'shares_outstanding': 15204137000,
      'avg_volume': 48500000,
      'week52_high': '199.6200',
      'week52_low': '164.0800',
      'turnover_rate': '0.30',
      'exchange': 'NASDAQ',
      'sector': 'Technology',
      'as_of': '2026-03-13T14:30:00.000Z',
    };

    test('parses quote fields', () {
      final dto = StockDetailDto.fromJson(stockDetailJson);
      expect(dto.symbol, 'AAPL');
      expect(dto.price, '182.5200');
      expect(dto.marketStatus, 'REGULAR');
      expect(dto.session, 'Regular Trading Hours');
      expect(dto.delayed, isFalse);
    });

    test('parses fundamental fields', () {
      final dto = StockDetailDto.fromJson(stockDetailJson);
      expect(dto.marketCap, '2.80T');
      expect(dto.peRatio, '28.50');
      expect(dto.pbRatio, '42.30');
      expect(dto.dividendYield, '0.52');
      expect(dto.sharesOutstanding, 15204137000);
      expect(dto.avgVolume, 48500000);
      expect(dto.week52High, '199.6200');
      expect(dto.week52Low, '164.0800');
      expect(dto.turnoverRate, '0.30');
      expect(dto.exchange, 'NASDAQ');
      expect(dto.sector, 'Technology');
      expect(dto.asOf, '2026-03-13T14:30:00.000Z');
    });

    test('defaults is_stale=false when absent', () {
      final dto = StockDetailDto.fromJson(stockDetailJson);
      expect(dto.isStale, isFalse);
      expect(dto.staleSinceMs, 0);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // WatchlistResponseDto
  // ───────────────────────────────────────────────────────────────────────────
  group('WatchlistResponseDto.fromJson', () {
    test('parses symbols list and quotes map (§10.4)', () {
      final json = {
        'symbols': ['AAPL', 'TSLA'],
        'quotes': {
          'AAPL': {
            'symbol': 'AAPL',
            'name': 'Apple Inc.',
            'name_zh': '苹果',
            'market': 'US',
            'price': '182.5200',
            'change': '2.3400',
            'change_pct': '1.30',
            'volume': 45200000,
            'bid': '182.5100',
            'ask': '182.5300',
            'turnover': '8.24B',
            'prev_close': '180.1800',
            'open': '180.5000',
            'high': '183.1200',
            'low': '180.2500',
            'market_cap': '2.80T',
            'delayed': false,
            'market_status': 'REGULAR',
          },
          'TSLA': {
            'symbol': 'TSLA',
            'name': 'Tesla, Inc.',
            'name_zh': '特斯拉',
            'market': 'US',
            'price': '241.3800',
            'change': '-3.2100',
            'change_pct': '-1.31',
            'volume': 52100000,
            'bid': '241.3500',
            'ask': '241.4200',
            'turnover': '12.57B',
            'prev_close': '244.5900',
            'open': '244.0000',
            'high': '245.8800',
            'low': '240.1100',
            'market_cap': '768.00B',
            'delayed': false,
            'market_status': 'REGULAR',
          },
        },
        'as_of': '2026-03-13T14:30:00.000Z',
      };

      final dto = WatchlistResponseDto.fromJson(json);
      expect(dto.symbols, ['AAPL', 'TSLA']);
      expect(dto.quotes, hasLength(2));
      expect(dto.quotes['TSLA']?.price, '241.3800');
    });
  });
}
