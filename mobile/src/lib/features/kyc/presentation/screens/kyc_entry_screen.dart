import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../application/kyc_session_notifier.dart';
import '../../domain/entities/kyc_session.dart';

class KycEntryScreen extends ConsumerWidget {
  const KycEntryScreen({super.key});

  static const _colors = ColorTokens.greenUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(kycSessionProvider);

    return Scaffold(
      backgroundColor: _colors.background,
      body: sessionState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        noSession: () => _OnboardingView(
          onStart: () => context.push(RouteNames.kycSteps),
        ),
        active: (session) => _ActiveSessionView(
          session: session,
          onContinue: () {
            if (session.status.isPolling ||
                session.status == KycStatus.approved ||
                session.status == KycStatus.rejected) {
              context.push(RouteNames.kycStatus);
            } else {
              context.push(RouteNames.kycSteps);
            }
          },
        ),
        expired: () => _ExpiredView(
          onRestart: () async {
            await ref
                .read(kycSessionProvider.notifier)
                .clearSession();
            if (context.mounted) context.push(RouteNames.kycSteps);
          },
        ),
        error: (msg) => _ErrorView(message: msg),
      ),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 48, color: Color(0xFF0DC582)),
            const SizedBox(height: 24),
            const Text(
              '开立您的证券账户',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              '完成开户后，您即可交易美股 (NYSE / NASDAQ) 证券。\n预计完成时间：15 分钟',
              style: TextStyle(color: Colors.white60, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 32),
            _BenefitRow(icon: Icons.verified_user_outlined, text: 'SEC / FINRA 合规开户'),
            _BenefitRow(icon: Icons.shield_outlined, text: 'PII 数据加密保护'),
            _BenefitRow(icon: Icons.trending_up_outlined, text: '开户后即可入金并开始交易'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0DC582),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  '开始开户',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0DC582)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ActiveSessionView extends StatelessWidget {
  const _ActiveSessionView({required this.session, required this.onContinue});
  final KycSession session;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.pending_outlined, size: 48, color: Color(0xFF1A73E8)),
            const SizedBox(height: 24),
            const Text(
              '继续完成开户',
              style: TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              '您已完成第 ${session.currentStep - 1} 步，共 8 步。\n${_statusMessage(session.status)}',
              style: const TextStyle(color: Colors.white60, fontSize: 15, height: 1.6),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  session.status.isPolling ? '查看审核状态' : '继续开户',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusMessage(KycStatus status) => switch (status) {
        KycStatus.needsMoreInfo => '审核需要您补充材料，请继续。',
        KycStatus.pendingReview => '申请已提交，正在审核中（预计 1 个工作日）。',
        KycStatus.approved => '恭喜！账户已开通。',
        KycStatus.rejected => '申请未通过，请联系客服。',
        _ => '请继续完成剩余步骤。',
      };
}

class _ExpiredView extends StatelessWidget {
  const _ExpiredView({required this.onRestart});
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.timer_off_outlined, size: 48, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              '开户草稿已过期',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              '由于超过 60 天未操作，您的开户资料已过期。\n您可以重新填写，部分信息将为您预填。',
              style: TextStyle(color: Colors.white60, fontSize: 15, height: 1.6),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRestart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('重新开始',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(kycSessionProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
