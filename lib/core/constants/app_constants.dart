/// Fixed enum-like value lists shared across the Add/Edit Person forms
/// and used to build dropdowns. Mirrors the backend's allowed values
/// exactly so client-side validation never drifts from the server.
class AppConstants {
  AppConstants._();

  static const List<String> genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  static const List<String> maritalStatuses = ['Single', 'Married', 'Divorced', 'Widowed'];

  static const List<String> activeRelationships = [
    'Employee',
    'Partner',
    'Banker',
    'Customer',
    'Candidate',
    'Management',
  ];

  static const List<String> overallStatuses = ['ACTIVE', 'INACTIVE', 'DECEASED'];
}
