import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/person_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/person_card.dart';

class PersonListScreen extends ConsumerWidget {
  const PersonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personListAsync = ref.watch(personListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Persons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.searchPerson),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addPerson),
        icon: const Icon(Icons.add),
        label: const Text('Add Person'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(personListProvider.notifier).refresh(),
        child: personListAsync.when(
          loading: () => const LoadingWidget(message: 'Loading persons...'),
          error: (e, _) => AppErrorWidget(
            message: 'Could not load persons.\n${_shortError(e)}',
            onRetry: () => ref.read(personListProvider.notifier).refresh(),
          ),
          data: (persons) {
            if (persons.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'No Person Records Found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(child: Text('Create your first master record.')),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.addPerson),
                      icon: const Icon(Icons.add),
                      label: const Text('ADD PERSON'),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 90),
              itemCount: persons.length,
              itemBuilder: (context, index) {
                final person = persons[index];
                return PersonCard(
                  person: person,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.personDetails,
                    arguments: person.referenceId,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _shortError(Object e) => e.toString().replaceAll('Exception: ', '');
}
