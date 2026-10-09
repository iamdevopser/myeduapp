import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/local/app_database.dart';
import '../data/models/student_category_model.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_empty_state.dart';
import 'student_platform_screen.dart';

/// Davranışlar — Excel benzeri tablo, sticky öğrenci kolonu, iki eksen scroll.
class StudentBehaviorsPanel extends StatefulWidget {
  const StudentBehaviorsPanel({
    super.key,
    required this.classId,
    required this.selectedDate,
    required this.onDateChanged,
    this.readOnly = false,
    this.viewStudentId,
    this.hiddenStudentIds = const {},
  });

  final int classId;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool readOnly;
  final int? viewStudentId;
  final Set<int> hiddenStudentIds;

  @override
  State<StudentBehaviorsPanel> createState() => _StudentBehaviorsPanelState();
}

class _StudentBehaviorsPanelState extends State<StudentBehaviorsPanel> {
  static const double _studentColumnWidth = 180;
  static const double _behaviorColumnWidth = 132;
  static const double _headerHeight = 56;
  static const double _rowHeight = 48;

  final ScrollController _verticalBody = ScrollController();
  final ScrollController _horizontalHeader = ScrollController();
  final ScrollController _horizontalBody = ScrollController();

  Set<String> _checkedKeys = {};
  Set<String> _publishedKeys = {};
  bool _loadingRecords = true;
  String? _recordsDateKey;

