import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/auth/domain/entities/auth_token.dart';
import 'package:trading_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:trading_app/features/auth/domain/usecases/refresh_token_usecase.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RefreshTokenUseCase refreshTokenUseCase;
  late _MockAuthRepository mockRepository;

  setUp(() {
    AppLogger.init(verbose: false);
    mockRepository = _MockAuthRepository();
    refreshTokenUseCase = RefreshTokenUseCase(mockRepository);
  });

  group('RefreshTokenUseCase', () {
    // ─── Happy Path Tests ───────────────────────────────────────────
    group('Happy Path', () {
      test('should refresh token and return new token', () async {
        // Arrange
        const refreshToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
            'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.'
            'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

        final newToken = AuthToken(
          accessToken: 'new-access-token-456',
          refreshToken: 'new-refresh-token-789',
          accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          accountId: 'account-456',
          accountStatus: 'ACTIVE',
        );

        when(() => mockRepository.refreshToken(refreshToken: refreshToken))
            .thenAnswer((_) async => newToken);

        // Act
        final result = await refreshTokenUseCase(refreshToken: refreshToken);

        // Assert
        expect(result, newToken);
        expect(result.accessToken, 'new-access-token-456');
      });

      test('should return token that expires in more than 5 minutes without cascade', () async {
        // Arrange
        const refreshToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
            'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.'
            'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

        final newToken = AuthToken(
          accessToken: 'new-access-token-456',
          refreshToken: 'new-refresh-token-789',
          // Expires in 10 minutes (more than 5-minute buffer)
          accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
          accountId: 'account-456',
          accountStatus: 'ACTIVE',
        );

        when(() => mockRepository.refreshToken(refreshToken: refreshToken))
            .thenAnswer((_) async => newToken);

        // Act
        final result = await refreshTokenUseCase(refreshToken: refreshToken);

        // Assert
        expect(result, newToken);
        expect(result.accessToken, 'new-access-token-456');
        // Verify repository was called only once (no cascade)
        verify(() => mockRepository.refreshToken(refreshToken: refreshToken)).called(1);
      });
    });

    // ─── Cascade Refresh Tests ──────────────────────────────────────
    group('Cascade Refresh', () {
      test('should cascade refresh if new token expires within 5 minutes', () async {
        // Arrange
        const initialRefreshToken = 'header.payload1.signature';
        const cascadeRefreshToken = 'header.payload2.signature';

        // First response: token expires in 3 minutes (< 5 minute buffer)
        final shortLivedToken = AuthToken(
          accessToken: 'short-lived-access',
          refreshToken: cascadeRefreshToken,
          accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 3)),
          accountId: 'account-123',
          accountStatus: 'ACTIVE',
        );

        // Final response: token expires in 30 minutes (> 5 minute buffer)
        final longLivedToken = AuthToken(
          accessToken: 'long-lived-access',
          refreshToken: 'final.refresh.token',
          accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
          accountId: 'account-456',
          accountStatus: 'ACTIVE',
        );

        // Setup mock to return different tokens on consecutive calls
        when(() => mockRepository.refreshToken(refreshToken: initialRefreshToken))
            .thenAnswer((_) async => shortLivedToken);
        when(() => mockRepository.refreshToken(refreshToken: cascadeRefreshToken))
            .thenAnswer((_) async => longLivedToken);

        // Act
        final result = await refreshTokenUseCase(refreshToken: initialRefreshToken);

        // Assert
        expect(result, longLivedToken);
        expect(result.accessToken, 'long-lived-access');
        // Verify cascade occurred: called with both initial and cascade tokens
        verify(() => mockRepository.refreshToken(refreshToken: initialRefreshToken)).called(1);
        verify(() => mockRepository.refreshToken(refreshToken: cascadeRefreshToken)).called(1);
      });

      test('should handle cascade chain with multiple short-lived tokens', () async {
        // Arrange
        const token1 = 'header.payload1.signature';
        const token2 = 'header.payload2.signature';
        const token3 = 'header.payload3.signature';

        final shortLived1 = AuthToken(
          accessToken: 'access-1',
          refreshToken: token2,
          accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 2)),
          accountId: 'account-1',
          accountStatus: 'ACTIVE',
        );

        final shortLived2 = AuthToken(
          accessToken: 'access-2',
          refreshToken: token3,
          accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 3)),
          accountId: 'account-2',
          accountStatus: 'ACTIVE',
        );

        final finalToken = AuthToken(
          accessToken: 'access-final',
          refreshToken: 'final.refresh.token',
          accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          accountId: 'account-final',
          accountStatus: 'ACTIVE',
        );

        when(() => mockRepository.refreshToken(refreshToken: token1))
            .thenAnswer((_) async => shortLived1);
        when(() => mockRepository.refreshToken(refreshToken: token2))
            .thenAnswer((_) async => shortLived2);
        when(() => mockRepository.refreshToken(refreshToken: token3))
            .thenAnswer((_) async => finalToken);

        // Act
        final result = await refreshTokenUseCase(refreshToken: token1);

        // Assert
        expect(result, finalToken);
        expect(result.accessToken, 'access-final');
        // All three refresh calls should have been made
        verify(() => mockRepository.refreshToken(refreshToken: token1)).called(1);
        verify(() => mockRepository.refreshToken(refreshToken: token2)).called(1);
        verify(() => mockRepository.refreshToken(refreshToken: token3)).called(1);
      });
    });

    // ─── Validation Tests ───────────────────────────────────────────
    group('Input Validation', () {
      test('should throw ValidationException for empty refresh token', () async {
        // Arrange
        const refreshToken = '';

        // Act & Assert
        expect(
          () => refreshTokenUseCase(refreshToken: refreshToken),
          throwsA(isA<ValidationException>().having(
            (e) => e.field,
            'field',
            'refreshToken',
          )),
        );
      });

      test('should throw ValidationException for invalid JWT format (missing parts)', () async {
        // Arrange - JWT should have 3 parts separated by dots
        const refreshToken = 'invalid-jwt-no-dots';

        // Act & Assert
        expect(
          () => refreshTokenUseCase(refreshToken: refreshToken),
          throwsA(isA<ValidationException>().having(
            (e) => e.field,
            'field',
            'refreshToken',
          )),
        );
      });

      test('should throw ValidationException for JWT with only 2 parts', () async {
        // Arrange
        const refreshToken = 'header.payload'; // Missing signature part

        // Act & Assert
        expect(
          () => refreshTokenUseCase(refreshToken: refreshToken),
          throwsA(isA<ValidationException>().having(
            (e) => e.field,
            'field',
            'refreshToken',
          )),
        );
      });

      test('should throw ValidationException for JWT with 4 parts', () async {
        // Arrange
        const refreshToken = 'header.payload.signature.extra'; // Too many parts

        // Act & Assert
        expect(
          () => refreshTokenUseCase(refreshToken: refreshToken),
          throwsA(isA<ValidationException>().having(
            (e) => e.field,
            'field',
            'refreshToken',
          )),
        );
      });

      test('should throw ValidationException for JWT with empty parts', () async {
        // Arrange
        const refreshToken = 'header..signature'; // Empty payload part

        // Act & Assert
        expect(
          () => refreshTokenUseCase(refreshToken: refreshToken),
          throwsA(isA<ValidationException>().having(
            (e) => e.field,
            'field',
            'refreshToken',
          )),
        );
      });
    });

    // ─── Error Handling Tests ───────────────────────────────────────
    group('Error Handling', () {
      test('should propagate AuthException (token expired)', () {
        // Arrange
        const refreshToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
            'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.'
            'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

        when(() => mockRepository.refreshToken(refreshToken: refreshToken))
            .thenThrow(AuthException(message: 'Refresh token expired'));

        // Act & Assert
        expect(
          refreshTokenUseCase(refreshToken: refreshToken),
          throwsA(isA<AuthException>()),
        );
      });

      test('should propagate NetworkException on network failure', () {
        // Arrange
        const refreshToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
            'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.'
            'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

        when(() => mockRepository.refreshToken(refreshToken: refreshToken))
            .thenThrow(NetworkException(message: 'Network timeout'));

        // Act & Assert
        expect(
          refreshTokenUseCase(refreshToken: refreshToken),
          throwsA(isA<NetworkException>()),
        );
      });

      test('should wrap unexpected Exception in NetworkException', () {
        // Arrange
        const refreshToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
            'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.'
            'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

        when(() => mockRepository.refreshToken(refreshToken: refreshToken))
            .thenThrow(Exception('Unexpected error'));

        // Act & Assert
        expect(
          refreshTokenUseCase(refreshToken: refreshToken),
          throwsA(isA<NetworkException>()),
        );
      });
    });
  });
}
