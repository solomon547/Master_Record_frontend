import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API configuration.
///
/// This is the ONLY place the backend base URL should be defined.
/// Switch [environment] to change target without touching any
/// service or screen code.
enum ApiEnvironment { androidEmulator, physicalDevice, production }

class ApiConstants {
  ApiConstants._();

  /// Change this single value to switch environments during development
  /// (this only affects non-web targets — see [baseUrl] below).
 static const ApiEnvironment environment = ApiEnvironment.production;

static const String _webBaseUrl =
    'http://localhost:5000';

static const String _physicalDeviceBaseUrl =
    'http://192.168.1.10:5000';

static const String _productionBaseUrl =
    'https://master-record.onrender.com';

static String get baseUrl {
  if (kIsWeb) return _productionBaseUrl;

  switch (environment) {
    case ApiEnvironment.androidEmulator:
      return 'http://10.0.2.2:5000';

    case ApiEnvironment.physicalDevice:
      return _physicalDeviceBaseUrl;

    case ApiEnvironment.production:
      return _productionBaseUrl;
  }
}

  static const String personsEndpoint = '/api/persons';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  // Longer timeout for OCR extraction calls, which can take a few seconds.
  static const Duration ocrReceiveTimeout = Duration(seconds: 30);

  /// Placeholder Association ID sent as `x-association-id` on every
  /// create/update/verify call, since the backend requires one (a
  /// People Master record must be created/modified "through an
  /// association entry"). Replace this with the real logged-in
  /// association's ID once this app has authentication.
  static const String currentAssociationId = 'ASSOC-APP-USER';

  /// Send 'TOP_MANAGEMENT' here to receive unmasked Aadhaar/PAN
  /// numbers from the backend. Left blank by default so numbers stay
  /// masked unless explicitly elevated (e.g. from a settings screen).
  static const String currentUserRole = '';

  // File validation
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocumentExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
}