import 'package:flutter/material.dart';

/// Shared form widgets for KYC step screens.
/// All widgets here are public (no underscore) for cross-file access.

class KycStepTitle extends StatelessWidget {
  const KycStepTitle({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }
}

class KycTextField extends StatelessWidget {
  const KycTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      style: TextStyle(color: enabled ? Colors.white : Colors.white38),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: enabled ? const Color(0xFF1E2530) : const Color(0xFF151B24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0DC582)),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
      ),
    );
  }
}

class KycDropdown<T> extends StatelessWidget {
  const KycDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E2530),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E2530),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              iconEnabledColor: Colors.white54,
            ),
          ),
        ),
      ],
    );
  }
}

class KycCheckboxRow extends StatelessWidget {
  const KycCheckboxRow({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF0DC582),
          checkColor: Colors.black,
        ),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ),
      ],
    );
  }
}

class KycNextButton extends StatelessWidget {
  const KycNextButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.label = '下一步',
  });

  final bool isLoading;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0DC582),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class KycDatePickerField extends StatelessWidget {
  const KycDatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final display = value != null
        ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}'
        : '请选择$label';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              DateTime.now().subtract(const Duration(days: 365 * 25)),
          firstDate: DateTime(1900),
          lastDate:
              DateTime.now().subtract(const Duration(days: 365 * 18)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF0DC582),
                surface: Color(0xFF1E2530),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2530),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                display,
                style: TextStyle(
                  color: value != null ? Colors.white : Colors.white38,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
