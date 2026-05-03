import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../data/settings_repository_impl.dart';

part 'change_phone_notifier.freezed.dart';
part 'change_phone_notifier.g.dart';

/// Steps in the change-phone flow (PRD §6.3).
enum ChangePhoneStep {
  /// User enters the new phone number
  enterNewPhone,

  /// OTP sent to old number; user must enter it
  verifyOldOtp,

  /// OTP sent to new number; user must enter it
  verifyNewOtp,

  /// All verifications passed — phone update complete
  success,
}

@freezed
sealed class ChangePhoneState with _$ChangePhoneState {
  const factory ChangePhoneState.idle() = _Idle;
  const factory ChangePhoneState.loading() = _Loading;
  const factory ChangePhoneState.step({
    required ChangePhoneStep step,
    required String newPhone,
  }) = _Step;
  const factory ChangePhoneState.error({required String message}) = _Error;
  const factory ChangePhoneState.success() = _Success;
}

/// State machine for the 3-step change-phone flow.
///
/// Corrected PRD §6.3 sequence:
///   1. startFlow(newPhone) → sends OTP to OLD phone (server derives from JWT)
///   2. submitOldOtp(code)  → verifies old phone, then sends OTP to newPhone
///   3. submitNewOtp(code)  → verifies new phone + finalises update
@riverpod
class ChangePhoneNotifier extends _$ChangePhoneNotifier {
  @override
  ChangePhoneState build() => const ChangePhoneState.idle();

  Future<void> startFlow({required String newPhone}) async {
    // Guard: prevent concurrent calls
    if (state is _Loading) return;
    state = const ChangePhoneState.loading();
    try {
      // Step 1: OTP goes to the authenticated user's CURRENT phone — no phone param
      await ref.read(settingsRepositoryProvider).sendOtpToCurrentPhone();
      state = ChangePhoneState.step(
        step: ChangePhoneStep.verifyOldOtp,
        newPhone: newPhone,
      );
    } on Object catch (e) {
      AppLogger.warning('changePhone.startFlow failed: ${e.runtimeType}');
      state = ChangePhoneState.error(message: _humanize(e));
    }
  }

  Future<void> submitOldOtp(String otpCode) async {
    final current = state;
    // Guard: reject if not in the expected step
    if (current is! _Step || current.step != ChangePhoneStep.verifyOldOtp) return;
    state = const ChangePhoneState.loading();
    try {
      await ref
          .read(settingsRepositoryProvider)
          .verifyOldPhoneOtp(otpCode: otpCode);
      // Step 2: now send OTP to the NEW phone
      await ref
          .read(settingsRepositoryProvider)
          .sendChangePhoneOtp(phone: current.newPhone);
      state = ChangePhoneState.step(
        step: ChangePhoneStep.verifyNewOtp,
        newPhone: current.newPhone,
      );
    } on Object catch (e) {
      AppLogger.warning('changePhone.submitOldOtp failed: ${e.runtimeType}');
      // Rate-limit and cooldown are unrecoverable — show error state
      if (e is BusinessException &&
          (e.errorCode == 'RATE_LIMIT' ||
              e.errorCode == 'PHONE_CHANGE_COOLDOWN')) {
        state = ChangePhoneState.error(message: '更换手机号每 30 天仅可操作一次');
      } else {
        // Network errors, wrong OTP, etc. — stay on step so user can retry
        state = current;
      }
    }
  }

  Future<void> submitNewOtp(String otpCode) async {
    final current = state;
    if (current is! _Step || current.step != ChangePhoneStep.verifyNewOtp) return;
    state = const ChangePhoneState.loading();
    try {
      await ref.read(settingsRepositoryProvider).verifyNewPhoneAndUpdate(
            newPhone: current.newPhone,
            otpCode: otpCode,
          );
      state = const ChangePhoneState.success();
    } on Object catch (e) {
      AppLogger.warning('changePhone.submitNewOtp failed: ${e.runtimeType}');
      state = current; // Stay on new OTP step for retry
    }
  }

  void reset() => state = const ChangePhoneState.idle();

  String _humanize(Object e) {
    final msg = e.toString();
    // Use neutral message to avoid account enumeration (security-compliance §API Security)
    if (msg.contains('already') || msg.contains('CONFLICT')) {
      return '手机号验证失败，请确认号码后重试';
    }
    if (msg.contains('30') || msg.contains('RATE_LIMIT')) {
      return '更换手机号每 30 天仅可操作一次';
    }
    if (msg.contains('OTP') || msg.contains('invalid')) {
      return '验证码错误，请重试';
    }
    return '操作失败，请稍后重试';
  }
}
