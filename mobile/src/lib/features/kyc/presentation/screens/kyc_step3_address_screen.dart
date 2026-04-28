import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/address_proof_notifier.dart';
import '../../domain/entities/address_proof.dart';
import '../widgets/kyc_shared_widgets.dart';

class KycStep3AddressScreen extends ConsumerStatefulWidget {
  const KycStep3AddressScreen({super.key});

  @override
  ConsumerState<KycStep3AddressScreen> createState() =>
      _KycStep3AddressScreenState();
}

class _KycStep3AddressScreenState
    extends ConsumerState<KycStep3AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  String _country = 'CN';
  AddressProofDocType _docType = AddressProofDocType.bankStatement;

  String? _fileName;
  Uint8List? _fileBytes;
  String? _mimeType;

  @override
  void dispose() {
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(addressProofProvider).maybeWhen(
          uploading: (_) => true,
          orElse: () => false,
        );

    ref.listen(addressProofProvider, (_, next) {
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
            const KycStepTitle(
              title: '地址证明',
              subtitle: '请提供近 3 个月内的银行账单或水电费账单',
            ),
            const SizedBox(height: 24),
            KycTextField(
              controller: _streetCtrl,
              label: '街道地址（英文）',
              validator: (v) => (v?.trim().isEmpty ?? true) ? '请填写街道地址' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: KycTextField(
                    controller: _cityCtrl,
                    label: '城市',
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? '请填写城市' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KycTextField(controller: _provinceCtrl, label: '省份 / 州'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: KycTextField(
                    controller: _postalCtrl,
                    label: '邮政编码',
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? '请填写邮编' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KycDropdown<String>(
                    label: '国家/地区',
                    value: _country,
                    items: const [
                      DropdownMenuItem(value: 'CN', child: Text('中国大陆')),
                      DropdownMenuItem(value: 'HK', child: Text('香港')),
                      DropdownMenuItem(value: 'US', child: Text('美国')),
                      DropdownMenuItem(value: 'OTHER', child: Text('其他')),
                    ],
                    onChanged: (v) => setState(() => _country = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            KycDropdown<AddressProofDocType>(
              label: '证明文件类型',
              value: _docType,
              items: const [
                DropdownMenuItem(
                    value: AddressProofDocType.bankStatement,
                    child: Text('银行账单')),
                DropdownMenuItem(
                    value: AddressProofDocType.utilityBill,
                    child: Text('水电费账单')),
                DropdownMenuItem(
                    value: AddressProofDocType.governmentLetter,
                    child: Text('政府信函')),
              ],
              onChanged: (v) => setState(() => _docType = v!),
            ),
            const SizedBox(height: 20),
            _FilePicker(fileName: _fileName, onPickFile: _pickFile),
            const SizedBox(height: 8),
            const Text(
              '不接受：截图、无日期文件、非官方文件',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 32),
            KycNextButton(isLoading: isLoading, onPressed: _submit),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件大小不能超过 10MB')));
      return;
    }
    setState(() {
      _fileName = picked.name;
      _fileBytes = bytes;
      _mimeType = 'image/jpeg';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请上传地址证明文件')));
      return;
    }
    await ref.read(addressProofProvider.notifier).submit(
          proof: AddressProof(
            street: _streetCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            province: _provinceCtrl.text.trim(),
            postalCode: _postalCtrl.text.trim(),
            country: _country,
            proofDocumentPath: _fileName!,
            proofDocumentType: _docType,
          ),
          fileBytes: _fileBytes!,
          mimeType: _mimeType ?? 'image/jpeg',
        );
  }
}

class _FilePicker extends StatelessWidget {
  const _FilePicker({required this.fileName, required this.onPickFile});
  final String? fileName;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPickFile,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2530),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: fileName != null ? const Color(0xFF0DC582) : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(
              fileName != null ? Icons.attach_file : Icons.upload_file_outlined,
              color: fileName != null ? const Color(0xFF0DC582) : Colors.white38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName ?? '选择文件（PDF / JPG / PNG，≤ 10MB）',
                style: TextStyle(
                  color: fileName != null ? Colors.white70 : Colors.white38,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
