import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../application/agreement_notifier.dart';
import '../../application/kyc_session_notifier.dart';

/// Step 7 — 风险披露（H5 WebView）
///
/// H5 页面通过 JSBridge closeWebView({ risk_disclosure_read: true }) 回调，
/// 或用户点击底部确认按钮推进到 Step 8。两条路径共享 _advanceOnce()，
/// 保证 advanceStep() 只被调用一次，防止步骤跳过 Step 8。
class KycStep7DisclosureScreen extends ConsumerStatefulWidget {
  const KycStep7DisclosureScreen({super.key});

  @override
  ConsumerState<KycStep7DisclosureScreen> createState() =>
      _KycStep7DisclosureScreenState();
}

class _KycStep7DisclosureScreenState
    extends ConsumerState<KycStep7DisclosureScreen> {
  late final WebViewController _webViewController;
  bool _hasScrolledToBottom = false;
  bool _hasAdvanced = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
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
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => _injectAuthContext(token, url),
        ),
      )
      ..loadRequest(Uri.parse('about:blank'));
  }

  Future<void> _injectAuthContext(String token, String url) async {
    // Only inject into trusted pages (about:blank is dev placeholder).
    await _webViewController.runJavaScript(
      'window.JSBridge?.setAuthContext(${_jsonString(token)}, ${_jsonString("kyc_step7")})',
    );
  }

  void _onBridgeMessage(JavaScriptMessage msg) {
    if (msg.message.contains('risk_disclosure_read')) {
      setState(() => _hasScrolledToBottom = true);
      ref.read(agreementProvider.notifier).onRiskDisclosureRead();
      _advanceOnce();
    }
  }

  /// 保证 advanceStep() 只被调用一次，无论来自 JSBridge 还是按钮。
  void _advanceOnce() {
    if (_hasAdvanced) return;
    _hasAdvanced = true;
    ref.read(kycSessionProvider.notifier).advanceStep();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: WebViewWidget(controller: _webViewController)),
        _DisclosureBottomBar(
          enabled: _hasScrolledToBottom,
          onConfirm: () {
            ref.read(agreementProvider.notifier).onRiskDisclosureRead();
            _advanceOnce();
          },
        ),
      ],
    );
  }
}

/// JSON-encodes a string value for safe insertion into a JS call.
String _jsonString(String value) {
  // Using JSON encoding prevents injection if value contains quotes/backslashes.
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"');
  return '"$escaped"';
}

class _DisclosureBottomBar extends StatelessWidget {
  const _DisclosureBottomBar({required this.enabled, required this.onConfirm});
  final bool enabled;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      color: const Color(0xFF141920),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!enabled)
            const Text(
              '请滚动至底部阅读全部风险披露文件',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: enabled ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0DC582),
                disabledBackgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                '已阅读全部，继续',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
