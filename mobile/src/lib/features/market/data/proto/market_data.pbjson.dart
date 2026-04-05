// This is a generated file - do not edit.
//
// Generated from market_data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

import 'package:protobuf/well_known_types/google/protobuf/timestamp.pbjson.dart'
    as $0;

@$core.Deprecated('Use marketDescriptor instead')
const Market$json = {
  '1': 'Market',
  '2': [
    {'1': 'MARKET_UNSPECIFIED', '2': 0},
    {'1': 'MARKET_US', '2': 1},
    {'1': 'MARKET_HK', '2': 2},
  ],
};

/// Descriptor for `Market`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List marketDescriptor = $convert.base64Decode(
    'CgZNYXJrZXQSFgoSTUFSS0VUX1VOU1BFQ0lGSUVEEAASDQoJTUFSS0VUX1VTEAESDQoJTUFSS0'
    'VUX0hLEAI=');

@$core.Deprecated('Use marketStatusDescriptor instead')
const MarketStatus$json = {
  '1': 'MarketStatus',
  '2': [
    {'1': 'MARKET_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'MARKET_STATUS_REGULAR', '2': 1},
    {'1': 'MARKET_STATUS_PRE_MARKET', '2': 2},
    {'1': 'MARKET_STATUS_AFTER_HOURS', '2': 3},
    {'1': 'MARKET_STATUS_CLOSED', '2': 4},
    {'1': 'MARKET_STATUS_HALTED', '2': 5},
  ],
};

/// Descriptor for `MarketStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List marketStatusDescriptor = $convert.base64Decode(
    'CgxNYXJrZXRTdGF0dXMSHQoZTUFSS0VUX1NUQVRVU19VTlNQRUNJRklFRBAAEhkKFU1BUktFVF'
    '9TVEFUVVNfUkVHVUxBUhABEhwKGE1BUktFVF9TVEFUVVNfUFJFX01BUktFVBACEh0KGU1BUktF'
    'VF9TVEFUVVNfQUZURVJfSE9VUlMQAxIYChRNQVJLRVRfU1RBVFVTX0NMT1NFRBAEEhgKFE1BUk'
    'tFVF9TVEFUVVNfSEFMVEVEEAU=');

@$core.Deprecated('Use quoteDescriptor instead')
const Quote$json = {
  '1': 'Quote',
  '2': [
    {'1': 'symbol', '3': 1, '4': 1, '5': 9, '10': 'symbol'},
    {
      '1': 'market',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.brokerage.market_data.v1.Market',
      '10': 'market'
    },
    {'1': 'price', '3': 3, '4': 1, '5': 9, '10': 'price'},
    {'1': 'change', '3': 4, '4': 1, '5': 9, '10': 'change'},
    {'1': 'change_pct', '3': 5, '4': 1, '5': 9, '10': 'changePct'},
    {'1': 'volume', '3': 6, '4': 1, '5': 3, '10': 'volume'},
    {'1': 'bid', '3': 7, '4': 1, '5': 9, '10': 'bid'},
    {'1': 'ask', '3': 8, '4': 1, '5': 9, '10': 'ask'},
    {'1': 'open', '3': 9, '4': 1, '5': 9, '10': 'open'},
    {'1': 'high', '3': 10, '4': 1, '5': 9, '10': 'high'},
    {'1': 'low', '3': 11, '4': 1, '5': 9, '10': 'low'},
    {'1': 'prev_close', '3': 12, '4': 1, '5': 9, '10': 'prevClose'},
    {'1': 'turnover', '3': 13, '4': 1, '5': 9, '10': 'turnover'},
    {
      '1': 'market_status',
      '3': 14,
      '4': 1,
      '5': 14,
      '6': '.brokerage.market_data.v1.MarketStatus',
      '10': 'marketStatus'
    },
    {'1': 'is_stale', '3': 15, '4': 1, '5': 8, '10': 'isStale'},
    {'1': 'stale_since_ms', '3': 16, '4': 1, '5': 3, '10': 'staleSinceMs'},
    {'1': 'delayed', '3': 17, '4': 1, '5': 8, '10': 'delayed'},
    {
      '1': 'timestamp',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'timestamp'
    },
  ],
};

