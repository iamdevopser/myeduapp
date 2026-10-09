import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/local/app_database.dart';
import '../data/models/student_category_model.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../utils/course_form_options.dart';
import '../utils/app_navigation.dart';
import '../utils/path_utils.dart';
import '../utils/student_daily_performance.dart';
import '../utils/desktop_file_reveal.dart';
import '../utils/report_export_support.dart';
import '../utils/student_monthly_performance.dart';
import '../utils/student_report_score_display.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_shell.dart';
import '../services/pdf_service.dart';
import '../services/report_email_service.dart';
import '../services/report_excel_service.dart';
import '../services/student_report_pdf_labels.dart';
import '../utils/student_email_recipients.dart';

class StudentReportScreen extends StatefulWidget {
  const StudentReportScreen({super.key, this.initialClassId});

  final int? initialClassId;

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  bool _individual = true;
  int? _classId;
  int? _studentId;
  String? _categoryCode;
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  List<Map<String, Object?>> _classes = [];
  List<Map<String, Object?>> _students = [];
  List<StudentCategory> _categories = [];
  List<Map<String, Object?>> _rows = [];
  List<Map<String, Object?>> _allRows = [];
  List<StudentMonthlyPerformance> _monthlyRows = [];
  bool _loading = false;
  bool _exportPdfInProgress = false;
  bool _exportExcelInProgress = false;
  bool _exportBulkPdfInProgress = false;
  bool _sendReportEmailInProgress = false;

  bool get _canExportReport =>
      !_loading &&
      _classId != null &&
      (!_individual || _studentId != null);

  bool get _canExportBulkPdf =>
      !_loading && _classId != null && _students.isNotEmpty;

  bool get _canSendReportEmail => _canExportBulkPdf;

