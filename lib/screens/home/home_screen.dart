import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/person_provider.dart';
import '../../routes/app_routes.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personListAsync = ref.watch(personListProvider);
    final dueForReviewAsync = ref.watch(dueForReviewProvider);
    final birthdaysAsync = ref.watch(upcomingBirthdaysProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('People Master')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(personListProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Text(
              'Master Person Identity System',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.people_alt_outlined, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Persons', style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          personListAsync.when(
                            data: (list) => Text('${list.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            loading: () => const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (e, _) => const Text('--'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _SmallStatCard(
                    icon: Icons.event_repeat,
                    label: 'Review Due',
                    asyncCount: dueForReviewAsync,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SmallStatCard(
                    icon: Icons.cake_outlined,
                    label: 'Birthdays (7d)',
                    asyncCount: birthdaysAsync,
                    color: Colors.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addPerson),
              icon: const Icon(Icons.add),
              label: const Text('ADD PERSON'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.personList),
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text('PERSON LIST'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.searchPerson),
              icon: const Icon(Icons.search),
              label: const Text('SEARCH PERSON'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final AsyncValue<List<dynamic>> asyncCount;
  final Color color;

  const _SmallStatCard({required this.icon, required this.label, required this.asyncCount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            asyncCount.when(
              data: (list) => Text('${list.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => const Text('--'),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
