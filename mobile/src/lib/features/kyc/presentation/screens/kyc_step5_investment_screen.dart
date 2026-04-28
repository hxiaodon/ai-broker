import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/investment_assessment_notifier.dart';
import '../../domain/entities/investment_assessment.dart';
import '../widgets/kyc_shared_widgets.dart';

class KycStep5InvestmentScreen extends ConsumerStatefulWidget {
  const KycStep5InvestmentScreen({super.key});

  @override
  ConsumerState<KycStep5InvestmentScreen> createState() =>
      _KycStep5InvestmentScreenState();
}

class _KycStep5InvestmentScreenState
    extends ConsumerState<KycStep5InvestmentScreen> {
  InvestmentObjective _objective = InvestmentObjective.growth;
  RiskTolerance _risk = RiskTolerance.moderate;
  TimeHorizon _horizon = TimeHorizon.medium;
  int _stockExp = 0;
  LiquidityNeed _liquidity = LiquidityNeed.medium;

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(investmentAssessmentProvider).maybeWhen(
          submitting: () => true,
          orElse: () => false,
        );

    ref.listen(investmentAssessmentProvider, (_, next) {
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
          const KycStepTitle(title: '投资评估', subtitle: '帮助我们了解您的投资偏好'),
          const SizedBox(height: 24),
          _RadioGroup<InvestmentObjective>(
            label: '投资目标',
            value: _objective,
            items: const [
              (InvestmentObjective.capitalPreservation, '资本保全'),
              (InvestmentObjective.income, '稳定收益'),
              (InvestmentObjective.growth, '资本增值'),
              (InvestmentObjective.speculation, '高风险高回报'),
            ],
            onChanged: (v) => setState(() => _objective = v),
          ),
          const SizedBox(height: 20),
          _RadioGroup<RiskTolerance>(
            label: '风险承受能力',
            value: _risk,
            items: const [
              (RiskTolerance.conservative, '保守型'),
              (RiskTolerance.moderate, '稳健型'),
              (RiskTolerance.aggressive, '进取型'),
            ],
            onChanged: (v) => setState(() => _risk = v),
          ),
          const SizedBox(height: 20),
          _RadioGroup<TimeHorizon>(
            label: '投资期限',
            value: _horizon,
            items: const [
              (TimeHorizon.short, '短期（< 1 年）'),
              (TimeHorizon.medium, '中期（1–5 年）'),
              (TimeHorizon.long, '长期（> 5 年）'),
            ],
            onChanged: (v) => setState(() => _horizon = v),
          ),
          const SizedBox(height: 20),
          _SliderField(
            label: '股票投资年限',
            value: _stockExp.toDouble(),
            min: 0,
            max: 30,
            divisions: 30,
            displayValue: _stockExp == 0 ? '无经验' : '$_stockExp 年',
            onChanged: (v) => setState(() => _stockExp = v.round()),
          ),
          const SizedBox(height: 20),
          _RadioGroup<LiquidityNeed>(
            label: '资金流动性需求',
            value: _liquidity,
            items: const [
              (LiquidityNeed.low, '低（较少需要动用资金）'),
              (LiquidityNeed.medium, '中（偶尔需要动用）'),
              (LiquidityNeed.high, '高（随时可能需要）'),
            ],
            onChanged: (v) => setState(() => _liquidity = v),
          ),
          const SizedBox(height: 32),
          KycNextButton(isLoading: isLoading, onPressed: _submit),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    await ref.read(investmentAssessmentProvider.notifier).submit(
          InvestmentAssessment(
            investmentObjective: _objective,
            riskTolerance: _risk,
            timeHorizon: _horizon,
            stockExperienceYears: _stockExp,
            liquidityNeed: _liquidity,
          ),
        );
  }
}

class _RadioGroup<T> extends StatelessWidget {
  const _RadioGroup({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...items.map(
          (item) => RadioListTile<T>(
            value: item.$1,
            groupValue: value,
            onChanged: (v) => onChanged(v as T),
            title: Text(item.$2,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            activeColor: const Color(0xFF0DC582),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text(displayValue,
                style: const TextStyle(color: Color(0xFF0DC582), fontSize: 14)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: const Color(0xFF0DC582),
          inactiveColor: Colors.white12,
        ),
      ],
    );
  }
}
