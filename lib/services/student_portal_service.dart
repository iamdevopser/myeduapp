import '../data/local/app_database.dart';
import '../data/models/student_category_model.dart';
import '../models/student_enrollment.dart';
import '../utils/mentorship_helpers.dart';
import '../utils/student_announcement_meta.dart';
import '../utils/student_score_display.dart';
import '../utils/teacher_display_name.dart';

/// Öğrenci paneli verileri — yalnızca oturumdaki öğrenci(ler) için.
class StudentPortalService {
  StudentPortalService(this._db);

  final AppDatabase _db;

  static const String defaultTeacherLabel = 'Öğretmen';

  Future<List<StudentEnrollment>> listAllEnrollments() async {
    final classes = await _db.getStudentClasses();
    final result = <StudentEnrollment>[];
    for (final cls in classes) {
      final classId = cls['id'] as int;
      final className = cls['ad'] as String;
      final section = cls['sube'] as String?;
      final students = await _db.getStudents(classId);
      for (final row in students) {
        result.add(
          StudentEnrollment(
            classId: classId,
            studentId: row['id'] as int,
            className: className,
            section: section,
            studentName: row['ad_soyad'] as String,
            number: row['numara'] as int,
            email: row['email'] as String?,
          ),
        );
      }
    }
    return result;
  }

  /// Aynı kişinin birden fazla sınıf kaydı (ad + numara eşleşmesi).
  Future<List<StudentEnrollment>> enrollmentsForIdentity(
    StudentEnrollment primary,
  ) async {
    final all = await listAllEnrollments();
    return all
        .where(
          (e) =>
              e.studentId == primary.studentId ||
              (e.studentName == primary.studentName &&
                  e.number == primary.number),
        )
        .toList();
  }

  Future<StudentEnrollment?> enrollmentBySession({
    required int classId,
    required int studentId,
  }) async {
    final all = await listAllEnrollments();
    for (final e in all) {
      if (e.classId == classId && e.studentId == studentId) return e;
    }
    return null;
  }

  Future<StudentDashboardSummary> loadDashboardSummary(
    List<StudentEnrollment> enrollments,
  ) async {
    var courseCount = 0;
    var pendingHomework = 0;
    var upcomingExams = 0;
    var absenceCount = 0;
    final today = AppDatabase.scoreDateKey(DateTime.now());

    courseCount = (await loadCourses(enrollments)).length;

    for (final enr in enrollments) {
      final scores = await _db.getStudentScores(enr.classId);
      final studentScores = scores
          .where((r) => r['ogrenci_id'] == enr.studentId)
          .toList();

      for (final row in studentScores) {
        final tur = await _columnType(row['kolon_id'] as int);
        if (tur == 'homework') {
          final done = (row['yapildi'] as int?) == 1;
          final score = row['not_deger'] as int?;
          if (!done && score == null) pendingHomework++;
        }
        if (tur == 'exam') {
          final date = row['tarih'] as String? ?? '';
          if (date.compareTo(today) >= 0 && row['not_deger'] == null) {
            upcomingExams++;
          }
        }
        if (studentScoreRowIsAbsent(row)) absenceCount++;
      }
    }

    return StudentDashboardSummary(
      courseCount: courseCount,
      pendingHomework: pendingHomework,
      upcomingExams: upcomingExams,
      absenceCount: absenceCount,
    );
  }

