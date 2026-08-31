import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/person_model.dart';

/// Maps a file extension to its multipart content type.
/// `MultipartFile.fromBytes` defaults to application/octet-stream, which
/// the backend's upload filter rejects — so we must send the real type.
String _contentTypeFor(String filename) {
  final name = filename.toLowerCase();
  if (name.endsWith('.pdf')) return 'application/pdf';
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
  return 'application/octet-stream';
}

/// Everything needed to create or update a person. Kept as one bundle
/// so the confirm-the-final-value flow (Aadhaar vs PAN vs typed value)
/// is always submitted together and consistently.
class PersonFormData {
  final String? fullNameAadhaar;
  final String? fullNamePan;
  final String fullNameConfirmed;

  final String mobileNumber;
  final String alternativeMobile;
  final String email;
  final String gender;
  final String maritalStatus;

  final String? dateOfBirthAadhaar; // ISO date string
  final String? dateOfBirthPan;
  final DateTime? dateOfBirthConfirmed;

  final String permanentAddress;
  final String communicationAddress;
  final bool communicationSameAsPermanent;
  final String city;
  final String state;
  final String pincode;

  final String aadhaarNumber;
  final String panNumber;

  final List<String> activeRelationships;

  final XFile? profilePhoto;
  final XFile? aadhaarFront;
  final XFile? aadhaarBack;
  final XFile? panDocument;

  const PersonFormData({
    this.fullNameAadhaar,
    this.fullNamePan,
    required this.fullNameConfirmed,
    required this.mobileNumber,
    this.alternativeMobile = '',
    required this.email,
    this.gender = '',
    this.maritalStatus = '',
    this.dateOfBirthAadhaar,
    this.dateOfBirthPan,
    this.dateOfBirthConfirmed,
    this.permanentAddress = '',
    this.communicationAddress = '',
    this.communicationSameAsPermanent = true,
    required this.city,
    required this.state,
    required this.pincode,
    this.aadhaarNumber = '',
    this.panNumber = '',
    this.activeRelationships = const [],
    this.profilePhoto,
    this.aadhaarFront,
    this.aadhaarBack,
    this.panDocument,
  });
}

/// Builds a Dio MultipartFile from an XFile using its bytes rather than
/// its path. XFile.path is a real filesystem path on mobile/desktop but
/// a blob: URL on Flutter Web, so MultipartFile.fromFile(path) (which
/// needs dart:io) silently fails on web. Reading bytes works on every
/// platform.
Future<MultipartFile> _toMultipart(XFile file) async {
  final bytes = await file.readAsBytes();
  return MultipartFile.fromBytes(
    bytes,
    filename: file.name,
    contentType: MediaType.parse(_contentTypeFor(file.name)),
  );
}

class PersonService {
  final Dio _dio = DioClient().dio;

  Future<FormData> _buildFormData(PersonFormData form) async {
    final map = <String, dynamic>{
      if (form.fullNameAadhaar != null) 'fullNameAadhaar': form.fullNameAadhaar,
      if (form.fullNamePan != null) 'fullNamePan': form.fullNamePan,
      'fullNameConfirmed': form.fullNameConfirmed,
      'mobileNumber': form.mobileNumber,
      'alternativeMobile': form.alternativeMobile,
      'email': form.email,
      'gender': form.gender,
      'maritalStatus': form.maritalStatus,
      if (form.dateOfBirthAadhaar != null) 'dateOfBirthAadhaar': form.dateOfBirthAadhaar,
      if (form.dateOfBirthPan != null) 'dateOfBirthPan': form.dateOfBirthPan,
      if (form.dateOfBirthConfirmed != null)
        'dateOfBirthConfirmed': form.dateOfBirthConfirmed!.toIso8601String(),
      'permanentAddress': form.permanentAddress,
      'communicationAddress': form.communicationAddress,
      'communicationSameAsPermanent': form.communicationSameAsPermanent.toString(),
      'city': form.city,
      'state': form.state,
      'pincode': form.pincode,
      if (form.aadhaarNumber.isNotEmpty) 'aadhaarNumber': form.aadhaarNumber,
      if (form.panNumber.isNotEmpty) 'panNumber': form.panNumber,
      if (form.activeRelationships.isNotEmpty) 'activeRelationships': form.activeRelationships,
    };

    if (form.profilePhoto != null) {
      map['profilePhoto'] = await _toMultipart(form.profilePhoto!);
    }
    if (form.aadhaarFront != null) {
      map['aadhaarFront'] = await _toMultipart(form.aadhaarFront!);
    }
    if (form.aadhaarBack != null) {
      map['aadhaarBack'] = await _toMultipart(form.aadhaarBack!);
    }
    if (form.panDocument != null) {
      map['panDocument'] = await _toMultipart(form.panDocument!);
    }

    return FormData.fromMap(map);
  }

