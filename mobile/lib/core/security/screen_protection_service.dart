import 'package:flutter/widgets.dart';
import 'package:screen_protector/screen_protector.dart';
import '../logging/app_logger.dart';

/// Provides screen capture / screenshot protection for sensitive screens.
///
/// iOS: overlays a blank UITextField to prevent screenshot content capture.
/// Android: sets FLAG_SECURE on the window, which also blocks Recents thumbnail.
///
/// Usage: Mix into State classes for screens requiring protection.
///
/// ```dart
/// class _OrderConfirmScreenState extends State<OrderConfirmScreen>
///     with ScreenProtectionMixin {
///   ...
/// }
/// ```
mixin ScreenProtectionMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    _enableProtection();
  }

  @override
  void dispose() {
    _disableProtection();
    super.dispose();
  }

  Future<void> _enableProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      AppLogger.debug('Screen protection enabled for ${widget.runtimeType}');
    } catch (e, st) {
      AppLogger.warning(
        'Could not enable screen protection',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _disableProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
    } catch (e, st) {
      AppLogger.warning(
        'Could not disable screen protection',
        error: e,
        stackTrace: st,
      );
    }
  }
}

/// Standalone helper for programmatic protection control
/// (e.g., enabling protection when a bottom sheet opens).
class ScreenProtectionService {
  const ScreenProtectionService();

  Future<void> enable() async {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (e, st) {
      AppLogger.warning('enable() failed', error: e, stackTrace: st);
    }
  }

  Future<void> disable() async {
    try {
      await ScreenProtector.preventScreenshotOff();
    } catch (e, st) {
      AppLogger.warning('disable() failed', error: e, stackTrace: st);
    }
  }
}
