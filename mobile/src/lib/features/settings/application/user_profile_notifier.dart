import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/settings_repository_impl.dart';
import '../domain/entities/user_profile.dart';

part 'user_profile_notifier.g.dart';

/// Fetches and caches the user's profile from GET /v1/profile.
///
/// autoDispose: profile is refetched when user navigates back to the screen.
@riverpod
Future<UserProfile> userProfile(Ref ref) =>
    ref.watch(settingsRepositoryProvider).getProfile();
