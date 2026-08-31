/// A single document upload event.
class DocumentEntry {
  final String? fileUrl;
  final String? fileName;
  final DateTime? uploadedAt;
  final String? uploadedBy;

  const DocumentEntry({this.fileUrl, this.fileName, this.uploadedAt, this.uploadedBy});

  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;

  factory DocumentEntry.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DocumentEntry();
    return DocumentEntry(
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      uploadedAt: json['uploadedAt'] != null ? DateTime.tryParse(json['uploadedAt']) : null,
      uploadedBy: json['uploadedBy'] as String?,
    );
  }
}

/// A document "slot" (e.g. Aadhaar front) — the current file plus
/// its full upload history, per the spec's audit-history requirement.
class DocumentSlot {
  final DocumentEntry? current;
  final List<DocumentEntry> history;

  const DocumentSlot({this.current, this.history = const []});

  bool get hasFile => current?.hasFile ?? false;

  factory DocumentSlot.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DocumentSlot();
    return DocumentSlot(
      current: json['current'] != null ? DocumentEntry.fromJson(json['current']) : null,
      history: (json['history'] as List? ?? [])
          .map((e) => DocumentEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A value that was auto-extracted from Aadhaar and/or PAN, checked
/// for a mismatch between the two, and confirmed by a human.
class ConfirmableField {
  final String? aadhaarValue;
  final String? panValue;
  final bool mismatch;
  final String? confirmedValue;

  const ConfirmableField({this.aadhaarValue, this.panValue, this.mismatch = false, this.confirmedValue});

  factory ConfirmableField.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ConfirmableField();
    return ConfirmableField(
      aadhaarValue: json['aadhaarValue'] as String?,
      panValue: json['panValue'] as String?,
      mismatch: json['mismatch'] as bool? ?? false,
      confirmedValue: json['confirmedValue'] as String?,
    );
  }
}

class AuditStamp {
  final String? associationId;
  final DateTime? at;

  const AuditStamp({this.associationId, this.at});

  factory AuditStamp.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AuditStamp();
    return AuditStamp(
      associationId: json['associationId'] as String?,
      at: json['at'] != null ? DateTime.tryParse(json['at']) : null,
    );
  }
}

class Person {
  final String id;
  final String referenceId; // People ID, e.g. PER0000001

  final ConfirmableField fullName;
  final String mobileNumber;
  final String alternativeMobile;
  final String email;
  final String gender;
  final ConfirmableField dateOfBirth;
  final String maritalStatus;

  final String permanentAddress;
  final String communicationAddress;
  final bool communicationSameAsPermanent;
  final String city;
  final String state;
  final String pincode;

  final String? aadhaarNumber; // masked unless caller is Top Management
  final String? panNumber; // masked unless caller is Top Management

  final DocumentSlot profilePhoto;
  final DocumentSlot aadhaarFront;
  final DocumentSlot aadhaarBack;
  final DocumentSlot panDocument;

  final List<String> activeRelationships;

  final AuditStamp createdBy;
  final AuditStamp lastModifiedBy;
  final AuditStamp lastVerifiedBy;
  final DateTime? nextReviewDueAt;

  final String overallStatus; // ACTIVE / INACTIVE / DECEASED

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Person({
    required this.id,
    required this.referenceId,
    required this.fullName,
    required this.mobileNumber,
    required this.alternativeMobile,
    required this.email,
    required this.gender,
    required this.dateOfBirth,
    required this.maritalStatus,
    required this.permanentAddress,
    required this.communicationAddress,
    required this.communicationSameAsPermanent,
    required this.city,
    required this.state,
    required this.pincode,
    required this.aadhaarNumber,
    required this.panNumber,
    required this.profilePhoto,
    required this.aadhaarFront,
    required this.aadhaarBack,
    required this.panDocument,
    required this.activeRelationships,
    required this.createdBy,
    required this.lastModifiedBy,
    required this.lastVerifiedBy,
    required this.nextReviewDueAt,
    required this.overallStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => overallStatus == 'ACTIVE';
  String get displayName => fullName.confirmedValue ?? fullName.aadhaarValue ?? fullName.panValue ?? '';

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['_id'] as String? ?? '',
      referenceId: json['referenceId'] as String? ?? '',
      fullName: ConfirmableField.fromJson(json['fullName']),
      mobileNumber: json['mobileNumber'] as String? ?? '',
      alternativeMobile: json['alternativeMobile'] as String? ?? '',
      email: json['email'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      dateOfBirth: ConfirmableField.fromJson(json['dateOfBirth']),
      maritalStatus: json['maritalStatus'] as String? ?? '',
      permanentAddress: json['permanentAddress'] as String? ?? '',
      communicationAddress: json['communicationAddress'] as String? ?? '',
      communicationSameAsPermanent: json['communicationSameAsPermanent'] as bool? ?? true,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      aadhaarNumber: json['aadhaarNumber'] as String?,
      panNumber: json['panNumber'] as String?,
      profilePhoto: DocumentSlot.fromJson(json['profilePhoto']),
      aadhaarFront: DocumentSlot.fromJson(json['aadhaarFront']),
      aadhaarBack: DocumentSlot.fromJson(json['aadhaarBack']),
      panDocument: DocumentSlot.fromJson(json['panDocument']),
      activeRelationships: (json['activeRelationships'] as List? ?? []).map((e) => e.toString()).toList(),
      createdBy: AuditStamp.fromJson(json['createdBy']),
      lastModifiedBy: AuditStamp.fromJson(json['lastModifiedBy']),
      lastVerifiedBy: AuditStamp.fromJson(json['lastVerifiedBy']),
      nextReviewDueAt: json['nextReviewDueAt'] != null ? DateTime.tryParse(json['nextReviewDueAt']) : null,
      overallStatus: json['overallStatus'] as String? ?? 'ACTIVE',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }
}

/// Result of calling /extract-aadhaar or /extract-pan.
class ExtractedDocumentData {
  final String? name;
  final String? dob; // ISO date string, e.g. "2000-05-10"
  final String? aadhaarNumber;
  final String? panNumber;

  const ExtractedDocumentData({this.name, this.dob, this.aadhaarNumber, this.panNumber});

  factory ExtractedDocumentData.fromJson(Map<String, dynamic> json) {
    return ExtractedDocumentData(
      name: json['name'] as String?,
      dob: json['dob'] as String?,
      aadhaarNumber: json['aadhaarNumber'] as String?,
      panNumber: json['panNumber'] as String?,
    );
  }
}
