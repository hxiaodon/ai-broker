import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../data/kyc_repository_impl.dart';
import '../domain/entities/personal_info.dart';
import 'kyc_session_notifier.dart';

part 'personal_info_notifier.freezed.dart';
part 'personal_info_notifier.g.dart';

@freezed
sealed class PersonalInfoState with _$PersonalInfoState {
  const factory PersonalInfoState.idle() = _Idle;
  const factory PersonalInfoState.submitting() = _Submitting;
  const factory PersonalInfoState.success() = _Success;
  const factory PersonalInfoState.error({required String message}) = _Error;
}

@riverpod
class PersonalInfoNotifier extends _$PersonalInfoNotifier {
  @override
  PersonalInfoState build() => const PersonalInfoState.idle();

  Future<void> submit(PersonalInfo info) async {
    if (!info.isAdult) {
      state = const PersonalInfoState.error(
          message: '必须年满 18 岁方可开户');
      return;
    }
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(info.firstName) ||
        !RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(info.lastName)) {
      state = const PersonalInfoState.error(
          message: '姓名仅允许英文字母');
      return;
    }

    state = const PersonalInfoState.submitting();
    try {
      final session = await ref.read(kycRepositoryProvider).startKyc(info);
      // Embed the legal name so Step 8 can compare the signature input.
      final sessionWithName = session.copyWith(
        accountHolderName: info.fullName,
      );
      await ref.read(kycSessionProvider.notifier).setSession(sessionWithName);
      state = const PersonalInfoState.success();
    } on Object catch (e) {
      AppLogger.warning('PersonalInfo submit failed: $e');
      state = PersonalInfoState.error(message: _userMessage(e));
    }
  }

  void reset() => state = const PersonalInfoState.idle();
}

String _userMessage(Object e) {
  // Avoid leaking internal DioException details to the UI.
  final raw = e.toString();
  if (raw.contains('INVALID_AGE')) return '必须年满 18 岁方可开户';
  if (raw.contains('INVALID_PHONE')) return '手机号格式不正确';
  if (raw.contains('SocketException') || raw.contains('TimeoutException')) {
    return '网络错误，请检查连接后重试';
  }
  return '提交失败，请稍后重试';
}
