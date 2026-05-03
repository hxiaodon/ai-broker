import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/screen_protection_service.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../../shared/widgets/error/error_view.dart';
import '../../../../shared/widgets/loading/skeleton_loader.dart';
import '../../application/account_status_notifier.dart';
import '../../application/user_profile_notifier.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/entities/user_profile.dart';

/// Personal profile screen — all fields are read-only (PRD §5.1).
///
/// Displays PII in masked form (PRD masking rules).
/// Shows W-8BEN status with renewal banner when expiring/expired.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with ScreenProtectionMixin {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final statusAsync = ref.watch(accountStatusProvider);

    return Scaffold(
      backgroundColor: ColorTokens.greenUp.background,
      appBar: AppBar(
        title: const Text('个人资料'),
        backgroundColor: ColorTokens.greenUp.surface,
        elevation: 0,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => ErrorView(
          message: '加载失败，请重试',
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // W-8BEN Banner (if expiring or expired)
            statusAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (status) => _W8BenBanner(status: status),
            ),
            // Basic info
            _SectionCard(
              title: '基本信息',
              children: [
                _ReadonlyField(label: '姓名', value: profile.fullName),
                _ReadonlyField(
                  label: '手机号',
                  value: profile.maskedPhone,
                ),
                _ReadonlyField(label: '邮箱', value: profile.maskedEmail),
              ],
            ),
            const SizedBox(height: 16),
            // Identity info
            _SectionCard(
              title: '身份信息',
              children: [
                _ReadonlyField(label: '证件类型', value: profile.idType),
                _ReadonlyField(
                  label: '证件号码',
                  value: profile.maskedIdNumber,
                  isVerified: true,
                ),
                _ReadonlyField(
                  label: '开户日期',
                  value: _formatDate(profile.accountOpenedAt),
                ),
                _ReadonlyField(
                  label: '账户类型',
                  value: profile.accountType,
                ),
                _ReadonlyField(
                  label: 'KYC 等级',
                  value: profile.kycTier == KycTier.tier2 ? 'Tier 2 — 已认证' : 'Tier 1 — 审核中',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tax info
            statusAsync.when(
              loading: () => const SkeletonLoader(
                width: double.infinity,
                height: 120,
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (status) => _TaxInfoCard(status: status),
            ),
            const SizedBox(height: 16),
            // Contact customer service for modifications
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorTokens.greenUp.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ColorTokens.greenUp.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: ColorTokens.greenUp.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'KYC 信息经官方核验，如需修改请联系客服',
                      style: TextStyle(
                        color: ColorTokens.greenUp.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// ─── W-8BEN Banner ───────────────────────────────────────────────────────────

class _W8BenBanner extends StatelessWidget {
  const _W8BenBanner({required this.status});
  final AccountStatus status;

  @override
  Widget build(BuildContext context) {
    if (status.w8BenStatus == W8BenStatus.notSigned ||
        status.w8BenStatus == W8BenStatus.valid) {
      if (!status.isW8BenExpiringSoon) return const SizedBox.shrink();
    }

    final isExpired = status.isW8BenExpired;
    final color = isExpired ? ColorTokens.greenUp.error : const Color(0xFFFFC107);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isExpired
                  ? 'W-8BEN 已过期，股息预扣税率已变为 30%。请立即续签。'
                  : 'W-8BEN 即将到期（${_daysLeft(status.w8BenExpiresAt)}天后），请及时续签以保持 10% 协定税率。',
              style: TextStyle(color: ColorTokens.greenUp.onSurface, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  int _daysLeft(DateTime? exp) =>
      exp?.difference(DateTime.now().toUtc()).inDays ?? 0;
}

// ─── Tax Info Card ────────────────────────────────────────────────────────────

class _TaxInfoCard extends StatelessWidget {
  const _TaxInfoCard({required this.status});
  final AccountStatus status;

  @override
  Widget build(BuildContext context) {
    final badgeColor = switch (status.w8BenStatus) {
      W8BenStatus.valid => Colors.green,
      W8BenStatus.expiringSoon => const Color(0xFFFFC107),
      W8BenStatus.expired => ColorTokens.greenUp.error,
      W8BenStatus.notSigned => ColorTokens.greenUp.onSurfaceVariant,
    };
    final statusLabel = switch (status.w8BenStatus) {
      W8BenStatus.valid => '有效',
      W8BenStatus.expiringSoon => '即将到期',
      W8BenStatus.expired => '已过期',
      W8BenStatus.notSigned => '未签署',
    };

    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.greenUp.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorTokens.greenUp.divider),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'W-8BEN 税务信息',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _TaxRow(label: '税务身份', value: '非美国税务居民'),
          _TaxRow(label: '表格类型', value: 'W-8BEN'),
          _TaxRow(
            label: '有效期',
            value: status.w8BenExpiresAt != null
                ? _formatDate(status.w8BenExpiresAt!)
                : '--',
          ),
          _TaxRow(
            label: '预扣税率',
            value: status.withholdingTaxRate,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {}, // Phase 1: contact support
                    child: const Text('查看表单'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {}, // Phase 1: contact support (OQ-02)
                    child: const Text('申请续签'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _TaxRow extends StatelessWidget {
  const _TaxRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ColorTokens.greenUp.divider, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: ColorTokens.greenUp.onSurfaceVariant, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Section Card ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: ColorTokens.greenUp.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: ColorTokens.greenUp.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.label,
    required this.value,
    this.isVerified = false,
  });

  final String label;
  final String value;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ColorTokens.greenUp.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: ColorTokens.greenUp.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (isVerified)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '已验证',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