/// Descriptor for `Quote`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List quoteDescriptor = $convert.base64Decode(
    'CgVRdW90ZRIWCgZzeW1ib2wYASABKAlSBnN5bWJvbBI4CgZtYXJrZXQYAiABKA4yIC5icm9rZX'
    'JhZ2UubWFya2V0X2RhdGEudjEuTWFya2V0UgZtYXJrZXQSFAoFcHJpY2UYAyABKAlSBXByaWNl'
    'EhYKBmNoYW5nZRgEIAEoCVIGY2hhbmdlEh0KCmNoYW5nZV9wY3QYBSABKAlSCWNoYW5nZVBjdB'
    'IWCgZ2b2x1bWUYBiABKANSBnZvbHVtZRIQCgNiaWQYByABKAlSA2JpZBIQCgNhc2sYCCABKAlS'
    'A2FzaxISCgRvcGVuGAkgASgJUgRvcGVuEhIKBGhpZ2gYCiABKAlSBGhpZ2gSEAoDbG93GAsgAS'
    'gJUgNsb3cSHQoKcHJldl9jbG9zZRgMIAEoCVIJcHJldkNsb3NlEhoKCHR1cm5vdmVyGA0gASgJ'
    'Ugh0dXJub3ZlchJLCg1tYXJrZXRfc3RhdHVzGA4gASgOMiYuYnJva2VyYWdlLm1hcmtldF9kYX'
    'RhLnYxLk1hcmtldFN0YXR1c1IMbWFya2V0U3RhdHVzEhkKCGlzX3N0YWxlGA8gASgIUgdpc1N0'
    'YWxlEiQKDnN0YWxlX3NpbmNlX21zGBAgASgDUgxzdGFsZVNpbmNlTXMSGAoHZGVsYXllZBgRIA'
    'EoCFIHZGVsYXllZBI4Cgl0aW1lc3RhbXAYEiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0'
    'YW1wUgl0aW1lc3RhbXA=');

@$core.Deprecated('Use getQuoteRequestDescriptor instead')
const GetQuoteRequest$json = {
  '1': 'GetQuoteRequest',
  '2': [
    {'1': 'symbols', '3': 1, '4': 3, '5': 9, '10': 'symbols'},
  ],
};

/// Descriptor for `GetQuoteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getQuoteRequestDescriptor = $convert.base64Decode(
    'Cg9HZXRRdW90ZVJlcXVlc3QSGAoHc3ltYm9scxgBIAMoCVIHc3ltYm9scw==');

@$core.Deprecated('Use getQuoteResponseDescriptor instead')
const GetQuoteResponse$json = {
  '1': 'GetQuoteResponse',
  '2': [
    {
      '1': 'quotes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.brokerage.market_data.v1.GetQuoteResponse.QuotesEntry',
      '10': 'quotes'
    },
    {
      '1': 'as_of',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'asOf'
    },
  ],
  '3': [GetQuoteResponse_QuotesEntry$json],
};

