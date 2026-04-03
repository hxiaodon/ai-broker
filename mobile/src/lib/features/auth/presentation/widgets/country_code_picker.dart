import 'package:flutter/material.dart';

import '../../../../shared/theme/color_tokens.dart';

/// Supported country dial codes for phone login.
///
/// PRD §6.1: +86 China (11 digits), +852 HK (8 digits).
enum CountryCode {
  china(dialCode: '+86', label: '中国大陆', flag: '🇨🇳', maxLength: 11),
  hongKong(dialCode: '+852', label: '香港', flag: '🇭🇰', maxLength: 8);

  const CountryCode({
    required this.dialCode,
    required this.label,
    required this.flag,
    required this.maxLength,
  });

  final String dialCode;
  final String label;
  final String flag;
  final int maxLength;
}

/// Shows a bottom sheet for country code selection.
///
/// Called from [PhoneInputWidget]. Matches hifi prototype phone.html region-btn.
Future<CountryCode?> showCountryCodePicker(
  BuildContext context, {
  required CountryCode current,
  required ColorTokens colors,
}) {
  return showModalBottomSheet<CountryCode>(
    context: context,
    backgroundColor: colors.surfaceVariant,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) => _CountryCodePickerSheet(
      current: current,
      colors: colors,
    ),
  );
}

class _CountryCodePickerSheet extends StatelessWidget {
  const _CountryCodePickerSheet({
    required this.current,
    required this.colors,
  });

  final CountryCode current;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.divider,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '选择区号',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final code in CountryCode.values)
            InkWell(
              onTap: () => Navigator.of(context).pop(code),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Text(code.flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        code.label,
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      code.dialCode,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (code == current)
                      Icon(Icons.check, size: 18, color: colors.primary)
                    else
                      const SizedBox(width: 18),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
