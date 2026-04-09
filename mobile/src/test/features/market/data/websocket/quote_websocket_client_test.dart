// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:fake_async/fake_async.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/data/proto/market_data.pb.dart'
    as proto;
import 'package:trading_app/features/market/data/websocket/quote_websocket_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake WebSocket channel
// ─────────────────────────────────────────────────────────────────────────────

/// Simulates the server side of a WebSocket connection.
///
/// - Push server → client messages via [serverSend].
/// - Inspect messages the client sent via [sent].
/// - Simulate server close via [serverClose].
class FakeWebSocketChannel implements WebSocketChannel {
  FakeWebSocketChannel({int? closeCodeOverride})
      : _closeCodeOverride = closeCodeOverride;

  // Satisfy StreamChannelMixin abstract members not used in tests.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final int? _closeCodeOverride;

  // Use sync:true so that serverSend() delivers synchronously to _onFrame,
  // leaving only one async hop (to _quoteController listeners).
  final _serverToClient = StreamController<dynamic>.broadcast(sync: true);
  final _clientMessages = <dynamic>[];

  int? _serverCloseCode;

  /// Messages the app sent to the "server" (for assertion).
  List<dynamic> get sent => List.unmodifiable(_clientMessages);

  /// Push a message from the fake server to the client.
  void serverSend(dynamic msg) => _serverToClient.add(msg);

  /// Simulate the server closing the connection with [code].
  Future<void> serverClose([int? code]) async {
    _serverCloseCode = code ?? _closeCodeOverride;
    await _serverToClient.close();
  }

  // ── WebSocketChannel interface ────────────────────────────────────────────

  @override
  Stream<dynamic> get stream => _serverToClient.stream;

  @override
  WebSocketSink get sink => _FakeWebSocketSink(
        onAdd: (data) => _clientMessages.add(data),
      );

  @override
  Future<void> get ready => Future<void>.value();

  @override
  int? get closeCode => _serverCloseCode ?? _closeCodeOverride;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => 'brokerage-market-v1';
}

class _FakeWebSocketSink implements WebSocketSink {
  _FakeWebSocketSink({required void Function(dynamic) onAdd}) : _onAdd = onAdd;

  final void Function(dynamic) _onAdd;

  @override
  void add(dynamic data) => _onAdd(data);

  @override
  Future<void> close([int? closeCode, String? closeReason]) =>
      Future<void>.value();

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<dynamic> get done => Future<void>.value();

  @override
  Future<void> addStream(Stream<dynamic> stream) => stream.drain<void>();
}

// ─────────────────────────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Decode a message the client sent as a JSON map.
Map<String, dynamic> decodeJson(dynamic raw) =>
    jsonDecode(raw as String) as Map<String, dynamic>;

/// Drain all pending microtasks (two async hops: serverSend → _onFrame →
/// _quoteController → listener). One microtask round is not enough, so we
/// schedule a zero-duration timer, which fires only after the microtask queue
/// is fully drained.
Future<void> drainStreams() => Future<void>.delayed(Duration.zero);

/// Build a minimal SNAPSHOT proto binary frame.
Uint8List buildSnapshotFrame({
  String symbol = 'AAPL',
  String price = '150.0000',
  String change = '1.5000',
  String changePct = '0.0100',
  int volume = 1000000,
  String prevClose = '148.5000',
  String open = '149.0000',
  String high = '151.0000',
  String low = '148.0000',
  String turnover = '150000000',
  String bid = '149.9900',
  String ask = '150.0100',
}) {
  final quote = proto.Quote(
    symbol: symbol,
    market: proto.Market.MARKET_US,
    price: price,
    change: change,
    changePct: changePct,
    volume: Int64(volume),
    prevClose: prevClose,
    open: open,
    high: high,
    low: low,
    turnover: turnover,
    bid: bid,
    ask: ask,
    marketStatus: proto.MarketStatus.MARKET_STATUS_REGULAR,
  );
  final frame = proto.WsQuoteFrame(
    frameType: proto.WsQuoteFrame_FrameType.FRAME_TYPE_SNAPSHOT,
    quote: quote,
  );
  return Uint8List.fromList(frame.writeToBuffer());
}

