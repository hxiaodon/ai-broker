// This is a generated file - do not edit.
//
// Generated from market_data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

import 'market_data.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'market_data.pbenum.dart';

/// ──────────────────────────────────────────────────────────────────────────
/// Quote — 实时行情快照
/// 来源：market-api-spec.md §3.3 + §7.3
/// 规范：所有价格字段使用 string（禁止 float/double，财务编码规范 Rule 1）
///       时间戳使用 google.protobuf.Timestamp（UTC），JSON encoding 自动序列化为 RFC 3339
/// ──────────────────────────────────────────────────────────────────────────
class Quote extends $pb.GeneratedMessage {
  factory Quote({
    $core.String? symbol,
    Market? market,
    $core.String? price,
    $core.String? change,
    $core.String? changePct,
    $fixnum.Int64? volume,
    $core.String? bid,
    $core.String? ask,
    $core.String? open,
    $core.String? high,
    $core.String? low,
    $core.String? prevClose,
    $core.String? turnover,
    MarketStatus? marketStatus,
    $core.bool? isStale,
    $fixnum.Int64? staleSinceMs,
    $core.bool? delayed,
    $0.Timestamp? timestamp,
  }) {
    final result = create();
    if (symbol != null) result.symbol = symbol;
    if (market != null) result.market = market;
    if (price != null) result.price = price;
    if (change != null) result.change = change;
    if (changePct != null) result.changePct = changePct;
    if (volume != null) result.volume = volume;
    if (bid != null) result.bid = bid;
    if (ask != null) result.ask = ask;
    if (open != null) result.open = open;
    if (high != null) result.high = high;
    if (low != null) result.low = low;
    if (prevClose != null) result.prevClose = prevClose;
    if (turnover != null) result.turnover = turnover;
    if (marketStatus != null) result.marketStatus = marketStatus;
    if (isStale != null) result.isStale = isStale;
    if (staleSinceMs != null) result.staleSinceMs = staleSinceMs;
    if (delayed != null) result.delayed = delayed;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  Quote._();

  factory Quote.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Quote.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Quote',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'brokerage.market_data.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'symbol')
    ..aE<Market>(2, _omitFieldNames ? '' : 'market', enumValues: Market.values)
    ..aOS(3, _omitFieldNames ? '' : 'price')
    ..aOS(4, _omitFieldNames ? '' : 'change')
    ..aOS(5, _omitFieldNames ? '' : 'changePct')
    ..aInt64(6, _omitFieldNames ? '' : 'volume')
    ..aOS(7, _omitFieldNames ? '' : 'bid')
    ..aOS(8, _omitFieldNames ? '' : 'ask')
    ..aOS(9, _omitFieldNames ? '' : 'open')
    ..aOS(10, _omitFieldNames ? '' : 'high')
    ..aOS(11, _omitFieldNames ? '' : 'low')
    ..aOS(12, _omitFieldNames ? '' : 'prevClose')
    ..aOS(13, _omitFieldNames ? '' : 'turnover')
    ..aE<MarketStatus>(14, _omitFieldNames ? '' : 'marketStatus',
        enumValues: MarketStatus.values)
    ..aOB(15, _omitFieldNames ? '' : 'isStale')
    ..aInt64(16, _omitFieldNames ? '' : 'staleSinceMs')
    ..aOB(17, _omitFieldNames ? '' : 'delayed')
    ..aOM<$0.Timestamp>(18, _omitFieldNames ? '' : 'timestamp',
        subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Quote clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Quote copyWith(void Function(Quote) updates) =>
      super.copyWith((message) => updates(message as Quote)) as Quote;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Quote create() => Quote._();
  @$core.override
  Quote createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Quote getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Quote>(create);
  static Quote? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get symbol => $_getSZ(0);
  @$pb.TagNumber(1)
  set symbol($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSymbol() => $_has(0);
  @$pb.TagNumber(1)
  void clearSymbol() => $_clearField(1);

  @$pb.TagNumber(2)
  Market get market => $_getN(1);
  @$pb.TagNumber(2)
  set market(Market value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMarket() => $_has(1);
  @$pb.TagNumber(2)
  void clearMarket() => $_clearField(2);

  /// 价格字段（US: 4位小数；HK: 3位小数）
  @$pb.TagNumber(3)
  $core.String get price => $_getSZ(2);
  @$pb.TagNumber(3)
  set price($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPrice() => $_has(2);
  @$pb.TagNumber(3)
  void clearPrice() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get change => $_getSZ(3);
  @$pb.TagNumber(4)
  set change($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChange() => $_has(3);
  @$pb.TagNumber(4)
  void clearChange() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get changePct => $_getSZ(4);
  @$pb.TagNumber(5)
  set changePct($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasChangePct() => $_has(4);
  @$pb.TagNumber(5)
  void clearChangePct() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get volume => $_getI64(5);
  @$pb.TagNumber(6)
  set volume($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVolume() => $_has(5);
  @$pb.TagNumber(6)
  void clearVolume() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get bid => $_getSZ(6);
  @$pb.TagNumber(7)
  set bid($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBid() => $_has(6);
  @$pb.TagNumber(7)
  void clearBid() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get ask => $_getSZ(7);
  @$pb.TagNumber(8)
  set ask($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAsk() => $_has(7);
  @$pb.TagNumber(8)
  void clearAsk() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get open => $_getSZ(8);
  @$pb.TagNumber(9)
  set open($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasOpen() => $_has(8);
  @$pb.TagNumber(9)
  void clearOpen() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get high => $_getSZ(9);
  @$pb.TagNumber(10)
  set high($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasHigh() => $_has(9);
  @$pb.TagNumber(10)
  void clearHigh() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get low => $_getSZ(10);
  @$pb.TagNumber(11)
  set low($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasLow() => $_has(10);
  @$pb.TagNumber(11)
  void clearLow() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get prevClose => $_getSZ(11);
  @$pb.TagNumber(12)
  set prevClose($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPrevClose() => $_has(11);
  @$pb.TagNumber(12)
  void clearPrevClose() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get turnover => $_getSZ(12);
  @$pb.TagNumber(13)
  set turnover($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasTurnover() => $_has(12);
  @$pb.TagNumber(13)
  void clearTurnover() => $_clearField(13);

  @$pb.TagNumber(14)
  MarketStatus get marketStatus => $_getN(13);
  @$pb.TagNumber(14)
  set marketStatus(MarketStatus value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasMarketStatus() => $_has(13);
  @$pb.TagNumber(14)
  void clearMarketStatus() => $_clearField(14);

  /// 数据质量字段（来源：market-data-system.md Appendix D）
  /// 展示阈值：5s；交易风控阈值：1s（由 Trading Engine 自行基于 timestamp 计算）
  @$pb.TagNumber(15)
  $core.bool get isStale => $_getBF(14);
  @$pb.TagNumber(15)
  set isStale($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasIsStale() => $_has(14);
  @$pb.TagNumber(15)
  void clearIsStale() => $_clearField(15);

  @$pb.TagNumber(16)
  $fixnum.Int64 get staleSinceMs => $_getI64(15);
  @$pb.TagNumber(16)
  set staleSinceMs($fixnum.Int64 value) => $_setInt64(15, value);
  @$pb.TagNumber(16)
  $core.bool hasStaleSinceMs() => $_has(15);
  @$pb.TagNumber(16)
  void clearStaleSinceMs() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.bool get delayed => $_getBF(16);
  @$pb.TagNumber(17)
  set delayed($core.bool value) => $_setBool(16, value);
  @$pb.TagNumber(17)
  $core.bool hasDelayed() => $_has(16);
  @$pb.TagNumber(17)
  void clearDelayed() => $_clearField(17);

  @$pb.TagNumber(18)
  $0.Timestamp get timestamp => $_getN(17);
  @$pb.TagNumber(18)
  set timestamp($0.Timestamp value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasTimestamp() => $_has(17);
  @$pb.TagNumber(18)
  void clearTimestamp() => $_clearField(18);
  @$pb.TagNumber(18)
  $0.Timestamp ensureTimestamp() => $_ensure(17);
}

class GetQuoteRequest extends $pb.GeneratedMessage {
  factory GetQuoteRequest({
    $core.Iterable<$core.String>? symbols,
  }) {
    final result = create();
    if (symbols != null) result.symbols.addAll(symbols);
    return result;
  }

  GetQuoteRequest._();

  factory GetQuoteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetQuoteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetQuoteRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'brokerage.market_data.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'symbols')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetQuoteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetQuoteRequest copyWith(void Function(GetQuoteRequest) updates) =>
      super.copyWith((message) => updates(message as GetQuoteRequest))
          as GetQuoteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetQuoteRequest create() => GetQuoteRequest._();
  @$core.override
  GetQuoteRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetQuoteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetQuoteRequest>(create);
  static GetQuoteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get symbols => $_getList(0);
}

class GetQuoteResponse extends $pb.GeneratedMessage {
  factory GetQuoteResponse({
    $core.Iterable<$core.MapEntry<$core.String, Quote>>? quotes,
    $0.Timestamp? asOf,
  }) {
    final result = create();
    if (quotes != null) result.quotes.addEntries(quotes);
    if (asOf != null) result.asOf = asOf;
    return result;
  }

  GetQuoteResponse._();

  factory GetQuoteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetQuoteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetQuoteResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'brokerage.market_data.v1'),
      createEmptyInstance: create)
    ..m<$core.String, Quote>(1, _omitFieldNames ? '' : 'quotes',
        entryClassName: 'GetQuoteResponse.QuotesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: Quote.create,
        valueDefaultOrMaker: Quote.getDefault,
        packageName: const $pb.PackageName('brokerage.market_data.v1'))
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'asOf',
        subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetQuoteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetQuoteResponse copyWith(void Function(GetQuoteResponse) updates) =>
      super.copyWith((message) => updates(message as GetQuoteResponse))
          as GetQuoteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetQuoteResponse create() => GetQuoteResponse._();
  @$core.override
  GetQuoteResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetQuoteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetQuoteResponse>(create);
  static GetQuoteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, Quote> get quotes => $_getMap(0);

  @$pb.TagNumber(2)
  $0.Timestamp get asOf => $_getN(1);
  @$pb.TagNumber(2)
  set asOf($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAsOf() => $_has(1);
  @$pb.TagNumber(2)
  void clearAsOf() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureAsOf() => $_ensure(1);
}

class GetMarketStatusRequest extends $pb.GeneratedMessage {
  factory GetMarketStatusRequest({
    Market? market,
  }) {
    final result = create();
    if (market != null) result.market = market;
    return result;
  }

  GetMarketStatusRequest._();

  factory GetMarketStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetMarketStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMarketStatusRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'brokerage.market_data.v1'),
      createEmptyInstance: create)
    ..aE<Market>(1, _omitFieldNames ? '' : 'market', enumValues: Market.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMarketStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMarketStatusRequest copyWith(
          void Function(GetMarketStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetMarketStatusRequest))
          as GetMarketStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetMarketStatusRequest create() => GetMarketStatusRequest._();
  @$core.override
  GetMarketStatusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetMarketStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetMarketStatusRequest>(create);
  static GetMarketStatusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  Market get market => $_getN(0);
  @$pb.TagNumber(1)
  set market(Market value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMarket() => $_has(0);
  @$pb.TagNumber(1)
  void clearMarket() => $_clearField(1);
}

class GetMarketStatusResponse extends $pb.GeneratedMessage {
  factory GetMarketStatusResponse({
    Market? market,
    MarketStatus? status,
    $0.Timestamp? sessionOpen,
    $0.Timestamp? sessionClose,
    $0.Timestamp? asOf,
  }) {
    final result = create();
    if (market != null) result.market = market;
    if (status != null) result.status = status;
    if (sessionOpen != null) result.sessionOpen = sessionOpen;
    if (sessionClose != null) result.sessionClose = sessionClose;
    if (asOf != null) result.asOf = asOf;
    return result;
  }

  GetMarketStatusResponse._();

  factory GetMarketStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetMarketStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMarketStatusResponse',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'brokerage.market_data.v1'),
      createEmptyInstance: create)
    ..aE<Market>(1, _omitFieldNames ? '' : 'market', enumValues: Market.values)
    ..aE<MarketStatus>(2, _omitFieldNames ? '' : 'status',
        enumValues: MarketStatus.values)
    ..aOM<$0.Timestamp>(3, _omitFieldNames ? '' : 'sessionOpen',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'sessionClose',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(5, _omitFieldNames ? '' : 'asOf',
        subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMarketStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMarketStatusResponse copyWith(
          void Function(GetMarketStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetMarketStatusResponse))
          as GetMarketStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetMarketStatusResponse create() => GetMarketStatusResponse._();
  @$core.override
  GetMarketStatusResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetMarketStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetMarketStatusResponse>(create);
  static GetMarketStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Market get market => $_getN(0);
  @$pb.TagNumber(1)
  set market(Market value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMarket() => $_has(0);
  @$pb.TagNumber(1)
  void clearMarket() => $_clearField(1);

  @$pb.TagNumber(2)
  MarketStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(MarketStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Timestamp get sessionOpen => $_getN(2);
  @$pb.TagNumber(3)
  set sessionOpen($0.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionOpen() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionOpen() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Timestamp ensureSessionOpen() => $_ensure(2);

  @$pb.TagNumber(4)
  $0.Timestamp get sessionClose => $_getN(3);
  @$pb.TagNumber(4)
  set sessionClose($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSessionClose() => $_has(3);
  @$pb.TagNumber(4)
  void clearSessionClose() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureSessionClose() => $_ensure(3);

  @$pb.TagNumber(5)
  $0.Timestamp get asOf => $_getN(4);
  @$pb.TagNumber(5)
  set asOf($0.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAsOf() => $_has(4);
  @$pb.TagNumber(5)
  void clearAsOf() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Timestamp ensureAsOf() => $_ensure(4);
}

class WsQuoteFrame extends $pb.GeneratedMessage {
  factory WsQuoteFrame({
    WsQuoteFrame_FrameType? frameType,
    Quote? quote,
  }) {
    final result = create();
    if (frameType != null) result.frameType = frameType;
    if (quote != null) result.quote = quote;
    return result;
  }

  WsQuoteFrame._();

  factory WsQuoteFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WsQuoteFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WsQuoteFrame',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'brokerage.market_data.v1'),
      createEmptyInstance: create)
    ..aE<WsQuoteFrame_FrameType>(1, _omitFieldNames ? '' : 'frameType',
        enumValues: WsQuoteFrame_FrameType.values)
    ..aOM<Quote>(2, _omitFieldNames ? '' : 'quote', subBuilder: Quote.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WsQuoteFrame clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WsQuoteFrame copyWith(void Function(WsQuoteFrame) updates) =>
      super.copyWith((message) => updates(message as WsQuoteFrame))
          as WsQuoteFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WsQuoteFrame create() => WsQuoteFrame._();
  @$core.override
  WsQuoteFrame createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WsQuoteFrame getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WsQuoteFrame>(create);
  static WsQuoteFrame? _defaultInstance;

  @$pb.TagNumber(1)
  WsQuoteFrame_FrameType get frameType => $_getN(0);
  @$pb.TagNumber(1)
  set frameType(WsQuoteFrame_FrameType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFrameType() => $_has(0);
  @$pb.TagNumber(1)
  void clearFrameType() => $_clearField(1);

  @$pb.TagNumber(2)
  Quote get quote => $_getN(1);
  @$pb.TagNumber(2)
  set quote(Quote value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasQuote() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuote() => $_clearField(2);
  @$pb.TagNumber(2)
  Quote ensureQuote() => $_ensure(1);
}

/// QuoteUpdatedEvent 是 Kafka topic brokerage.market-data.quote.updated 的消息体。
/// 每次 feed handler 收到新 tick 时发布。
class QuoteUpdatedEvent extends $pb.GeneratedMessage {
  factory QuoteUpdatedEvent({
    $core.String? eventId,
    $0.Timestamp? occurredAt,
    Quote? quote,
  }) {
    final result = create();
    if (eventId != null) result.eventId = eventId;
    if (occurredAt != null) result.occurredAt = occurredAt;
    if (quote != null) result.quote = quote;
    return result;
  }

  QuoteUpdatedEvent._();

  factory QuoteUpdatedEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory QuoteUpdatedEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QuoteUpdatedEvent',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'brokerage.market_data.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'eventId')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'occurredAt',
        subBuilder: $0.Timestamp.create)
    ..aOM<Quote>(3, _omitFieldNames ? '' : 'quote', subBuilder: Quote.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuoteUpdatedEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuoteUpdatedEvent copyWith(void Function(QuoteUpdatedEvent) updates) =>
      super.copyWith((message) => updates(message as QuoteUpdatedEvent))
          as QuoteUpdatedEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QuoteUpdatedEvent create() => QuoteUpdatedEvent._();
  @$core.override
  QuoteUpdatedEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static QuoteUpdatedEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QuoteUpdatedEvent>(create);
  static QuoteUpdatedEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get eventId => $_getSZ(0);
  @$pb.TagNumber(1)
  set eventId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEventId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEventId() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get occurredAt => $_getN(1);
  @$pb.TagNumber(2)
  set occurredAt($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOccurredAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearOccurredAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureOccurredAt() => $_ensure(1);

  @$pb.TagNumber(3)
  Quote get quote => $_getN(2);
  @$pb.TagNumber(3)
  set quote(Quote value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasQuote() => $_has(2);
  @$pb.TagNumber(3)
  void clearQuote() => $_clearField(3);
  @$pb.TagNumber(3)
  Quote ensureQuote() => $_ensure(2);
}

/// ──────────────────────────────────────────────────────────────────────────
/// gRPC Service — 供 Trading Engine 调用（预交易风控、交易时段判断）
/// 来源：contracts/market-data-to-trading.md
/// ──────────────────────────────────────────────────────────────────────────
class MarketDataServiceApi {
  final $pb.RpcClient _client;

  MarketDataServiceApi(this._client);

  /// GetQuote 按需查询最新报价，主要用于下单前的价格验证和风控检查。
  /// Trading Engine 应检查 Quote.timestamp，若超过 1s 则视为数据过旧并拒绝市价单。
  $async.Future<GetQuoteResponse> getQuote(
          $pb.ClientContext? ctx, GetQuoteRequest request) =>
      _client.invoke<GetQuoteResponse>(
          ctx, 'MarketDataService', 'GetQuote', request, GetQuoteResponse());

  /// GetMarketStatus 查询市场当前交易时段，用于交易时段执行控制。
  $async.Future<GetMarketStatusResponse> getMarketStatus(
          $pb.ClientContext? ctx, GetMarketStatusRequest request) =>
      _client.invoke<GetMarketStatusResponse>(ctx, 'MarketDataService',
          'GetMarketStatus', request, GetMarketStatusResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
