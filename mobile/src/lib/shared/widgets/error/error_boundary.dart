import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../.././core/logging/app_logger.dart';
import '../../.././core/errors/global_error_handler.dart';

/// Widget-level error boundary that catches errors in the widget tree.
///
/// Displays a user-friendly error screen with recovery options.
/// Automatically reports the error to Sentry.
///
/// Usage:
/// ```dart
/// ErrorBoundary(
///   child: MyApp(),
///   onError: (error, stack) => print('Caught: $error'),
/// )
/// ```
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
  });

  final Widget child;
  final void Function(Object error, StackTrace stack)? onError;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorScreen(
        error: _error!,
        stackTrace: _stackTrace,
        onReset: _reset,
        onReportIssue: _showFeedback,
      );
    }

    ErrorWidget.builder = (FlutterErrorDetails details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
      });

      GlobalErrorHandler.reportError(
        details.exception,
        stackTrace: details.stack,
        userMessage: '应用发生错误',
      );

      widget.onError?.call(details.exception, details.stack ?? StackTrace.current);

      return SizedBox.expand(
        child: _ErrorScreen(
          error: details.exception,
          stackTrace: details.stack,
          onReset: _reset,
          onReportIssue: _showFeedback,
        ),
      );
    };

    return widget.child;
  }

  void _reset() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  void _showFeedback() {
    if (_error == null) return;

    showDialog<void>(
      context: context,
      builder: (_) => UserFeedbackDialog(error: _error!),
    );
  }
}

/// User feedback dialog for reporting errors.
class UserFeedbackDialog extends StatefulWidget {
  const UserFeedbackDialog({
    super.key,
    required this.error,
    this.defaultMessage,
  });

  final Object error;
  final String? defaultMessage;

  @override
  State<UserFeedbackDialog> createState() => _UserFeedbackDialogState();
}

class _UserFeedbackDialogState extends State<UserFeedbackDialog> {
  late TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.defaultMessage ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('帮助我们改进'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '遇到问题了？告诉我们发生了什么。您的反馈帮助我们改进应用。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                hintText: '请描述您遇到的问题...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('提交'),
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    setState(() => _isSubmitting = true);

    try {
      final feedback = SentryFeedback(
        message: _controller.text,
        associatedEventId: Sentry.lastEventId,
      );

      await Sentry.captureFeedback(feedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('感谢您的反馈')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.error('Failed to submit user feedback: $e', error: e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Full-screen error display when the app crashes.
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({
    required this.error,
    required this.stackTrace,
    required this.onReset,
    required this.onReportIssue,
  });

  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onReset;
  final VoidCallback onReportIssue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用错误'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              '应用发生错误',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '我们已记录此问题。请尝试刷新应用。',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '错误详情',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新加载'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onReportIssue,
                  icon: const Icon(Icons.feedback_outlined),
                  label: const Text('报告问题'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
