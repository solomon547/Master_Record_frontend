import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

/// Single centralized Dio instance. Base URL, headers, timeouts and
/// generic error/logging behaviour are configured once here so that
/// no individual service repeats this setup.
class DioClient {
  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'x-association-id': ApiConstants.currentAssociationId,
          if (ApiConstants.currentUserRole.isNotEmpty)
            'x-user-role': ApiConstants.currentUserRole,
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          // Never log sensitive document content — Dio logging here is
          // limited to method/path/status only.
          // ignore: avoid_print
          print('[API ERROR] ${e.requestOptions.method} ${e.requestOptions.path} -> ${e.response?.statusCode}');
          handler.next(e);
        },
      ),
    );
  }

  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio _dio;
  Dio get dio => _dio;
}

/// Normalizes any Dio/network failure into a short, user-friendly
/// message. Raw stack traces / backend internals are never shown
/// to the user.
String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'Could not connect to the server. Check your internet connection.';
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        if (data is Map && data['message'] != null) {
          return data['message'].toString();
        }
        return 'Request failed (${error.response?.statusCode ?? 'unknown'}).';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}
