import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/routing/route_names.dart';
import '../../application/agreement_notifier.dart';
import '../../application/kyc_session_notifier.dart';
import '../../application/kyc_submit_notifier.dart';

/// Step 8 — 协议签署
/// H5 WebView 展示协议文本（只读），签名由 Native TextField 完成。
class KycStep8AgreementScreen extends ConsumerStatefulWidget {
  const KycStep8AgreementScreen({super.key});

  @override
  ConsumerState<KycStep8AgreementScreen> createState() =>
      _KycStep8AgreementScreenState();
}

class _KycStep8AgreementScreenState
    extends ConsumerState<KycStep8AgreementScreen> {
  late final WebViewController _webViewController;
  final _signatureCtrl = TextEditingController();
  bool _agreed = false;
  bool _agreementsRead = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _signatureCtrl.dispose();
    super.dispose();
  }

  void _initWebView() {
    final sessionState = ref.read(kycSessionProvider);
    final token = sessionState.maybeWhen(
      active: (session) => session.sessionId,
      orElse: () => '',
    );
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: _onBridgeMessage,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          // jsonEncode prevents JS injection if token contains quotes/backslashes.
          final payload = jsonEncode({
            'token': token,
            'step': 'kyc_step8',
          });
          _webViewController.runJavaScript(
            'window.JSBridge?.setAuthContext($payload)',
          );
        },
      ))
      ..loadRequest(Uri.parse('about:blank'));
  }

  void _onBridgeMessage(JavaScriptMessage msg) {
    if (msg.message.contains('agreements_scrolled')) {
      setState(() => _agreementsRead = true);
      ref.read(agreementProvider.notifier).onAgreementsRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    final agreementState = ref.watch(agreementProvider);
    final submitState = ref.watch(kycSubmitProvider);
    final sessionState = ref.watch(kycSessionProvider);
    final expectedName = sessionState.maybeWhen(
      active: (s) => s.accountHolderName ?? '',
      orElse: () => '',
    );

    ref.listen(kycSubmitProvider, (_, next) {
      next.whenOrNull(
        submitted: () => context.go(RouteNames.kycStatus),
        error: (msg) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg))),
      );
    });

    final isLoading =
        agreementState.maybeWhen(submitting: () => true, orElse: () => false) ||
        submitState.maybeWhen(submitting: () => true, orElse: () => false);

    return Column(
      children: [
        // H5 WebView for agreement text
        Expanded(
          flex: 3,
          child: WebViewWidget(controller: _webViewController),
        ),

        // Native signing area
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          color: const Color(0xFF141920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '请在下方输入您的完整英文姓名以完成协议签署',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _signatureCtrl,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
                decoration: InputDecoration(
                  hintText: '您的英文全名',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: const Color(0xFF1E2530),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF0DC582)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v!),
                    activeColor: const Color(0xFF0DC582),
                    checkColor: Colors.black,
                  ),
                  const Expanded(
                    child: Text(
                      '本人已阅读并同意上述所有协议',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading || !_agreed
                      ? null
                      : () => _submitAll(expectedName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0DC582),
                    disabledBackgroundColor: Colors.white12,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('提交申请',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitAll(String expectedName) async {
    await ref.read(agreementProvider.notifier).submit(
          signatureInput: _signatureCtrl.text,
          expectedName: expectedName,
        );
    final agreementOk = ref.read(agreementProvider).maybeWhen(
          success: () => true,
          orElse: () => false,
        );
    if (!agreementOk) return;
    await ref.read(kycSubmitProvider.notifier).submit();
  }
}
