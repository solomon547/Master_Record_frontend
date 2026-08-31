import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/person_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/person_card.dart';

class SearchPersonScreen extends ConsumerStatefulWidget {
  const SearchPersonScreen({super.key});

  @override
  ConsumerState<SearchPersonScreen> createState() => _SearchPersonScreenState();
}

class _SearchPersonScreenState extends ConsumerState<SearchPersonScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(personSearchProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(personSearchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search Person')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                hintText: 'Search by Reference ID, name, mobile or email',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: resultsAsync.when(
              loading: () => const LoadingWidget(message: 'Searching...'),
              error: (e, _) => AppErrorWidget(message: 'Search failed. Please try again.'),
              data: (persons) {
                if (_controller.text.trim().isEmpty) {
                  return Center(
                    child: Text(
                      'Start typing to search',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }
                if (persons.isEmpty) {
                  return const Center(child: Text('No matching person found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
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
        ],
      ),
    );
  }
}