@$core.Deprecated('Use getQuoteResponseDescriptor instead')
const GetQuoteResponse_QuotesEntry$json = {
  '1': 'QuotesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.brokerage.market_data.v1.Quote',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `GetQuoteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getQuoteResponseDescriptor = $convert.base64Decode(
    'ChBHZXRRdW90ZVJlc3BvbnNlEk4KBnF1b3RlcxgBIAMoCzI2LmJyb2tlcmFnZS5tYXJrZXRfZG'
    'F0YS52MS5HZXRRdW90ZVJlc3BvbnNlLlF1b3Rlc0VudHJ5UgZxdW90ZXMSLwoFYXNfb2YYAiAB'
    'KAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgRhc09mGloKC1F1b3Rlc0VudHJ5EhAKA2'
    'tleRgBIAEoCVIDa2V5EjUKBXZhbHVlGAIgASgLMh8uYnJva2VyYWdlLm1hcmtldF9kYXRhLnYx'
    'LlF1b3RlUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use getMarketStatusRequestDescriptor instead')
const GetMarketStatusRequest$json = {
  '1': 'GetMarketStatusRequest',
  '2': [
    {
      '1': 'market',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.brokerage.market_data.v1.Market',
      '10': 'market'
    },
  ],
};

/// Descriptor for `GetMarketStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMarketStatusRequestDescriptor =
    $convert.base64Decode(
        'ChZHZXRNYXJrZXRTdGF0dXNSZXF1ZXN0EjgKBm1hcmtldBgBIAEoDjIgLmJyb2tlcmFnZS5tYX'
        'JrZXRfZGF0YS52MS5NYXJrZXRSBm1hcmtldA==');

@$core.Deprecated('Use getMarketStatusResponseDescriptor instead')
const GetMarketStatusResponse$json = {
  '1': 'GetMarketStatusResponse',
  '2': [
    {
      '1': 'market',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.brokerage.market_data.v1.Market',
      '10': 'market'
    },
    {
      '1': 'status',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.brokerage.market_data.v1.MarketStatus',
      '10': 'status'
    },
    {
      '1': 'session_open',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'sessionOpen'
    },
    {
      '1': 'session_close',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'sessionClose'
    },
    {
      '1': 'as_of',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'asOf'
    },
  ],
};

/// Descriptor for `GetMarketStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMarketStatusResponseDescriptor = $convert.base64Decode(
    'ChdHZXRNYXJrZXRTdGF0dXNSZXNwb25zZRI4CgZtYXJrZXQYASABKA4yIC5icm9rZXJhZ2UubW'
    'Fya2V0X2RhdGEudjEuTWFya2V0UgZtYXJrZXQSPgoGc3RhdHVzGAIgASgOMiYuYnJva2VyYWdl'
    'Lm1hcmtldF9kYXRhLnYxLk1hcmtldFN0YXR1c1IGc3RhdHVzEj0KDHNlc3Npb25fb3BlbhgDIA'
    'EoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSC3Nlc3Npb25PcGVuEj8KDXNlc3Npb25f'
    'Y2xvc2UYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgxzZXNzaW9uQ2xvc2USLw'
    'oFYXNfb2YYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgRhc09m');

@$core.Deprecated('Use wsQuoteFrameDescriptor instead')
const WsQuoteFrame$json = {
  '1': 'WsQuoteFrame',
  '2': [
    {
      '1': 'frame_type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.brokerage.market_data.v1.WsQuoteFrame.FrameType',
      '10': 'frameType'
    },
    {
      '1': 'quote',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.brokerage.market_data.v1.Quote',
      '10': 'quote'
    },
  ],
  '4': [WsQuoteFrame_FrameType$json],
};

@$core.Deprecated('Use wsQuoteFrameDescriptor instead')
const WsQuoteFrame_FrameType$json = {
  '1': 'FrameType',
  '2': [
    {'1': 'FRAME_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'FRAME_TYPE_SNAPSHOT', '2': 1},
    {'1': 'FRAME_TYPE_TICK', '2': 2},
    {'1': 'FRAME_TYPE_DELAYED', '2': 3},
  ],
};

/// Descriptor for `WsQuoteFrame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List wsQuoteFrameDescriptor = $convert.base64Decode(
    'CgxXc1F1b3RlRnJhbWUSTwoKZnJhbWVfdHlwZRgBIAEoDjIwLmJyb2tlcmFnZS5tYXJrZXRfZG'
    'F0YS52MS5Xc1F1b3RlRnJhbWUuRnJhbWVUeXBlUglmcmFtZVR5cGUSNQoFcXVvdGUYAiABKAsy'
    'Hy5icm9rZXJhZ2UubWFya2V0X2RhdGEudjEuUXVvdGVSBXF1b3RlIm0KCUZyYW1lVHlwZRIaCh'
    'ZGUkFNRV9UWVBFX1VOU1BFQ0lGSUVEEAASFwoTRlJBTUVfVFlQRV9TTkFQU0hPVBABEhMKD0ZS'
    'QU1FX1RZUEVfVElDSxACEhYKEkZSQU1FX1RZUEVfREVMQVlFRBAD');

