import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/color_tokens.dart';
import '../../application/personal_info_notifier.dart';
import '../../domain/entities/kyc_enums.dart';
import '../../domain/entities/personal_info.dart';
import '../widgets/kyc_shared_widgets.dart';

class KycStep1PersonalScreen extends ConsumerStatefulWidget {
  const KycStep1PersonalScreen({super.key});

  @override
  ConsumerState<KycStep1PersonalScreen> createState() =>
      _KycStep1PersonalScreenState();
}

class _KycStep1PersonalScreenState
    extends ConsumerState<KycStep1PersonalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _chineseNameCtrl = TextEditingController();
  final _employerCtrl = TextEditingController();

  DateTime? _dateOfBirth;
  String _nationality = 'CN';
  IdType _idType = IdType.chinaResidentId;
  EmploymentStatus _employmentStatus = EmploymentStatus.employed;
  bool _isPep = false;
  bool _isInsider = false;

  static const _colors = ColorTokens.greenUp;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _chineseNameCtrl.dispose();
    _employerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(personalInfoProvider).maybeWhen(
          submitting: () => true,
          orElse: () => false,
        );

    ref.listen(personalInfoProvider, (_, next) {
      next.whenOrNull(
        error: (msg) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg))),
      );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const KycStepTitle(title: '个人信息', subtitle: '请填写与证件一致的英文姓名'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: KycTextField(
                    controller: _firstNameCtrl,
                    label: '名 (First Name)',
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? '请输入名' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KycTextField(
                    controller: _lastNameCtrl,
                    label: '姓 (Last Name)',
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? '请输入姓' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            KycTextField(controller: _chineseNameCtrl, label: '中文姓名（选填）'),
            const SizedBox(height: 16),
            KycDatePickerField(
              label: '出生日期',
              value: _dateOfBirth,
              onChanged: (d) => setState(() => _dateOfBirth = d),
            ),
            const SizedBox(height: 16),
            KycDropdown<String>(
              label: '国籍',
              value: _nationality,
              items: const [
                DropdownMenuItem(value: 'CN', child: Text('中国大陆')),
                DropdownMenuItem(value: 'HK', child: Text('香港')),
                DropdownMenuItem(value: 'US', child: Text('美国')),
                DropdownMenuItem(value: 'OTHER', child: Text('其他')),
              ],
              onChanged: (v) => setState(() => _nationality = v!),
            ),
            const SizedBox(height: 16),
            KycDropdown<IdType>(
              label: '证件类型',
              value: _idType,
              items: const [
                DropdownMenuItem(value: IdType.chinaResidentId, child: Text('中华人民共和国居民身份证')),
                DropdownMenuItem(value: IdType.hkid, child: Text('香港身份证 (HKID)')),
                DropdownMenuItem(value: IdType.passport, child: Text('国际护照')),
                DropdownMenuItem(value: IdType.mainlandPermit, child: Text('港澳通行证')),
              ],
              onChanged: (v) => setState(() => _idType = v!),
            ),
            const SizedBox(height: 16),
            KycDropdown<EmploymentStatus>(
              label: '就业状况',
              value: _employmentStatus,
              items: const [
                DropdownMenuItem(value: EmploymentStatus.employed, child: Text('在职')),
                DropdownMenuItem(value: EmploymentStatus.selfEmployed, child: Text('自雇')),
                DropdownMenuItem(value: EmploymentStatus.retired, child: Text('退休')),
                DropdownMenuItem(value: EmploymentStatus.student, child: Text('学生')),
                DropdownMenuItem(value: EmploymentStatus.other, child: Text('其他')),
              ],
              onChanged: (v) => setState(() => _employmentStatus = v!),
            ),
            if (_employmentStatus == EmploymentStatus.employed) ...[
              const SizedBox(height: 16),
              KycTextField(
                controller: _employerCtrl,
                label: '雇主 / 公司名称',
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? '请输入雇主名称' : null,
              ),
            ],
            const SizedBox(height: 24),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            KycCheckboxRow(
              value: _isPep,
              label: '本人系政治敏感人士 (PEP)',
              onChanged: (v) => setState(() => _isPep = v!),
            ),
            if (_isPep)
              const Padding(
                padding: EdgeInsets.only(left: 36, bottom: 8),
                child: Text(
                  '勾选后将进入人工合规审核，预计延长 2–3 个工作日',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            KycCheckboxRow(
              value: _isInsider,
              label: '本人系证券公司内部人员',
              onChanged: (v) => setState(() => _isInsider = v!),
            ),
            const SizedBox(height: 32),
            KycNextButton(isLoading: isLoading, onPressed: _submit),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请选择出生日期')));
      return;
    }
    await ref.read(personalInfoProvider.notifier).submit(
          PersonalInfo(
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            chineseName: _chineseNameCtrl.text.trim().isEmpty
                ? null
                : _chineseNameCtrl.text.trim(),
            dateOfBirth: _dateOfBirth!,
            nationality: _nationality,
            idType: _idType,
            employmentStatus: _employmentStatus,
            employerName: _employmentStatus == EmploymentStatus.employed
                ? _employerCtrl.text.trim()
                : null,
            isPep: _isPep,
            isInsiderOfBroker: _isInsider,
          ),
        );
  }
}
