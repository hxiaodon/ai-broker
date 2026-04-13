// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $QuoteCachesTable extends QuoteCaches
    with TableInfo<$QuoteCachesTable, QuoteCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuoteCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _marketMeta = const VerificationMeta('market');
  @override
  late final GeneratedColumn<String> market = GeneratedColumn<String>(
    'market',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameZhMeta = const VerificationMeta('nameZh');
  @override
  late final GeneratedColumn<String> nameZh = GeneratedColumn<String>(
    'name_zh',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<String> price = GeneratedColumn<String>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changeMeta = const VerificationMeta('change');
  @override
  late final GeneratedColumn<String> change = GeneratedColumn<String>(
    'change',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changePctMeta = const VerificationMeta(
    'changePct',
  );
  @override
  late final GeneratedColumn<String> changePct = GeneratedColumn<String>(
    'change_pct',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<int> volume = GeneratedColumn<int>(
    'volume',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bidMeta = const VerificationMeta('bid');
  @override
  late final GeneratedColumn<String> bid = GeneratedColumn<String>(
    'bid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _askMeta = const VerificationMeta('ask');
  @override
  late final GeneratedColumn<String> ask = GeneratedColumn<String>(
    'ask',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _turnoverMeta = const VerificationMeta(
    'turnover',
  );
  @override
  late final GeneratedColumn<String> turnover = GeneratedColumn<String>(
    'turnover',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prevCloseMeta = const VerificationMeta(
    'prevClose',
  );
  @override
  late final GeneratedColumn<String> prevClose = GeneratedColumn<String>(
    'prev_close',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openMeta = const VerificationMeta('open');
  @override
  late final GeneratedColumn<String> open = GeneratedColumn<String>(
    'open',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _highMeta = const VerificationMeta('high');
  @override
  late final GeneratedColumn<String> high = GeneratedColumn<String>(
    'high',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lowMeta = const VerificationMeta('low');
  @override
  late final GeneratedColumn<String> low = GeneratedColumn<String>(
    'low',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _marketCapMeta = const VerificationMeta(
    'marketCap',
  );
  @override
  late final GeneratedColumn<String> marketCap = GeneratedColumn<String>(
    'market_cap',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peRatioMeta = const VerificationMeta(
    'peRatio',
  );
  @override
  late final GeneratedColumn<String> peRatio = GeneratedColumn<String>(
    'pe_ratio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _delayedMeta = const VerificationMeta(
    'delayed',
  );
  @override
  late final GeneratedColumn<bool> delayed = GeneratedColumn<bool>(
    'delayed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("delayed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _marketStatusMeta = const VerificationMeta(
    'marketStatus',
  );
  @override
  late final GeneratedColumn<String> marketStatus = GeneratedColumn<String>(
    'market_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isStaleMeta = const VerificationMeta(
    'isStale',
  );
  @override
  late final GeneratedColumn<bool> isStale = GeneratedColumn<bool>(
    'is_stale',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_stale" IN (0, 1))',
    ),
    defaultValue: Constant(false),
  );
  static const VerificationMeta _staleSinceMsMeta = const VerificationMeta(
    'staleSinceMs',
  );
  @override
  late final GeneratedColumn<int> staleSinceMs = GeneratedColumn<int>(
    'stale_since_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: Constant(0),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<String> cachedAt = GeneratedColumn<String>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    symbol,
    market,
    name,
    nameZh,
    price,
    change,
    changePct,
    volume,
    bid,
    ask,
    turnover,
    prevClose,
    open,
    high,
    low,
    marketCap,
    peRatio,
    delayed,
    marketStatus,
    isStale,
    staleSinceMs,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quote_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuoteCache> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('market')) {
      context.handle(
        _marketMeta,
        market.isAcceptableOrUnknown(data['market']!, _marketMeta),
      );
    } else if (isInserting) {
      context.missing(_marketMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_zh')) {
      context.handle(
        _nameZhMeta,
        nameZh.isAcceptableOrUnknown(data['name_zh']!, _nameZhMeta),
      );
    } else if (isInserting) {
      context.missing(_nameZhMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('change')) {
      context.handle(
        _changeMeta,
        change.isAcceptableOrUnknown(data['change']!, _changeMeta),
      );
    } else if (isInserting) {
      context.missing(_changeMeta);
    }
    if (data.containsKey('change_pct')) {
      context.handle(
        _changePctMeta,
        changePct.isAcceptableOrUnknown(data['change_pct']!, _changePctMeta),
      );
    } else if (isInserting) {
      context.missing(_changePctMeta);
    }
    if (data.containsKey('volume')) {
      context.handle(
        _volumeMeta,
        volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeMeta);
    }
    if (data.containsKey('bid')) {
      context.handle(
        _bidMeta,
        bid.isAcceptableOrUnknown(data['bid']!, _bidMeta),
      );
    }
    if (data.containsKey('ask')) {
      context.handle(
        _askMeta,
        ask.isAcceptableOrUnknown(data['ask']!, _askMeta),
      );
    }
    if (data.containsKey('turnover')) {
      context.handle(
        _turnoverMeta,
        turnover.isAcceptableOrUnknown(data['turnover']!, _turnoverMeta),
      );
    } else if (isInserting) {
      context.missing(_turnoverMeta);
    }
    if (data.containsKey('prev_close')) {
      context.handle(
        _prevCloseMeta,
        prevClose.isAcceptableOrUnknown(data['prev_close']!, _prevCloseMeta),
      );
    } else if (isInserting) {
      context.missing(_prevCloseMeta);
    }
    if (data.containsKey('open')) {
      context.handle(
        _openMeta,
        open.isAcceptableOrUnknown(data['open']!, _openMeta),
      );
    } else if (isInserting) {
      context.missing(_openMeta);
    }
    if (data.containsKey('high')) {
      context.handle(
        _highMeta,
        high.isAcceptableOrUnknown(data['high']!, _highMeta),
      );
    } else if (isInserting) {
      context.missing(_highMeta);
    }
    if (data.containsKey('low')) {
      context.handle(
        _lowMeta,
        low.isAcceptableOrUnknown(data['low']!, _lowMeta),
      );
    } else if (isInserting) {
      context.missing(_lowMeta);
    }
    if (data.containsKey('market_cap')) {
      context.handle(
        _marketCapMeta,
        marketCap.isAcceptableOrUnknown(data['market_cap']!, _marketCapMeta),
      );
    } else if (isInserting) {
      context.missing(_marketCapMeta);
    }
    if (data.containsKey('pe_ratio')) {
      context.handle(
        _peRatioMeta,
        peRatio.isAcceptableOrUnknown(data['pe_ratio']!, _peRatioMeta),
      );
    }
    if (data.containsKey('delayed')) {
      context.handle(
        _delayedMeta,
        delayed.isAcceptableOrUnknown(data['delayed']!, _delayedMeta),
      );
    } else if (isInserting) {
      context.missing(_delayedMeta);
    }
    if (data.containsKey('market_status')) {
      context.handle(
        _marketStatusMeta,
        marketStatus.isAcceptableOrUnknown(
          data['market_status']!,
          _marketStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_marketStatusMeta);
    }
    if (data.containsKey('is_stale')) {
      context.handle(
        _isStaleMeta,
        isStale.isAcceptableOrUnknown(data['is_stale']!, _isStaleMeta),
      );
    }
    if (data.containsKey('stale_since_ms')) {
      context.handle(
        _staleSinceMsMeta,
        staleSinceMs.isAcceptableOrUnknown(
          data['stale_since_ms']!,
          _staleSinceMsMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbol, market};
  @override
  QuoteCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuoteCache(
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      market: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}market'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameZh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_zh'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price'],
      )!,
      change: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change'],
      )!,
      changePct: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change_pct'],
      )!,
      volume: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}volume'],
      )!,
      bid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bid'],
      ),
      ask: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ask'],
      ),
      turnover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turnover'],
      )!,
      prevClose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prev_close'],
      )!,
      open: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}open'],
      )!,
      high: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}high'],
      )!,
      low: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}low'],
      )!,
      marketCap: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}market_cap'],
      )!,
      peRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pe_ratio'],
      ),
      delayed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}delayed'],
      )!,
      marketStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}market_status'],
      )!,
      isStale: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_stale'],
      )!,
      staleSinceMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stale_since_ms'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $QuoteCachesTable createAlias(String alias) {
    return $QuoteCachesTable(attachedDatabase, alias);
  }
}