/// Build a minimal TICK proto binary frame (partial patch).
Uint8List buildTickFrame({
  String symbol = 'AAPL',
  String price = '150.5000',
  String change = '2.0000',
  String changePct = '0.0134',
  int volume = 1200000,
}) {
  final quote = proto.Quote(
    symbol: symbol,
    price: price,
    change: change,
    changePct: changePct,
    volume: Int64(volume),
  );
  final frame = proto.WsQuoteFrame(
    frameType: proto.WsQuoteFrame_FrameType.FRAME_TYPE_TICK,
    quote: quote,
  );
  return Uint8List.fromList(frame.writeToBuffer());
}

/// Build a DELAYED proto binary frame (T-15min guest quote).
Uint8List buildDelayedFrame({
  String symbol = 'AAPL',
  String price = '149.5000',
}) {
  final quote = proto.Quote(
    symbol: symbol,
    market: proto.Market.MARKET_US,
    price: price,
    delayed: true,
    marketStatus: proto.MarketStatus.MARKET_STATUS_REGULAR,
  );
  final frame = proto.WsQuoteFrame(
    frameType: proto.WsQuoteFrame_FrameType.FRAME_TYPE_DELAYED,
    quote: quote,
  );
  return Uint8List.fromList(frame.writeToBuffer());
}

/// JSON `auth_result` success frame.
String authResultJson({String userType = 'registered'}) =>
    jsonEncode({'type': 'auth_result', 'success': true, 'user_type': userType});

/// JSON `auth_result` failure frame.
String authResultFailJson() =>
    jsonEncode({'type': 'auth_result', 'success': false});

/// JSON `reauth_result` success frame.
String reauthResultJson({String userType = 'registered'}) => jsonEncode(
    {'type': 'reauth_result', 'success': true, 'user_type': userType});

/// JSON `reauth_result` failure frame.
String reauthResultFailJson() =>
    jsonEncode({'type': 'reauth_result', 'success': false});

