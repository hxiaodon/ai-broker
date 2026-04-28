import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/document_upload_notifier.dart';
import '../../domain/entities/document_upload.dart';
import '../widgets/kyc_shared_widgets.dart';

class KycStep2DocumentScreen extends ConsumerStatefulWidget {
  const KycStep2DocumentScreen({super.key});

  @override
  ConsumerState<KycStep2DocumentScreen> createState() =>
      _KycStep2DocumentScreenState();
}

class _KycStep2DocumentScreenState
    extends ConsumerState<KycStep2DocumentScreen> {
  DocumentType _docType = DocumentType.chinaResidentId;

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(documentUploadProvider);
    final isLoading = uploadState.maybeWhen(
      uploading: (_) => true,
      orElse: () => false,
    );
    final isSumsubLaunched = uploadState.maybeWhen(
      sumsubLaunched: () => true,
      orElse: () => false,
    );
    final isSuccess = uploadState.maybeWhen(
      success: (_) => true,
      orElse: () => false,
    );
    final errorMessage = uploadState.maybeWhen(
      error: (msg) => msg,
      orElse: () => null,
    );

    ref.listen(documentUploadProvider, (_, next) {
      next.whenOrNull(
        error: (msg) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg))),
      );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KycStepTitle(
            title: '证件上传',
            subtitle: '上传有效证件，系统将自动识别信息',
          ),
          const SizedBox(height: 24),
          KycDropdown<DocumentType>(
            label: '证件类型',
            value: _docType,
            items: const [
              DropdownMenuItem(
                  value: DocumentType.chinaResidentId,
                  child: Text('中华人民共和国居民身份证')),
              DropdownMenuItem(value: DocumentType.hkid, child: Text('香港身份证 (HKID)')),
              DropdownMenuItem(value: DocumentType.passport, child: Text('国际护照')),
              DropdownMenuItem(
                  value: DocumentType.mainlandPermit, child: Text('港澳通行证')),
            ],
            onChanged: (v) => setState(() => _docType = v!),
          ),
          const SizedBox(height: 24),
          _RequirementsList(),
          const SizedBox(height: 24),
          if (isSumsubLaunched)
            _StatusCard(
              icon: Icons.hourglass_top_outlined,
              color: Colors.orange,
              message: 'Sumsub 验证流程已启动，请按提示操作...',
            )
          else if (isSuccess)
            const _StatusCard(
              icon: Icons.check_circle_outline,
              color: Color(0xFF0DC582),
              message: '证件已验证，继续下一步',
            )
          else
            KycNextButton(
              label: '启动证件验证',
              isLoading: isLoading,
              onPressed: _startSumsub,
            ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startSumsub() async {
    try {
      final token = await ref
          .read(documentUploadProvider.notifier)
          .initSumsubFlow(_docType);
      // TODO: Replace with real Sumsub Flutter SDK launch.
      // Pass token.accessToken to the SDK; call onSumsubSuccess in the SDK callback.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await ref
            .read(documentUploadProvider.notifier)
            .onSumsubSuccess(
              applicantId: token.applicantId,
              documentType: _docType,
            );
      }
    } on Exception catch (e) {
      // Biometric failure and network errors surface via provider state (error listener above).
      // Only log here to avoid double-surfacing; the state listener shows the SnackBar.
      debugPrint('Sumsub flow error: $e');
    }
  }
}

class _RequirementsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      '证件四角完整，不遮挡',
      '光线均匀，无反光，无模糊',
      '文件大小 ≤ 10MB（JPG / PNG）',
      '不接受过期证件',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2530),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('拍摄要求',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...items.map((t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 5, color: Colors.white38),
                    const SizedBox(width: 8),
                    Text(t,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 13)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: color, fontSize: 14))),
        ],
      ),
    );
  }
}