class QuoteCache extends DataClass implements Insertable<QuoteCache> {
  /// Stock symbol (e.g., 'AAPL', '00700')
  final String symbol;

  /// Market: "US" or "HK"
  final String market;

  /// Company name (English)
  final String name;

  /// Company name (Chinese). Empty string if not available.
  final String nameZh;

  /// Latest trade price (stored as string to preserve Decimal precision)
  final String price;

  /// Price change vs previous close
  final String change;

  /// Percentage change (2 decimal places)
  final String changePct;

  /// Daily volume (in shares)
  final int volume;

  /// Best bid price. Null when market closed.
  final String? bid;

  /// Best ask price. Null when market closed.
  final String? ask;

  /// Daily turnover (with unit suffix, e.g., "8.24B")
  final String turnover;

  /// Previous regular-session close
  final String prevClose;

  /// Daily open price
  final String open;

  /// Daily high price
  final String high;

  /// Daily low price
  final String low;

  /// Market cap (with unit suffix, e.g., "2.80T")
  final String marketCap;

  /// P/E ratio (TTM). Null for stocks with no earnings.
  final String? peRatio;

  /// True if quote is delayed 15 minutes (guest user)
  final bool delayed;

  /// Current market trading status ("PRE", "TRADING", "AFTER", "CLOSED")
  final String marketStatus;

