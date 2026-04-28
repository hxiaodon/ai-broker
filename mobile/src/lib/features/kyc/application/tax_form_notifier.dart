import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../data/kyc_repository_impl.dart';
import '../domain/entities/tax_form.dart';
import 'kyc_error_messages.dart';
import 'kyc_session_notifier.dart';

part 'tax_form_notifier.freezed.dart';
part 'tax_form_notifier.g.dart';

@freezed
sealed class TaxFormState with _$TaxFormState {
  const factory TaxFormState.idle() = _Idle;
  const factory TaxFormState.submitting() = _Submitting;
  const factory TaxFormState.success() = _Success;
  const factory TaxFormState.error({required String message}) = _Error;
}

@riverpod
class TaxFormNotifier extends _$TaxFormNotifier {
  String? _pendingIdempotencyKey;

  @override
  TaxFormState build() => const TaxFormState.idle();

  /// Submits W-8BEN tax form.
  /// TIN transmitted via HTTPS — server applies AES-256-GCM at rest.
  Future<void> submitW8Ben({
    required String fullName,
    required String countryOfTaxResidence,
    String? tin,
    required bool tinNotAvailable,
    String? address,
  }) async {
    final sessionId = ref.read(kycSessionProvider).maybeWhen(
      active: (session) => session.sessionId,
      orElse: () => null,
    );
    if (sessionId == null) return;

    final form = TaxForm(
      type: TaxFormType.w8ben,
      w8ben: W8BenInfo(
        fullName: fullName,
        countryOfTaxResidence: countryOfTaxResidence,
        tin: tin,
        tinNotAvailable: tinNotAvailable,
        address: address,
        signatureDate: DateTime.now().toUtc(),
      ),
    );
    await _doSubmit(sessionId, form);
  }

  /// Submits W-9 tax form.
  /// SSN transmitted via HTTPS — server applies AES-256-GCM at rest.
  Future<void> submitW9({
    required String fullName,
    required String ssn,
    required String address,
  }) async {
    final sessionId = ref.read(kycSessionProvider).maybeWhen(
      active: (session) => session.sessionId,
      orElse: () => null,
    );
    if (sessionId == null) return;

    final form = TaxForm(
      type: TaxFormType.w9,
      w9: W9Info(fullName: fullName, ssn: ssn, address: address),
    );
    await _doSubmit(sessionId, form);
  }

  Future<void> _doSubmit(String sessionId, TaxForm form) async {
    _pendingIdempotencyKey ??= const Uuid().v4();
    final idempotencyKey = _pendingIdempotencyKey!;

    state = const TaxFormState.submitting();
    try {
      await ref.read(kycRepositoryProvider).submitTaxForm(
            sessionId: sessionId,
            form: form,
            idempotencyKey: idempotencyKey,
          );
      _pendingIdempotencyKey = null;
      ref.read(kycSessionProvider.notifier).advanceStep();
      state = const TaxFormState.success();
    } on Object catch (e) {
      AppLogger.warning('TaxForm submit failed: $e');
      state = TaxFormState.error(message: kycUserMessage(e));
    }
  }

  void reset() {
    _pendingIdempotencyKey = null;
    state = const TaxFormState.idle();
  }
}
