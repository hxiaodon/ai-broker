import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../application/kyc_session_notifier.dart';
import '../../domain/entities/kyc_session.dart';

/// KYC 审核状态页 — 显示提交后的审核进度。
/// 由 KycSessionNotifier 自动轮询，状态变更自动刷新 UI。
class KycReviewStatusScreen extends ConsumerWidget {
  const KycReviewStatusScreen({super.key});

  static const _colors = ColorTokens.greenUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(kycSessionProvider);

    return Scaffold(
      backgroundColor: _colors.background,
      appBar: AppBar(
        backgroundColor: _colors.surface,
        title: const Text('开户审核',
            style: TextStyle(color: Colors.white70, fontSize: 16)),
        automaticallyImplyLeading: false,
      ),
      body: sessionState.maybeWhen(
        active: (session) => _StatusBody(session: session),
        orElse: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({required this.session});
  final KycSession session;

  @override
  Widget build(BuildContext context) {
    return switch (session.status) {
      KycStatus.pendingReview || KycStatus.submitted => _PendingView(session: session),
      KycStatus.needsMoreInfo => _NeedsMoreInfoView(session: session),
      KycStatus.approved => _ApprovedView(session: session),
      KycStatus.rejected => _RejectedView(session: session),
      _ => _PendingView(session: session),
    };
  }
}

// ──────────── Pending / Reviewing ────────────

class _PendingView extends StatelessWidget {
  const _PendingView({required this.session});
  final KycSession session;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFF0DC582)),
          const SizedBox(height: 24),
          const Text('审核进行中',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '预计 ${session.estimatedTimeMinutes != null ? '${session.estimatedTimeMinutes! ~/ 60} 个工作日' : '1 个工作日'} 内完成审核',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 40),
          _Timeline(currentStepIndex: _resolveTimelineStep(session.currentStep)),
          const SizedBox(height: 40),
          const Text(
            '审核结果将通过 App 通知及短信推送',
            style: TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _resolveTimelineStep(int kycStep) {
    if (kycStep >= 8) return 2;
    return 1;
  }
}

// ──────────── Needs More Info ────────────

class _NeedsMoreInfoView extends ConsumerWidget {
  const _NeedsMoreInfoView({required this.session});
  final KycSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined,
              size: 48, color: Colors.orange),
          const SizedBox(height: 20),
          const Text('需要补充材料',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (session.rejectionReason != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text(
                session.rejectionReason!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate back to step router, KycSessionNotifier
                // will route to needsMoreInfoStep automatically.
                context.push(RouteNames.kycSteps);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('去补件',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────── Approved ────────────

class _ApprovedView extends StatelessWidget {
  const _ApprovedView({required this.session});
  final KycSession session;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 64, color: Color(0xFF0DC582)),
          const SizedBox(height: 24),
          const Text('账户已开通！',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text(
            '恭喜您完成开户审核，现在可以入金并开始交易。',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _Timeline(currentStepIndex: 4, completed: true),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(RouteNames.funding),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0DC582),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('立即入金',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(RouteNames.market),
            child: const Text('先浏览行情',
                style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }
}

// ──────────── Rejected ────────────

class _RejectedView extends StatelessWidget {
  const _RejectedView({required this.session});
  final KycSession session;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, size: 48, color: Colors.red),
          const SizedBox(height: 20),
          const Text('申请未通过',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (session.rejectionReason != null)
            Text(
              session.rejectionReason!,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 14, height: 1.6),
            ),
          const SizedBox(height: 32),
          const Text(
            '如有疑问，请联系客服',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {/* Launch customer support */},
            icon: const Icon(Icons.headset_mic_outlined, size: 18),
            label: const Text('联系客服'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────── Timeline widget ────────────

class _Timeline extends StatelessWidget {
  const _Timeline({required this.currentStepIndex, this.completed = false});
  final int currentStepIndex;
  final bool completed;

  static const _nodes = [
    '申请已提交',
    '身份核验',
    '人工审核',
    '合规审批',
    '账户已激活',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_nodes.length, (i) {
        final isDone = completed || i < currentStepIndex;
        final isActive = !completed && i == currentStepIndex;
        return _TimelineNode(
          label: _nodes[i],
          isDone: isDone,
          isActive: isActive,
          isLast: i == _nodes.length - 1,
        );
      }),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.isLast,
  });

  final String label;
  final bool isDone;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? const Color(0xFF0DC582)
        : isActive
            ? Colors.orange
            : Colors.white24;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? const Color(0xFF0DC582)
                        : isActive
                            ? Colors.orange
                            : Colors.transparent,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : isActive
                          ? const Icon(Icons.circle,
                              size: 8, color: Colors.white)
                          : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDone ? const Color(0xFF0DC582) : Colors.white12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: isLast ? 0 : 20, top: 2),
              child: Text(
                label,
                style: TextStyle(
                  color: isDone
                      ? const Color(0xFF0DC582)
                      : isActive
                          ? Colors.orange
                          : Colors.white38,
                  fontSize: 14,
                  fontWeight: isActive
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
