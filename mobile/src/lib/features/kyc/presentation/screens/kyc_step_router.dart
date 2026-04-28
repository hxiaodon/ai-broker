import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../application/kyc_session_notifier.dart';
import 'kyc_step1_personal_screen.dart';
import 'kyc_step2_document_screen.dart';
import 'kyc_step3_address_screen.dart';
import 'kyc_step4_finance_screen.dart';
import 'kyc_step5_investment_screen.dart';
import 'kyc_step6_tax_screen.dart';
import 'kyc_step7_disclosure_screen.dart';
import 'kyc_step8_agreement_screen.dart';

/// KYC step container. Renders the correct step based on [KycSessionNotifier]
/// current step. Wraps each screen with a shared progress header.
class KycStepRouter extends ConsumerWidget {
  const KycStepRouter({super.key});

  static const _colors = ColorTokens.greenUp;
  static const _totalSteps = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(kycSessionProvider);

    final currentStep = sessionState.maybeWhen(
      active: (session) => session.currentStep,
      orElse: () => 1,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmed = await _confirmLeave(context);
        if (confirmed && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: _colors.background,
        appBar: AppBar(
          backgroundColor: _colors.surface,
          leading: IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: Colors.white70,
            onPressed: () async {
              if (await _confirmLeave(context) && context.mounted) {
                context.pop();
              }
            },
          ),
          title: Text(
            '开户 — 第 $currentStep / $_totalSteps 步',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: _StepProgressBar(
              currentStep: currentStep,
              totalSteps: _totalSteps,
            ),
          ),
        ),
        body: _stepScreen(currentStep),
      ),
    );
  }

  Widget _stepScreen(int step) => switch (step) {
        1 => const KycStep1PersonalScreen(),
        2 => const KycStep2DocumentScreen(),
        3 => const KycStep3AddressScreen(),
        4 => const KycStep4FinanceScreen(),
        5 => const KycStep5InvestmentScreen(),
        6 => const KycStep6TaxScreen(),
        7 => const KycStep7DisclosureScreen(),
        8 => const KycStep8AgreementScreen(),
        _ => const KycStep1PersonalScreen(),
      };

  Future<bool> _confirmLeave(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1E2530),
            title: const Text('离开开户？',
                style: TextStyle(color: Colors.white)),
            content: const Text(
              '您的填写进度已自动保存，稍后可继续。',
              style: TextStyle(color: Colors.white60),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('继续填写'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('离开', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.white12,
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0DC582)),
      minHeight: 4,
    );
  }
}