  Future<String?> _columnType(int columnId) async {
    final rows = await _db.database.query(
      'not_kolonlari',
      columns: ['tur'],
      where: 'id = ?',
      whereArgs: [columnId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['tur'] as String?;
  }

  Future<List<StudentPortalHomework>> loadHomework({
    required List<StudentEnrollment> enrollments,
    String? filter,
  }) async {
    final items = <StudentPortalHomework>[];
    for (final enr in enrollments) {
      final columns = await _db.getScoreColumns(enr.classId);
      final homeworkCols = columns
          .where((c) => c['tur'] == 'homework')
          .toList();
      final scores = await _db.getStudentScores(enr.classId);
      for (final col in homeworkCols) {
        final columnId = col['id'] as int;
        final teacherLabel = await TeacherDisplayName.forScoreColumn(
          _db,
          columnId,
        );
        final row = scores.firstWhere(
          (r) => r['ogrenci_id'] == enr.studentId && r['kolon_id'] == columnId,
          orElse: () => {},
        );
        final done = (row['yapildi'] as int?) == 1;
        final score = row['not_deger'] as int?;
        final status = done
            ? StudentAssignmentStatus.completed
            : (score != null
                  ? StudentAssignmentStatus.completed
                  : StudentAssignmentStatus.pending);
        items.add(
          StudentPortalHomework(
            enrollment: enr,
            title: col['ad'] as String,
            teacherLabel: teacherLabel,
            dueDate: row['tarih'] as String?,
            status: status,
          ),
        );
      }
    }
    return _filterHomework(items, filter);
  }

  List<StudentPortalHomework> _filterHomework(
    List<StudentPortalHomework> items,
    String? filter,
  ) {
    if (filter == null || filter == 'all') return items;
    if (filter == 'pending') {
      return items
          .where((i) => i.status == StudentAssignmentStatus.pending)
          .toList();
    }
    if (filter == 'completed') {
      return items
          .where((i) => i.status == StudentAssignmentStatus.completed)
          .toList();
    }
    return items;
  }

  Future<List<StudentPortalExam>> loadExams(
    List<StudentEnrollment> enrollments,
  ) async {
    final today = AppDatabase.scoreDateKey(DateTime.now());
    final items = <StudentPortalExam>[];
    for (final enr in enrollments) {
      final columns = await _db.getScoreColumns(enr.classId);
      final examCols = columns.where((c) => c['tur'] == 'exam').toList();
      final scores = await _db.getStudentScores(enr.classId);
      for (final col in examCols) {
        final columnId = col['id'] as int;
        final teacherLabel = await TeacherDisplayName.forScoreColumn(
          _db,
          columnId,
        );
        final matching = scores.where(
          (r) => r['ogrenci_id'] == enr.studentId && r['kolon_id'] == columnId,
        );
        for (final row in matching) {
          final date = row['tarih'] as String? ?? today;
          final score = row['not_deger'] as int?;
          final absent = studentScoreRowIsAbsent(row);
          items.add(
            StudentPortalExam(
              enrollment: enr,
              title: col['ad'] as String,
              teacherLabel: teacherLabel,
              date: date,
              score: score,
              absent: absent,
              isUpcoming:
                  date.compareTo(today) >= 0 && score == null && !absent,
            ),
          );
        }
        if (matching.isEmpty) {
          items.add(
            StudentPortalExam(
              enrollment: enr,
              title: col['ad'] as String,
              teacherLabel: teacherLabel,
              date: today,
              isUpcoming: true,
            ),
          );
        }
      }
    }
    return items;
  }

  Future<List<Map<String, Object?>>> loadPerformanceRows(
    StudentEnrollment enr,
  ) async {
    return _db.getStudentReportRows(
      classId: enr.classId,
      studentId: enr.studentId,
    );
  }

  Future<List<StudentPortalAttendance>> loadAttendance(
    List<StudentEnrollment> enrollments,
  ) async {
    final items = <StudentPortalAttendance>[];
    for (final enr in enrollments) {
      final rows = await _db.getStudentReportRows(
        classId: enr.classId,
        studentId: enr.studentId,
      );
      for (final row in rows) {
        if (!studentScoreRowIsAbsent(row)) continue;
        final tur = row['tur'] as String? ?? '';
        items.add(
          StudentPortalAttendance(
            enrollment: enr,
            date: row['tarih'] as String? ?? '',
            courseLabel: _categoryLabel(tur),
            teacherLabel: await TeacherDisplayName.forScoreColumn(
              _db,
              row['kolon_id'] as int,
            ),
          ),
        );
      }
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  String _categoryLabel(String code) {
    switch (code) {
      case 'homework':
        return 'Ödev';
      case 'exam':
        return 'Sınav';
      case 'performance':
        return 'Performans';
      default:
        return code;
    }
  }

  Future<List<StudentPortalCourse>> loadCourses(
    List<StudentEnrollment> enrollments,
  ) async {
    if (enrollments.isEmpty) return [];
    final classIds = enrollments.map((e) => e.classId).toSet();
    final linkedLessonIds = await _db.lessonIdsLinkedToStudentClasses(classIds);
    final rows = await _db.listLessonsForAcademicPlanning();
    final result = <StudentPortalCourse>[];
    final seen = <int>{};
    for (final r in rows) {
      final lessonId = r['id'] as int;
      if (seen.contains(lessonId)) continue;
      final sinifAd = (r['sinif_ad'] as String? ?? '').trim();
      final matches =
          linkedLessonIds.contains(lessonId) ||
          enrollments.any((e) => _lessonMatchesStudentClass(sinifAd, e));
      if (!matches) continue;
      seen.add(lessonId);
      result.add(
        StudentPortalCourse(
          lessonId: lessonId,
          name: r['ad'] as String,
          className: sinifAd,
          teacherLabel: await TeacherDisplayName.forLesson(_db, lessonId),
        ),
      );
    }
    return result;
  }

  bool _lessonMatchesStudentClass(
    String platformClassName,
    StudentEnrollment e,
  ) {
    final grade = e.className.trim();
    if (grade.isEmpty) return false;
    final platform = platformClassName.toUpperCase();
    return platform.startsWith(grade) || platform.contains('$grade.');
  }

  Future<List<StudentPortalDocument>> loadDocuments(
    List<StudentEnrollment> enrollments,
  ) async {
    final courses = await loadCourses(enrollments);
    final lessonIds = courses.map((c) => c.lessonId).toSet();
    if (lessonIds.isEmpty) return [];
    final placeholders = List.filled(lessonIds.length, '?').join(',');
    final rows = await _db.database.rawQuery('''
      SELECT i.id, i.ad, i.tur, i.olusturma_tarihi, d.id as ders_id,
             d.ad as ders_ad, c.ad as sinif_ad
      FROM icerikler i
      JOIN dersler d ON d.id = i.ders_id
      JOIN siniflar c ON c.id = d.sinif_id
      WHERE i.arsiv = 0 AND i.ders_id IN ($placeholders)
      ORDER BY i.olusturma_tarihi DESC
      LIMIT 100
      ''', lessonIds.toList());
    final out = <StudentPortalDocument>[];
    for (final r in rows) {
      final lessonId = r['ders_id'] as int;
      out.add(
        StudentPortalDocument(
          contentId: r['id'] as int,
          lessonId: lessonId,
          name: r['ad'] as String,
          type: r['tur'] as String,
          courseName: r['ders_ad'] as String,
          className: r['sinif_ad'] as String? ?? '',
          teacherLabel: await TeacherDisplayName.forLesson(_db, lessonId),
          date: r['olusturma_tarihi'] as String? ?? '',
        ),
      );
    }
    return out;
  }

  Future<List<StudentPortalAnnouncement>> loadAnnouncements(
    List<StudentEnrollment> enrollments,
  ) async {
    final classIds = enrollments.map((e) => e.classId).toSet();
    final rows = await _db.listStudentAnnouncementsForClasses(classIds);
    final items = <StudentPortalAnnouncement>[];
    for (final r in rows) {
      final lessonId = r['ders_id'] as int?;
      final explicit = r['ogretmen_adi'] as String?;
      final teacherLabel = lessonId != null
          ? await TeacherDisplayName.resolve(
              _db,
              explicit: explicit,
              lessonTeacherName:
                  (await _db.getLessonRow(lessonId))?['ogretmen_adi']
                      as String?,
            )
          : await TeacherDisplayName.resolve(_db, explicit: explicit);
      items.add(_announcementFromRow(r, teacherLabel: teacherLabel));
    }
    return items;
  }

  Future<List<StudentPortalMentorshipEvent>> loadMentorshipEvents(
    List<StudentEnrollment> enrollments,
  ) async {
    final items = <StudentPortalMentorshipEvent>[];
    final seen = <int>{};
    for (final enr in enrollments) {
      final rows = await _db.getMentorshipEvents(
        classId: enr.classId,
        studentId: enr.studentId,
      );
      for (final row in rows) {
        final id = row['id'] as int;
        if (seen.contains(id)) continue;
        seen.add(id);
        items.add(
          StudentPortalMentorshipEvent(
            id: id,
            title: row['baslik'] as String,
            date: row['tarih'] as String,
            time: row['saat'] as String,
            type: row['tur'] as String? ?? MentorshipEventType.group,
            description: row['aciklama'] as String? ?? '',
          ),
        );
      }
    }
    items.sort((a, b) => '${a.date}${a.time}'.compareTo('${b.date}${b.time}'));
    return items;
  }

  Future<StudentPortalAnnouncement?> loadAnnouncementById(
    int id, {
    required List<StudentEnrollment> enrollments,
  }) async {
    final items = await loadAnnouncements(enrollments);
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  StudentPortalAnnouncement _announcementFromRow(
    Map<String, Object?> r, {
    required String teacherLabel,
  }) {
    final tur = StudentAnnouncementTargetTypeDb.fromDb(
      r['hedef_tur'] as String?,
    );
    return StudentPortalAnnouncement(
      id: r['id'] as int,
      title: r['baslik'] as String,
      body: r['icerik'] as String,
      teacherLabel: teacherLabel,
      courseName: (r['ders_adi'] as String?)?.trim() ?? '',
      date:
          (r['yayin_tarihi'] as String?)?.split('T').first ??
          (r['olusturma_tarihi'] as String?)?.split('T').first ??
          '',
      targetType: tur,
      classId: r['sinif_id'] as int?,
      coverImagePath: r['kapak_gorsel_yolu'] as String?,
    );
  }

  Future<List<StudentPortalTodayLesson>> loadTodayLessons(
    List<StudentEnrollment> enrollments,
  ) async {
    final now = DateTime.now();
    final weekday = now.weekday;
    if (weekday > 5) return [];
    final day = weekday;
    final entries = await _db.getWeeklyScheduleEntries();
    final slots = await _db.getWeeklySchedulePeriodSlots();
    final classIds = enrollments.map((e) => e.classId).toSet();
    final labels = enrollments.map((e) => e.scheduleClassLabel).toSet();
    final result = <StudentPortalTodayLesson>[];
    for (final row in entries) {
      if ((row['gun'] as int?) != day) continue;
      final studentClassId = row['ogrenci_sinif_id'] as int?;
      final classLabel = (row['sinif_metin'] as String? ?? '').trim();
      final matchesById =
          studentClassId != null && classIds.contains(studentClassId);
      final matchesByLabel =
          classLabel.isNotEmpty &&
          labels.any((l) => classLabel.toUpperCase() == l.toUpperCase());
      if (!matchesById && !matchesByLabel) continue;
      final period = row['saat_sira'] as int? ?? 1;
      final start = row['baslangic'] as String? ?? '';
      final end = row['bitis'] as String? ?? '';
      final lessonId = row['ders_id'] as int?;
      final subject = (row['ders_ad'] as String?)?.trim();
      final teacherLabel = lessonId != null
          ? await TeacherDisplayName.forLesson(_db, lessonId)
          : await TeacherDisplayName.resolve(_db);
      result.add(
        StudentPortalTodayLesson(
          timeRange: '$start – $end',
          courseName: subject != null && subject.isNotEmpty
              ? subject
              : classLabel,
          teacherLabel: teacherLabel,
          groupLabel: classLabel,
          period: period,
        ),
      );
    }
    result.sort((a, b) => a.period.compareTo(b.period));
    return result;
  }

  Future<List<Map<String, Object?>>> loadPublishedBehaviors(
    StudentEnrollment enr,
  ) async {
    final hasColumn = await _db.database.rawQuery(
      "SELECT name FROM pragma_table_info('ogrenci_davranis_kayitlari') "
      "WHERE name = 'ogrenciye_goster'",
    );
    final filterPublished = hasColumn.isNotEmpty;
    final rows = await _db.getStudentBehaviorReportRows(
      classId: enr.classId,
      studentId: enr.studentId,
    );
    if (!filterPublished) return [];
    return rows
        .where((r) => (r['ogrenciye_goster'] as int? ?? 0) == 1)
        .toList();
  }
}

class StudentDashboardSummary {
  const StudentDashboardSummary({
    required this.courseCount,
    required this.pendingHomework,
    required this.upcomingExams,
    required this.absenceCount,
  });

  final int courseCount;
  final int pendingHomework;
  final int upcomingExams;
  final int absenceCount;
}

enum StudentAssignmentStatus { pending, completed, overdue }

class StudentPortalHomework {
  const StudentPortalHomework({
    required this.enrollment,
    required this.title,
    required this.teacherLabel,
    required this.status,
    this.dueDate,
  });

  final StudentEnrollment enrollment;
  final String title;
  final String teacherLabel;
  final String? dueDate;
  final StudentAssignmentStatus status;
}

class StudentPortalExam {
  const StudentPortalExam({
    required this.enrollment,
    required this.title,
    required this.teacherLabel,
    required this.date,
    this.score,
    this.absent = false,
    this.isUpcoming = false,
  });

  final StudentEnrollment enrollment;
  final String title;
  final String teacherLabel;
  final String date;
  final int? score;
  final bool absent;
  final bool isUpcoming;
}

class StudentPortalAttendance {
  const StudentPortalAttendance({
    required this.enrollment,
    required this.date,
    required this.courseLabel,
    required this.teacherLabel,
  });

  final StudentEnrollment enrollment;
  final String date;
  final String courseLabel;
  final String teacherLabel;
}

class StudentPortalCourse {
  const StudentPortalCourse({
    required this.lessonId,
    required this.name,
    required this.className,
    required this.teacherLabel,
  });

  final int lessonId;
  final String name;
  final String className;
  final String teacherLabel;
}

class StudentPortalDocument {
  const StudentPortalDocument({
    required this.contentId,
    required this.lessonId,
    required this.name,
    required this.type,
    required this.courseName,
    required this.className,
    required this.teacherLabel,
    required this.date,
  });

  final int contentId;
  final int lessonId;
  final String name;
  final String type;
  final String courseName;
  final String className;
  final String teacherLabel;
  final String date;
}

class StudentPortalAnnouncement {
  const StudentPortalAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.teacherLabel,
    required this.courseName,
    required this.date,
    required this.targetType,
    this.classId,
    this.coverImagePath,
  });

  final int id;
  final String title;
  final String body;
  final String teacherLabel;
  final String courseName;
  final String date;
  final StudentAnnouncementTargetType targetType;
  final int? classId;
  final String? coverImagePath;
}

class StudentPortalMentorshipEvent {
  const StudentPortalMentorshipEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.type,
    required this.description,
  });

  final int id;
  final String title;
  final String date;
  final String time;
  final String type;
  final String description;

  bool get isParentMeeting => type == MentorshipEventType.parentMeeting;
}

class StudentPortalTodayLesson {
  const StudentPortalTodayLesson({
    required this.timeRange,
    required this.courseName,
    required this.teacherLabel,
    required this.groupLabel,
    required this.period,
  });

  final String timeRange;
  final String courseName;
  final String teacherLabel;
  final String groupLabel;
  final int period;
}