  /// True when data has not been refreshed within 1 second
  final bool isStale;

  /// Duration in milliseconds that quote has been stale
  final int staleSinceMs;

  /// Timestamp when this cache was last updated (UTC, ISO8601)
  final String cachedAt;
  const QuoteCache({
    required this.symbol,
    required this.market,
    required this.name,
    required this.nameZh,
    required this.price,
    required this.change,
    required this.changePct,
    required this.volume,
    this.bid,
    this.ask,
    required this.turnover,
    required this.prevClose,
    required this.open,
    required this.high,
    required this.low,
    required this.marketCap,
    this.peRatio,
    required this.delayed,
    required this.marketStatus,
    required this.isStale,
    required this.staleSinceMs,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    map['market'] = Variable<String>(market);
    map['name'] = Variable<String>(name);
    map['name_zh'] = Variable<String>(nameZh);
    map['price'] = Variable<String>(price);
    map['change'] = Variable<String>(change);
    map['change_pct'] = Variable<String>(changePct);
    map['volume'] = Variable<int>(volume);
    if (!nullToAbsent || bid != null) {
      map['bid'] = Variable<String>(bid);
    }
    if (!nullToAbsent || ask != null) {
      map['ask'] = Variable<String>(ask);
    }
    map['turnover'] = Variable<String>(turnover);
    map['prev_close'] = Variable<String>(prevClose);
    map['open'] = Variable<String>(open);
    map['high'] = Variable<String>(high);
    map['low'] = Variable<String>(low);
    map['market_cap'] = Variable<String>(marketCap);
    if (!nullToAbsent || peRatio != null) {
      map['pe_ratio'] = Variable<String>(peRatio);
    }
    map['delayed'] = Variable<bool>(delayed);
    map['market_status'] = Variable<String>(marketStatus);
    map['is_stale'] = Variable<bool>(isStale);
    map['stale_since_ms'] = Variable<int>(staleSinceMs);
    map['cached_at'] = Variable<String>(cachedAt);
    return map;
  }

  QuoteCachesCompanion toCompanion(bool nullToAbsent) {
    return QuoteCachesCompanion(
      symbol: Value(symbol),
      market: Value(market),
      name: Value(name),
      nameZh: Value(nameZh),
      price: Value(price),
      change: Value(change),
      changePct: Value(changePct),
      volume: Value(volume),
      bid: bid == null && nullToAbsent ? const Value.absent() : Value(bid),
      ask: ask == null && nullToAbsent ? const Value.absent() : Value(ask),
      turnover: Value(turnover),
      prevClose: Value(prevClose),
      open: Value(open),
      high: Value(high),
      low: Value(low),
      marketCap: Value(marketCap),
      peRatio: peRatio == null && nullToAbsent
          ? const Value.absent()
          : Value(peRatio),
      delayed: Value(delayed),
      marketStatus: Value(marketStatus),
      isStale: Value(isStale),
      staleSinceMs: Value(staleSinceMs),
      cachedAt: Value(cachedAt),
    );
  }

  factory QuoteCache.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuoteCache(
      symbol: serializer.fromJson<String>(json['symbol']),
      market: serializer.fromJson<String>(json['market']),
      name: serializer.fromJson<String>(json['name']),
      nameZh: serializer.fromJson<String>(json['nameZh']),
      price: serializer.fromJson<String>(json['price']),
      change: serializer.fromJson<String>(json['change']),
      changePct: serializer.fromJson<String>(json['changePct']),
      volume: serializer.fromJson<int>(json['volume']),
      bid: serializer.fromJson<String?>(json['bid']),
      ask: serializer.fromJson<String?>(json['ask']),
      turnover: serializer.fromJson<String>(json['turnover']),
      prevClose: serializer.fromJson<String>(json['prevClose']),
      open: serializer.fromJson<String>(json['open']),
      high: serializer.fromJson<String>(json['high']),
      low: serializer.fromJson<String>(json['low']),
      marketCap: serializer.fromJson<String>(json['marketCap']),
      peRatio: serializer.fromJson<String?>(json['peRatio']),
      delayed: serializer.fromJson<bool>(json['delayed']),
      marketStatus: serializer.fromJson<String>(json['marketStatus']),
      isStale: serializer.fromJson<bool>(json['isStale']),
      staleSinceMs: serializer.fromJson<int>(json['staleSinceMs']),
      cachedAt: serializer.fromJson<String>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'market': serializer.toJson<String>(market),
      'name': serializer.toJson<String>(name),
      'nameZh': serializer.toJson<String>(nameZh),
      'price': serializer.toJson<String>(price),
      'change': serializer.toJson<String>(change),
      'changePct': serializer.toJson<String>(changePct),
      'volume': serializer.toJson<int>(volume),
      'bid': serializer.toJson<String?>(bid),
      'ask': serializer.toJson<String?>(ask),
      'turnover': serializer.toJson<String>(turnover),
      'prevClose': serializer.toJson<String>(prevClose),
      'open': serializer.toJson<String>(open),
      'high': serializer.toJson<String>(high),
      'low': serializer.toJson<String>(low),
      'marketCap': serializer.toJson<String>(marketCap),
      'peRatio': serializer.toJson<String?>(peRatio),
      'delayed': serializer.toJson<bool>(delayed),
      'marketStatus': serializer.toJson<String>(marketStatus),
      'isStale': serializer.toJson<bool>(isStale),
      'staleSinceMs': serializer.toJson<int>(staleSinceMs),
      'cachedAt': serializer.toJson<String>(cachedAt),
    };
  }

