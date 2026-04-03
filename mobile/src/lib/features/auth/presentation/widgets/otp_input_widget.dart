import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/color_tokens.dart';

/// 6-box OTP input matching the hifi prototype (otp.html).
///
/// Visual states per prototype:
///   - empty: border = divider
///   - filled: border = onSurfaceVariant (secondary text)
///   - active (cursor position): border = primary, width 2
///   - error: border = error, background tinted red
///
/// iOS: Uses [AutofillHints.oneTimeCode] for SMS autofill.
/// Android: Caller is responsible for wiring smart_auth; onCompleted fires
/// from controller listener regardless of input source.
class OtpInputWidget extends StatefulWidget {
  const OtpInputWidget({
    super.key,
    required this.controller,
    required this.hasError,
    required this.onCompleted,
    required this.colors,
  });

  final TextEditingController controller;
  final bool hasError;

  /// Called when all 6 digits have been entered.
  final ValueChanged<String> onCompleted;
  final ColorTokens colors;

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    widget.controller.addListener(_onTextChanged);

    // Auto-focus when the widget first appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text.length == 6) {
      widget.onCompleted(text);
    }
    // Rebuild to update box visuals
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final colors = widget.colors;

    return GestureDetector(
      // Tapping anywhere on the row focuses the hidden field
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: [
          // Visible 6-box row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final isFilled = i < code.length;
              final isActive = !widget.hasError && i == code.length;

              Color borderColor;
              double borderWidth;
              Color boxBackground;

              if (widget.hasError) {
                borderColor = colors.error;
                borderWidth = 2;
                boxBackground = colors.error.withValues(alpha: 0.05);
              } else if (isActive) {
                borderColor = colors.primary;
                borderWidth = 2;
                boxBackground = colors.surface;
              } else if (isFilled) {
                borderColor = colors.onSurfaceVariant;
                borderWidth = 2;
                boxBackground = colors.surface;
              } else {
                borderColor = colors.divider;
                borderWidth = 2;
                boxBackground = colors.surface;
              }

              return Container(
                width: 44,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: boxBackground,
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  isFilled ? code[i] : (isActive ? '|' : ''),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isActive
                        ? colors.primary
                        : widget.hasError
                            ? colors.error
                            : colors.onSurface,
                  ),
                ),
              );
            }),
          ),
          // Hidden text field captures keyboard input
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) {}, // handled by controller listener
                // Ensure the cursor does not appear visually
                showCursor: false,
                style: const TextStyle(color: Colors.transparent),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
