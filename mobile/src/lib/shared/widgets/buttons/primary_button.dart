import 'package:flutter/material.dart';

/// Primary action button with loading state support.
///
/// Uses full-width layout by default per design spec.
/// Disables tap during loading to prevent double-submission.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = (enabled && !isLoading) ? onPressed : null;

    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [icon!, const SizedBox(width: 8), Text(label)],
              )
            : Text(label);

    return ElevatedButton(
      onPressed: effectiveOnPressed,
      child: child,
    );
  }
}
