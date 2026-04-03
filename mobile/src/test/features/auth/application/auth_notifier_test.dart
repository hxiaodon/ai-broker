import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import 'package:trading_app/core/auth/token_service.dart';
import 'package:trading_app/features/auth/application/auth_notifier.dart';
import 'package:trading_app/features/auth/data/auth_repository_impl.dart';
import 'package:trading_app/features/auth/domain/entities/auth_token.dart';
import 'package:trading_app/features/auth/domain/repositories/auth_repository.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}
class MockTokenService extends Mock implements TokenService {}

void main() {
  late MockAuthRepository mockRepository;
  late MockTokenService mockTokenService;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockTokenService = MockTokenService();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
        tokenServiceProvider.overrideWithValue(mockTokenService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier State Machine', () {
    test('initial state is unauthenticated', () {
      final state = container.read(authNotifierProvider);
      expect(state, const AuthState.unauthenticated());
    });

    test('loginWithToken transitions to authenticated', () async {
      when(() => mockRepository.isBiometricRegistered())
          .thenAnswer((_) async => false);

      final notifier = container.read(authNotifierProvider.notifier);
      final token = AuthToken(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
        accountId: 'acc_123',
        accountStatus: 'ACTIVE',
      );

      await notifier.loginWithToken(token: token);

      final state = container.read(authNotifierProvider);
      expect(state, isA<_Authenticated>());
      final authenticated = state as _Authenticated;
      expect(authenticated.accountId, 'acc_123');
      expect(authenticated.accountStatus, 'ACTIVE');
      expect(authenticated.biometricEnabled, false);
    });

    test('enterGuestMode transitions to guest', () {
      final notifier = container.read(authNotifierProvider.notifier);
      notifier.enterGuestMode();

      final state = container.read(authNotifierProvider);
      expect(state, const AuthState.guest());
    });

    test('logout transitions to unauthenticated and clears tokens', () async {
      // Setup authenticated state
      when(() => mockRepository.isBiometricRegistered())
          .thenAnswer((_) async => false);
      when(() => mockRepository.logout()).thenAnswer((_) async {});

      final notifier = container.read(authNotifierProvider.notifier);
      final token = AuthToken(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
        accountId: 'acc_123',
        accountStatus: 'ACTIVE',
      );

      await notifier.loginWithToken(token: token);
      expect(container.read(authNotifierProvider), isA<_Authenticated>());

      // Logout
      await notifier.logout();

      final state = container.read(authNotifierProvider);
      expect(state, const AuthState.unauthenticated());
      verify(() => mockRepository.logout()).called(1);
    });

    test('loginWithBiometric succeeds when refresh token is valid', () async {
      when(() => mockTokenService.getRefreshToken())
          .thenAnswer((_) async => 'valid_refresh_token');
      when(() => mockRepository.refreshToken(refreshToken: any(named: 'refreshToken')))
          .thenAnswer((_) async => AuthToken(
                accessToken: 'new_access_token',
                refreshToken: 'new_refresh_token',
                accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
                accountId: 'acc_123',
                accountStatus: 'ACTIVE',
              ));
      when(() => mockRepository.isBiometricRegistered())
          .thenAnswer((_) async => true);

      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.loginWithBiometric();

      expect(success, true);
      final state = container.read(authNotifierProvider);
      expect(state, isA<_Authenticated>());
      final authenticated = state as _Authenticated;
      expect(authenticated.biometricEnabled, true);
    });

    test('loginWithBiometric fails when refresh token is missing', () async {
      when(() => mockTokenService.getRefreshToken())
          .thenAnswer((_) async => null);

      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.loginWithBiometric();

      expect(success, false);
      final state = container.read(authNotifierProvider);
      expect(state, const AuthState.unauthenticated());
    });

    test('loginWithBiometric fails when refresh fails', () async {
      when(() => mockTokenService.getRefreshToken())
          .thenAnswer((_) async => 'expired_refresh_token');
      when(() => mockRepository.refreshToken(refreshToken: any(named: 'refreshToken')))
          .thenThrow(Exception('Token expired'));

      final notifier = container.read(authNotifierProvider.notifier);
      final success = await notifier.loginWithBiometric();

      expect(success, false);
      final state = container.read(authNotifierProvider);
      expect(state, const AuthState.unauthenticated());
    });

    test('handleRemoteKick clears tokens and transitions to unauthenticated', () async {
      // Setup authenticated state
      when(() => mockRepository.isBiometricRegistered())
          .thenAnswer((_) async => false);
      when(() => mockTokenService.clearTokens()).thenAnswer((_) async {});

      final notifier = container.read(authNotifierProvider.notifier);
      final token = AuthToken(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
        accountId: 'acc_123',
        accountStatus: 'ACTIVE',
      );

      await notifier.loginWithToken(token: token);
      expect(container.read(authNotifierProvider), isA<_Authenticated>());

      // Remote kick
      await notifier.handleRemoteKick();

      final state = container.read(authNotifierProvider);
      expect(state, const AuthState.unauthenticated());
      verify(() => mockTokenService.clearTokens()).called(1);
    });
  });

  group('AuthNotifier Session Restore', () {
    test('restores session when valid access token exists', () async {
      when(() => mockTokenService.getAccessToken())
          .thenAnswer((_) async => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2NvdW50X2lkIjoiYWNjXzEyMyJ9.test');
      when(() => mockTokenService.getRefreshToken())
          .thenAnswer((_) async => 'refresh_token');
      when(() => mockTokenService.isAccessTokenValid())
          .thenAnswer((_) async => true);
      when(() => mockRepository.isBiometricRegistered())
          .thenAnswer((_) async => true);

      // Create new container to trigger build
      final newContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          tokenServiceProvider.overrideWithValue(mockTokenService),
        ],
      );

      // Read provider to trigger build
      newContainer.read(authNotifierProvider);

      // Wait for async session restore
      await Future.delayed(const Duration(milliseconds: 100));

      final state = newContainer.read(authNotifierProvider);
      expect(state, isA<_Authenticated>());

      newContainer.dispose();
    });

    test('attempts silent refresh when access token is expired', () async {
      when(() => mockTokenService.getAccessToken())
          .thenAnswer((_) async => 'expired_token');
      when(() => mockTokenService.getRefreshToken())
          .thenAnswer((_) async => 'valid_refresh_token');
      when(() => mockTokenService.isAccessTokenValid())
          .thenAnswer((_) async => false);
      when(() => mockRepository.refreshToken(refreshToken: any(named: 'refreshToken')))
          .thenAnswer((_) async => AuthToken(
                accessToken: 'new_access_token',
                refreshToken: 'new_refresh_token',
                accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
                accountId: 'acc_123',
                accountStatus: 'ACTIVE',
              ));
      when(() => mockRepository.isBiometricRegistered())
          .thenAnswer((_) async => false);

      final newContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          tokenServiceProvider.overrideWithValue(mockTokenService),
        ],
      );

      newContainer.read(authNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = newContainer.read(authNotifierProvider);
      expect(state, isA<_Authenticated>());
      verify(() => mockRepository.refreshToken(refreshToken: 'valid_refresh_token')).called(1);

      newContainer.dispose();
    });

    test('stays unauthenticated when no tokens exist', () async {
      when(() => mockTokenService.getAccessToken())
          .thenAnswer((_) async => null);
      when(() => mockTokenService.getRefreshToken())
          .thenAnswer((_) async => null);

      final newContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          tokenServiceProvider.overrideWithValue(mockTokenService),
        ],
      );

      newContainer.read(authNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = newContainer.read(authNotifierProvider);
      expect(state, const AuthState.unauthenticated());

      newContainer.dispose();
    });

    test('clears session when silent refresh fails', () async {
      when(() => mockTokenService.getAccessToken())
          .thenAnswer((_) async => 'expired_token');
      when(() => mockTokenService.getRefreshToken())
          .thenAnswer((_) async => 'expired_refresh_token');
      when(() => mockTokenService.isAccessTokenValid())
          .thenAnswer((_) async => false);
      when(() => mockRepository.refreshToken(refreshToken: any(named: 'refreshToken')))
          .thenThrow(Exception('Refresh token expired'));
      when(() => mockTokenService.clearTokens()).thenAnswer((_) async {});

      final newContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          tokenServiceProvider.overrideWithValue(mockTokenService),
        ],
      );

      newContainer.read(authNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = newContainer.read(authNotifierProvider);
      expect(state, const AuthState.unauthenticated());
      verify(() => mockTokenService.clearTokens()).called(1);

      newContainer.dispose();
    });
  });

  group('AuthNotifier Token Refresh', () {
    test('checkAndRefreshIfNeeded refreshes when token is invalid', () async {
      // Setup authenticated state
      when(() => mockRepository.isBiometricRegistered())
          .thenAnswer((_) async => false);

      final notifier = container.read(authNotifierProvider.notifier);
      final token = AuthToken(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
        accountId: 'acc_123',
        accountStatus: 'ACTIVE',
      );

      await notifier.loginWithToken(token: token);

      // Mock token as invalid
      when(() => mockTokenService.isAccessTokenValid())
          .thenAnswer((_) async => false);
      when(() => mockTokenService.getRefreshToken())
          .thenAnswer((_) async => 'valid_refresh_token');
      when(() => mockRepository.refreshToken(refreshToken: any(named: 'refreshToken')))
          .thenAnswer((_) async => AuthToken(
                accessToken: 'refreshed_access_token',
                refreshToken: 'refreshed_refresh_token',
                accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
                accountId: 'acc_123',
                accountStatus: 'ACTIVE',
              ));
      when(() => mockRepository.isBiometricRegistered())
          .thenAnswer((_) async => false);

      await notifier.checkAndRefreshIfNeeded();

      verify(() => mockRepository.refreshToken(refreshToken: 'valid_refresh_token')).called(1);
    });

    test('checkAndRefreshIfNeeded does nothing when not authenticated', () async {
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.checkAndRefreshIfNeeded();

      verifyNever(() => mockTokenService.isAccessTokenValid());
    });

    test('checkAndRefreshIfNeeded does nothing when token is still valid', () async {
      // Setup authenticated state
      when(() => mockRepository.isBiometricRegistered())
          .thenAnswer((_) async => false);

      final notifier = container.read(authNotifierProvider.notifier);
      final token = AuthToken(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
        accountId: 'acc_123',
        accountStatus: 'ACTIVE',
      );

      await notifier.loginWithToken(token: token);

      // Mock token as still valid
      when(() => mockTokenService.isAccessTokenValid())
          .thenAnswer((_) async => true);

      await notifier.checkAndRefreshIfNeeded();

      verifyNever(() => mockRepository.refreshToken(refreshToken: any(named: 'refreshToken')));
    });
  });
}
