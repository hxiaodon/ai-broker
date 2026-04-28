import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/financial_profile_notifier.dart';
import '../../domain/entities/financial_profile.dart';
import '../../domain/entities/kyc_enums.dart';
import '../widgets/kyc_shared_widgets.dart';

class KycStep4FinanceScreen extends ConsumerStatefulWidget {
  const KycStep4FinanceScreen({super.key});

  @override
  ConsumerState<KycStep4FinanceScreen> createState() =>
      _KycStep4FinanceScreenState();
}

class _KycStep4FinanceScreenState
    extends ConsumerState<KycStep4FinanceScreen> {
  IncomeRange _income = IncomeRange.k25To50k;
  NetWorthRange _totalNetWorth = NetWorthRange.k25To100k;
  NetWorthRange _liquidNetWorth = NetWorthRange.k25To100k;
  final Set<FundsSource> _fundsSources = {};
  EmploymentStatus _employment = EmploymentStatus.employed;
  final _employerCtrl = TextEditingController();

  bool get _liquidNetWorthValid =>
      _liquidNetWorth.ordinalValue <= _totalNetWorth.ordinalValue;

  @override
  void dispose() {
    _employerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(financialProfileProvider).maybeWhen(
          submitting: () => true,
          orElse: () => false,
        );

    ref.listen(financialProfileProvider, (_, next) {
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
          const KycStepTitle(title: '财务状况', subtitle: '以下信息将保密存档用于合规审计'),
          const SizedBox(height: 24),
          KycDropdown<IncomeRange>(
            label: '年收入（USD 等值）',
            value: _income,
            items: const [
              DropdownMenuItem(value: IncomeRange.under25k, child: Text('< \$25K')),
              DropdownMenuItem(value: IncomeRange.k25To50k, child: Text('\$25K – \$50K')),
              DropdownMenuItem(value: IncomeRange.k50To100k, child: Text('\$50K – \$100K')),
              DropdownMenuItem(value: IncomeRange.k100To250k, child: Text('\$100K – \$250K')),
              DropdownMenuItem(value: IncomeRange.k250To500k, child: Text('\$250K – \$500K')),
              DropdownMenuItem(value: IncomeRange.k500To1m, child: Text('\$500K – \$1M')),
              DropdownMenuItem(value: IncomeRange.over1m, child: Text('> \$1M')),
            ],
            onChanged: (v) => setState(() => _income = v!),
          ),
          const SizedBox(height: 16),
          KycDropdown<NetWorthRange>(
            label: '总净资产（USD）',
            value: _totalNetWorth,
            items: _netWorthItems,
            onChanged: (v) {
              setState(() {
                _totalNetWorth = v!;
                if (_liquidNetWorth.ordinalValue > _totalNetWorth.ordinalValue) {
                  _liquidNetWorth = _totalNetWorth;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          KycDropdown<NetWorthRange>(
            label: '流动净资产（USD）',
            value: _liquidNetWorth,
            items: _netWorthItems,
            onChanged: (v) => setState(() => _liquidNetWorth = v!),
          ),
          if (!_liquidNetWorthValid)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '流动净资产不可超过总净资产',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          const SizedBox(height: 20),
          const Text('资金来源（可多选，至少选 1 项）',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          _FundsSourceSelector(
            selected: _fundsSources,
            onChanged: (s) => setState(() {
              if (_fundsSources.contains(s)) {
                _fundsSources.remove(s);
              } else {
                _fundsSources.add(s);
              }
            }),
          ),
          const SizedBox(height: 16),
          KycDropdown<EmploymentStatus>(
            label: '就业状况',
            value: _employment,
            items: const [
              DropdownMenuItem(value: EmploymentStatus.employed, child: Text('在职')),
              DropdownMenuItem(value: EmploymentStatus.selfEmployed, child: Text('自雇')),
              DropdownMenuItem(value: EmploymentStatus.retired, child: Text('退休')),
              DropdownMenuItem(value: EmploymentStatus.student, child: Text('学生')),
              DropdownMenuItem(value: EmploymentStatus.other, child: Text('其他')),
            ],
            onChanged: (v) => setState(() => _employment = v!),
          ),
          if (_employment == EmploymentStatus.employed) ...[
            const SizedBox(height: 16),
            KycTextField(controller: _employerCtrl, label: '雇主名称'),
          ],
          const SizedBox(height: 32),
          KycNextButton(
            isLoading: isLoading,
            onPressed: _liquidNetWorthValid
                ? _submit
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('流动净资产不可超过总净资产')),
                    ),
          ),
        ],
      ),
    );
  }

  static final _netWorthItems = const [
    DropdownMenuItem(value: NetWorthRange.under25k, child: Text('< \$25K')),
    DropdownMenuItem(value: NetWorthRange.k25To100k, child: Text('\$25K – \$100K')),
    DropdownMenuItem(value: NetWorthRange.k100To500k, child: Text('\$100K – \$500K')),
    DropdownMenuItem(value: NetWorthRange.k500To1m, child: Text('\$500K – \$1M')),
    DropdownMenuItem(value: NetWorthRange.m1To5m, child: Text('\$1M – \$5M')),
    DropdownMenuItem(value: NetWorthRange.over5m, child: Text('> \$5M')),
  ];

  Future<void> _submit() async {
    if (_fundsSources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请至少选择一项资金来源')));
      return;
    }
    await ref.read(financialProfileProvider.notifier).submit(
          FinancialProfile(
            annualIncomeRange: _income,
            totalNetWorthRange: _totalNetWorth,
            liquidNetWorthRange: _liquidNetWorth,
            fundsSources: _fundsSources.toList(),
            employmentStatus: _employment,
            employerName: _employment == EmploymentStatus.employed
                ? _employerCtrl.text.trim()
                : null,
          ),
        );
  }
}

class _FundsSourceSelector extends StatelessWidget {
  const _FundsSourceSelector({required this.selected, required this.onChanged});
  final Set<FundsSource> selected;
  final ValueChanged<FundsSource> onChanged;

  static const _labels = {
    FundsSource.salary: '工资薪金',
    FundsSource.investmentReturns: '投资收益',
    FundsSource.businessOperations: '经营收入',
    FundsSource.realEstate: '房产出租',
    FundsSource.inheritance: '遗产赠与',
    FundsSource.other: '其他',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FundsSource.values.map((s) {
        final isSelected = selected.contains(s);
        return GestureDetector(
          onTap: () => onChanged(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0DC582).withValues(alpha: 0.15)
                  : const Color(0xFF1E2530),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF0DC582) : Colors.white12,
              ),
            ),
            child: Text(
              _labels[s]!,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0DC582) : Colors.white60,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
