import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/settings_repository_impl.dart';
import '../domain/entities/account_status.dart';

part 'account_status_notifier.g.dart';

/// Fetches account compliance status from GET /v1/profile/account-status.
@riverpod
Future<AccountStatus> accountStatus(Ref ref) =>
    ref.watch(settingsRepositoryProvider).getAccountStatus();