  @override
  void initState() {
    super.initState();
    _linkScroll(_horizontalHeader, _horizontalBody);
    _linkScroll(_horizontalBody, _horizontalHeader);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecords());
  }

  @override
  void dispose() {
    _verticalBody.dispose();
    _horizontalHeader.dispose();
    _horizontalBody.dispose();
    super.dispose();
  }

  void _linkScroll(ScrollController leader, ScrollController follower) {
    leader.addListener(() {
      if (!follower.hasClients || follower.offset == leader.offset) return;
      follower.jumpTo(leader.offset);
    });
  }

  String get _dateKey => AppDatabase.scoreDateKey(widget.selectedDate);

  @override
  void didUpdateWidget(covariant StudentBehaviorsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.classId != widget.classId) {
      _loadRecords();
    }
  }

  Future<void> _loadRecords() async {
    final dateKey = _dateKey;
    setState(() {
      _loadingRecords = true;
      _recordsDateKey = dateKey;
    });
    try {
      final db = context.read<AppState>().db;
      final keys = await db.getStudentBehaviorRecordKeys(
        classId: widget.classId,
        date: dateKey,
      );
      final published = await db.getStudentBehaviorPublishKeys(
        classId: widget.classId,
        date: dateKey,
      );
      if (!mounted || _recordsDateKey != dateKey) return;
      setState(() {
        _checkedKeys = keys;
        _publishedKeys = published;
        _loadingRecords = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRecords = false);
    }
  }

  bool _isChecked(int studentId, int behaviorId) {
    return _checkedKeys.contains('${studentId}_$behaviorId');
  }

  Future<void> _toggle({
    required int studentId,
    required int behaviorId,
    required bool value,
  }) async {
    final key = '${studentId}_$behaviorId';
    final previous = Set<String>.from(_checkedKeys);
    setState(() {
      if (value) {
        _checkedKeys.add(key);
      } else {
        _checkedKeys.remove(key);
      }
    });
    try {
      await context.read<AppState>().db.setStudentBehaviorChecked(
            classId: widget.classId,
            studentId: studentId,
            behaviorId: behaviorId,
            date: _dateKey,
            checked: value,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkedKeys = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('saveFailed')),
        ),
      );
    }
  }

  Future<void> _togglePublish({
    required int studentId,
    required int behaviorId,
  }) async {
    final key = '${studentId}_$behaviorId';
    if (!_checkedKeys.contains(key)) return;
    final strings = AppLocalizations.of(context);
    final next = !_publishedKeys.contains(key);
    final previous = Set<String>.from(_publishedKeys);
    setState(() {
      if (next) {
        _publishedKeys.add(key);
      } else {
        _publishedKeys.remove(key);
      }
    });
    try {
      await context.read<AppState>().db.setStudentBehaviorVisibleToStudent(
            studentId: studentId,
            behaviorId: behaviorId,
            date: _dateKey,
            visible: next,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next
                ? strings.t('behaviorPublishedToStudent')
                : strings.t('behaviorHiddenFromStudent'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _publishedKeys = previous);
    }
  }

  Widget _dateNavigator(AppLocalizations strings) {
    return Row(
      children: [
        IconButton(
          tooltip: strings.t('previousDay'),
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            widget.onDateChanged(
              widget.selectedDate.subtract(const Duration(days: 1)),
            );
          },
        ),
        TextButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: widget.selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              widget.onDateChanged(picked);
            }
          },
          icon: const Icon(Icons.calendar_today),
          label: Text(
            '${strings.t('selectedDate')}: $_dateKey',
          ),
        ),
        IconButton(
          tooltip: strings.t('nextDay'),
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            widget.onDateChanged(
              widget.selectedDate.add(const Duration(days: 1)),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.read<AppState>();
    final locale = Localizations.localeOf(context).languageCode;
    final accent = AppColors.categoryColor(StudentCategory.behaviorsCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    studentCategoryIcon(StudentCategory.behaviorsCode),
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.t('behaviorsCategory'),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        strings.t('behaviorsTableHint'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _dateNavigator(strings),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<List<Map<String, Object?>>>>(
            future: Future.wait<List<Map<String, Object?>>>([
              state.db.getStudents(widget.classId),
              state.db.getBehaviorDefinitions(),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final students = snapshot.data![0];
              final behaviorRows = snapshot.data![1];
              List<Map<String, Object?>> studentList =
                  List<Map<String, Object?>>.from(students);
              if (widget.viewStudentId != null) {
                studentList = studentList
                    .where((s) => s['id'] == widget.viewStudentId)
                    .toList();
              } else if (widget.hiddenStudentIds.isNotEmpty) {
                studentList = studentList
                    .where((s) => !widget.hiddenStudentIds.contains(s['id']))
                    .toList();
              }
              if (studentList.isEmpty) {
                return AppEmptyState(
                  icon: Icons.people_outline,
                  title: strings.t('noStudents'),
                );
              }
              if (behaviorRows.isEmpty) {
                return AppEmptyState(
                  icon: Icons.fact_check_outlined,
                  title: strings.t('behaviorsLoadError'),
                );
              }

              final behaviors = behaviorRows
                  .map(
                    (row) => (
                      id: row['id'] as int,
                      label: row['ad'] as String,
                      kind: row['tur'] as String,
                    ),
                  )
                  .toList();

              if (_loadingRecords) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  SizedBox(
                    height: _headerHeight,
                    child: Row(
                      children: [
                        SizedBox(
                          width: _studentColumnWidth,
                          child: _headerCell(
                            strings.t('studentName'),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        Expanded(
                          child: Scrollbar(
                            controller: _horizontalHeader,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _horizontalHeader,
                              primary: false,
                              child: Row(
                                children: behaviors
                                    .map(
                                      (b) => SizedBox(
                                        width: _behaviorColumnWidth,
                                        child: _headerCell(
                                          b.label,
                                          kind: b.kind,
                                          locale: locale,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Scrollbar(
                      controller: _verticalBody,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _verticalBody,
                        primary: false,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: _studentColumnWidth,
                              child: Column(
                                children: studentList
                                    .map(
                                      (student) => _studentNameCell(
                                        '${student['numara']}',
                                        student['ad_soyad'] as String,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            Expanded(
                              child: Scrollbar(
                                controller: _horizontalBody,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  controller: _horizontalBody,
                                  primary: false,
                                  child: SizedBox(
                                    width:
                                        behaviors.length * _behaviorColumnWidth,
                                    child: Column(
                                      children: studentList.map((student) {
                                        final studentId = student['id'] as int;
                                        return Row(
                                          children: behaviors.map((b) {
                                            final checked = _isChecked(
                                              studentId,
                                              b.id,
                                            );
                                            return SizedBox(
                                              width: _behaviorColumnWidth,
                                              height: _rowHeight,
                                              child: Center(
                                                child: widget.readOnly
                                                    ? Icon(
                                                        checked
                                                            ? Icons.check_box
                                                            : Icons
                                                                .check_box_outline_blank,
                                                        size: 22,
                                                        color: checked
                                                            ? accent
                                                            : AppColors
                                                                .textMuted,
                                                      )
                                                    : Tooltip(
                                                        message: checked
                                                            ? strings.t(
                                                                'behaviorPublishLongPressHint',
                                                              )
                                                            : '',
                                                        child: GestureDetector(
                                                          onLongPress: checked
                                                              ? () =>
                                                                  _togglePublish(
                                                                    studentId:
                                                                        studentId,
                                                                    behaviorId:
                                                                        b.id,
                                                                  )
                                                              : null,
                                                          child: Stack(
                                                            alignment:
                                                                Alignment.center,
                                                            children: [
                                                              Checkbox(
                                                                value: checked,
                                                                onChanged: (v) {
                                                                  if (v ==
                                                                      null) {
                                                                    return;
                                                                  }
                                                                  _toggle(
                                                                    studentId:
                                                                        studentId,
                                                                    behaviorId:
                                                                        b.id,
                                                                    value: v,
                                                                  );
                                                                },
                                                              ),
                                                              if (_publishedKeys
                                                                  .contains(
                                                                '${studentId}_${b.id}',
                                                              ))
                                                                Positioned(
                                                                  right: 4,
                                                                  top: 4,
                                                                  child: Icon(
                                                                    Icons
                                                                        .visibility,
                                                                    size: 14,
                                                                    color: accent,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _headerCell(
    String label, {
    Alignment alignment = Alignment.center,
    String? kind,
    String locale = 'tr',
  }) {
    Color? stripe;
    if (kind == 'positive') {
      stripe = AppColors.accentGreen;
    } else if (kind == 'needs_improvement') {
      stripe = AppColors.accentOrange;
    }
    return Container(
      height: _headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: alignment,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (stripe != null)
            Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: stripe,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _studentNameCell(String number, String name) {
    return Container(
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              number,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
