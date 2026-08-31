import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/api_constants.dart';

/// Aadhaar / PAN document picker:
/// camera, gallery, or file picker (for PDFs).
///
/// Shows the selected file name and allows replace/remove.
/// Optionally triggers an OCR extraction callback after a file is picked.
///
/// Uses [XFile] (cross-platform) instead of dart:io [File] so the same
/// widget works on Android, iOS and the web.
class DocumentPickerField extends StatelessWidget {
  final String label;
  final XFile? selectedFile;
  final String? existingFileName;
  final ValueChanged<XFile?> onChanged;
  final ValueChanged<XFile>? onExtract;

  const DocumentPickerField({
    super.key,
    required this.label,
    required this.selectedFile,
    required this.onChanged,
    this.existingFileName,
    this.onExtract,
  });

  bool _isValidSize(int bytes) {
    return bytes <= ApiConstants.maxFileSizeBytes;
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (picked == null) return;

    if (!_isValidSize(await picked.length())) {
      if (!context.mounted) return;
      _showTooLarge(context);
      return;
    }

    _accept(context, picked);
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    if (!_isValidSize(await picked.length())) {
      if (!context.mounted) return;
      _showTooLarge(context);
      return;
    }

    _accept(context, picked);
  }

  Future<void> _pickFromFiles(BuildContext context) async {
    final selected = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ApiConstants.allowedDocumentExtensions,
    );

    if (selected == null) return;

    final xfile = selected.xFile;

    if (!_isValidSize(await xfile.length())) {
      if (!context.mounted) return;
      _showTooLarge(context);
      return;
    }

    _accept(context, xfile);
  }

  void _accept(BuildContext context, XFile file) {
    onChanged(file);

    if (onExtract != null) {
      onExtract!(file);
    }
  }

  void _showTooLarge(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File is too large. Max size is 5MB.'),
      ),
    );
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file_outlined,
              ),
              title: const Text('Choose File (PDF/Image)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromFiles(context);
              },
            ),
            if (selectedFile != null ||
                (existingFileName?.isNotEmpty ?? false))
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: const Text(
                  'Remove File',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onChanged(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  String get _displayName {
    if (selectedFile != null) {
      return selectedFile!.name;
    }

    if (existingFileName != null &&
        existingFileName!.isNotEmpty) {
      return existingFileName!;
    }

    return 'No file selected';
  }

  bool get _hasFile {
    return selectedFile != null ||
        (existingFileName?.isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showSourceSheet(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _hasFile
                      ? Icons.insert_drive_file
                      : Icons.upload_file_outlined,
                  color: _hasFile
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade500,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _hasFile
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
