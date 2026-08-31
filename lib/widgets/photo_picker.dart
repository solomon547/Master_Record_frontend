import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/api_constants.dart';

/// Profile photo picker: camera / gallery, preview, replace, remove.
///
/// Uses [XFile] (cross-platform) instead of dart:io [File] so the same
/// widget works on Android, iOS and the web.
class PhotoPickerField extends StatelessWidget {
  final XFile? selectedFile;
  final String? existingUrl; // used when editing a person who already has a photo
  final ValueChanged<XFile?> onChanged;
  final String label;

  const PhotoPickerField({
    super.key,
    required this.selectedFile,
    required this.onChanged,
    this.existingUrl,
    this.label = 'Profile Photo',
  });

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final sizeBytes = await picked.length();

    if (sizeBytes > ApiConstants.maxFileSizeBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo is too large. Max size is 5MB.')),
        );
      }
      return;
    }

    onChanged(picked);
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
                _pick(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, ImageSource.gallery);
              },
            ),
            if (selectedFile != null || (existingUrl?.isNotEmpty ?? false))
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
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

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedFile != null || (existingUrl?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showSourceSheet(context),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: hasSelection
                ? ClipOval(
                    child: _PreviewImage(selectedFile: selectedFile, existingUrl: existingUrl),
                  )
                : Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade600, size: 28),
          ),
        ),
      ],
    );
  }
}

/// Renders the selected photo as a memory image (works on web + mobile)
/// or the existing server photo via network URL.
class _PreviewImage extends StatefulWidget {
  final XFile? selectedFile;
  final String? existingUrl;
  const _PreviewImage({this.selectedFile, this.existingUrl});

  @override
  State<_PreviewImage> createState() => _PreviewImageState();
}

class _PreviewImageState extends State<_PreviewImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _PreviewImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFile?.path != widget.selectedFile?.path) {
      _load();
    }
  }

  Future<void> _load() async {
    final file = widget.selectedFile;
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.selectedFile;
    if (file != null) {
      final bytes = _bytes;
      if (bytes != null) {
        return Image.memory(bytes, fit: BoxFit.cover, width: 96, height: 96);
      }
      return const SizedBox(width: 96, height: 96);
    }
    final url = widget.existingUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(url, fit: BoxFit.cover, width: 96, height: 96);
    }
    return const SizedBox(width: 96, height: 96);
  }
}
