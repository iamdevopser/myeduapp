import '../data/local/app_database.dart';
import '../services/student_portal_service.dart';

/// Öğretmen görünen adı: ders/kolon → ayarlar → varsayılan.
class TeacherDisplayName {
  static const String settingKey = 'teacher_display_name';

  static Future<String> resolve(
    AppDatabase db, {
    String? columnTeacherName,
    String? lessonTeacherName,
    String? explicit,
  }) async {
    for (final candidate in [
      explicit,
      columnTeacherName,
      lessonTeacherName,
    ]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    final global = await db.getSetting(settingKey);
    if (global != null && global.trim().isNotEmpty) {
      return global.trim();
    }
    return StudentPortalService.defaultTeacherLabel;
  }

  static Future<String> forScoreColumn(AppDatabase db, int columnId) async {
    final col = await db.getScoreColumnById(columnId);
    return resolve(
      db,
      columnTeacherName: col?['ogretmen_adi'] as String?,
    );
  }

  static Future<String> forLesson(AppDatabase db, int lessonId) async {
    final row = await db.getLessonRow(lessonId);
    return resolve(
      db,
      lessonTeacherName: row?['ogretmen_adi'] as String?,
    );
  }
}
