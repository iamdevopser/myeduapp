import '../data/local/app_database.dart';
import '../data/models/parent_guardian_model.dart';
import '../utils/course_form_options.dart';

class SecretaryParentService {
  SecretaryParentService(this._db);

  final AppDatabase _db;

  Future<List<ParentGuardian>> listParents({String? search}) async {
    final rows = await _db.listParentGuardians(searchQuery: search);
    return rows.map(ParentGuardian.fromMap).toList();
  }

  Future<ParentGuardian?> getParent(int id) async {
    final row = await _db.getParentGuardianById(id);
    if (row == null) return null;
    return ParentGuardian.fromMap(row);
  }

  Future<int> createParent({
    required String fullName,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) {
    return _db.insertParentGuardian(
      fullName: fullName,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );
  }

  Future<void> updateParent({
    required int id,
    required String fullName,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) {
    return _db.updateParentGuardian(
      id: id,
      fullName: fullName,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );
  }

  /// `false` = bağlı öğrenci var, silinmedi.
  Future<bool> tryDeleteParent(int parentId) {
    return _db.deleteParentGuardian(parentId);
  }

  Future<int> linkToStudent({
    required int studentId,
    required int parentId,
    required ParentRelationType relation,
    bool isPrimary = false,
  }) {
    return _db.linkStudentParent(
      studentId: studentId,
      parentId: parentId,
      relationCode: relation.code,
      isPrimary: isPrimary,
    );
  }

  Future<void> unlink(int linkId) => _db.unlinkStudentParent(linkId);

  Future<List<StudentParentLink>> parentsForStudent(int studentId) async {
    final rows = await _db.listParentsForStudent(studentId);
    return rows.map((r) => _mapStudentParentLink(r, studentId)).toList();
  }

  Future<List<StudentParentLink>> studentsForParent(int parentId) async {
    final rows = await _db.listStudentsForParent(parentId);
    return rows.map((r) => _mapParentStudentLink(r, parentId)).toList();
  }

  StudentParentLink _mapStudentParentLink(
    Map<String, Object?> row,
    int studentId,
  ) {
    return StudentParentLink(
      linkId: row['link_id'] as int,
      studentId: studentId,
      parentId: row['veli_id'] as int,
      relation: ParentRelationTypeCodes.fromCode(row['yakinlik'] as String?),
      isPrimary: (row['birincil'] as int? ?? 0) == 1,
      parentName: row['ad_soyad'] as String? ?? '',
      parentPhone: row['telefon'] as String?,
      parentEmail: row['email'] as String?,
    );
  }

  StudentParentLink _mapParentStudentLink(
    Map<String, Object?> row,
    int parentId,
  ) {
    final grade = CourseFormOptions.resolveGrade(row['sinif_ad'] as String?);
    final section = CourseFormOptions.resolveSection(
      row['sinif_sube'] as String?,
    );
    final classLabel = grade != null
        ? '${CourseFormOptions.gradeLabel(grade)} $section'
        : '${row['sinif_ad']} $section';
    return StudentParentLink(
      linkId: row['link_id'] as int,
      studentId: row['ogrenci_id'] as int,
      parentId: parentId,
      relation: ParentRelationTypeCodes.fromCode(row['yakinlik'] as String?),
      isPrimary: (row['birincil'] as int? ?? 0) == 1,
      parentName: '',
      studentName: row['ad_soyad'] as String?,
      studentNumber: row['numara'] as int?,
      classLabel: classLabel.trim(),
    );
  }
}
