import 'package:flutter/material.dart';

import '../models/person_model.dart';
import '../screens/home/home_screen.dart';
import '../screens/person/add_person_screen.dart';
import '../screens/person/edit_person_screen.dart';
import '../screens/person/person_details_screen.dart';
import '../screens/person/person_list_screen.dart';
import '../screens/person/search_person_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String addPerson = '/add-person';
  static const String personList = '/persons';
  static const String personDetails = '/person-details';
  static const String editPerson = '/edit-person';
  static const String searchPerson = '/search';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case addPerson:
        return MaterialPageRoute(builder: (_) => const AddPersonScreen());
      case personList:
        return MaterialPageRoute(builder: (_) => const PersonListScreen());
      case searchPerson:
        return MaterialPageRoute(builder: (_) => const SearchPersonScreen());
      case personDetails:
        final referenceId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => PersonDetailsScreen(referenceId: referenceId));
      case editPerson:
        final person = settings.arguments as Person;
        return MaterialPageRoute(builder: (_) => EditPersonScreen(person: person));
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