  QuoteCache copyWith({
    String? symbol,
    String? market,
    String? name,
    String? nameZh,
    String? price,
    String? change,
    String? changePct,
    int? volume,
    Value<String?> bid = const Value.absent(),
    Value<String?> ask = const Value.absent(),
    String? turnover,
    String? prevClose,
    String? open,
    String? high,
    String? low,
    String? marketCap,
    Value<String?> peRatio = const Value.absent(),
    bool? delayed,
    String? marketStatus,
    bool? isStale,
    int? staleSinceMs,
    String? cachedAt,
  }) => QuoteCache(
    symbol: symbol ?? this.symbol,
    market: market ?? this.market,
    name: name ?? this.name,
    nameZh: nameZh ?? this.nameZh,
    price: price ?? this.price,
    change: change ?? this.change,
    changePct: changePct ?? this.changePct,
    volume: volume ?? this.volume,
    bid: bid.present ? bid.value : this.bid,
    ask: ask.present ? ask.value : this.ask,
    turnover: turnover ?? this.turnover,
    prevClose: prevClose ?? this.prevClose,
    open: open ?? this.open,
    high: high ?? this.high,
    low: low ?? this.low,
    marketCap: marketCap ?? this.marketCap,
    peRatio: peRatio.present ? peRatio.value : this.peRatio,
    delayed: delayed ?? this.delayed,
    marketStatus: marketStatus ?? this.marketStatus,
    isStale: isStale ?? this.isStale,
    staleSinceMs: staleSinceMs ?? this.staleSinceMs,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  QuoteCache copyWithCompanion(QuoteCachesCompanion data) {
    return QuoteCache(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      market: data.market.present ? data.market.value : this.market,
      name: data.name.present ? data.name.value : this.name,
      nameZh: data.nameZh.present ? data.nameZh.value : this.nameZh,
      price: data.price.present ? data.price.value : this.price,
      change: data.change.present ? data.change.value : this.change,
      changePct: data.changePct.present ? data.changePct.value : this.changePct,
      volume: data.volume.present ? data.volume.value : this.volume,
      bid: data.bid.present ? data.bid.value : this.bid,
      ask: data.ask.present ? data.ask.value : this.ask,
      turnover: data.turnover.present ? data.turnover.value : this.turnover,
      prevClose: data.prevClose.present ? data.prevClose.value : this.prevClose,
      open: data.open.present ? data.open.value : this.open,
      high: data.high.present ? data.high.value : this.high,
      low: data.low.present ? data.low.value : this.low,
      marketCap: data.marketCap.present ? data.marketCap.value : this.marketCap,
      peRatio: data.peRatio.present ? data.peRatio.value : this.peRatio,
      delayed: data.delayed.present ? data.delayed.value : this.delayed,
      marketStatus: data.marketStatus.present
          ? data.marketStatus.value
          : this.marketStatus,
      isStale: data.isStale.present ? data.isStale.value : this.isStale,
      staleSinceMs: data.staleSinceMs.present
          ? data.staleSinceMs.value
          : this.staleSinceMs,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuoteCache(')
          ..write('symbol: $symbol, ')
          ..write('market: $market, ')
          ..write('name: $name, ')
          ..write('nameZh: $nameZh, ')
          ..write('price: $price, ')
          ..write('change: $change, ')
          ..write('changePct: $changePct, ')
          ..write('volume: $volume, ')
          ..write('bid: $bid, ')
          ..write('ask: $ask, ')
          ..write('turnover: $turnover, ')
          ..write('prevClose: $prevClose, ')
          ..write('open: $open, ')
          ..write('high: $high, ')
          ..write('low: $low, ')
          ..write('marketCap: $marketCap, ')
          ..write('peRatio: $peRatio, ')
          ..write('delayed: $delayed, ')
          ..write('marketStatus: $marketStatus, ')
          ..write('isStale: $isStale, ')
          ..write('staleSinceMs: $staleSinceMs, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    symbol,
    market,
    name,
    nameZh,
    price,
    change,
    changePct,
    volume,
    bid,
    ask,
    turnover,
    prevClose,
    open,
    high,
    low,
    marketCap,
    peRatio,
    delayed,
    marketStatus,
    isStale,
    staleSinceMs,
    cachedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuoteCache &&
          other.symbol == this.symbol &&
          other.market == this.market &&
          other.name == this.name &&
          other.nameZh == this.nameZh &&
          other.price == this.price &&
          other.change == this.change &&
          other.changePct == this.changePct &&
          other.volume == this.volume &&
          other.bid == this.bid &&
          other.ask == this.ask &&
          other.turnover == this.turnover &&
          other.prevClose == this.prevClose &&
          other.open == this.open &&
          other.high == this.high &&
          other.low == this.low &&
          other.marketCap == this.marketCap &&
          other.peRatio == this.peRatio &&
          other.delayed == this.delayed &&
          other.marketStatus == this.marketStatus &&
          other.isStale == this.isStale &&
          other.staleSinceMs == this.staleSinceMs &&
          other.cachedAt == this.cachedAt);
}

class QuoteCachesCompanion extends UpdateCompanion<QuoteCache> {
  final Value<String> symbol;
  final Value<String> market;
  final Value<String> name;
  final Value<String> nameZh;
  final Value<String> price;
  final Value<String> change;
  final Value<String> changePct;
  final Value<int> volume;
  final Value<String?> bid;
  final Value<String?> ask;
  final Value<String> turnover;
  final Value<String> prevClose;
  final Value<String> open;
  final Value<String> high;
  final Value<String> low;
  final Value<String> marketCap;
  final Value<String?> peRatio;
  final Value<bool> delayed;
  final Value<String> marketStatus;
  final Value<bool> isStale;
  final Value<int> staleSinceMs;
  final Value<String> cachedAt;
  final Value<int> rowid;
  const QuoteCachesCompanion({
    this.symbol = const Value.absent(),
    this.market = const Value.absent(),
    this.name = const Value.absent(),
    this.nameZh = const Value.absent(),
    this.price = const Value.absent(),
    this.change = const Value.absent(),
    this.changePct = const Value.absent(),
    this.volume = const Value.absent(),
    this.bid = const Value.absent(),
    this.ask = const Value.absent(),
    this.turnover = const Value.absent(),
    this.prevClose = const Value.absent(),
    this.open = const Value.absent(),
    this.high = const Value.absent(),
    this.low = const Value.absent(),
    this.marketCap = const Value.absent(),
    this.peRatio = const Value.absent(),
    this.delayed = const Value.absent(),
    this.marketStatus = const Value.absent(),
    this.isStale = const Value.absent(),
    this.staleSinceMs = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuoteCachesCompanion.insert({
    required String symbol,
    required String market,
    required String name,
    required String nameZh,
    required String price,
    required String change,
    required String changePct,
    required int volume,
    this.bid = const Value.absent(),
    this.ask = const Value.absent(),
    required String turnover,
    required String prevClose,
    required String open,
    required String high,
    required String low,
    required String marketCap,
    this.peRatio = const Value.absent(),
    required bool delayed,
    required String marketStatus,
    this.isStale = const Value.absent(),
    this.staleSinceMs = const Value.absent(),
    required String cachedAt,
    this.rowid = const Value.absent(),
  }) : symbol = Value(symbol),
       market = Value(market),
       name = Value(name),
       nameZh = Value(nameZh),
       price = Value(price),
       change = Value(change),
       changePct = Value(changePct),
       volume = Value(volume),
       turnover = Value(turnover),
       prevClose = Value(prevClose),
       open = Value(open),
       high = Value(high),
       low = Value(low),
       marketCap = Value(marketCap),
       delayed = Value(delayed),
       marketStatus = Value(marketStatus),
       cachedAt = Value(cachedAt);
  static Insertable<QuoteCache> custom({
    Expression<String>? symbol,
    Expression<String>? market,
    Expression<String>? name,
    Expression<String>? nameZh,
    Expression<String>? price,
    Expression<String>? change,
    Expression<String>? changePct,
    Expression<int>? volume,
    Expression<String>? bid,
    Expression<String>? ask,
    Expression<String>? turnover,
    Expression<String>? prevClose,
    Expression<String>? open,
    Expression<String>? high,
    Expression<String>? low,
    Expression<String>? marketCap,
    Expression<String>? peRatio,
    Expression<bool>? delayed,
    Expression<String>? marketStatus,
    Expression<bool>? isStale,
    Expression<int>? staleSinceMs,
    Expression<String>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (market != null) 'market': market,
      if (name != null) 'name': name,
      if (nameZh != null) 'name_zh': nameZh,
      if (price != null) 'price': price,
      if (change != null) 'change': change,
      if (changePct != null) 'change_pct': changePct,
      if (volume != null) 'volume': volume,
      if (bid != null) 'bid': bid,
      if (ask != null) 'ask': ask,
      if (turnover != null) 'turnover': turnover,
      if (prevClose != null) 'prev_close': prevClose,
      if (open != null) 'open': open,
      if (high != null) 'high': high,
      if (low != null) 'low': low,
      if (marketCap != null) 'market_cap': marketCap,
      if (peRatio != null) 'pe_ratio': peRatio,
      if (delayed != null) 'delayed': delayed,
      if (marketStatus != null) 'market_status': marketStatus,
      if (isStale != null) 'is_stale': isStale,
      if (staleSinceMs != null) 'stale_since_ms': staleSinceMs,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuoteCachesCompanion copyWith({
    Value<String>? symbol,
    Value<String>? market,
    Value<String>? name,
    Value<String>? nameZh,
    Value<String>? price,
    Value<String>? change,
    Value<String>? changePct,
    Value<int>? volume,
    Value<String?>? bid,
    Value<String?>? ask,
    Value<String>? turnover,
    Value<String>? prevClose,
    Value<String>? open,
    Value<String>? high,
    Value<String>? low,
    Value<String>? marketCap,
    Value<String?>? peRatio,
    Value<bool>? delayed,
    Value<String>? marketStatus,
    Value<bool>? isStale,
    Value<int>? staleSinceMs,
    Value<String>? cachedAt,
    Value<int>? rowid,
  }) {
    return QuoteCachesCompanion(
      symbol: symbol ?? this.symbol,
      market: market ?? this.market,
      name: name ?? this.name,
      nameZh: nameZh ?? this.nameZh,
      price: price ?? this.price,
      change: change ?? this.change,
      changePct: changePct ?? this.changePct,
      volume: volume ?? this.volume,
      bid: bid ?? this.bid,
      ask: ask ?? this.ask,
      turnover: turnover ?? this.turnover,
      prevClose: prevClose ?? this.prevClose,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      marketCap: marketCap ?? this.marketCap,
      peRatio: peRatio ?? this.peRatio,
      delayed: delayed ?? this.delayed,
      marketStatus: marketStatus ?? this.marketStatus,
      isStale: isStale ?? this.isStale,
      staleSinceMs: staleSinceMs ?? this.staleSinceMs,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (market.present) {
      map['market'] = Variable<String>(market.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameZh.present) {
      map['name_zh'] = Variable<String>(nameZh.value);
    }
    if (price.present) {
      map['price'] = Variable<String>(price.value);
    }
    if (change.present) {
      map['change'] = Variable<String>(change.value);
    }
    if (changePct.present) {
      map['change_pct'] = Variable<String>(changePct.value);
    }
    if (volume.present) {
      map['volume'] = Variable<int>(volume.value);
    }
    if (bid.present) {
      map['bid'] = Variable<String>(bid.value);
    }
    if (ask.present) {
      map['ask'] = Variable<String>(ask.value);
    }
    if (turnover.present) {
      map['turnover'] = Variable<String>(turnover.value);
    }
    if (prevClose.present) {
      map['prev_close'] = Variable<String>(prevClose.value);
    }
    if (open.present) {
      map['open'] = Variable<String>(open.value);
    }
    if (high.present) {
      map['high'] = Variable<String>(high.value);
    }
    if (low.present) {
      map['low'] = Variable<String>(low.value);
    }
    if (marketCap.present) {
      map['market_cap'] = Variable<String>(marketCap.value);
    }
    if (peRatio.present) {
      map['pe_ratio'] = Variable<String>(peRatio.value);
    }
    if (delayed.present) {
      map['delayed'] = Variable<bool>(delayed.value);
    }
    if (marketStatus.present) {
      map['market_status'] = Variable<String>(marketStatus.value);
    }
    if (isStale.present) {
      map['is_stale'] = Variable<bool>(isStale.value);
    }
    if (staleSinceMs.present) {
      map['stale_since_ms'] = Variable<int>(staleSinceMs.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<String>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuoteCachesCompanion(')
          ..write('symbol: $symbol, ')
          ..write('market: $market, ')
          ..write('name: $name, ')
          ..write('nameZh: $nameZh, ')
          ..write('price: $price, ')
          ..write('change: $change, ')
          ..write('changePct: $changePct, ')
          ..write('volume: $volume, ')
          ..write('bid: $bid, ')
          ..write('ask: $ask, ')
          ..write('turnover: $turnover, ')
          ..write('prevClose: $prevClose, ')
          ..write('open: $open, ')
          ..write('high: $high, ')
          ..write('low: $low, ')
          ..write('marketCap: $marketCap, ')
          ..write('peRatio: $peRatio, ')
          ..write('delayed: $delayed, ')
          ..write('marketStatus: $marketStatus, ')
          ..write('isStale: $isStale, ')
          ..write('staleSinceMs: $staleSinceMs, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QuoteCachesTable quoteCaches = $QuoteCachesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [quoteCaches];
}

typedef $$QuoteCachesTableCreateCompanionBuilder =
    QuoteCachesCompanion Function({
      required String symbol,
      required String market,
      required String name,
      required String nameZh,
      required String price,
      required String change,
      required String changePct,
      required int volume,
      Value<String?> bid,
      Value<String?> ask,
      required String turnover,
      required String prevClose,
      required String open,
      required String high,
      required String low,
      required String marketCap,
      Value<String?> peRatio,
      required bool delayed,
      required String marketStatus,
      Value<bool> isStale,
      Value<int> staleSinceMs,
      required String cachedAt,
      Value<int> rowid,
    });
typedef $$QuoteCachesTableUpdateCompanionBuilder =
    QuoteCachesCompanion Function({
      Value<String> symbol,
      Value<String> market,
      Value<String> name,
      Value<String> nameZh,
      Value<String> price,
      Value<String> change,
      Value<String> changePct,
      Value<int> volume,
      Value<String?> bid,
      Value<String?> ask,
      Value<String> turnover,
      Value<String> prevClose,
      Value<String> open,
      Value<String> high,
      Value<String> low,
      Value<String> marketCap,
      Value<String?> peRatio,
      Value<bool> delayed,
      Value<String> marketStatus,
      Value<bool> isStale,
      Value<int> staleSinceMs,
      Value<String> cachedAt,
      Value<int> rowid,
    });

class $$QuoteCachesTableFilterComposer
    extends Composer<_$AppDatabase, $QuoteCachesTable> {
  $$QuoteCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get market => $composableBuilder(
    column: $table.market,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameZh => $composableBuilder(
    column: $table.nameZh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get change => $composableBuilder(
    column: $table.change,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changePct => $composableBuilder(
    column: $table.changePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bid => $composableBuilder(
    column: $table.bid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ask => $composableBuilder(
    column: $table.ask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get turnover => $composableBuilder(
    column: $table.turnover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prevClose => $composableBuilder(
    column: $table.prevClose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get open => $composableBuilder(
    column: $table.open,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get high => $composableBuilder(
    column: $table.high,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get low => $composableBuilder(
    column: $table.low,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marketCap => $composableBuilder(
    column: $table.marketCap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peRatio => $composableBuilder(
    column: $table.peRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get delayed => $composableBuilder(
    column: $table.delayed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marketStatus => $composableBuilder(
    column: $table.marketStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStale => $composableBuilder(
    column: $table.isStale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get staleSinceMs => $composableBuilder(
    column: $table.staleSinceMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuoteCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuoteCachesTable> {
  $$QuoteCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get market => $composableBuilder(
    column: $table.market,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameZh => $composableBuilder(
    column: $table.nameZh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get change => $composableBuilder(
    column: $table.change,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changePct => $composableBuilder(
    column: $table.changePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bid => $composableBuilder(
    column: $table.bid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ask => $composableBuilder(
    column: $table.ask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get turnover => $composableBuilder(
    column: $table.turnover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prevClose => $composableBuilder(
    column: $table.prevClose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get open => $composableBuilder(
    column: $table.open,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get high => $composableBuilder(
    column: $table.high,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get low => $composableBuilder(
    column: $table.low,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marketCap => $composableBuilder(
    column: $table.marketCap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peRatio => $composableBuilder(
    column: $table.peRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get delayed => $composableBuilder(
    column: $table.delayed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marketStatus => $composableBuilder(
    column: $table.marketStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStale => $composableBuilder(
    column: $table.isStale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get staleSinceMs => $composableBuilder(
    column: $table.staleSinceMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuoteCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuoteCachesTable> {
  $$QuoteCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get market =>
      $composableBuilder(column: $table.market, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameZh =>
      $composableBuilder(column: $table.nameZh, builder: (column) => column);

  GeneratedColumn<String> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get change =>
      $composableBuilder(column: $table.change, builder: (column) => column);

  GeneratedColumn<String> get changePct =>
      $composableBuilder(column: $table.changePct, builder: (column) => column);

  GeneratedColumn<int> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  GeneratedColumn<String> get bid =>
      $composableBuilder(column: $table.bid, builder: (column) => column);

  GeneratedColumn<String> get ask =>
      $composableBuilder(column: $table.ask, builder: (column) => column);

  GeneratedColumn<String> get turnover =>
      $composableBuilder(column: $table.turnover, builder: (column) => column);

  GeneratedColumn<String> get prevClose =>
      $composableBuilder(column: $table.prevClose, builder: (column) => column);

  GeneratedColumn<String> get open =>
      $composableBuilder(column: $table.open, builder: (column) => column);

  GeneratedColumn<String> get high =>
      $composableBuilder(column: $table.high, builder: (column) => column);

  GeneratedColumn<String> get low =>
      $composableBuilder(column: $table.low, builder: (column) => column);

  GeneratedColumn<String> get marketCap =>
      $composableBuilder(column: $table.marketCap, builder: (column) => column);

  GeneratedColumn<String> get peRatio =>
      $composableBuilder(column: $table.peRatio, builder: (column) => column);

  GeneratedColumn<bool> get delayed =>
      $composableBuilder(column: $table.delayed, builder: (column) => column);

  GeneratedColumn<String> get marketStatus => $composableBuilder(
    column: $table.marketStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isStale =>
      $composableBuilder(column: $table.isStale, builder: (column) => column);

  GeneratedColumn<int> get staleSinceMs => $composableBuilder(
    column: $table.staleSinceMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$QuoteCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuoteCachesTable,
          QuoteCache,
          $$QuoteCachesTableFilterComposer,
          $$QuoteCachesTableOrderingComposer,
          $$QuoteCachesTableAnnotationComposer,
          $$QuoteCachesTableCreateCompanionBuilder,
          $$QuoteCachesTableUpdateCompanionBuilder,
          (
            QuoteCache,
            BaseReferences<_$AppDatabase, $QuoteCachesTable, QuoteCache>,
          ),
          QuoteCache,
          PrefetchHooks Function()
        > {
  $$QuoteCachesTableTableManager(_$AppDatabase db, $QuoteCachesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuoteCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuoteCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuoteCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> symbol = const Value.absent(),
                Value<String> market = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameZh = const Value.absent(),
                Value<String> price = const Value.absent(),
                Value<String> change = const Value.absent(),
                Value<String> changePct = const Value.absent(),
                Value<int> volume = const Value.absent(),
                Value<String?> bid = const Value.absent(),
                Value<String?> ask = const Value.absent(),
                Value<String> turnover = const Value.absent(),
                Value<String> prevClose = const Value.absent(),
                Value<String> open = const Value.absent(),
                Value<String> high = const Value.absent(),
                Value<String> low = const Value.absent(),
                Value<String> marketCap = const Value.absent(),
                Value<String?> peRatio = const Value.absent(),
                Value<bool> delayed = const Value.absent(),
                Value<String> marketStatus = const Value.absent(),
                Value<bool> isStale = const Value.absent(),
                Value<int> staleSinceMs = const Value.absent(),
                Value<String> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuoteCachesCompanion(
                symbol: symbol,
                market: market,
                name: name,
                nameZh: nameZh,
                price: price,
                change: change,
                changePct: changePct,
                volume: volume,
                bid: bid,
                ask: ask,
                turnover: turnover,
                prevClose: prevClose,
                open: open,
                high: high,
                low: low,
                marketCap: marketCap,
                peRatio: peRatio,
                delayed: delayed,
                marketStatus: marketStatus,
                isStale: isStale,
                staleSinceMs: staleSinceMs,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String symbol,
                required String market,
                required String name,
                required String nameZh,
                required String price,
                required String change,
                required String changePct,
                required int volume,
                Value<String?> bid = const Value.absent(),
                Value<String?> ask = const Value.absent(),
                required String turnover,
                required String prevClose,
                required String open,
                required String high,
                required String low,
                required String marketCap,
                Value<String?> peRatio = const Value.absent(),
                required bool delayed,
                required String marketStatus,
                Value<bool> isStale = const Value.absent(),
                Value<int> staleSinceMs = const Value.absent(),
                required String cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuoteCachesCompanion.insert(
                symbol: symbol,
                market: market,
                name: name,
                nameZh: nameZh,
                price: price,
                change: change,
                changePct: changePct,
                volume: volume,
                bid: bid,
                ask: ask,
                turnover: turnover,
                prevClose: prevClose,
                open: open,
                high: high,
                low: low,
                marketCap: marketCap,
                peRatio: peRatio,
                delayed: delayed,
                marketStatus: marketStatus,
                isStale: isStale,
                staleSinceMs: staleSinceMs,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuoteCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuoteCachesTable,
      QuoteCache,
      $$QuoteCachesTableFilterComposer,
      $$QuoteCachesTableOrderingComposer,
      $$QuoteCachesTableAnnotationComposer,
      $$QuoteCachesTableCreateCompanionBuilder,
      $$QuoteCachesTableUpdateCompanionBuilder,
      (
        QuoteCache,
        BaseReferences<_$AppDatabase, $QuoteCachesTable, QuoteCache>,
      ),
      QuoteCache,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QuoteCachesTableTableManager get quoteCaches =>
      $$QuoteCachesTableTableManager(_db, _db.quoteCaches);
}
