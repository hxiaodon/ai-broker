// This is a generated file - do not edit.
//
// Generated from market_data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Market 标识交易所所在市场（来源：market-api-spec.md §1.4）
class Market extends $pb.ProtobufEnum {
  static const Market MARKET_UNSPECIFIED =
      Market._(0, _omitEnumNames ? '' : 'MARKET_UNSPECIFIED');
  static const Market MARKET_US =
      Market._(1, _omitEnumNames ? '' : 'MARKET_US');
  static const Market MARKET_HK =
      Market._(2, _omitEnumNames ? '' : 'MARKET_HK');

  static const $core.List<Market> values = <Market>[
    MARKET_UNSPECIFIED,
    MARKET_US,
    MARKET_HK,
  ];

  static final $core.List<Market?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Market? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Market._(super.value, super.name);
}

/// MarketStatus 标识当前交易时段（来源：market-api-spec.md §1.4）
class MarketStatus extends $pb.ProtobufEnum {
  static const MarketStatus MARKET_STATUS_UNSPECIFIED =
      MarketStatus._(0, _omitEnumNames ? '' : 'MARKET_STATUS_UNSPECIFIED');
  static const MarketStatus MARKET_STATUS_REGULAR =
      MarketStatus._(1, _omitEnumNames ? '' : 'MARKET_STATUS_REGULAR');
  static const MarketStatus MARKET_STATUS_PRE_MARKET =
      MarketStatus._(2, _omitEnumNames ? '' : 'MARKET_STATUS_PRE_MARKET');
  static const MarketStatus MARKET_STATUS_AFTER_HOURS =
      MarketStatus._(3, _omitEnumNames ? '' : 'MARKET_STATUS_AFTER_HOURS');
  static const MarketStatus MARKET_STATUS_CLOSED =
      MarketStatus._(4, _omitEnumNames ? '' : 'MARKET_STATUS_CLOSED');
  static const MarketStatus MARKET_STATUS_HALTED =
      MarketStatus._(5, _omitEnumNames ? '' : 'MARKET_STATUS_HALTED');

  static const $core.List<MarketStatus> values = <MarketStatus>[
    MARKET_STATUS_UNSPECIFIED,
    MARKET_STATUS_REGULAR,
    MARKET_STATUS_PRE_MARKET,
    MARKET_STATUS_AFTER_HOURS,
    MARKET_STATUS_CLOSED,
    MARKET_STATUS_HALTED,
  ];

  static final $core.List<MarketStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static MarketStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MarketStatus._(super.value, super.name);
}

class WsQuoteFrame_FrameType extends $pb.ProtobufEnum {
  static const WsQuoteFrame_FrameType FRAME_TYPE_UNSPECIFIED =
      WsQuoteFrame_FrameType._(
          0, _omitEnumNames ? '' : 'FRAME_TYPE_UNSPECIFIED');
  static const WsQuoteFrame_FrameType FRAME_TYPE_SNAPSHOT =
      WsQuoteFrame_FrameType._(1, _omitEnumNames ? '' : 'FRAME_TYPE_SNAPSHOT');
  static const WsQuoteFrame_FrameType FRAME_TYPE_TICK =
      WsQuoteFrame_FrameType._(2, _omitEnumNames ? '' : 'FRAME_TYPE_TICK');
  static const WsQuoteFrame_FrameType FRAME_TYPE_DELAYED =
      WsQuoteFrame_FrameType._(3, _omitEnumNames ? '' : 'FRAME_TYPE_DELAYED');

  static const $core.List<WsQuoteFrame_FrameType> values =
      <WsQuoteFrame_FrameType>[
    FRAME_TYPE_UNSPECIFIED,
    FRAME_TYPE_SNAPSHOT,
    FRAME_TYPE_TICK,
    FRAME_TYPE_DELAYED,
  ];

  static final $core.List<WsQuoteFrame_FrameType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static WsQuoteFrame_FrameType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const WsQuoteFrame_FrameType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
