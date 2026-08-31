import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/person_model.dart';
import '../services/person_service.dart';

final personServiceProvider = Provider<PersonService>((ref) => PersonService());

/// Loads and holds the full person list for the Person List screen.
class PersonListNotifier extends AsyncNotifier<List<Person>> {
  @override
  Future<List<Person>> build() async {
    return ref.read(personServiceProvider).getAllPersons();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(personServiceProvider).getAllPersons());
  }
}

final personListProvider = AsyncNotifierProvider<PersonListNotifier, List<Person>>(
  PersonListNotifier.new,
);

/// Search results, driven by the Search screen's text field.
class PersonSearchNotifier extends AsyncNotifier<List<Person>> {
  @override
  Future<List<Person>> build() async => [];

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(personServiceProvider).searchPersons(query));
  }
}

final personSearchProvider = AsyncNotifierProvider<PersonSearchNotifier, List<Person>>(
  PersonSearchNotifier.new,
);

/// Fetches a single person by referenceId (Person Details screen).
final personDetailsProvider =
    FutureProvider.autoDispose.family<Person, String>((ref, referenceId) async {
  return ref.read(personServiceProvider).getPersonByReferenceId(referenceId);
});

/// People due for their 3-year liveliness review (Home screen summary).
final dueForReviewProvider = FutureProvider.autoDispose<List<Person>>((ref) async {
  return ref.read(personServiceProvider).getDueForReview();
});

/// People with an upcoming birthday (Home screen summary).
final upcomingBirthdaysProvider = FutureProvider.autoDispose<List<Person>>((ref) async {
  return ref.read(personServiceProvider).getUpcomingBirthdays();
});

/// Drives the Add Person / Edit Person submit button state so the
/// button can be disabled while a request is in flight.
class PersonFormNotifier extends AsyncNotifier<Person?> {
  @override
  Future<Person?> build() async => null;

  Future<Person> createPerson(PersonFormData form) async {
    state = const AsyncLoading();
    try {
      final person = await ref.read(personServiceProvider).createPerson(form);
      state = AsyncData(person);
      ref.invalidate(personListProvider);
      return person;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Person> updatePerson(String referenceId, PersonFormData form) async {
    state = const AsyncLoading();
    try {
      final person = await ref.read(personServiceProvider).updatePerson(referenceId, form);
      state = AsyncData(person);
      ref.invalidate(personListProvider);
      ref.invalidate(personDetailsProvider(referenceId));
      return person;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Person> updateStatus(String referenceId, String status) async {
    final person = await ref.read(personServiceProvider).updateStatus(referenceId, status);
    ref.invalidate(personListProvider);
    ref.invalidate(personDetailsProvider(referenceId));
    return person;
  }

  Future<Person> verifyPerson(String referenceId) async {
    final person = await ref.read(personServiceProvider).verifyPerson(referenceId);
    ref.invalidate(personListProvider);
    ref.invalidate(personDetailsProvider(referenceId));
    return person;
  }
}

final personFormProvider = AsyncNotifierProvider<PersonFormNotifier, Person?>(
  PersonFormNotifier.new,
);
