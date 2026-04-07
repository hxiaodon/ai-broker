import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/color_tokens.dart';
import 'country_code_picker.dart';

/// Phone number input row matching the hifi prototype (phone.html).
///
/// Layout: [region-btn] + [text-field]
/// Region button opens [showCountryCodePicker].
/// Text field accepts only digits, max length per [CountryCode.maxLength].
class PhoneInputWidget extends StatefulWidget {
  const PhoneInputWidget({
    super.key,
    required this.controller,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.onChanged,
    required this.colors,
  });

  final TextEditingController controller;
  final CountryCode selectedCountry;
  final ValueChanged<CountryCode> onCountryChanged;
  final ValueChanged<String> onChanged;
  final ColorTokens colors;

  @override
  State<PhoneInputWidget> createState() => _PhoneInputWidgetState();
}

class _PhoneInputWidgetState extends State<PhoneInputWidget> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _hasFocus = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final picked = await showCountryCodePicker(
      context,
      current: widget.selectedCountry,
      colors: widget.colors,
    );
    if (picked != null && picked != widget.selectedCountry) {
      // Clear digits — max length changes between regions
      widget.controller.clear();
      widget.onCountryChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final borderColor = _hasFocus ? colors.primary : colors.divider;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Region button — hifi: "🌐 +86 ▾"
        GestureDetector(
          key: const Key('country_code_button'),
          onTap: _pickCountry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.selectedCountry.flag,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.selectedCountry.dialCode,
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.onSurface,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Phone number input
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(
                color: borderColor,
                width: _hasFocus ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(
                  widget.selectedCountry.maxLength,
                ),
              ],
              onChanged: widget.onChanged,
              style: TextStyle(
                fontSize: 15,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: '请输入手机号',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: colors.onSurface.withValues(alpha: 0.35),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