  @override
  void initState() {
    super.initState();
    _classId = widget.initialClassId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFilters());
  }

  Future<void> _loadFilters() async {
    final db = context.read<AppState>().db;
    final classes = await db.getStudentClasses();
    _classId ??= classes.isNotEmpty ? classes.first['id'] as int : null;
    await _loadClassDependents(db);
    if (mounted) setState(() => _classes = classes);
    await _refreshRows();
  }

  Future<void> _loadClassDependents(AppDatabase db) async {
    if (_classId == null) {
      _students = [];
      _categories = [];
      return;
    }
    _students = await db.getStudents(_classId!);
    _categories = await db.getStudentCategories(_classId!);
    if (_studentId != null &&
        _students.every((row) => row['id'] != _studentId)) {
      _studentId = null;
    }
  }

  List<Map<String, Object?>> _filterRowsByCategory(
    List<Map<String, Object?>> rows,
  ) {
    if (_categoryCode == null) {
      return rows;
    }
    if (StudentCategory.isPerformanceCode(_categoryCode!)) {
      return rows
          .where(
            (row) => StudentCategory.performanceScoreTypes.contains(row['tur']),
          )
          .toList();
    }
    if (_categoryCode == StudentCategory.behaviorsCode) {
      return rows
          .where((row) => row['tur'] == StudentCategory.behaviorsCode)
          .toList();
    }
    return rows.where((row) => row['tur'] == _categoryCode).toList();
  }

  Future<void> _refreshRows() async {
    if (_classId == null || (_individual && _studentId == null)) {
      setState(() {
        _rows = [];
        _allRows = [];
        _monthlyRows = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final db = context.read<AppState>().db;
    final scoreRows = await db.getStudentReportRows(
      classId: _classId,
      studentId: _individual ? _studentId : null,
      fromDate: AppDatabase.scoreDateKey(_from),
      toDate: AppDatabase.scoreDateKey(_to),
    );
    final behaviorRows = await db.getStudentBehaviorReportRows(
      classId: _classId!,
      studentId: _individual ? _studentId : null,
      fromDate: AppDatabase.scoreDateKey(_from),
      toDate: AppDatabase.scoreDateKey(_to),
    );
    final mappedBehaviors = behaviorRows
        .map(
          (row) => <String, Object?>{
            'ogrenci_id': row['ogrenci_id'],
            'ad_soyad': row['ad_soyad'],
            'numara': row['numara'],
            'sinif_id': _classId,
            'tarih': row['tarih'],
            'tur': StudentCategory.behaviorsCode,
            'kolon_ad': row['davranis_ad'],
            'davranis_ad': row['davranis_ad'],
            'not_deger': null,
            'yapildi': null,
            'devamsiz': 0,
          },
        )
        .toList();
    final allRows = _categoryCode == StudentCategory.behaviorsCode
        ? mappedBehaviors
        : [...scoreRows, ...mappedBehaviors];
    if (!mounted) return;
    final strings = AppLocalizations.of(context);
    final locale = strings.locale.languageCode;
    final displayRows = _filterRowsByCategory(allRows);
    final categoryNames = {
      for (final category in _categories)
        category.code: _categoryLabel(category.code, strings),
    };
    setState(() {
      _allRows = allRows;
      _rows = displayRows;
      _monthlyRows = StudentMonthlyPerformance.fromReportRows(
        allRows,
        categoryNames: categoryNames,
        locale: locale,
      );
      _loading = false;
    });
  }

  Future<void> _pickDate({required bool from}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
    await _refreshRows();
  }

  List<List<String>> _detailTable(
    AppLocalizations strings,
    List<Map<String, Object?>> rows,
  ) {
    return [
      [
        strings.t('studentName'),
        strings.t('selectedDate'),
        strings.t('category'),
        strings.t('note'),
        strings.t('value'),
      ],
      ...rows.map((row) {
        final date = '${row['tarih'] ?? ''}';
        return [
          '${row['numara']} ${row['ad_soyad']}',
          StudentDailyPerformance.formatDisplayDate(date),
          _scoreTypeLabel(row, strings),
          _scoreDescription(row),
          _valueOf(row),
        ];
      }),
    ];
  }

  String _scoreDescription(Map<String, Object?> row) =>
      studentReportScoreDescription(row);

  String _scoreTypeLabel(Map<String, Object?> row, AppLocalizations strings) {
    final tur = row['tur'] as String? ?? '';
    return studentReportScoreTypeLabel(
      categoryCode: tur,
      categoryLabel: _categoryLabel(tur, strings),
      columnName: row['kolon_ad'] as String?,
    );
  }

  List<List<String>> _monthlyCategoryTable(
    AppLocalizations strings,
    List<StudentMonthlyPerformance> monthlyRows,
  ) {
    return [
      [
        strings.t('studentName'),
        strings.t('monthlyHistory'),
        strings.t('category'),
        strings.t('categoryAverage'),
        strings.t('monthlyAverage'),
      ],
      ...monthlyRows.map(
        (row) => [
          row.studentName,
          row.monthLabel,
          row.categoryName,
          row.categoryAverage.toStringAsFixed(2),
          row.monthlyOverallAverage.toStringAsFixed(2),
        ],
      ),
    ];
  }

  List<List<String>> _dailyAverageTable(AppLocalizations strings) {
    if (_individual && _studentId != null) {
      final daily = StudentDailyPerformance.sortedDailyListForStudent(
        _allRows,
        studentId: _studentId!,
      );
      if (daily.isEmpty) {
        return [];
      }
      final period = StudentDailyPerformance.periodAverageFromDailyAverages(
        {for (final item in daily) item.date: item.dailyAverage},
      );
      return [
        [
          strings.t('selectedDate'),
          strings.t('dailyAverage'),
        ],
        ...daily.map(
          (item) => [
            StudentDailyPerformance.formatDisplayDate(item.date),
            StudentDailyPerformance.formatAverage(item.dailyAverage),
          ],
        ),
        [
          strings.t('periodAverage'),
          StudentDailyPerformance.formatAverage(period),
        ],
      ];
    }

    final byStudent =
        StudentDailyPerformance.dailyAveragesByStudent(_allRows);
    if (byStudent.isEmpty) {
      return [];
    }
    final rows = <List<String>>[];
    for (final student in _students) {
      final studentId = student['id'] as int;
      final daily = byStudent[studentId];
      if (daily == null || daily.isEmpty) {
        continue;
      }
      final studentName =
          '${student['numara']} ${student['ad_soyad']}'.trim();
      final dates = daily.keys.toList()..sort();
      for (final date in dates) {
        rows.add([
          studentName,
          StudentDailyPerformance.formatDisplayDate(date),
          StudentDailyPerformance.formatAverage(daily[date]),
        ]);
      }
      rows.add([
        studentName,
        strings.t('periodAverage'),
        StudentDailyPerformance.formatAverage(
          StudentDailyPerformance.periodAverageFromDailyAverages(daily),
        ),
      ]);
    }
    if (rows.isEmpty) {
      return [];
    }
    return [
      [
        strings.t('studentName'),
        strings.t('selectedDate'),
        strings.t('dailyAverage'),
      ],
      ...rows,
    ];
  }

  List<List<String>> _monthlyOverallTable(
    AppLocalizations strings,
    List<StudentMonthlyPerformance> monthlyRows,
  ) {
    final uniqueRows =
        StudentMonthlyPerformance.uniqueMonthlyOverallRows(monthlyRows);
    return [
      [
        strings.t('studentName'),
        strings.t('monthlyHistory'),
        strings.t('monthlyAverage'),
      ],
      ...uniqueRows.map(
        (row) => [row['student']!, row['month']!, row['overall']!],
      ),
    ];
  }

  List<StudentMonthlyPerformance> _monthlyRowsFromAllRows(
    List<Map<String, Object?>> allRows,
    AppLocalizations strings,
  ) {
    final categoryNames = {
      for (final category in _categories)
        category.code: _categoryLabel(category.code, strings),
    };
    return StudentMonthlyPerformance.fromReportRows(
      allRows,
      categoryNames: categoryNames,
      locale: strings.locale.languageCode,
    );
  }

  List<List<String>> _dailyAverageTableForStudent(
    AppLocalizations strings,
    List<Map<String, Object?>> allRows,
    int studentId,
  ) {
    final daily = StudentDailyPerformance.sortedDailyListForStudent(
      allRows,
      studentId: studentId,
    );
    if (daily.isEmpty) {
      return [];
    }
    final period = StudentDailyPerformance.periodAverageFromDailyAverages(
      {for (final item in daily) item.date: item.dailyAverage},
    );
    return [
      [
        strings.t('selectedDate'),
        strings.t('dailyAverage'),
      ],
      ...daily.map(
        (item) => [
          StudentDailyPerformance.formatDisplayDate(item.date),
          StudentDailyPerformance.formatAverage(item.dailyAverage),
        ],
      ),
      [
        strings.t('periodAverage'),
        StudentDailyPerformance.formatAverage(period),
      ],
    ];
  }

  ({
    List<List<String>> detail,
    List<List<String>> summary,
    List<List<String>> dailyAverage,
    List<List<String>> monthlyCategory,
    List<List<String>> monthlyOverall,
  }) _pdfTablesForStudent({
    required int studentId,
    required List<Map<String, Object?>> allRows,
    required AppLocalizations strings,
  }) {
    final studentRows =
        allRows.where((row) => row['ogrenci_id'] == studentId).toList();
    final displayRows = _filterRowsByCategory(studentRows);
    final monthlyRows = _monthlyRowsFromAllRows(studentRows, strings);
    return (
      detail: _detailTable(strings, displayRows),
      summary: _summaryTable(strings, displayRows),
      dailyAverage: _dailyAverageTableForStudent(strings, allRows, studentId),
      monthlyCategory: _monthlyCategoryTable(strings, monthlyRows),
      monthlyOverall: _monthlyOverallTable(strings, monthlyRows),
    );
  }

  StudentReportPdfLabels _studentReportPdfLabels(AppLocalizations strings) {
    return StudentReportPdfLabels(
      catalogNotice: strings.t('reportPdfCatalogNotice'),
      summarySection: strings.t('reportPdfSummary'),
      dailyAverageSection: strings.t('dailyAverage'),
      monthlyPerformanceSection: strings.t('monthlyHistory'),
      monthlyCategorySection: strings.t('reportPdfMonthlyCategoryAverages'),
    );
  }

  Future<Uint8List> _buildReportPdfBytes({
    required AppLocalizations strings,
    required List<List<String>> detail,
    required List<List<String>> summary,
    required List<List<String>> dailyAverage,
    required List<List<String>> monthlyCategory,
    required List<List<String>> monthlyOverall,
  }) {
    return PdfService().buildStudentReportPdfBytes(
      title: strings.t('individualReport'),
      subtitle:
          '${AppDatabase.scoreDateKey(_from)} - ${AppDatabase.scoreDateKey(_to)}',
      labels: _studentReportPdfLabels(strings),
      headers: detail.first,
      rows: detail.skip(1).toList(),
      summaryHeaders: summary.first,
      summaryRows: summary.skip(1).toList(),
      dailyAverageHeaders: dailyAverage.isEmpty ? null : dailyAverage.first,
      dailyAverageRows:
          dailyAverage.length <= 1 ? null : dailyAverage.skip(1).toList(),
      monthlyCategoryHeaders:
          monthlyCategory.isEmpty ? null : monthlyCategory.first,
      monthlyCategoryRows: monthlyCategory.length <= 1
          ? null
          : monthlyCategory.skip(1).toList(),
      monthlyOverallHeaders:
          monthlyOverall.isEmpty ? null : monthlyOverall.first,
      monthlyOverallRows: monthlyOverall.length <= 1
          ? null
          : monthlyOverall.skip(1).toList(),
    );
  }

  Future<PdfBytesWriteResult> _writeStudentReportPdf({
    required String targetPath,
    required AppLocalizations strings,
    required List<List<String>> detail,
    required List<List<String>> summary,
    required List<List<String>> dailyAverage,
    required List<List<String>> monthlyCategory,
    required List<List<String>> monthlyOverall,
  }) async {
    final bytes = await _buildReportPdfBytes(
      strings: strings,
      detail: detail,
      summary: summary,
      dailyAverage: dailyAverage,
      monthlyCategory: monthlyCategory,
      monthlyOverall: monthlyOverall,
    );
    return PdfService.writePdfBytesResilient(targetPath, bytes);
  }

  List<List<String>> _summaryTable(
    AppLocalizations strings,
    List<Map<String, Object?>> rows,
  ) {
    final grouped = <String, List<int>>{};
    for (final row in rows) {
      final key =
          '${row['ad_soyad']}|${_scoreTypeLabel(row, strings)}|${_scoreDescription(row)}';
      final score = row['not_deger'] as int?;
      if (score != null) {
        grouped.putIfAbsent(key, () => []).add(score);
      }
    }
    return [
      [
        strings.t('studentName'),
        strings.t('category'),
        strings.t('average'),
        strings.t('total'),
      ],
      ...grouped.entries.map((entry) {
        final parts = entry.key.split('|');
        final scores = entry.value;
        final sum = scores.fold<int>(0, (a, b) => a + b);
        final avg = scores.isEmpty ? 0 : sum / scores.length;
        return [
          parts.first,
          parts.length > 1 ? parts[1] : '',
          avg.toStringAsFixed(1),
          '$sum',
        ];
      }),
    ];
  }

  String? _systemCategoryLabel(AppLocalizations strings, String code) {
    switch (code) {
      case 'materials':
        return strings.t('materials');
      case 'activity':
        return strings.t('activities');
      case 'homework':
        return strings.t('homeworks');
      case 'exam':
        return strings.t('exams');
      case 'performance':
        return strings.t('performance');
      case 'behaviors':
        return strings.t('behaviorsCategory');
      default:
        return null;
    }
  }

  String _categoryLabel(String code, AppLocalizations strings) {
    final system = _systemCategoryLabel(strings, code);
    if (system != null) {
      return system;
    }
    for (final category in _categories) {
      if (category.code == code) return category.name;
    }
    return code;
  }

  String _valueOf(Map<String, Object?> row) {
    if (row['davranis_ad'] != null) {
      return row['davranis_ad'] as String;
    }
    if ((row['devamsiz'] as int? ?? 0) == 1) {
      return 'a';
    }
    final score = row['not_deger'];
    final done = row['yapildi'] == 1;
    if (score != null) return '$score';
    return done ? '✓' : '';
  }

  List<StudentCategory> _scorableCategories() {
    return _categories
        .where(
          (category) =>
              category.active &&
              category.code != 'students' &&
              category.code != StudentCategory.behaviorsCode,
        )
        .toList();
  }

  List<StudentCategory> _visibleReportCategories() {
    final categories = _scorableCategories();
    if (_categoryCode == null) {
      return categories;
    }
    return categories.where((category) => category.code == _categoryCode).toList();
  }

  Map<String, Object?>? _selectedClassRow() {
    if (_classId == null) return null;
    for (final row in _classes) {
      if (row['id'] == _classId) return row;
    }
    return null;
  }

  Map<String, Object?>? _selectedStudentRow() {
    if (_studentId == null) return null;
    for (final row in _students) {
      if (row['id'] == _studentId) return row;
    }
    return null;
  }

  String _classSectionLabel(Map<String, Object?> classRow) {
    final grade =
        CourseFormOptions.parseGradeFromName(classRow['ad'] as String? ?? '');
    final section = (classRow['sube'] as String?)?.trim();
    final gradeLabel =
        grade != null ? CourseFormOptions.gradeLabel(grade) : '${classRow['ad']}';
    if (section != null && section.isNotEmpty) {
      return '$gradeLabel / $section Şubesi';
    }
    return gradeLabel;
  }

  String _reportCategoryCode(String typeCode) {
    if (StudentCategory.performanceScoreTypes.contains(typeCode)) {
      return StudentCategory.performanceCode;
    }
    return typeCode;
  }

  Map<String, double> _categoryAverages({int? studentId}) {
    final grouped = <String, List<int>>{};
    for (final row in _allRows) {
      if (studentId != null && row['ogrenci_id'] != studentId) {
        continue;
      }
      final code = row['tur'] as String? ?? '';
      if (code == 'students') continue;
      final score = row['not_deger'] as int?;
      if (!StudentDailyPerformance.isNumericScore(score)) continue;
      grouped.putIfAbsent(_reportCategoryCode(code), () => []).add(score!);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: entry.value.reduce((a, b) => a + b) / entry.value.length,
    };
  }

  double? _overallAverage(Map<String, double> categoryAverages) {
    if (categoryAverages.isEmpty) return null;
    final values = categoryAverages.values.toList();
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _formatPivotDate(String date) {
    if (date.length >= 10) {
      return '${date.substring(5, 7)}-${date.substring(8, 10)}';
    }
    return date;
  }

  List<StudentDailyPerformance> _individualDailyAverages(
    List<Map<String, Object?>> sourceRows,
  ) {
    if (_studentId == null) {
      return [];
    }
    return StudentDailyPerformance.sortedDailyListForStudent(
      sourceRows,
      studentId: _studentId!,
    );
  }

  double? _individualPeriodAverage(List<Map<String, Object?>> sourceRows) {
    if (_studentId == null) {
      return null;
    }
    final daily = StudentDailyPerformance.dailyAveragesForStudent(
      sourceRows,
      studentId: _studentId!,
    );
    return StudentDailyPerformance.periodAverageFromDailyAverages(daily);
  }

  List<_ReportPivotRow> _individualPivotRows(List<Map<String, Object?>> sourceRows) {
    final studentId = _studentId;
    if (studentId == null) {
      return [];
    }
    final categories = _visibleReportCategories();
    final byDate = <String, Map<String, List<int>>>{};
    for (final row in sourceRows) {
      if (row['ogrenci_id'] != studentId) continue;
      final date = row['tarih'] as String? ?? '';
      final code = row['tur'] as String? ?? '';
      if (date.isEmpty || code == 'students') continue;
      final score = row['not_deger'] as int?;
      if (!StudentDailyPerformance.isNumericScore(score)) continue;
      byDate.putIfAbsent(date, () => {});
      byDate[date]!.putIfAbsent(code, () => []).add(score!);
    }
    final dailyOverallByDate = StudentDailyPerformance.dailyAveragesForStudent(
      sourceRows,
      studentId: studentId,
    );
    final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
    return dates.map((date) {
      final values = <String, double?>{};
      for (final category in categories) {
        final code = category.code;
        if (StudentCategory.isPerformanceCode(code)) {
          final performanceScores = <int>[];
          for (final performanceType in StudentCategory.performanceScoreTypes) {
            performanceScores.addAll(byDate[date]?[performanceType] ?? []);
          }
          values[code] = StudentDailyPerformance.averageOfScores(
            performanceScores,
          );
        } else {
          final scores = byDate[date]?[code];
          values[code] = scores == null || scores.isEmpty
              ? null
              : StudentDailyPerformance.averageOfScores(scores);
        }
      }
      return _ReportPivotRow(
        label: _formatPivotDate(date),
        values: values,
        overall: dailyOverallByDate[date],
      );
    }).toList();
  }

  List<_ReportPivotRow> _classPivotRows(List<Map<String, Object?>> sourceRows) {
    final categories = _visibleReportCategories();
    final byStudent = <int, Map<String, List<int>>>{};
    final studentNames = <int, String>{};
    final studentOrder = <int, int>{};
    for (final row in sourceRows) {
      final studentId = row['ogrenci_id'] as int?;
      final code = row['tur'] as String? ?? '';
      if (studentId == null || code == 'students') continue;
      final score = row['not_deger'] as int?;
      if (!StudentDailyPerformance.isNumericScore(score)) continue;
      studentNames[studentId] =
          '${row['numara'] ?? ''} ${row['ad_soyad'] ?? ''}'.trim();
      studentOrder[studentId] = row['numara'] as int? ?? 0;
      byStudent.putIfAbsent(studentId, () => {});
      byStudent[studentId]!.putIfAbsent(code, () => []).add(score!);
    }
    final dailyByStudent =
        StudentDailyPerformance.dailyAveragesByStudent(sourceRows);
    final studentIds = byStudent.keys.toList()
      ..sort((a, b) => studentOrder[a]!.compareTo(studentOrder[b]!));
    return studentIds.map((studentId) {
      final values = <String, double?>{};
      for (final category in categories) {
        final code = category.code;
        if (StudentCategory.isPerformanceCode(code)) {
          final performanceScores = <int>[];
          for (final performanceType in StudentCategory.performanceScoreTypes) {
            performanceScores.addAll(
              byStudent[studentId]?[performanceType] ?? [],
            );
          }
          values[code] =
              StudentDailyPerformance.averageOfScores(performanceScores);
        } else {
          final scores = byStudent[studentId]?[code];
          values[code] = scores == null || scores.isEmpty
              ? null
              : StudentDailyPerformance.averageOfScores(scores);
        }
      }
      return _ReportPivotRow(
        label: studentNames[studentId] ?? '',
        values: values,
        overall: StudentDailyPerformance.periodAverageFromDailyAverages(
          dailyByStudent[studentId] ?? {},
        ),
      );
    }).toList();
  }

  String _classReportFileStem() {
    final classRow = _selectedClassRow();
    if (classRow == null) return 'sinif';
    return sanitizePathSegment(
      CourseFormOptions.studentClassGradeSectionLabel(
        classRow['ad'] as String? ?? '',
        section: classRow['sube'] as String?,
      ).replaceAll(' ', '_'),
    );
  }

  String _reportFileNameForStudent(
    Map<String, Object?> student,
    String extension,
  ) {
    final classPart = _classReportFileStem();
    final name =
        sanitizeReportFileStem(student['ad_soyad'] as String? ?? 'ogrenci');
    final numara = '${student['numara'] ?? ''}';
    final uniqueSuffix = numara.isNotEmpty ? '${numara}_' : '';
    return '${name}_$uniqueSuffix$classPart.$extension';
  }

  String _suggestedReportFileName(String extension) {
    final classPart = _classReportFileStem();

    if (_individual) {
      final student = _selectedStudentRow();
      if (student != null) {
        return _reportFileNameForStudent(student, extension);
      }
      return '${sanitizeReportFileStem('ogrenci')}_$classPart.$extension';
    }

    return '${classPart}_sinif_raporu.$extension';
  }

  Future<void> _exportPdf() async {
    if (_exportPdfInProgress) return;

    final strings = AppLocalizations.of(context);
    String? targetPath;
    try {
      final pickPdf = await pickReportExportSavePath(
        dialogTitle: strings.t('exportPdf'),
        suggestedFileName: _suggestedReportFileName('pdf'),
        extension: 'pdf',
        folderPickDialogTitle: strings.t('exportPickFolder'),
      );
      switch (pickPdf.outcome) {
        case ReportSavePickOutcome.cancelled:
          return;
        case ReportSavePickOutcome.failed:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.t('exportSaveDialogFailed'))),
          );
          return;
        case ReportSavePickOutcome.success:
          targetPath = pickPdf.path;
      }
      if (targetPath == null) return;

      targetPath = normalizeReportSavePath(targetPath, 'pdf');
      await ensureReportExportParentDirectory(targetPath);

      setState(() => _exportPdfInProgress = true);

      final PdfBytesWriteResult writeResult;
      if (_individual && _studentId != null) {
        final tables = _pdfTablesForStudent(
          studentId: _studentId!,
          allRows: _allRows,
          strings: strings,
        );
        writeResult = await _writeStudentReportPdf(
          targetPath: targetPath,
          strings: strings,
          detail: tables.detail,
          summary: tables.summary,
          dailyAverage: tables.dailyAverage,
          monthlyCategory: tables.monthlyCategory,
          monthlyOverall: tables.monthlyOverall,
        );
      } else {
        final detail = _detailTable(strings, _rows);
        final summary = _summaryTable(strings, _rows);
        final dailyAverage = _dailyAverageTable(strings);
        final monthlyCategory = _monthlyCategoryTable(strings, _monthlyRows);
        final monthlyOverall = _monthlyOverallTable(strings, _monthlyRows);

        writeResult = await PdfService().exportStudentReportPdf(
          targetPath: targetPath,
          title: strings.t('classReport'),
          subtitle:
              '${AppDatabase.scoreDateKey(_from)} - ${AppDatabase.scoreDateKey(_to)}',
          labels: StudentReportPdfLabels(
            catalogNotice: strings.t('reportPdfCatalogNotice'),
            summarySection: strings.t('reportPdfSummary'),
            dailyAverageSection: strings.t('dailyAverage'),
            monthlyPerformanceSection: strings.t('monthlyHistory'),
            monthlyCategorySection:
                strings.t('reportPdfMonthlyCategoryAverages'),
          ),
          headers: detail.first,
          rows: detail.skip(1).toList(),
          summaryHeaders: summary.first,
          summaryRows: summary.skip(1).toList(),
          dailyAverageHeaders:
              dailyAverage.isEmpty ? null : dailyAverage.first,
          dailyAverageRows: dailyAverage.length <= 1
              ? null
              : dailyAverage.skip(1).toList(),
          monthlyCategoryHeaders:
              monthlyCategory.isEmpty ? null : monthlyCategory.first,
          monthlyCategoryRows: monthlyCategory.length <= 1
              ? null
              : monthlyCategory.skip(1).toList(),
          monthlyOverallHeaders:
              monthlyOverall.isEmpty ? null : monthlyOverall.first,
          monthlyOverallRows: monthlyOverall.length <= 1
              ? null
              : monthlyOverall.skip(1).toList(),
        );
      }

      debugPrint(
        'PDF export saved: ${writeResult.savedPath} '
        '(sharing retries: ${writeResult.sharingRetryCount})',
      );
      if (!mounted) return;
      await showReportExportSuccessAndReveal(
        context: context,
        strings: strings,
        savedPath: writeResult.savedPath,
        savedMessageKey: 'pdfSaved',
      );
    } on PathAccessException catch (e, stackTrace) {
      debugPrint(
        'PDF export PathAccessException: targetPath=$targetPath '
        'errno=${e.osError?.errorCode} error=$e\n$stackTrace',
      );
      if (!mounted) return;
      final locked = e.osError?.errorCode == 32;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locked
                ? strings.t('exportPdfFileInUse')
                : strings.t('exportPdfFailed'),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(
        'PDF export failed: targetPath=$targetPath error=$e\n$stackTrace',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('exportPdfFailed'))),
      );
    } finally {
      if (mounted) {
        setState(() => _exportPdfInProgress = false);
      } else {
        _exportPdfInProgress = false;
      }
    }
  }

  Future<void> _exportExcel() async {
    if (_exportExcelInProgress) return;

    final strings = AppLocalizations.of(context);
    String? path;
    try {
      final pickExcel = await pickReportExportSavePath(
        dialogTitle: strings.t('exportExcel'),
        suggestedFileName: _suggestedReportFileName('xlsx'),
        extension: 'xlsx',
        folderPickDialogTitle: strings.t('exportPickFolder'),
      );
      switch (pickExcel.outcome) {
        case ReportSavePickOutcome.cancelled:
          return;
        case ReportSavePickOutcome.failed:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.t('exportSaveDialogFailed'))),
          );
          return;
        case ReportSavePickOutcome.success:
          path = pickExcel.path;
      }
      if (path == null) return;

      path = normalizeReportSavePath(path, 'xlsx');
      await ensureReportExportParentDirectory(path);

      setState(() => _exportExcelInProgress = true);

      await ReportExcelService().writeWorkbook(
        path: path,
        detailRows: _detailTable(strings, _rows),
        summaryRows: _summaryTable(strings, _rows),
        dailyAverageRows: _dailyAverageTable(strings),
        monthlyCategoryRows: _monthlyCategoryTable(strings, _monthlyRows),
        monthlyOverallRows: _monthlyOverallTable(strings, _monthlyRows),
      );

      debugPrint('Excel export saved: $path');
      if (!mounted) return;
      await showReportExportSuccessAndReveal(
        context: context,
        strings: strings,
        savedPath: path,
        savedMessageKey: 'excelSaved',
      );
    } on PathAccessException catch (e, stackTrace) {
      debugPrint(
        'Excel export PathAccessException: targetPath=$path '
        'errno=${e.osError?.errorCode} error=$e\n$stackTrace',
      );
      if (!mounted) return;
      final locked = e.osError?.errorCode == 32;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locked
                ? strings.t('exportPdfFileInUse')
                : strings.t('exportExcelFailed'),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Excel export failed: targetPath=$path error=$e\n$stackTrace',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('exportExcelFailed'))),
      );
    } finally {
      if (mounted) {
        setState(() => _exportExcelInProgress = false);
      } else {
        _exportExcelInProgress = false;
      }
    }
  }

  Future<void> _exportBulkPdf() async {
    if (_exportBulkPdfInProgress || !_canExportBulkPdf) return;

    final strings = AppLocalizations.of(context);
    final selectedIds = await showDialog<Set<int>>(
      context: context,
      builder: (context) => _BulkReportStudentDialog(
        strings: strings,
        students: _students,
      ),
    );
    if (selectedIds == null) return;
    if (selectedIds.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('exportBulkPdfNoStudents'))),
      );
      return;
    }

    final pickDir = await pickReportExportDirectory(
      dialogTitle: strings.t('exportPickFolder'),
    );
    switch (pickDir.outcome) {
      case ReportSavePickOutcome.cancelled:
        return;
      case ReportSavePickOutcome.failed:
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t('exportSaveDialogFailed'))),
        );
        return;
      case ReportSavePickOutcome.success:
        break;
    }
    final directory = pickDir.path;
    if (directory == null || directory.isEmpty) return;

    if (!mounted) return;
    setState(() => _exportBulkPdfInProgress = true);

    var failures = 0;
    var successCount = 0;
    String? firstSavedPath;
    try {
      final db = context.read<AppState>().db;
      final allRows = await db.getStudentReportRows(
        classId: _classId,
        studentId: null,
        fromDate: AppDatabase.scoreDateKey(_from),
        toDate: AppDatabase.scoreDateKey(_to),
      );
      final ordered = _students
          .where((row) => selectedIds.contains(row['id'] as int))
          .toList()
        ..sort(
          (a, b) => (a['numara'] as int? ?? 0).compareTo(
            b['numara'] as int? ?? 0,
          ),
        );

      for (final student in ordered) {
        final studentId = student['id'] as int;
        try {
          final fileName = _reportFileNameForStudent(student, 'pdf');
          var targetPath = await uniqueExportPathInDirectory(
            directory,
            fileName,
          );
          targetPath = normalizeReportSavePath(targetPath, 'pdf');
          await ensureReportExportParentDirectory(targetPath);

          final tables = _pdfTablesForStudent(
            studentId: studentId,
            allRows: allRows,
            strings: strings,
          );
          final writeResult = await _writeStudentReportPdf(
            targetPath: targetPath,
            strings: strings,
            detail: tables.detail,
            summary: tables.summary,
            dailyAverage: tables.dailyAverage,
            monthlyCategory: tables.monthlyCategory,
            monthlyOverall: tables.monthlyOverall,
          );
          firstSavedPath ??= writeResult.savedPath;
          successCount++;
        } catch (e, stackTrace) {
          failures++;
          debugPrint(
            'Bulk PDF failed for student $studentId: $e\n$stackTrace',
          );
        }
      }

      if (!mounted) return;
      if (successCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t('exportPdfFailed'))),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings
                .t('exportBulkPdfSaved')
                .replaceAll('{count}', '$successCount'),
          ),
        ),
      );
      if (failures > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings
                  .t('exportBulkPdfPartialFailure')
                  .replaceAll('{failures}', '$failures'),
            ),
          ),
        );
      }
      if (firstSavedPath != null) {
        final revealed =
            await revealSavedFileInSystemFileManager(firstSavedPath);
        if (!mounted) return;
        if (!revealed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.t('exportRevealFailed'))),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _exportBulkPdfInProgress = false);
      } else {
        _exportBulkPdfInProgress = false;
      }
    }
  }

  Future<void> _sendReportsByEmail() async {
    if (_sendReportEmailInProgress || !_canSendReportEmail) return;

    final strings = AppLocalizations.of(context);
    final state = context.read<AppState>();
    final smtp = await state.loadSmtpSettings();
    if (!mounted) return;
    if (!smtp.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('smtpNotConfigured'))),
      );
      return;
    }

    List<int> studentIds;
    if (_individual && _studentId != null) {
      studentIds = [_studentId!];
    } else {
      final picked = await showDialog<Set<int>>(
        context: context,
        builder: (context) => _BulkReportStudentDialog(
          strings: strings,
          students: _students,
        ),
      );
      if (!mounted) return;
      if (picked == null || picked.isEmpty) {
        if (picked != null && picked.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.t('exportBulkPdfNoStudents'))),
          );
        }
        return;
      }
      studentIds = picked.toList();
    }

    if (!mounted) return;
    final roles = await showDialog<ReportEmailRecipientRoles>(
      context: context,
      builder: (context) => _ReportEmailRecipientsDialog(strings: strings),
    );
    if (roles == null || !roles.anySelected) return;

    if (!mounted) return;
    setState(() => _sendReportEmailInProgress = true);

    var emailsSent = 0;
    var failures = 0;
    var missingAddressCount = 0;
    var invalidAddressCount = 0;
    var sendFailureCount = 0;
    String? firstInvalidAddress;
    try {
      final db = state.db;
      if (!await db.studentEmailColumnsReady()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.t('studentEmailSchemaMissing')),
            duration: const Duration(seconds: 10),
          ),
        );
        return;
      }
      await _loadClassDependents(db);
      if (!mounted) return;
      final allRows = await db.getStudentReportRows(
        classId: _classId,
        studentId: null,
        fromDate: AppDatabase.scoreDateKey(_from),
        toDate: AppDatabase.scoreDateKey(_to),
      );
      final emailService = ReportEmailService();
      final fromKey = AppDatabase.scoreDateKey(_from);
      final toKey = AppDatabase.scoreDateKey(_to);

      final ordered = _students
          .where((row) => studentIds.contains(row['id'] as int))
          .toList()
        ..sort(
          (a, b) => (a['numara'] as int? ?? 0).compareTo(
            b['numara'] as int? ?? 0,
          ),
        );

      for (final student in ordered) {
        final studentId = student['id'] as int;
        final studentRow =
            await db.getStudentById(studentId) ?? student;
        final pick = pickStudentReportRecipientEmails(
          studentRow,
          toStudent: roles.toStudent,
          toMother: roles.toMother,
          toFather: roles.toFather,
        );
        if (pick.validEmails.isEmpty) {
          failures++;
          if (pick.invalidEmails.isNotEmpty) {
            invalidAddressCount++;
            firstInvalidAddress ??= pick.invalidEmails.first;
          } else if (pick.hadEmptyFieldsForSelectedRoles) {
            missingAddressCount++;
          } else {
            missingAddressCount++;
          }
          continue;
        }
        final recipients = pick.validEmails;
        try {
          final tables = _pdfTablesForStudent(
            studentId: studentId,
            allRows: allRows,
            strings: strings,
          );
          final bytes = await _buildReportPdfBytes(
            strings: strings,
            detail: tables.detail,
            summary: tables.summary,
            dailyAverage: tables.dailyAverage,
            monthlyCategory: tables.monthlyCategory,
            monthlyOverall: tables.monthlyOverall,
          );
          final studentName = studentRow['ad_soyad'] as String? ?? '';
          final subject = strings
              .t('reportEmailSubject')
              .replaceAll('{name}', studentName);
          final body = strings
              .t('reportEmailBody')
              .replaceAll('{student}', studentName)
              .replaceAll('{from}', fromKey)
              .replaceAll('{to}', toKey);
          final attachmentName = _reportFileNameForStudent(studentRow, 'pdf');
          await emailService.sendReportPdf(
            smtp: smtp,
            recipients: recipients,
            subject: subject,
            bodyText: body,
            pdfBytes: bytes,
            attachmentFileName: attachmentName,
          );
          emailsSent += recipients.length;
        } catch (e, stackTrace) {
          failures++;
          sendFailureCount++;
          debugPrint(
            'Report email failed for student $studentId: $e\n$stackTrace',
          );
          if (mounted && sendFailureCount == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(resolveSmtpErrorMessage(strings, e)),
                duration: const Duration(seconds: 8),
              ),
            );
          }
        }
      }

      if (!mounted) return;
      if (emailsSent == 0) {
        if (sendFailureCount > 0) {
          return;
        }
        final message = invalidAddressCount > 0 && firstInvalidAddress != null
            ? strings
                .t('reportEmailInvalidStored')
                .replaceAll('{email}', firstInvalidAddress!)
            : missingAddressCount > 0
                ? strings.t('reportEmailMissingInProfile')
                : strings.t('reportEmailNoRecipients');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 10),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.t('reportEmailSent').replaceAll('{count}', '$emailsSent'),
          ),
        ),
      );
      if (failures > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings
                  .t('reportEmailPartialFailure')
                  .replaceAll('{failures}', '$failures'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendReportEmailInProgress = false);
      } else {
        _sendReportEmailInProgress = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final categories = _visibleReportCategories();
    final categoryAverages = _individual
        ? _categoryAverages(studentId: _studentId)
        : _categoryAverages();
    final dailyAverages = _individual
        ? _individualDailyAverages(_allRows)
        : <StudentDailyPerformance>[];
    final periodAverage = _individual
        ? _individualPeriodAverage(_allRows)
        : null;
    final overallAverage = periodAverage ?? _overallAverage(categoryAverages);
    final pivotRows = _individual
        ? _individualPivotRows(_allRows)
        : _classPivotRows(_allRows);
    final selectedStudent = _selectedStudentRow();
    final selectedClass = _selectedClassRow();
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < AppSpacing.phoneBreakpoint;
    final isTablet = width >= AppSpacing.phoneBreakpoint &&
        width < AppSpacing.desktopBreakpoint;

    return AppShell(
      teacherSection: TeacherNavSection.reports,
      title: strings.t('reports'),
      subtitle: strings.t('reportsSubtitle'),
      leading: buildPushedScreenBackLeading(context),
      actions: [
        FilledButton.icon(
          onPressed: (!_canExportReport || _exportPdfInProgress) ? null : _exportPdf,
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: Text(strings.t('exportPdf')),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: (!_canExportBulkPdf || _exportBulkPdfInProgress)
              ? null
              : _exportBulkPdf,
          icon: const Icon(Icons.file_copy_outlined, size: 18),
          label: Text(strings.t('exportBulkPdf')),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: (!_canSendReportEmail || _sendReportEmailInProgress)
              ? null
              : _sendReportsByEmail,
          icon: const Icon(Icons.email_outlined, size: 18),
          label: Text(strings.t('sendReportEmail')),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: (!_canExportReport || _exportExcelInProgress)
              ? null
              : _exportExcel,
          icon: const Icon(Icons.table_chart, size: 18),
          label: Text(strings.t('exportExcel')),
        ),
      ],
      child: ColoredBox(
        color: AppColors.background,
        child: Padding(
          padding: EdgeInsets.all(isPhone ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReportTypeSegment(
                individual: _individual,
                individualLabel: strings.t('individualReport'),
                classLabel: strings.t('classReport'),
                onChanged: (value) {
                  setState(() => _individual = value);
                  _refreshRows();
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _ReportFilterPanel(
                strings: strings,
                individual: _individual,
                isPhone: isPhone,
                isTablet: isTablet,
                classId: _classId,
                studentId: _studentId,
                categoryCode: _categoryCode,
                classes: _classes,
                students: _students,
                categories: _categories,
                from: _from,
                to: _to,
                selectedClass: selectedClass,
                onClassChanged: (value) async {
                  _classId = value;
                  _studentId = null;
                  _categoryCode = null;
                  await _loadClassDependents(context.read<AppState>().db);
                  setState(() {});
                  await _refreshRows();
                },
                onStudentChanged: (value) {
                  setState(() => _studentId = value);
                  _refreshRows();
                },
                onCategoryChanged: (value) {
                  setState(() => _categoryCode = value);
                  _refreshRows();
                },
                onPickDate: _pickDate,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _allRows.isEmpty
                        ? AppEmptyState(
                            icon: Icons.assessment_outlined,
                            title: strings.t('noReportData'),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_individual &&
                                    selectedStudent != null &&
                                    selectedClass != null) ...[
                                  _StudentSummaryCard(
                                    strings: strings,
                                    studentName:
                                        '${selectedStudent['ad_soyad']}',
                                    classSectionLabel:
                                        _classSectionLabel(selectedClass),
                                    dateRange:
                                        '${AppDatabase.scoreDateKey(_from)} - ${AppDatabase.scoreDateKey(_to)}',
                                    overallAverage: overallAverage,
                                    periodAverageLabel:
                                        strings.t('periodAverage'),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  if (dailyAverages.isNotEmpty) ...[
                                    _DailyAverageTable(
                                      strings: strings,
                                      dailyAverages: dailyAverages,
                                      periodAverage: periodAverage,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],
                                ],
                                if (categories.isNotEmpty) ...[
                                  _CategoryAverageCards(
                                    strings: strings,
                                    categories: categories,
                                    averages: categoryAverages,
                                    isPhone: isPhone,
                                    isTablet: isTablet,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                                if (_rows.isNotEmpty) ...[
                                  _ScoreDetailTable(
                                    strings: strings,
                                    rows: _rows,
                                    scoreTypeLabel: _scoreTypeLabel,
                                    scoreDescription: _scoreDescription,
                                    valueOf: _valueOf,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                                _ReportPivotTable(
                                  strings: strings,
                                  rowHeader: _individual
                                      ? strings.t('selectedDate')
                                      : strings.t('studentName'),
                                  categories: categories,
                                  rows: pivotRows,
                                  isPhone: isPhone,
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreDetailTable extends StatelessWidget {
  const _ScoreDetailTable({
    required this.strings,
    required this.rows,
    required this.scoreTypeLabel,
    required this.scoreDescription,
    required this.valueOf,
  });

  final AppLocalizations strings;
  final List<Map<String, Object?>> rows;
  final String Function(Map<String, Object?> row, AppLocalizations strings)
      scoreTypeLabel;
  final String Function(Map<String, Object?> row) scoreDescription;
  final String Function(Map<String, Object?> row) valueOf;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('scoreDetails'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.background),
              columns: [
                DataColumn(label: Text(strings.t('studentName'))),
                DataColumn(label: Text(strings.t('selectedDate'))),
                DataColumn(label: Text(strings.t('category'))),
                DataColumn(label: Text(strings.t('note'))),
                DataColumn(label: Text(strings.t('value'))),
              ],
              rows: rows
                  .map(
                    (row) => DataRow(
                      cells: [
                        DataCell(
                          Text('${row['numara']} ${row['ad_soyad']}'),
                        ),
                        DataCell(
                          Text(
                            StudentDailyPerformance.formatDisplayDate(
                              '${row['tarih'] ?? ''}',
                            ),
                          ),
                        ),
                        DataCell(Text(scoreTypeLabel(row, strings))),
                        DataCell(
                          Text(
                            scoreDescription(row),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DataCell(Text(valueOf(row))),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportPivotRow {
  const _ReportPivotRow({
    required this.label,
    required this.values,
    required this.overall,
  });

  final String label;
  final Map<String, double?> values;
  final double? overall;
}

IconData _studentCategoryIcon(String code) {
  switch (code) {
    case 'students':
      return Icons.people_outline;
    case 'performance':
      return Icons.insights_outlined;
    case 'materials':
      return Icons.folder_outlined;
    case 'activity':
    case 'activities':
      return Icons.event_outlined;
    case 'homework':
      return Icons.assignment_outlined;
    case 'exam':
      return Icons.quiz_outlined;
    default:
      return Icons.category_outlined;
  }
}

class _ReportTypeSegment extends StatelessWidget {
  const _ReportTypeSegment({
    required this.individual,
    required this.individualLabel,
    required this.classLabel,
    required this.onChanged,
  });

  final bool individual;
  final String individualLabel;
  final String classLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _segmentButton(
              label: individualLabel,
              selected: individual,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _segmentButton(
              label: classLabel,
              selected: !individual,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.primaryBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportFilterPanel extends StatelessWidget {
  const _ReportFilterPanel({
    required this.strings,
    required this.individual,
    required this.isPhone,
    required this.isTablet,
    required this.classId,
    required this.studentId,
    required this.categoryCode,
    required this.classes,
    required this.students,
    required this.categories,
    required this.from,
    required this.to,
    required this.selectedClass,
    required this.onClassChanged,
    required this.onStudentChanged,
    required this.onCategoryChanged,
    required this.onPickDate,
  });

  final AppLocalizations strings;
  final bool individual;
  final bool isPhone;
  final bool isTablet;
  final int? classId;
  final int? studentId;
  final String? categoryCode;
  final List<Map<String, Object?>> classes;
  final List<Map<String, Object?>> students;
  final List<StudentCategory> categories;
  final DateTime from;
  final DateTime to;
  final Map<String, Object?>? selectedClass;
  final ValueChanged<int?> onClassChanged;
  final ValueChanged<int?> onStudentChanged;
  final ValueChanged<String?> onCategoryChanged;
  final Future<void> Function({required bool from}) onPickDate;

  @override
  Widget build(BuildContext context) {
    final section = (selectedClass?['sube'] as String?)?.trim() ?? '';
    final fields = <Widget>[
      if (individual)
        _filterField(
          label: strings.t('selectStudent'),
          child: DropdownButtonFormField<int>(
            value: studentId,
            decoration: _filterDecoration(strings.t('selectStudent')),
            items: students
                .map(
                  (row) => DropdownMenuItem(
                    value: row['id'] as int,
                    child: Text('${row['numara']} ${row['ad_soyad']}'),
                  ),
                )
                .toList(),
            onChanged: onStudentChanged,
          ),
        ),
      _filterField(
        label: strings.t('dateRange'),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => onPickDate(from: true),
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(AppDatabase.scoreDateKey(from)),
            ),
            OutlinedButton.icon(
              onPressed: () => onPickDate(from: false),
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(AppDatabase.scoreDateKey(to)),
            ),
          ],
        ),
      ),
      _filterField(
        label: strings.t('category'),
        child: DropdownButtonFormField<String?>(
          value: categoryCode,
          decoration: _filterDecoration(strings.t('allCategories')),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(strings.t('allCategories')),
            ),
            ...categories
                .where((category) => category.code != 'students')
                .map(
                  (category) => DropdownMenuItem<String?>(
                    value: category.code,
                    child: Text(category.name),
                  ),
                ),
          ],
          onChanged: onCategoryChanged,
        ),
      ),
      _filterField(
        label: strings.t('selectClass'),
        child: DropdownButtonFormField<int>(
          value: classId,
          decoration: _filterDecoration(strings.t('selectClass')),
          items: classes
              .map(
                (row) => DropdownMenuItem(
                  value: row['id'] as int,
                  child: Text(
                    CourseFormOptions.studentClassLabel(
                      row['ad'] as String,
                      row['yil'] as String,
                      section: row['sube'] as String?,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onClassChanged,
        ),
      ),
      _filterField(
        label: strings.t('studentClassSection'),
        child: InputDecorator(
          decoration: _filterDecoration(strings.t('studentClassSection')),
          child: Text(
            section.isEmpty ? '-' : section,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    ];

    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = isPhone ? 1 : (isTablet ? 2 : 3);
          final itemWidth =
              (constraints.maxWidth - (columns - 1) * AppSpacing.md) / columns;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: fields
                .map((field) => SizedBox(width: itemWidth, child: field))
                .toList(),
          );
        },
      ),
    );
  }

  InputDecoration _filterDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _filterField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _StudentSummaryCard extends StatelessWidget {
  const _StudentSummaryCard({
    required this.strings,
    required this.studentName,
    required this.classSectionLabel,
    required this.dateRange,
    required this.overallAverage,
    required this.periodAverageLabel,
  });

  final AppLocalizations strings;
  final String studentName;
  final String classSectionLabel;
  final String dateRange;
  final double? overallAverage;
  final String periodAverageLabel;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < AppSpacing.phoneBreakpoint;
    final overallText =
        StudentDailyPerformance.formatAverage(overallAverage, fractionDigits: 2);

    return AppCard(
      child: isPhone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryLeft(context),
                const SizedBox(height: AppSpacing.lg),
                _summaryRight(overallText),
              ],
            )
          : Row(
              children: [
                Expanded(child: _summaryLeft(context)),
                const SizedBox(width: AppSpacing.xl),
                _summaryRight(overallText),
              ],
            ),
    );
  }

  Widget _summaryLeft(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
          child: const Icon(
            Icons.person_outline,
            color: AppColors.primaryBlue,
            size: 30,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                classSectionLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRight(String overallText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          strings.t('reportDate'),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateRange,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          periodAverageLabel,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          overallText,
          style: const TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 28,
          ),
        ),
      ],
    );
  }
}

class _CategoryAverageCards extends StatelessWidget {
  const _CategoryAverageCards({
    required this.strings,
    required this.categories,
    required this.averages,
    required this.isPhone,
    required this.isTablet,
  });

  final AppLocalizations strings;
  final List<StudentCategory> categories;
  final Map<String, double> averages;
  final bool isPhone;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    if (isPhone) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.35,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) => _categoryCard(
          context,
          categories[index],
          averages[categories[index].code],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            SizedBox(
              width: isTablet ? 150 : 160,
              child: _categoryCard(
                context,
                categories[i],
                averages[categories[i].code],
              ),
            ),
            if (i < categories.length - 1) const SizedBox(width: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  Widget _categoryCard(
    BuildContext context,
    StudentCategory category,
    double? average,
  ) {
    final color = AppColors.categoryColor(category.code);
    final valueText =
        average == null ? '-' : average.toStringAsFixed(average % 1 == 0 ? 0 : 1);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _studentCategoryIcon(category.code),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            category.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.t('average'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            valueText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReportPivotTable extends StatelessWidget {
  const _ReportPivotTable({
    required this.strings,
    required this.rowHeader,
    required this.categories,
    required this.rows,
    this.isPhone = false,
  });

  final AppLocalizations strings;
  final String rowHeader;
  final List<StudentCategory> categories;
  final List<_ReportPivotRow> rows;
  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    String formatScore(double? value) {
      if (value == null) return '-';
      return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
    }

    if (isPhone) {
      return Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ),
                              Text(
                                formatScore(row.values[category.code]),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              strings.t('overallAverageColumn'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            formatScore(row.overall),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.background,
            ),
            columnSpacing: 20,
            horizontalMargin: 12,
            columns: [
              DataColumn(label: Text(rowHeader)),
              ...categories.map(
                (category) => DataColumn(label: Text(category.name)),
              ),
              DataColumn(label: Text(strings.t('overallAverageColumn'))),
            ],
            rows: rows
                .map(
                  (row) => DataRow(
                    cells: [
                      DataCell(Text(row.label)),
                      ...categories.map(
                        (category) => DataCell(
                          Text(formatScore(row.values[category.code])),
                        ),
                      ),
                      DataCell(Text(formatScore(row.overall))),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _DailyAverageTable extends StatelessWidget {
  const _DailyAverageTable({
    required this.strings,
    required this.dailyAverages,
    required this.periodAverage,
  });

  final AppLocalizations strings;
  final List<StudentDailyPerformance> dailyAverages;
  final double? periodAverage;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('dailyAverage'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(strings.t('selectedDate'))),
                DataColumn(label: Text(strings.t('dailyAverage'))),
              ],
              rows: [
                ...dailyAverages.reversed.map(
                  (item) => DataRow(
                    cells: [
                      DataCell(
                        Text(
                          StudentDailyPerformance.formatDisplayDate(item.date),
                        ),
                      ),
                      DataCell(
                        Text(
                          StudentDailyPerformance.formatAverage(
                            item.dailyAverage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        strings.t('periodAverage'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(
                      Text(
                        StudentDailyPerformance.formatAverage(periodAverage),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportEmailRecipientsDialog extends StatefulWidget {
  const _ReportEmailRecipientsDialog({required this.strings});

  final AppLocalizations strings;

  @override
  State<_ReportEmailRecipientsDialog> createState() =>
      _ReportEmailRecipientsDialogState();
}

class _ReportEmailRecipientsDialogState
    extends State<_ReportEmailRecipientsDialog> {
  bool _toStudent = true;
  bool _toMother = true;
  bool _toFather = true;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return AlertDialog(
      title: Text(strings.t('reportEmailRecipientsTitle')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            value: _toStudent,
            onChanged: (v) => setState(() => _toStudent = v ?? false),
            title: Text(strings.t('reportEmailToStudent')),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _toMother,
            onChanged: (v) => setState(() => _toMother = v ?? false),
            title: Text(strings.t('reportEmailToMother')),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _toFather,
            onChanged: (v) => setState(() => _toFather = v ?? false),
            title: Text(strings.t('reportEmailToFather')),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.t('close')),
        ),
        FilledButton(
          onPressed: () {
            if (!_toStudent && !_toMother && !_toFather) return;
            Navigator.pop(
              context,
              ReportEmailRecipientRoles(
                toStudent: _toStudent,
                toMother: _toMother,
                toFather: _toFather,
              ),
            );
          },
          child: Text(strings.t('sendReportEmail')),
        ),
      ],
    );
  }
}

class _BulkReportStudentDialog extends StatefulWidget {
  const _BulkReportStudentDialog({
    required this.strings,
    required this.students,
  });

  final AppLocalizations strings;
  final List<Map<String, Object?>> students;

  @override
  State<_BulkReportStudentDialog> createState() =>
      _BulkReportStudentDialogState();
}

class _BulkReportStudentDialogState extends State<_BulkReportStudentDialog> {
  late final Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.students.map((row) => row['id'] as int).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final listHeight = (widget.students.length * 52.0 + 8).clamp(120.0, 360.0);
    return AlertDialog(
      title: Text(strings.t('exportBulkPdfTitle')),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selected
                        ..clear()
                        ..addAll(
                          widget.students.map((row) => row['id'] as int),
                        );
                    });
                  },
                  child: Text(strings.t('selectAllStudents')),
                ),
                TextButton(
                  onPressed: () => setState(_selected.clear),
                  child: Text(strings.t('clearSelection')),
                ),
              ],
            ),
            SizedBox(
              height: listHeight,
              child: ListView.builder(
                itemCount: widget.students.length,
                itemBuilder: (context, index) {
                  final row = widget.students[index];
                  final id = row['id'] as int;
                  return CheckboxListTile(
                    value: _selected.contains(id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(id);
                        } else {
                          _selected.remove(id);
                        }
                      });
                    },
                    title: Text('${row['numara']} ${row['ad_soyad']}'),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.t('close')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, Set<int>.from(_selected)),
          child: Text(strings.t('exportBulkPdf')),
        ),
      ],
    );
  }
}
