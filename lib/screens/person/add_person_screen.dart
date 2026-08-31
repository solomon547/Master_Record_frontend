import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/dio_client.dart';
import '../../models/person_model.dart';
import '../../providers/person_provider.dart';
import '../../services/person_service.dart';
import '../../widgets/confirmable_field_card.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/document_picker.dart';
import '../../widgets/photo_picker.dart';

class AddPersonScreen extends ConsumerStatefulWidget {
  const AddPersonScreen({super.key});

  @override
  ConsumerState<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends ConsumerState<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameConfirmedController = TextEditingController();
  final _dobConfirmedController = TextEditingController();
  final _mobileController = TextEditingController();
  final _altMobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _communicationAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _aadhaarNumberController = TextEditingController();
  final _panNumberController = TextEditingController();

  String _gender = '';
  String _maritalStatus = '';
  bool _communicationSameAsPermanent = true;
  final Set<String> _activeRelationships = {};

  XFile? _profilePhoto;
  XFile? _aadhaarFront;
  XFile? _aadhaarBack;
  XFile? _panDocument;

  ExtractedDocumentData? _aadhaarExtracted;
  ExtractedDocumentData? _panExtracted;
  bool _extractingAadhaar = false;
  bool _extractingPan = false;

  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameConfirmedController.dispose();
    _dobConfirmedController.dispose();
    _mobileController.dispose();
    _altMobileController.dispose();
    _emailController.dispose();
    _permanentAddressController.dispose();
    _communicationAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _aadhaarNumberController.dispose();
    _panNumberController.dispose();
    super.dispose();
  }

  Future<void> _onAadhaarFrontPicked(XFile file) async {
    setState(() => _extractingAadhaar = true);
    try {
      final extracted = await ref.read(personServiceProvider).extractAadhaar(file);
      setState(() {
        _aadhaarExtracted = extracted;
        if (extracted.aadhaarNumber != null && _aadhaarNumberController.text.isEmpty) {
          _aadhaarNumberController.text = extracted.aadhaarNumber!;
        }
        if (extracted.name != null && _fullNameConfirmedController.text.isEmpty) {
          _fullNameConfirmedController.text = extracted.name!;
        }
        if (extracted.dob != null && _dobConfirmedController.text.isEmpty) {
          _dobConfirmedController.text = extracted.dob!;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not auto-read Aadhaar: ${friendlyErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _extractingAadhaar = false);
    }
  }

  Future<void> _onPanPicked(XFile file) async {
    setState(() => _extractingPan = true);
    try {
      final extracted = await ref.read(personServiceProvider).extractPan(file);
      setState(() {
        _panExtracted = extracted;
        if (extracted.panNumber != null && _panNumberController.text.isEmpty) {
          _panNumberController.text = extracted.panNumber!;
        }
        if (extracted.name != null && _fullNameConfirmedController.text.isEmpty) {
          _fullNameConfirmedController.text = extracted.name!;
        }
        if (extracted.dob != null && _dobConfirmedController.text.isEmpty) {
          _dobConfirmedController.text = extracted.dob!;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not auto-read PAN: ${friendlyErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _extractingPan = false);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_dobConfirmedController.text) ?? DateTime(now.year - 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dobConfirmedController.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final form = PersonFormData(
        fullNameAadhaar: _aadhaarExtracted?.name,
        fullNamePan: _panExtracted?.name,
        fullNameConfirmed: _fullNameConfirmedController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        alternativeMobile: _altMobileController.text.trim(),
        email: _emailController.text.trim(),
        gender: _gender,
        maritalStatus: _maritalStatus,
        dateOfBirthAadhaar: _aadhaarExtracted?.dob,
        dateOfBirthPan: _panExtracted?.dob,
        dateOfBirthConfirmed:
            _dobConfirmedController.text.isNotEmpty ? DateTime.tryParse(_dobConfirmedController.text) : null,
        permanentAddress: _permanentAddressController.text.trim(),
        communicationAddress: _communicationSameAsPermanent
            ? _permanentAddressController.text.trim()
            : _communicationAddressController.text.trim(),
        communicationSameAsPermanent: _communicationSameAsPermanent,
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        aadhaarNumber: _aadhaarNumberController.text.trim(),
        panNumber: _panNumberController.text.trim().toUpperCase(),
        activeRelationships: _activeRelationships.toList(),
        profilePhoto: _profilePhoto,
        aadhaarFront: _aadhaarFront,
        aadhaarBack: _aadhaarBack,
        panDocument: _panDocument,
      );

      final person = await ref.read(personFormProvider.notifier).createPerson(form);

      if (!mounted) return;
      await _showSuccessDialog(person.referenceId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showSuccessDialog(String referenceId) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Person Saved'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PEOPLE MASTER RECORD SAVED SUCCESSFULLY'),
            const SizedBox(height: 16),
            const Text('People ID', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(referenceId, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Person')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: PhotoPickerField(
                selectedFile: _profilePhoto,
                onChanged: (file) => setState(() => _profilePhoto = file),
              ),
            ),
            const SizedBox(height: 24),

            _SectionTitle('Identity Documents'),
            const SizedBox(height: 12),
            DocumentPickerField(
              label: 'Aadhaar Document (Front)',
              selectedFile: _aadhaarFront,
              onChanged: (file) => setState(() => _aadhaarFront = file),
              onExtract: (file) => _onAadhaarFrontPicked(file),
            ),
            if (_extractingAadhaar) const _ExtractingIndicator('Reading Aadhaar...'),
            const SizedBox(height: 16),

            DocumentPickerField(
              label: 'Aadhaar Document (Back)',
              selectedFile: _aadhaarBack,
              onChanged: (file) => setState(() => _aadhaarBack = file),
            ),
            const SizedBox(height: 16),

            DocumentPickerField(
              label: 'PAN Document',
              selectedFile: _panDocument,
              onChanged: (file) => setState(() => _panDocument = file),
              onExtract: (file) => _onPanPicked(file),
            ),
            if (_extractingPan) const _ExtractingIndicator('Reading PAN...'),
            const SizedBox(height: 24),

            _SectionTitle('Name & Date of Birth'),
            const SizedBox(height: 12),
            ConfirmableFieldCard(
              label: 'Full Name',
              aadhaarValue: _aadhaarExtracted?.name,
              panValue: _panExtracted?.name,
              confirmedController: _fullNameConfirmedController,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Full name is required';
                if (value.length < 2) return 'Full name must be at least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDob,
              child: AbsorbPointer(
                child: ConfirmableFieldCard(
                  label: 'Date of Birth',
                  aadhaarValue: _aadhaarExtracted?.dob,
                  panValue: _panExtracted?.dob,
                  confirmedController: _dobConfirmedController,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _SectionTitle('Contact Details'),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _mobileController,
              label: 'Mobile Number',
              required: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Mobile number is required';
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) return 'Enter a valid 10-digit mobile number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _altMobileController,
              label: 'Alternative Mobile',
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return null;
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) return 'Enter a valid 10-digit mobile number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              label: 'Email ID',
              required: true,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Email is required';
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 24),

            _SectionTitle('Personal Details'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender.isEmpty ? null : _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: AppConstants.genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (value) => setState(() => _gender = value ?? ''),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _maritalStatus.isEmpty ? null : _maritalStatus,
              decoration: const InputDecoration(labelText: 'Marital Status'),
              items: AppConstants.maritalStatuses.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (value) => setState(() => _maritalStatus = value ?? ''),
            ),
            const SizedBox(height: 24),

            _SectionTitle('Address'),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _permanentAddressController,
              label: 'Permanent Address',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _communicationSameAsPermanent,
              title: const Text('Communication address same as permanent'),
              onChanged: (v) => setState(() => _communicationSameAsPermanent = v ?? true),
            ),
            if (!_communicationSameAsPermanent) ...[
              const SizedBox(height: 8),
              CustomTextField(
                controller: _communicationAddressController,
                label: 'Communication Address',
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 16),
            CustomTextField(
              controller: _cityController,
              label: 'City',
              required: true,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'City is required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _stateController,
              label: 'State',
              required: true,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'State is required' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _pincodeController,
              label: 'Pincode',
              required: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Pincode is required';
                if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Enter a valid 6-digit pincode';
                return null;
              },
            ),
            const SizedBox(height: 24),

            _SectionTitle('Identity Numbers'),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _aadhaarNumberController,
              label: 'Aadhaar Number',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
              hint: 'Auto-filled after uploading Aadhaar',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _panNumberController,
              label: 'PAN Number',
              inputFormatters: [LengthLimitingTextInputFormatter(10)],
              hint: 'Auto-filled after uploading PAN',
            ),
            const SizedBox(height: 24),

            _SectionTitle('Active Relationship'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: AppConstants.activeRelationships.map((r) {
                final selected = _activeRelationships.contains(r);
                return FilterChip(
                  label: Text(r),
                  selected: selected,
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _activeRelationships.add(r);
                    } else {
                      _activeRelationships.remove(r);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('SAVE PERSON'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        fontSize: 15,
      ),
    );
  }
}

class _ExtractingIndicator extends StatelessWidget {
  final String message;
  const _ExtractingIndicator(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 10),
          Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
}
