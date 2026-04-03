import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/core/storage/secure_storage_service.dart';
import 'package:trading_app/features/auth/data/auth_repository_impl.dart';
import 'package:trading_app/features/auth/presentation/screens/biometric_setup_screen.dart';

// Mocks
class MockAuthRepositoryImpl extends Mock implements AuthRepositoryImpl {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  setUpAll(() {
    // Initialize AppLogger before any tests run
    AppLogger.init(verbose: true);
  });

  group('BiometricSetupScreen - Phase 1 Basic', () {
    // Phase 1: Basic instantiation and compilation check
    // Full testing deferred to Phase 2 when full app context available

    testWidgets('screen instantiates without error', (tester) async {
      // This is a minimal test to ensure the screen compiles and basic widget structure exists
      try {
        final screen = const BiometricSetupScreen();
        expect(screen, isNotNull);
      } catch (e) {
        fail('BiometricSetupScreen failed to instantiate: $e');
      }
    });

    testWidgets('screen state can be created', (tester) async {
      // Verify the ConsumerStatefulWidget structure
      final widget = BiometricSetupScreen();
      final state = widget.createState();
      expect(state, isNotNull);
    });
  });

  group('BiometricSetupScreen - Deferred to Phase 2', () {
    // These tests require full app context with GoRouter and are deferred to Phase 2
    // See: docs/specs/shared/h5-vs-native-decision.md for navigation architecture

    testWidgets('renders and handles biometric setup flow', (tester) async {
      // TODO: Phase 2 - Full setup flow testing with ProviderScope
      // Expected behavior per PRD §T05:
      // 1. Screen displays biometric setup instructions
      // 2. "开始设置" button initiates biometric enrollment via local_auth
      // 3. Device prompts user for Face ID / Touch ID
      // 4. On success: show confirmation, persist to flutter_secure_storage
      // 5. Navigate to next screen in onboarding flow
      // Requires: ProviderScope + GoRouter + mocked AuthRepositoryImpl
      // References: PRD §T05, hifi prototype
    }, skip: true);

    testWidgets('handles user skipping setup', (tester) async {
      // TODO: Phase 2 - Skip counter logic with persistent storage
      // Expected: User can skip setup up to 3 times
      // When: User taps "稍后设置" button
      // Then: Skip count increments; check stored value via SecureStorageService
      // After 3 skips: Force setup or disable skip button
      // State: Tracked via flutter_secure_storage key 'biometric_skip_count'
      // References: PRD §T05, tech-spec §4.2 secure storage
    }, skip: true);

    testWidgets('registers biometric with server', (tester) async {
      // TODO: Phase 2 - Server enrollment API integration
      // Expected: After local biometric enrollment succeeds
      // Then: Call AuthRepositoryImpl.registerBiometric() with device public key
      // API: POST /auth/biometric with { deviceId, publicKey, enrollmentId }
      // Storage: Persist encrypted device key to secure storage
      // Error handling: Network failure → retry; server rejection → show error
      // References: AMS contract docs/contracts/ams-to-mobile.md
    }, skip: true);
  });
}
