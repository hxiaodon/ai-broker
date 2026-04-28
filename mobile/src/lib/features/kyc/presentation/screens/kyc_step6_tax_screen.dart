import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tax_form_notifier.dart';
import '../widgets/kyc_shared_widgets.dart';

class KycStep6TaxScreen extends ConsumerStatefulWidget {
  const KycStep6TaxScreen({super.key});

  @override
  ConsumerState<KycStep6TaxScreen> createState() => _KycStep6TaxScreenState();
}

class _KycStep6TaxScreenState extends ConsumerState<KycStep6TaxScreen> {
  bool _isUsTaxResident = false;

  // W-8BEN fields
  final _fullNameCtrl = TextEditingController();
  String _countryOfTaxResidence = 'CN';
  final _tinCtrl = TextEditingController();
  bool _tinNotAvailable = false;

  // W-9 fields
  final _w9NameCtrl = TextEditingController();
  final _ssnCtrl = TextEditingController();
  final _w9AddressCtrl = TextEditingController();

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _tinCtrl.dispose();
    _w9NameCtrl.dispose();
    _ssnCtrl.dispose();
    _w9AddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(taxFormProvider).maybeWhen(
          submitting: () => true,
          orElse: () => false,
        );

    ref.listen(taxFormProvider, (_, next) {
      next.whenOrNull(
        error: (msg) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg))),
      );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KycStepTitle(title: '税务申报', subtitle: 'IRS 要求必须完成税务身份确认'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2530),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '您是否为美国税务居民？',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  '美国公民、绿卡持有人或满足居住时间测试的人士',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ChoiceChip(
                        label: '是（填写 W-9）',
                        selected: _isUsTaxResident,
                        onTap: () => setState(() => _isUsTaxResident = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ChoiceChip(
                        label: '否（填写 W-8BEN）',
                        selected: !_isUsTaxResident,
                        onTap: () => setState(() => _isUsTaxResident = false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_isUsTaxResident)
            _W9Form(
              nameCtrl: _w9NameCtrl,
              ssnCtrl: _ssnCtrl,
              addressCtrl: _w9AddressCtrl,
            )
          else
            _W8BenForm(
              nameCtrl: _fullNameCtrl,
              country: _countryOfTaxResidence,
              tinCtrl: _tinCtrl,
              tinNotAvailable: _tinNotAvailable,
              onCountryChanged: (v) =>
                  setState(() => _countryOfTaxResidence = v!),
              onTinNotAvailableChanged: (v) =>
                  setState(() => _tinNotAvailable = v!),
            ),
          const SizedBox(height: 32),
          KycNextButton(isLoading: isLoading, onPressed: _submit),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_isUsTaxResident) {
      if (_w9NameCtrl.text.trim().isEmpty ||
          _ssnCtrl.text.trim().isEmpty ||
          _w9AddressCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请完整填写 W-9 信息')));
        return;
      }
      await ref.read(taxFormProvider.notifier).submitW9(
            fullName: _w9NameCtrl.text.trim(),
            ssn: _ssnCtrl.text.trim(),
            address: _w9AddressCtrl.text.trim(),
          );
    } else {
      if (_fullNameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请填写姓名')));
        return;
      }
      await ref.read(taxFormProvider.notifier).submitW8Ben(
            fullName: _fullNameCtrl.text.trim(),
            countryOfTaxResidence: _countryOfTaxResidence,
            tin: _tinNotAvailable ? null : _tinCtrl.text.trim(),
            tinNotAvailable: _tinNotAvailable,
          );
    }
  }
}

class _W8BenForm extends StatelessWidget {
  const _W8BenForm({
    required this.nameCtrl,
    required this.country,
    required this.tinCtrl,
    required this.tinNotAvailable,
    required this.onCountryChanged,
    required this.onTinNotAvailableChanged,
  });

  final TextEditingController nameCtrl;
  final String country;
  final TextEditingController tinCtrl;
  final bool tinNotAvailable;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<bool?> onTinNotAvailableChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoBox(
          text: 'W-8BEN 证明您不是美国税务居民。'
              '签署后可申请税收协定优惠税率（中美协定：股息税从 30% 降至 10%）。'
              '有效期 3 年，到期前系统会提醒续签。',
        ),
        const SizedBox(height: 16),
        KycTextField(controller: nameCtrl, label: '英文全名（与证件一致）'),
        const SizedBox(height: 16),
        KycDropdown<String>(
          label: '税务居住国',
          value: country,
          items: const [
            DropdownMenuItem(value: 'CN', child: Text('中国大陆')),
            DropdownMenuItem(value: 'HK', child: Text('香港')),
            DropdownMenuItem(value: 'SG', child: Text('新加坡')),
            DropdownMenuItem(value: 'OTHER', child: Text('其他')),
          ],
          onChanged: onCountryChanged,
        ),
        const SizedBox(height: 16),
        KycTextField(
          controller: tinCtrl,
          label: 'TIN / 税务识别号',
          enabled: !tinNotAvailable,
        ),
        KycCheckboxRow(
          value: tinNotAvailable,
          label: '我暂无税务识别号',
          onChanged: onTinNotAvailableChanged,
        ),
      ],
    );
  }
}

class _W9Form extends StatelessWidget {
  const _W9Form({
    required this.nameCtrl,
    required this.ssnCtrl,
    required this.addressCtrl,
  });

  final TextEditingController nameCtrl;
  final TextEditingController ssnCtrl;
  final TextEditingController addressCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _InfoBox(text: 'W-9 用于美国税务居民申报纳税人识别号。'),
        const SizedBox(height: 16),
        KycTextField(controller: nameCtrl, label: '英文全名'),
        const SizedBox(height: 16),
        KycTextField(
          controller: ssnCtrl,
          label: 'SSN（格式：XXX-XX-XXXX）',
          obscureText: true,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        KycTextField(controller: addressCtrl, label: '美国地址'),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: const Color(0xFF1A73E8).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF1A73E8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 12, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0DC582).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF0DC582) : Colors.white12,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF0DC582) : Colors.white54,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
