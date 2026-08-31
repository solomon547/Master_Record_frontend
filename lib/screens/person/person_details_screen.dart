import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/dio_client.dart';
import '../../models/person_model.dart';
import '../../providers/person_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class PersonDetailsScreen extends ConsumerWidget {
  final String referenceId;
  const PersonDetailsScreen({super.key, required this.referenceId});

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, Person person, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set status to $newStatus'),
        content: Text(
          'This person\'s People ID (${person.referenceId}) remains reserved. The record is never deleted, only status-changed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(personFormProvider.notifier).updateStatus(person.referenceId, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  Future<void> _verify(BuildContext context, WidgetRef ref, Person person) async {
    try {
      await ref.read(personFormProvider.notifier).verifyPerson(person.referenceId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Person verified')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  /// Robustly parses the confirmed date of birth. The backend may
  /// return either an ISO string (e.g. "1998-09-15") or a JavaScript
  /// Date.toString() form (e.g. "Tue Sep 15 1998 00:00:00 GMT+0530 ...").
  static String _formatDob(String? value) {
    if (value == null || value.isEmpty) return '-';
    final trimmed = value.trim();

    DateTime? parsed = DateTime.tryParse(trimmed);
    if (parsed == null) {
      try {
        parsed = DateFormat('EEE MMM dd yyyy HH:mm:ss').parse(trimmed);
      } catch (_) {
        parsed = null;
      }
    }
    if (parsed != null) return DateFormat('dd MMM yyyy').format(parsed);
    return trimmed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(personDetailsProvider(referenceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Person Details')),
      body: personAsync.when(
        loading: () => const LoadingWidget(message: 'Loading person...'),
        error: (e, _) => AppErrorWidget(
          message: 'Could not load this person.',
          onRetry: () => ref.invalidate(personDetailsProvider(referenceId)),
        ),
        data: (person) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
              Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    person.profilePhoto.hasFile ? NetworkImage(person.profilePhoto.current!.fileUrl!) : null,
                onBackgroundImageError: person.profilePhoto.hasFile ? (_, __) {} : null,
                child: !person.profilePhoto.hasFile
                    ? Text(
                        person.displayName.isNotEmpty ? person.displayName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                person.displayName.isEmpty ? '(Name pending)' : person.displayName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            if (person.fullName.mismatch) ...[
              const SizedBox(height: 4),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text('Aadhaar/PAN name mismatch', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: person.isActive ? Colors.green.shade50 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  person.overallStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: person.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _DetailCard(children: [
              _DetailRow(label: 'People ID', value: person.referenceId, emphasize: true),
              _DetailRow(label: 'Mobile Number', value: person.mobileNumber),
              if (person.alternativeMobile.isNotEmpty)
                _DetailRow(label: 'Alt. Mobile', value: person.alternativeMobile),
              _DetailRow(label: 'Email ID', value: person.email),
              _DetailRow(
                label: 'Date of Birth',
                value: _formatDob(person.dateOfBirth.confirmedValue),
              ),
              _DetailRow(label: 'Gender', value: person.gender.isEmpty ? '-' : person.gender),
              _DetailRow(label: 'Marital Status', value: person.maritalStatus.isEmpty ? '-' : person.maritalStatus),
            ]),
            const SizedBox(height: 16),

            _DetailCard(title: 'Address', children: [
              _DetailRow(label: 'Permanent', value: person.permanentAddress.isEmpty ? '-' : person.permanentAddress),
              _DetailRow(
                label: 'Communication',
                value: person.communicationSameAsPermanent
                    ? 'Same as permanent'
                    : (person.communicationAddress.isEmpty ? '-' : person.communicationAddress),
              ),
              _DetailRow(label: 'City', value: person.city),
              _DetailRow(label: 'State', value: person.state),
              _DetailRow(label: 'Pincode', value: person.pincode),
            ]),
            const SizedBox(height: 16),

            _DetailCard(title: 'Identity Numbers (masked unless Top Management)', children: [
              _DetailRow(label: 'Aadhaar Number', value: person.aadhaarNumber ?? '-'),
              _DetailRow(label: 'PAN Number', value: person.panNumber ?? '-'),
            ]),
            const SizedBox(height: 16),

            _DetailCard(title: 'Documents', children: [
              _DocumentRow(label: 'Profile Photo', slot: person.profilePhoto),
              _DocumentRow(label: 'Aadhaar Front', slot: person.aadhaarFront),
              _DocumentRow(label: 'Aadhaar Back', slot: person.aadhaarBack),
              _DocumentRow(label: 'PAN Document', slot: person.panDocument),
            ]),
            const SizedBox(height: 16),

            if (person.activeRelationships.isNotEmpty) ...[
              _DetailCard(title: 'Active Relationships', children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: person.activeRelationships
                      .map((r) => Chip(label: Text(r), visualDensity: VisualDensity.compact))
                      .toList(),
                ),
              ]),
              const SizedBox(height: 16),
            ],

            _DetailCard(title: 'Audit', children: [
              _DetailRow(label: 'Created By', value: person.createdBy.associationId ?? '-'),
              _DetailRow(
                label: 'Created At',
                value: person.createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(person.createdAt!) : '-',
              ),
              _DetailRow(label: 'Last Modified By', value: person.lastModifiedBy.associationId ?? '-'),
              _DetailRow(
                label: 'Last Modified At',
                value:
                    person.lastModifiedBy.at != null ? DateFormat('dd MMM yyyy, hh:mm a').format(person.lastModifiedBy.at!) : '-',
              ),
              _DetailRow(label: 'Last Verified By', value: person.lastVerifiedBy.associationId ?? 'Not yet verified'),
              _DetailRow(
                label: 'Next Review Due',
                value: person.nextReviewDueAt != null ? DateFormat('dd MMM yyyy').format(person.nextReviewDueAt!) : '-',
              ),
            ]),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.editPerson, arguments: person),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('EDIT'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _verify(context, ref, person),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('MARK AS VERIFIED'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _changeStatus(
                      context,
                      ref,
                      person,
                      person.isActive ? 'INACTIVE' : 'ACTIVE',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: person.isActive ? Colors.red : Colors.green,
                      side: BorderSide(color: person.isActive ? Colors.red : Colors.green),
                    ),
                    child: Text(person.isActive ? 'DEACTIVATE' : 'ACTIVATE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _changeStatus(context, ref, person, 'DECEASED'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueGrey,
                      side: const BorderSide(color: Colors.blueGrey),
                    ),
                    child: const Text('MARK DECEASED'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const _DetailCard({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  const _DetailRow({required this.label, required this.value, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(
            child: Text(
              value,
              style: emphasize
                  ? TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
                  : const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final String label;
  final DocumentSlot slot;
  const _DocumentRow({required this.label, required this.slot});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            slot.hasFile ? Icons.check_circle : Icons.remove_circle_outline,
            color: slot.hasFile ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            slot.hasFile
                ? (slot.history.isEmpty ? 'Uploaded' : 'Uploaded (${slot.history.length} previous)')
                : 'Not uploaded',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
