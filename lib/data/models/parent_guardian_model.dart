/// Veli–öğrenci yakınlık türü (`ogrenci_veliler.yakinlik`).
enum ParentRelationType {
  anne,
  baba,
  diger,
}

extension ParentRelationTypeCodes on ParentRelationType {
  String get code {
    return switch (this) {
      ParentRelationType.anne => 'anne',
      ParentRelationType.baba => 'baba',
      ParentRelationType.diger => 'diger',
    };
  }

  static ParentRelationType fromCode(String? value) {
    return switch (value) {
      'anne' => ParentRelationType.anne,
      'baba' => ParentRelationType.baba,
      _ => ParentRelationType.diger,
    };
  }
}

class ParentGuardian {
  const ParentGuardian({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.address,
    this.notes,
    required this.createdAt,
    this.linkedStudentCount = 0,
  });

  final int id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final int linkedStudentCount;

  factory ParentGuardian.fromMap(Map<String, Object?> map) {
    return ParentGuardian(
      id: map['id'] as int,
      fullName: map['ad_soyad'] as String,
      phone: map['telefon'] as String?,
      email: map['email'] as String?,
      address: map['adres'] as String?,
      notes: map['notlar'] as String?,
      createdAt: DateTime.parse(map['olusturma_tarihi'] as String),
      linkedStudentCount: map['linked_count'] as int? ?? 0,
    );
  }
}

class StudentParentLink {
  const StudentParentLink({
    required this.linkId,
    required this.studentId,
    required this.parentId,
    required this.relation,
    required this.isPrimary,
    required this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.studentName,
    this.studentNumber,
    this.classLabel,
  });

  final int linkId;
  final int studentId;
  final int parentId;
  final ParentRelationType relation;
  final bool isPrimary;
  final String parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String? studentName;
  final int? studentNumber;
  final String? classLabel;
}