  /// Calls /extract-aadhaar with the given image, returning the
  /// OCR-suggested name/DOB/number. The caller must still show these
  /// to the user for confirmation — never applied automatically.
  Future<ExtractedDocumentData> extractAadhaar(XFile image) async {
    final formData = FormData.fromMap({
      'document': await _toMultipart(image),
    });
    final response = await _dio.post(
      '${ApiConstants.personsEndpoint}/extract-aadhaar',
      data: formData,
      options: Options(receiveTimeout: ApiConstants.ocrReceiveTimeout),
    );
    return ExtractedDocumentData.fromJson(response.data['data']);
  }

  Future<ExtractedDocumentData> extractPan(XFile image) async {
    final formData = FormData.fromMap({
      'document': await _toMultipart(image),
    });
    final response = await _dio.post(
      '${ApiConstants.personsEndpoint}/extract-pan',
      data: formData,
      options: Options(receiveTimeout: ApiConstants.ocrReceiveTimeout),
    );
    return ExtractedDocumentData.fromJson(response.data['data']);
  }

  /// Checks for an existing person with the same Aadhaar/PAN number
  /// before creating a new one, per spec (never duplicate by identity
  /// document). Returns the existing referenceId if found.
  Future<String?> checkDuplicate({String? aadhaarNumber, String? panNumber}) async {
    if ((aadhaarNumber == null || aadhaarNumber.isEmpty) && (panNumber == null || panNumber.isEmpty)) {
      return null;
    }
    final response = await _dio.get(
      '${ApiConstants.personsEndpoint}/check-duplicate',
      queryParameters: {
        if (aadhaarNumber != null && aadhaarNumber.isNotEmpty) 'aadhaarNumber': aadhaarNumber,
        if (panNumber != null && panNumber.isNotEmpty) 'panNumber': panNumber,
      },
    );
    final data = response.data['data'];
    return data['duplicate'] == true ? data['referenceId'] as String? : null;
  }

  Future<Person> createPerson(PersonFormData form) async {
    final formData = await _buildFormData(form);
    final response = await _dio.post(ApiConstants.personsEndpoint, data: formData);
    return Person.fromJson(response.data['data']);
  }

  Future<List<Person>> getAllPersons() async {
    final response = await _dio.get(ApiConstants.personsEndpoint);
    final List list = response.data['data'] as List;
    return list.map((e) => Person.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Person> getPersonByReferenceId(String referenceId) async {
    final response = await _dio.get('${ApiConstants.personsEndpoint}/$referenceId');
    return Person.fromJson(response.data['data']);
  }

  Future<List<Person>> searchPersons(String query) async {
    final response = await _dio.get(
      '${ApiConstants.personsEndpoint}/search',
      queryParameters: {'q': query},
    );
    final List list = response.data['data'] as List;
    return list.map((e) => Person.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Person> updatePerson(String referenceId, PersonFormData form) async {
    final formData = await _buildFormData(form);
    final response = await _dio.put('${ApiConstants.personsEndpoint}/$referenceId', data: formData);
    return Person.fromJson(response.data['data']);
  }

  Future<Person> verifyPerson(String referenceId) async {
    final response = await _dio.patch('${ApiConstants.personsEndpoint}/$referenceId/verify');
    return Person.fromJson(response.data['data']);
  }

  Future<Person> updateStatus(String referenceId, String status) async {
    final response = await _dio.patch(
      '${ApiConstants.personsEndpoint}/$referenceId/status',
      data: {'status': status},
    );
    return Person.fromJson(response.data['data']);
  }

  Future<List<Person>> getDueForReview() async {
    final response = await _dio.get('${ApiConstants.personsEndpoint}/due-for-review');
    final List list = response.data['data'] as List;
    return list.map((e) => Person.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Person>> getUpcomingBirthdays({int days = 7}) async {
    final response = await _dio.get(
      '${ApiConstants.personsEndpoint}/upcoming-birthdays',
      queryParameters: {'days': days},
    );
    final List list = response.data['data'] as List;
    return list.map((e) => Person.fromJson(e as Map<String, dynamic>)).toList();
  }
}