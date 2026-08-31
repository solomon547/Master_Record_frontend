import 'package:flutter/material.dart';

import '../models/person_model.dart';

class PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;

  const PersonCard({super.key, required this.person, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'DECEASED':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(person.overallStatus);
    final name = person.displayName;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.grey.shade200,
          backgroundImage:
              person.profilePhoto.hasFile ? NetworkImage(person.profilePhoto.current!.fileUrl!) : null,
          onBackgroundImageError: person.profilePhoto.hasFile
              ? (_, __) {}
              : null,
          child: !person.profilePhoto.hasFile
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(name.isEmpty ? '(Name pending)' : name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(person.referenceId,
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
            if (person.mobileNumber.isNotEmpty) Text(person.mobileNumber),
            if (person.email.isNotEmpty) Text(person.email, overflow: TextOverflow.ellipsis),
            if (person.activeRelationships.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  person.activeRelationships.join(', '),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.4)),
          ),
          child: Text(
            person.overallStatus,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor.withOpacity(0.9)),
          ),
        ),
      ),
    );
  }
}