// ─────────────────────────────────────────────────────────────────────────────
// Test suite
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // AppLogger uses a `late final` field — must be initialized before any test
  // that calls through to the client (which logs internally).
  setUpAll(() => AppLogger.init());

  late FakeWebSocketChannel fakeChannel;
  late QuoteWebSocketClient client;

  /// Create a fresh client + channel pair.
  void createClient({int? serverCloseCode}) {
    fakeChannel = FakeWebSocketChannel(closeCodeOverride: serverCloseCode);
    client = QuoteWebSocketClient(
      wsUrl: 'wss://fake.example.com/market',
      authTimeoutSeconds: 5,
      pingIntervalSeconds: 30,
      channelFactory: (_, {protocols}) => fakeChannel,
    );
  }

  /// Connect and complete the auth handshake in one step.
  ///
  /// The `await Future<void>.microtask(...)` here lets `connect()` advance
  /// past `await _channel!.ready` and register its auth completer before we
  /// push the server auth_result (avoids a missed-event race on the sync
  /// broadcast controller).
  Future<WsUserType> connectAndAuth({
    String? token,
    String userType = 'registered',
  }) async {
    final connectFuture = client.connect(token: token);
    await Future<void>.microtask(() {});
    fakeChannel.serverSend(authResultJson(userType: userType));
    return connectFuture;
  }

  // ── connect() ──────────────────────────────────────────────────────────────

  group('connect()', () {
    test('registered auth — sends auth action with token and returns registered',
        () async {
      createClient();
      final result = await connectAndAuth(token: 'jwt-token-123');

      expect(result, WsUserType.registered);
      final authMsg = decodeJson(fakeChannel.sent.first);
      expect(authMsg['action'], 'auth');
      expect(authMsg['token'], 'jwt-token-123');
    });

    test('guest auth — sends empty token and returns guest', () async {
      createClient();
      final result = await connectAndAuth(token: null, userType: 'guest');

      expect(result, WsUserType.guest);
      final authMsg = decodeJson(fakeChannel.sent.first);
      expect(authMsg['token'], '');
    });

    test('auth failure — throws AuthException', () async {
      createClient();
      final connectFuture = client.connect(token: 'bad-token');
      await Future<void>.microtask(() {});
      fakeChannel.serverSend(authResultFailJson());

      await expectLater(connectFuture, throwsA(isA<AuthException>()));
    });

    test('auth timeout — throws AuthException after authTimeoutSeconds', () {
      fakeAsync((fake) {
        createClient();

        Object? caughtError;
        client.connect(token: 'any').then<void>(
          (_) {},
          onError: (Object e) { caughtError = e; },
        );

        // Elapse past the 5-second auth timeout without sending auth_result.
        fake.elapse(const Duration(seconds: 6));

        expect(caughtError, isA<AuthException>());
      });
    });

    test('connect() wraps channel factory exception in NetworkException',
        () async {
      client = QuoteWebSocketClient(
        wsUrl: 'wss://fake.example.com/market',
        channelFactory: (_, {protocols}) =>
            throw Exception('connection refused'),
      );

      await expectLater(
        client.connect(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('second connect() call throws StateError before auth completes',
        () async {
      createClient();
      final f = client.connect(token: 'tok');
      await Future<void>.microtask(() {});

      expect(
        () => client.connect(token: 'tok2'),
        throwsA(isA<StateError>()),
      );

      // Finish the pending auth to avoid leaked futures.
      fakeChannel.serverSend(authResultJson());
      await f;
    });
  });

  // ── subscribe() / unsubscribe() ────────────────────────────────────────────

  group('subscribe() / unsubscribe()', () {
    test('subscribe sends correct JSON action with symbols list', () async {
      createClient();
      await connectAndAuth();

      await client.subscribe(['AAPL', 'TSLA']);

      final msg = decodeJson(fakeChannel.sent.last);
      expect(msg['action'], 'subscribe');
      expect(msg['symbols'], ['AAPL', 'TSLA']);
    });

    test('unsubscribe sends correct JSON action', () async {
      createClient();
      await connectAndAuth();

      await client.subscribe(['AAPL', 'TSLA']);
      client.unsubscribe(['TSLA']);

      final msg = decodeJson(fakeChannel.sent.last);
      expect(msg['action'], 'unsubscribe');
      expect(msg['symbols'], ['TSLA']);
    });

    test('subscribe() throws StateError when not connected', () {
      createClient();
      expect(
        () => client.subscribe(['AAPL']),
        throwsA(isA<StateError>()),
      );
    });

    test('unsubscribe() throws StateError when not connected', () {
      createClient();
      expect(
        () => client.unsubscribe(['AAPL']),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ── binary frames — SNAPSHOT ───────────────────────────────────────────────

  group('binary frames — SNAPSHOT', () {
    test('SNAPSHOT frame is decoded and emitted on quoteStream', () async {
      createClient();
      await connectAndAuth();

      final updates = <WsQuoteUpdate>[];
      final sub = client.quoteStream.listen(updates.add);

      fakeChannel.serverSend(buildSnapshotFrame(symbol: 'AAPL', price: '150.0000'));
      await drainStreams();

      expect(updates, hasLength(1));
      expect(updates.first.frameType, WsFrameType.snapshot);
      expect(updates.first.symbol, 'AAPL');
      expect(updates.first.quote.price, Decimal.parse('150.0000'));

      await sub.cancel();
    });

    test('SNAPSHOT sets bid/ask from proto string fields', () async {
      createClient();
      await connectAndAuth();

      final updates = <WsQuoteUpdate>[];
      final sub = client.quoteStream.listen(updates.add);

      fakeChannel.serverSend(
        buildSnapshotFrame(bid: '149.9900', ask: '150.0100'),
      );
      await drainStreams();

      expect(updates.first.quote.bid, Decimal.parse('149.9900'));
      expect(updates.first.quote.ask, Decimal.parse('150.0100'));

      await sub.cancel();
    });

    test('SNAPSHOT with empty bid/ask proto fields produces null bid/ask',
        () async {
      createClient();
      await connectAndAuth();

      final updates = <WsQuoteUpdate>[];
      final sub = client.quoteStream.listen(updates.add);

      // Omit bid/ask — proto3 zero-value is empty string, maps to null.
      final quote = proto.Quote(
        symbol: 'AAPL',
        price: '150.0000',
        marketStatus: proto.MarketStatus.MARKET_STATUS_REGULAR,
      );
      final frame = proto.WsQuoteFrame(
        frameType: proto.WsQuoteFrame_FrameType.FRAME_TYPE_SNAPSHOT,
        quote: quote,
      );
      fakeChannel.serverSend(Uint8List.fromList(frame.writeToBuffer()));
      await drainStreams();

      expect(updates.first.quote.bid, isNull);
      expect(updates.first.quote.ask, isNull);

      await sub.cancel();
    });
  });

  // ── binary frames — TICK ───────────────────────────────────────────────────

  group('binary frames — TICK', () {
    test('TICK frame is decoded with WsFrameType.tick', () async {
      createClient();
      await connectAndAuth();

      final updates = <WsQuoteUpdate>[];
      final sub = client.quoteStream.listen(updates.add);

      fakeChannel.serverSend(buildTickFrame(symbol: 'TSLA', price: '250.5000'));
      await drainStreams();

      expect(updates, hasLength(1));
      expect(updates.first.frameType, WsFrameType.tick);
      expect(updates.first.symbol, 'TSLA');
      expect(updates.first.quote.price, Decimal.parse('250.5000'));

      await sub.cancel();
    });
  });

  // ── binary frames — DELAYED ────────────────────────────────────────────────

  group('binary frames — DELAYED', () {
    test('DELAYED frame is decoded with WsFrameType.delayed and delayed=true',
        () async {
      createClient();
      await connectAndAuth();

      final updates = <WsQuoteUpdate>[];
      final sub = client.quoteStream.listen(updates.add);

      fakeChannel.serverSend(buildDelayedFrame(symbol: 'BABA', price: '80.0000'));
      await drainStreams();

      expect(updates.first.frameType, WsFrameType.delayed);
      expect(updates.first.quote.delayed, isTrue);

      await sub.cancel();
    });
  });

  // ── HK market frame ────────────────────────────────────────────────────────

  group('HK market frame', () {
    test('MARKET_HK proto field maps to market="HK" on the domain Quote',
        () async {
      createClient();
      await connectAndAuth();

      final updates = <WsQuoteUpdate>[];
      final sub = client.quoteStream.listen(updates.add);

      final quote = proto.Quote(
        symbol: '0700',
        market: proto.Market.MARKET_HK,
        price: '450.000',
        marketStatus: proto.MarketStatus.MARKET_STATUS_REGULAR,
      );
      final frame = proto.WsQuoteFrame(
        frameType: proto.WsQuoteFrame_FrameType.FRAME_TYPE_SNAPSHOT,
        quote: quote,
      );
      fakeChannel.serverSend(Uint8List.fromList(frame.writeToBuffer()));
      await drainStreams();

      expect(updates.first.quote.market, 'HK');

      await sub.cancel();
    });
  });

  // ── garbled binary frame ───────────────────────────────────────────────────

  group('invalid binary frame', () {
    test('garbled bytes propagate error to quoteStream for UI warning',
        () async {
      createClient();
      await connectAndAuth();

      final errors = <Object>[];
      final sub = client.quoteStream.listen((_) {}, onError: errors.add);

      fakeChannel.serverSend(Uint8List.fromList([0xFF, 0xFE, 0x00]));
      await drainStreams();

      expect(errors, hasLength(1));
      expect(errors.first, isA<BusinessException>());
      expect((errors.first as BusinessException).errorCode, 'PROTOBUF_DECODE_ERROR');

      await sub.cancel();
    });
  });

  // ── JSON control frames ────────────────────────────────────────────────────

  group('text frames — control', () {
    test('token_expiring adds WsTokenExpiringException to quoteStream',
        () async {
      createClient();
      await connectAndAuth();

      final errors = <Object>[];
      final sub = client.quoteStream.listen((_) {}, onError: errors.add);

      fakeChannel.serverSend(
        jsonEncode({'type': 'token_expiring', 'expires_in': 30}),
      );
      await drainStreams();

      expect(errors, hasLength(1));
      expect(errors.first, isA<WsTokenExpiringException>());
      expect(
        (errors.first as WsTokenExpiringException).expiresInSeconds,
        30,
      );

      await sub.cancel();
    });

    test('server error frame adds BusinessException to quoteStream', () async {
      createClient();
      await connectAndAuth();

      final errors = <Object>[];
      final sub = client.quoteStream.listen((_) {}, onError: errors.add);

      fakeChannel.serverSend(jsonEncode({
        'type': 'error',
        'code': 'SYMBOL_LIMIT_EXCEEDED',
        'message': 'Too many symbols',
      }));
      await drainStreams();

      expect(errors.first, isA<BusinessException>());
      expect(
        (errors.first as BusinessException).errorCode,
        'SYMBOL_LIMIT_EXCEEDED',
      );

      await sub.cancel();
    });

    test('subscribe_ack is consumed without emitting errors', () async {
      createClient();
      await connectAndAuth();

      final errors = <Object>[];
      final sub = client.quoteStream.listen((_) {}, onError: errors.add);

      fakeChannel.serverSend(
        jsonEncode({'type': 'subscribe_ack', 'symbols': ['AAPL']}),
      );
      await drainStreams();

      expect(errors, isEmpty);
      await sub.cancel();
    });

    test('pong frame is silently consumed', () async {
      createClient();
      await connectAndAuth();

      final errors = <Object>[];
      final sub = client.quoteStream.listen((_) {}, onError: errors.add);

      fakeChannel.serverSend(jsonEncode({'type': 'pong'}));
      await drainStreams();

      expect(errors, isEmpty);
      await sub.cancel();
    });

    test('malformed JSON text frame propagates error to stream', () async {
      createClient();
      await connectAndAuth();

      final errors = <Object>[];
      final sub = client.quoteStream.listen((_) {}, onError: errors.add);

      fakeChannel.serverSend('not json {{{');
      await drainStreams();

      expect(errors, hasLength(1));
      expect(errors.first, isA<BusinessException>());
      expect((errors.first as BusinessException).errorCode, 'JSON_DECODE_ERROR');
      await sub.cancel();
    });
  });

  // ── reauth() ───────────────────────────────────────────────────────────────

  group('reauth()', () {
    test('reauth success — future resolves with new WsUserType', () async {
      createClient();
      await connectAndAuth(token: null, userType: 'guest');

      final reauthFuture = client.reauth('new-jwt-token');
      fakeChannel.serverSend(reauthResultJson(userType: 'registered'));

      final result = await reauthFuture;
      expect(result, WsUserType.registered);

      // The reauth action message must carry the new token.
      final msg = decodeJson(
        fakeChannel.sent.firstWhere(
          (m) => (decodeJson(m))['action'] == 'reauth',
        ),
      );
      expect(msg['token'], 'new-jwt-token');
    });

    test('reauth failure — future completes with AuthException', () async {
      createClient();
      await connectAndAuth();

      final reauthFuture = client.reauth('expired-token');
      fakeChannel.serverSend(reauthResultFailJson());

      await expectLater(reauthFuture, throwsA(isA<AuthException>()));
    });

    test('reauth() throws StateError when not connected', () {
      createClient();
      expect(
        () => client.reauth('token'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ── close code mapping ─────────────────────────────────────────────────────

  group('close code mapping', () {
    Future<Object?> captureCloseCodeError(int code) async {
      createClient(serverCloseCode: code);
      await connectAndAuth();

      Object? captured;
      final sub = client.quoteStream.listen(
        (_) {},
        onError: (Object e) { captured = e; },
      );

      await fakeChannel.serverClose(code);
      await drainStreams();
      await sub.cancel();

      return captured;
    }

    test('code 4001 → AuthException', () async {
      final err = await captureCloseCodeError(4001);
      expect(err, isA<AuthException>());
    });

    test('code 4002 → AuthException', () async {
      final err = await captureCloseCodeError(4002);
      expect(err, isA<AuthException>());
    });

    test('code 4003 → BusinessException with SYMBOL_LIMIT_EXCEEDED', () async {
      final err = await captureCloseCodeError(4003);
      expect(err, isA<BusinessException>());
      expect((err! as BusinessException).errorCode, 'SYMBOL_LIMIT_EXCEEDED');
    });

    test('code 4004 → NetworkException', () async {
      final err = await captureCloseCodeError(4004);
      expect(err, isA<NetworkException>());
    });

    test('unexpected close code (1006) → NetworkException', () async {
      final err = await captureCloseCodeError(1006);
      expect(err, isA<NetworkException>());
    });
  });

  // ── heartbeat ping timer ───────────────────────────────────────────────────

  group('heartbeat ping timer', () {
    test('ping is sent every pingIntervalSeconds', () {
      fakeAsync((fake) {
        createClient();

        bool connected = false;
        client.connect(token: 'tok').then<void>(
          (_) { connected = true; },
          onError: (_) {},
        );

        fake.flushMicrotasks();
        fakeChannel.serverSend(authResultJson());
        fake.flushMicrotasks();

        expect(connected, isTrue);

        final sentBefore = fakeChannel.sent.length;

        // First interval → 1 ping.
        fake.elapse(const Duration(seconds: 30));
        final pingsAfter30 = fakeChannel.sent
            .skip(sentBefore)
            .where((m) => (decodeJson(m))['action'] == 'ping')
            .length;
        expect(pingsAfter30, 1);

        // Second interval → 2 total pings.
        fake.elapse(const Duration(seconds: 30));
        final pingsAfter60 = fakeChannel.sent
            .skip(sentBefore)
            .where((m) => (decodeJson(m))['action'] == 'ping')
            .length;
        expect(pingsAfter60, 2);
      });
    });

    test('ping is NOT sent after close()', () {
      fakeAsync((fake) {
        createClient();

        client.connect(token: 'tok').then<void>(
          (_) {},
          onError: (_) {},
        );
        fake.flushMicrotasks();
        fakeChannel.serverSend(authResultJson());
        fake.flushMicrotasks();

        client.close();
        fake.flushMicrotasks();

        final sentBefore = fakeChannel.sent.length;
        fake.elapse(const Duration(seconds: 60));

        final pings = fakeChannel.sent.skip(sentBefore).where((m) {
          try {
            return (decodeJson(m))['action'] == 'ping';
          } catch (_) {
            return false;
          }
        }).length;
        expect(pings, 0);
      });
    });
  });

  // ── dispose() ─────────────────────────────────────────────────────────────

  group('dispose()', () {
    test('quoteStream is closed after dispose()', () async {
      createClient();
      await connectAndAuth();

      await client.dispose();

      final done = Completer<void>();
      client.quoteStream.listen(
        (_) {},
        onDone: done.complete,
        cancelOnError: false,
      );
      await done.future.timeout(const Duration(milliseconds: 100));
    });
  });

  // ── multiple frames in sequence ────────────────────────────────────────────

  group('multiple quote updates', () {
    test('SNAPSHOT + SNAPSHOT + TICK frames are emitted in order', () async {
      createClient();
      await connectAndAuth();

      final updates = <WsQuoteUpdate>[];
      final sub = client.quoteStream.listen(updates.add);

      fakeChannel.serverSend(buildSnapshotFrame(symbol: 'AAPL', price: '150.0000'));
      fakeChannel.serverSend(buildSnapshotFrame(symbol: 'TSLA', price: '250.0000'));
      fakeChannel.serverSend(buildTickFrame(symbol: 'AAPL', price: '150.5000'));
      await drainStreams();

      expect(updates, hasLength(3));
      expect(updates[0].symbol, 'AAPL');
      expect(updates[0].frameType, WsFrameType.snapshot);
      expect(updates[1].symbol, 'TSLA');
      expect(updates[1].frameType, WsFrameType.snapshot);
      expect(updates[2].symbol, 'AAPL');
      expect(updates[2].frameType, WsFrameType.tick);
      expect(updates[2].quote.price, Decimal.parse('150.5000'));

      await sub.cancel();
    });
  });
}
