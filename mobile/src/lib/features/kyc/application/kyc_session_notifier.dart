import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../data/kyc_repository_impl.dart';
import '../domain/entities/kyc_session.dart';

part 'kyc_session_notifier.freezed.dart';
part 'kyc_session_notifier.g.dart';

const _kSessionIdKey = 'kyc_session_id';
const _kPollIntervalSeconds = 5;
const _kMaxPollAttempts = 120; // 10 minutes max

@freezed
sealed class KycSessionState with _$KycSessionState {
  const factory KycSessionState.loading() = _Loading;
  const factory KycSessionState.noSession() = _NoSession;
  const factory KycSessionState.active({required KycSession session}) = _Active;
  const factory KycSessionState.expired() = _Expired;
  const factory KycSessionState.error({required String message}) = _KycError;
}

@Riverpod(keepAlive: true)
class KycSessionNotifier extends _$KycSessionNotifier {
  Timer? _pollTimer;
  int _pollAttempts = 0;

  @override
  KycSessionState build() {
    ref.onDispose(_cancelPolling);
    _restoreSession();
    return const KycSessionState.loading();
  }

  Future<void> _restoreSession() async {
    const storage = FlutterSecureStorage();
    final sessionId = await storage.read(
      key: _kSessionIdKey,
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    );
    if (sessionId == null) {
      state = const KycSessionState.noSession();
      return;
    }
    try {
      final session =
          await ref.read(kycRepositoryProvider).getKycStatus(sessionId);
      if (session.status == KycStatus.expired) {
        state = const KycSessionState.expired();
      } else {
        state = KycSessionState.active(session: session);
        if (session.status.isPolling) _startPolling(sessionId);
      }
    } on DioException catch (e) {
      AppLogger.warning('KYC session restore failed (network): $e');
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        // Token expired or session invalidated — clear stale key and start fresh.
        await _clearStoredSessionId();
        state = const KycSessionState.noSession();
      } else {
        // Transient network error — preserve the key and let the user retry.
        state = const KycSessionState.error(message: '网络错误，请检查连接后重试');
      }
    } on Object catch (e) {
      AppLogger.warning('KYC session restore failed: $e');
      state = const KycSessionState.error(message: '加载开户状态失败，请重试');
    }
  }

  /// Called after Step 1 startKyc succeeds — persists sessionId.
  Future<void> setSession(KycSession session) async {
    const storage = FlutterSecureStorage();
    await storage.write(
      key: _kSessionIdKey,
      value: session.sessionId,
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    );
    state = KycSessionState.active(session: session);
  }

  /// Advance to next step locally (optimistic, server is source of truth).
  void advanceStep() {
    final current = state;
    if (current is! _Active) return;
    state = KycSessionState.active(
      session: current.session.copyWith(
        currentStep: current.session.currentStep + 1,
      ),
    );
  }

  /// Begin status polling after final submit.
  void startPollingAfterSubmit(String sessionId) {
    _startPolling(sessionId);
  }

  void _startPolling(String sessionId) {
    _cancelPolling();
    _pollAttempts = 0; // always reset — prevents stale count from prior sessions
    _pollTimer = Timer.periodic(
      const Duration(seconds: _kPollIntervalSeconds),
      (_) => _poll(sessionId),
    );
  }

  Future<void> _poll(String sessionId) async {
    _pollAttempts++;
    if (_pollAttempts > _kMaxPollAttempts) {
      _cancelPolling();
      return;
    }
    try {
      final session =
          await ref.read(kycRepositoryProvider).getKycStatus(sessionId);
      state = KycSessionState.active(session: session);
      if (session.status.isTerminal) _cancelPolling();
    } on Object catch (e) {
      AppLogger.warning('KYC status poll failed: $e');
    }
  }

  void _cancelPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Clear session on EXPIRED or after APPROVED (user starts fresh).
  Future<void> clearSession() async {
    _cancelPolling();
    await _clearStoredSessionId();
    state = const KycSessionState.noSession();
  }

  Future<void> _clearStoredSessionId() async {
    const storage = FlutterSecureStorage();
    await storage.delete(
      key: _kSessionIdKey,
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    );
  }
}
