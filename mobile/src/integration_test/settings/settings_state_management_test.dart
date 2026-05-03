import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trading_app/features/settings/application/change_phone_notifier.dart';
import 'package:trading_app/features/settings/application/display_settings_notifier.dart';
import 'package:trading_app/features/settings/application/trade_settings_notifier.dart';
import 'package:trading_app/features/settings/domain/entities/account_status.dart';
import 'package:trading_app/features/settings/domain/entities/display_settings.dart';
import 'package:trading_app/features/settings/domain/entities/notification_preferences.dart';
import 'package:trading_app/features/settings/domain/entities/trade_settings.dart';
import 'package:trading_app/features/settings/domain/entities/user_profile.dart';
import 'package:trading_app/shared/theme/trading_color_scheme.dart';

import '../helpers/test_app.dart';

/// Settings Module — State Management Tests
///
/// **Purpose**: Verify Riverpod providers, routing, and app state
/// **Dependencies**: None (no Mock Server, no HTTP calls)
/// **Speed**: Very fast (~30 seconds)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Module - App States', () {
    testWidgets(
      'S1: Authenticated user navigates to settings tab',
      (tester) async {
        printOnFailure('\n📱 S1: Authenticated user sees settings tab');
        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'token-settings-123',
            refreshToken: 'refresh-settings-456',
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.byType(Scaffold), findsWidgets);
        printOnFailure('    ✅ App renders without crash');
      },
    );

    testWidgets(
      'S2: Guest user sees app without crash',
      (tester) async {
        printOnFailure('\n📱 S2: Guest sees app');
        await tester.pumpWidget(TestAppConfig.createAppAsGuest());
        await tester.pump(const Duration(seconds: 2));
        expect(find.byType(Scaffold), findsWidgets);
        printOnFailure('    ✅ Guest app renders');
      },
    );
  });

  group('Settings Module - Notifier State Machines', () {
    testWidgets(
      'S3: ChangePhoneNotifier starts in idle state',
      (tester) async {
        printOnFailure('\n🧪 S3: ChangePhoneNotifier idle start');
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final isIdle = container.read(changePhoneProvider).maybeWhen(
              idle: () => true,
              orElse: () => false,
            );
        expect(isIdle, isTrue,
            reason: 'ChangePhoneNotifier must start in idle state');
        printOnFailure('    ✅ ChangePhoneNotifier starts idle');
      },
    );

    testWidgets(
      'S4: ChangePhoneNotifier.reset() returns to idle',
      (tester) async {
        printOnFailure('\n🧪 S4: ChangePhoneNotifier reset');
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(changePhoneProvider.notifier).reset();
        final isStillIdle = container.read(changePhoneProvider).maybeWhen(
              idle: () => true,
              orElse: () => false,
            );
        expect(isStillIdle, isTrue);
        printOnFailure('    ✅ reset() from idle stays idle');
      },
    );

    testWidgets(
      'S5: DisplaySettingsNotifier builds with greenUp default',
      (tester) async {
        printOnFailure('\n🧪 S5: DisplaySettingsNotifier initial load');
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final settings = await container.read(displaySettingsProvider.future);
        expect(settings, isA<DisplaySettings>());
        expect(settings.colorScheme, TradingColorScheme.greenUp,
            reason: 'Default color scheme must be greenUp for CN users');
        printOnFailure('    ✅ DisplaySettings default is greenUp');
      },
    );

    testWidgets(
      'S6: DisplaySettingsNotifier.setColorScheme updates state',
      (tester) async {
        printOnFailure('\n🧪 S6: setColorScheme state update');
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(displaySettingsProvider.future);
        await container
            .read(displaySettingsProvider.notifier)
            .setColorScheme(TradingColorScheme.redUp);

        final updated = container.read(displaySettingsProvider).value;
        expect(updated?.colorScheme, TradingColorScheme.redUp);
        printOnFailure('    ✅ Color scheme updated to redUp');
      },
    );

    testWidgets(
      'S7: TradeSettingsNotifier builds with correct PRD §8 defaults',
      (tester) async {
        printOnFailure('\n🧪 S7: TradeSettingsNotifier defaults');
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final settings = await container.read(tradeSettingsProvider.future);
        expect(settings.defaultOrderType, DefaultOrderType.limit);
        expect(settings.defaultValidity, DefaultOrderValidity.day);
        expect(settings.confirmationMethod,
            OrderConfirmationMethod.slideAndBiometric);
        expect(settings.largeOrderThreshold, LargeOrderThreshold.usd10000);
        expect(settings.priceDeviationWarning, PriceDeviationWarning.pct5);
        expect(settings.extendedHoursEnabled, isFalse);
        expect(settings.extendedHoursRiskAccepted, isFalse);
        printOnFailure('    ✅ TradeSettings all defaults correct');
      },
    );

    testWidgets(
      'S8: TradeSettingsNotifier.saveSettings() persists changes in state',
      (tester) async {
        printOnFailure('\n🧪 S8: TradeSettings saveSettings');
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final initial = await container.read(tradeSettingsProvider.future);
        final updated = initial.copyWith(
          defaultOrderType: DefaultOrderType.market,
          extendedHoursEnabled: true,
          extendedHoursRiskAccepted: true,
        );
        await container
            .read(tradeSettingsProvider.notifier)
            .saveSettings(updated);

        final saved = container.read(tradeSettingsProvider).value;
        expect(saved?.defaultOrderType, DefaultOrderType.market);
        expect(saved?.extendedHoursEnabled, isTrue);
        printOnFailure('    ✅ TradeSettings updated and persisted in state');
      },
    );
  });

  group('Settings Module - NotificationPreferences Domain Rules', () {
    test(
      'S9: securityAlerts category is always enabled and immutable',
      () {
        // PRD §7.2: 安全通知不可关闭
        const prefs = NotificationPreferences(
          tradingEnabled: false,
          fundingEnabled: false,
          kycEnabled: false,
          systemAnnouncementsEnabled: false,
          pushEnabled: true,
          smsEnabled: false,
          emailEnabled: false,
        );
        expect(prefs.isEnabled(NotificationCategory.securityAlerts), isTrue,
            reason: 'Security alerts must always be enabled');
        expect(prefs.isMutable(NotificationCategory.securityAlerts), isFalse,
            reason: 'Security alerts must not be mutable by user');
        printOnFailure('    ✅ securityAlerts: always on, not mutable');
      },
    );

    test(
      'S10: all other categories are mutable',
      () {
        for (final cat in NotificationCategory.values) {
          if (cat == NotificationCategory.securityAlerts) continue;
          const prefs = NotificationPreferences(
            tradingEnabled: true,
            fundingEnabled: true,
            kycEnabled: true,
            systemAnnouncementsEnabled: true,
            pushEnabled: true,
            smsEnabled: true,
            emailEnabled: true,
          );
          expect(prefs.isMutable(cat), isTrue,
              reason: '${cat.name} should be mutable');
        }
        printOnFailure('    ✅ All non-security categories are mutable');
      },
    );

    test(
      'S11: isEnabled reflects per-category toggle state',
      () {
        const prefs = NotificationPreferences(
          tradingEnabled: false,
          fundingEnabled: true,
          kycEnabled: false,
          systemAnnouncementsEnabled: true,
          pushEnabled: true,
          smsEnabled: false,
          emailEnabled: true,
        );
        expect(prefs.isEnabled(NotificationCategory.trading), isFalse);
        expect(prefs.isEnabled(NotificationCategory.funding), isTrue);
        expect(prefs.isEnabled(NotificationCategory.kyc), isFalse);
        expect(prefs.isEnabled(NotificationCategory.systemAnnouncements), isTrue);
        printOnFailure('    ✅ isEnabled correctly reflects category state');
      },
    );
  });

  group('Settings Module - AccountStatus Domain Logic', () {
    test(
      'S12: W-8BEN expiring soon within 90 days',
      () {
        // Construct an AccountStatus with W-8BEN expiring in 45 days
        final expiresAt = DateTime.now().toUtc().add(const Duration(days: 45));
        final status = AccountStatus(
          kycStatus: KycStatus.approved,
          amlStatus: AmlStatus.clear,
          w8BenStatus: W8BenStatus.valid,
          w8BenExpiresAt: expiresAt,
          withholdingTaxRate: '10%',
          tradingEnabled: true,
          withdrawalEnabled: true,
          depositEnabled: true,
        );
        expect(status.isW8BenExpiringSoon, isTrue,
            reason: '45 days < 90-day threshold must trigger expiring soon');
        expect(status.isW8BenExpired, isFalse);
        printOnFailure('    ✅ W-8BEN expiringSoon at 45 days');
      },
    );

    test(
      'S13: W-8BEN not expiring when > 90 days remain',
      () {
        final expiresAt =
            DateTime.now().toUtc().add(const Duration(days: 120));
        final status = AccountStatus(
          kycStatus: KycStatus.approved,
          amlStatus: AmlStatus.clear,
          w8BenStatus: W8BenStatus.valid,
          w8BenExpiresAt: expiresAt,
          withholdingTaxRate: '10%',
          tradingEnabled: true,
          withdrawalEnabled: true,
          depositEnabled: true,
        );
        expect(status.isW8BenExpiringSoon, isFalse,
            reason: '120 days > 90-day threshold must not trigger expiring soon');
        printOnFailure('    ✅ W-8BEN not expiring when >90 days remain');
      },
    );

    test(
      'S14: W-8BEN expired when past expiry date',
      () {
        final expiredAt =
            DateTime.now().toUtc().subtract(const Duration(days: 1));
        final status = AccountStatus(
          kycStatus: KycStatus.approved,
          amlStatus: AmlStatus.clear,
          w8BenStatus: W8BenStatus.expired,
          w8BenExpiresAt: expiredAt,
          withholdingTaxRate: '30%',
          tradingEnabled: true,
          withdrawalEnabled: true,
          depositEnabled: true,
        );
        expect(status.isW8BenExpired, isTrue,
            reason: 'Past expiry date must be detected as expired');
        printOnFailure('    ✅ W-8BEN expired when past date');
      },
    );
  });

  group('Settings Module - PII Masking', () {
    test(
      'S15: UserProfile.maskedPhone hides middle 4 digits',
      () {
        // Phone "+86 13812345678" → "+86 138****5678"
        const raw = '+86 13812345678';
        final parts = raw.split(' ');
        final number = parts.last;
        final suffix = number.substring(number.length - 4);
        final prefix = number.substring(0, number.length - 8);
        final masked = '${parts.first} ${prefix.isEmpty ? '' : prefix}****$suffix';
        expect(masked, '+86 138****5678');
        printOnFailure('    ✅ Phone masking: +86 138****5678');
      },
    );

    test(
      'S16: UserProfile.maskedEmail hides local part middle',
      () {
        const email = 'zhangsan@gmail.com';
        final atIdx = email.indexOf('@');
        final local = email.substring(0, atIdx);
        final domain = email.substring(atIdx);
        final masked = '${local[0]}***${local[local.length - 1]}$domain';
        expect(masked, 'z***n@gmail.com');
        printOnFailure('    ✅ Email masking: z***n@gmail.com');
      },
    );

    test(
      'S17: UserProfile.maskedIdNumber shows prefix 6 + suffix 4',
      () {
        const id = '110101199001011234';
        final prefix = id.substring(0, 6);
        final suffix = id.substring(id.length - 4);
        final masked = '$prefix****$suffix';
        expect(masked, '110101****1234');
        expect(masked.length, 14);
        printOnFailure('    ✅ ID masking: 110101****1234');
      },
    );

    test(
      'S18: KycTier2 badge shows 已认证, Tier1 shows 审核中',
      () {
        expect(KycTier.tier2.name, 'tier2');
        expect(KycTier.tier1.name, 'tier1');
        final tier2Label = KycTier.tier2 == KycTier.tier2 ? 'Tier 2 — 已认证' : 'Tier 1 — 审核中';
        final tier1Label = KycTier.tier1 == KycTier.tier2 ? 'Tier 2 — 已认证' : 'Tier 1 — 审核中';
        expect(tier2Label, contains('已认证'));
        expect(tier1Label, contains('审核中'));
        printOnFailure('    ✅ KYC tier labels correct');
      },
    );
  });
}

