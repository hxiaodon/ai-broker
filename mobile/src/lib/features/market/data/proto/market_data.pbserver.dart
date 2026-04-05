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

import 'package:protobuf/protobuf.dart' as $pb;

import 'market_data.pb.dart' as $1;
import 'market_data.pbjson.dart';

export 'market_data.pb.dart';

abstract class MarketDataServiceBase extends $pb.GeneratedService {
  $async.Future<$1.GetQuoteResponse> getQuote(
      $pb.ServerContext ctx, $1.GetQuoteRequest request);
  $async.Future<$1.GetMarketStatusResponse> getMarketStatus(
      $pb.ServerContext ctx, $1.GetMarketStatusRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'GetQuote':
        return $1.GetQuoteRequest();
      case 'GetMarketStatus':
        return $1.GetMarketStatusRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'GetQuote':
        return getQuote(ctx, request as $1.GetQuoteRequest);
      case 'GetMarketStatus':
        return getMarketStatus(ctx, request as $1.GetMarketStatusRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json =>
      MarketDataServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => MarketDataServiceBase$messageJson;
}
