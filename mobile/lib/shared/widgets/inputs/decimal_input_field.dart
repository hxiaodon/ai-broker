import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';

/// Text field specialised for financial decimal input.
///
/// Prevents floating-point input by treating the value as a string that is
/// only converted to [Decimal] on validation. The keyboard is numeric.
/// Negative values are only allowed when [allowNegative] is true.
class DecimalInputField extends StatefulWidget {
  const DecimalInputField({
    super.key,
    required this.label,
    required this.onChanged,
    this.initialValue,
    this.hint,
    this.decimalPlaces = 2,
    this.allowNegative = false,
    this.prefix,
    this.suffix,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final ValueChanged<Decimal?> onChanged;
  final Decimal? initialValue;
  final String? hint;
  final int decimalPlaces;
  final bool allowNegative;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  State<DecimalInputField> createState() => _DecimalInputFieldState();
}

class _DecimalInputFieldState extends State<DecimalInputField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toStringAsFixed(widget.decimalPlaces) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    if (value.isEmpty) {
      widget.onChanged(null);
      return;
    }
    final decimal = Decimal.tryParse(value);
    widget.onChanged(decimal);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        _DecimalInputFormatter(
          decimalPlaces: widget.decimalPlaces,
          allowNegative: widget.allowNegative,
        ),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefix: widget.prefix,
        suffix: widget.suffix,
      ),
      onChanged: _handleChanged,
      validator: widget.validator,
    );
  }
}

/// Input formatter that restricts input to valid decimal numbers.
class _DecimalInputFormatter extends TextInputFormatter {
  const _DecimalInputFormatter({
    required this.decimalPlaces,
    required this.allowNegative,
  });

  final int decimalPlaces;
  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    // Allow negative sign only at beginning
    if (text == '-' && allowNegative) return newValue;

    // Validate format: optional minus, digits, optional decimal point + digits
    final pattern = allowNegative
        ? r'^-?\d*\.?\d{0,' + decimalPlaces.toString() + r'}$'
        : r'^\d*\.?\d{0,' + decimalPlaces.toString() + r'}$';

    if (RegExp(pattern).hasMatch(text)) return newValue;
    return oldValue;
  }
}