@$core.Deprecated('Use quoteUpdatedEventDescriptor instead')
const QuoteUpdatedEvent$json = {
  '1': 'QuoteUpdatedEvent',
  '2': [
    {'1': 'event_id', '3': 1, '4': 1, '5': 9, '10': 'eventId'},
    {
      '1': 'occurred_at',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'occurredAt'
    },
    {
      '1': 'quote',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.brokerage.market_data.v1.Quote',
      '10': 'quote'
    },
  ],
};

/// Descriptor for `QuoteUpdatedEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List quoteUpdatedEventDescriptor = $convert.base64Decode(
    'ChFRdW90ZVVwZGF0ZWRFdmVudBIZCghldmVudF9pZBgBIAEoCVIHZXZlbnRJZBI7CgtvY2N1cn'
    'JlZF9hdBgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCm9jY3VycmVkQXQSNQoF'
    'cXVvdGUYAyABKAsyHy5icm9rZXJhZ2UubWFya2V0X2RhdGEudjEuUXVvdGVSBXF1b3Rl');

const $core.Map<$core.String, $core.dynamic> MarketDataServiceBase$json = {
  '1': 'MarketDataService',
  '2': [
    {
      '1': 'GetQuote',
      '2': '.brokerage.market_data.v1.GetQuoteRequest',
      '3': '.brokerage.market_data.v1.GetQuoteResponse'
    },
    {
      '1': 'GetMarketStatus',
      '2': '.brokerage.market_data.v1.GetMarketStatusRequest',
      '3': '.brokerage.market_data.v1.GetMarketStatusResponse'
    },
  ],
};

@$core.Deprecated('Use marketDataServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    MarketDataServiceBase$messageJson = {
  '.brokerage.market_data.v1.GetQuoteRequest': GetQuoteRequest$json,
  '.brokerage.market_data.v1.GetQuoteResponse': GetQuoteResponse$json,
  '.brokerage.market_data.v1.GetQuoteResponse.QuotesEntry':
      GetQuoteResponse_QuotesEntry$json,
  '.brokerage.market_data.v1.Quote': Quote$json,
  '.google.protobuf.Timestamp': $0.Timestamp$json,
  '.brokerage.market_data.v1.GetMarketStatusRequest':
      GetMarketStatusRequest$json,
  '.brokerage.market_data.v1.GetMarketStatusResponse':
      GetMarketStatusResponse$json,
};

/// Descriptor for `MarketDataService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List marketDataServiceDescriptor = $convert.base64Decode(
    'ChFNYXJrZXREYXRhU2VydmljZRJhCghHZXRRdW90ZRIpLmJyb2tlcmFnZS5tYXJrZXRfZGF0YS'
    '52MS5HZXRRdW90ZVJlcXVlc3QaKi5icm9rZXJhZ2UubWFya2V0X2RhdGEudjEuR2V0UXVvdGVS'
    'ZXNwb25zZRJ2Cg9HZXRNYXJrZXRTdGF0dXMSMC5icm9rZXJhZ2UubWFya2V0X2RhdGEudjEuR2'
    'V0TWFya2V0U3RhdHVzUmVxdWVzdBoxLmJyb2tlcmFnZS5tYXJrZXRfZGF0YS52MS5HZXRNYXJr'
    'ZXRTdGF0dXNSZXNwb25zZQ==');
