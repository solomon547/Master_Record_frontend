import 'package:flutter/material.dart';

/// Shows the Aadhaar-extracted and PAN-extracted values for a field
/// (name or date of birth) side by side, flags a mismatch, and lets
/// the user pick one or type a different final value — exactly the
/// "auto extract, check mismatch, ask for confirmation with an input
/// box" flow the spec requires. Never silently picks one for the user.
class ConfirmableFieldCard extends StatelessWidget {
  final String label;
  final String? aadhaarValue;
  final String? panValue;
  final TextEditingController confirmedController;
  final String? Function(String?)? validator;

  const ConfirmableFieldCard({
    super.key,
    required this.label,
    required this.aadhaarValue,
    required this.panValue,
    required this.confirmedController,
    this.validator,
  });

  bool get _hasMismatch =>
      aadhaarValue != null &&
      panValue != null &&
      aadhaarValue!.trim().toLowerCase() != panValue!.trim().toLowerCase();

  bool get _hasAnySource => (aadhaarValue?.isNotEmpty ?? false) || (panValue?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    if (!_hasAnySource) {
      // Nothing extracted yet (documents not uploaded) — plain input only.
      return TextFormField(
        controller: confirmedController,
        validator: validator,
        decoration: InputDecoration(labelText: '$label *'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _hasMismatch ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _hasMismatch ? Colors.orange.shade200 : Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasMismatch ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                size: 18,
                color: _hasMismatch ? Colors.orange.shade800 : Colors.green.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                _hasMismatch ? '$label mismatch found — please confirm' : '$label extracted',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _hasMismatch ? Colors.orange.shade800 : Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (aadhaarValue != null && aadhaarValue!.isNotEmpty)
            _SourceValueRow(
              source: 'Aadhaar',
              value: aadhaarValue!,
              onUse: () => confirmedController.text = aadhaarValue!,
            ),
          if (panValue != null && panValue!.isNotEmpty)
            _SourceValueRow(
              source: 'PAN',
              value: panValue!,
              onUse: () => confirmedController.text = panValue!,
            ),
          const SizedBox(height: 10),
          TextFormField(
            controller: confirmedController,
            validator: validator,
            decoration: InputDecoration(labelText: 'Final $label *', filled: true, fillColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SourceValueRow extends StatelessWidget {
  final String source;
  final String value;
  final VoidCallback onUse;

  const _SourceValueRow({required this.source, required this.value, required this.onUse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(source, style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
          TextButton(
            onPressed: onUse,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
            child: const Text('Use this', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
