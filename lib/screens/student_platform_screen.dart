import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';

enum _StudentSection {
  students,
  exams,
  homeworks,
  activities,
}

class StudentPlatformScreen extends StatefulWidget {
  const StudentPlatformScreen({super.key});

  @override
  State<StudentPlatformScreen> createState() => _StudentPlatformScreenState();
}

class _StudentPlatformScreenState extends State<StudentPlatformScreen> {
  int? _selectedClassId;
  _StudentSection _selectedSection = _StudentSection.students;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Consumer<AppState>(
      builder: (context, state, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.t('studentPlatform')),
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                tooltip: strings.t('goHome'),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
          body: Row(
            children: [
              Container(
                width: 300,
                color: const Color(0xFFEFF2FB),
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Text(strings.t('addStudentClass'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _ClassForm(onCreate: (name, year) async {
                      final id = await state.db.insertStudentClass(name, year);
                      setState(() {
                        _selectedClassId = id;
                      });
                    }),
                    const Divider(height: 24),
                    Text(strings.t('studentPlatform'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Map<String, Object?>>>(
                      future: state.db.getStudentClasses(),
                      builder: (context, snapshot) {
                        final classes = snapshot.data ?? [];
                        return Column(
                          children: classes.map((row) {
                            final classId = row['id'] as int;
                            final isSelected = _selectedClassId == classId;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: Text(row['ad'] as String),
                                  subtitle: Text(row['yil'] as String),
                                  selected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedClassId = classId;
                                      _selectedSection =
                                          _StudentSection.students;
                                    });
                                  },
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () async {
                                          final updated =
                                              await _showEditClassDialog(
                                            context,
                                            row['ad'] as String,
                                            row['yil'] as String,
                                          );
                                          if (updated != null) {
                                            await state.db.updateStudentClass(
                                              classId,
                                              updated['name']!,
                                              updated['year']!,
                                            );
                                            setState(() {});
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () async {
                                          await state.db.deleteStudentClass(
                                            classId,
                                          );
                                          setState(() {
                                            if (_selectedClassId == classId) {
                                              _selectedClassId = null;
                                              _selectedSection =
                                                  _StudentSection.students;
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 20),
                                    child: Column(
                                      children: [
                                        _buildSubMenuItem(
                                          classId: classId,
                                          section: _StudentSection.students,
                                          label: strings.t('studentList'),
                                        ),
                                        _buildSubMenuItem(
                                          classId: classId,
                                          section: _StudentSection.exams,
                                          label: strings.t('exams'),
                                        ),
                                        _buildSubMenuItem(
                                          classId: classId,
                                          section: _StudentSection.homeworks,
                                          label: strings.t('homeworks'),
                                        ),
                                        _buildSubMenuItem(
                                          classId: classId,
                                          section: _StudentSection.activities,
                                          label: strings.t('activities'),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _selectedClassId == null
                    ? Center(child: Text(strings.t('selectClass')))
                    : _StudentClassDetail(
                        classId: _selectedClassId!,
                        section: _selectedSection,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubMenuItem({
    required int classId,
    required _StudentSection section,
    required String label,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 8),
      title: Text(label),
      selected: _selectedClassId == classId && _selectedSection == section,
      onTap: () {
        setState(() {
          _selectedClassId = classId;
          _selectedSection = section;
        });
      },
    );
  }

  Future<Map<String, String>?> _showEditClassDialog(
    BuildContext context,
    String currentName,
    String currentYear,
  ) async {
    final strings = AppLocalizations.of(context);
    final nameController = TextEditingController(text: currentName);
    final yearController = TextEditingController(text: currentYear);
    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('edit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: strings.t('studentClassName')),
            ),
            TextField(
              controller: yearController,
              decoration: InputDecoration(labelText: strings.t('academicYear')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final year = yearController.text.trim();
              if (name.isEmpty || year.isEmpty) {
                return;
              }
              Navigator.of(context).pop({'name': name, 'year': year});
            },
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
  }
}

class _ClassForm extends StatefulWidget {
  const _ClassForm({required this.onCreate});

  final Future<void> Function(String name, String year) onCreate;

  @override
  State<_ClassForm> createState() => _ClassFormState();
}

class _ClassFormState extends State<_ClassForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      children: [
        TextField(
          controller: _yearController,
          decoration: InputDecoration(labelText: strings.t('academicYear')),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: strings.t('studentClassName')),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            final year = _yearController.text.trim();
            if (name.isEmpty || year.isEmpty) return;
            await widget.onCreate(name, year);
            _nameController.clear();
            _yearController.clear();
          },
          child: Text(strings.t('addStudentClass')),
        ),
      ],
    );
  }
}

class _StudentClassDetail extends StatefulWidget {
  const _StudentClassDetail({
    required this.classId,
    required this.section,
  });

  final int classId;
  final _StudentSection section;

  @override
  State<_StudentClassDetail> createState() => _StudentClassDetailState();
}

class _StudentClassDetailState extends State<_StudentClassDetail> {
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _bulkController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.read<AppState>();
    Widget content;
    switch (widget.section) {
      case _StudentSection.students:
        content = _buildStudentListSection(state, strings);
        break;
      case _StudentSection.exams:
        content = _buildScoresSection(
          state,
          strings,
          type: 'exam',
          titleLabel: strings.t('examColumnTitle'),
          clearLabel: strings.t('clearExamScores'),
        );
        break;
      case _StudentSection.homeworks:
        content = _buildScoresSection(
          state,
          strings,
          type: 'homework',
          titleLabel: strings.t('homeworkColumnTitle'),
          clearLabel: strings.t('clearHomeworkScores'),
        );
        break;
      case _StudentSection.activities:
        content = _buildScoresSection(
          state,
          strings,
          type: 'activity',
          titleLabel: strings.t('activityColumnTitle'),
          clearLabel: strings.t('clearActivityScores'),
        );
        break;
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: content,
    );
  }

  Widget _buildStudentListSection(
    AppState state,
    AppLocalizations strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _studentNameController,
                decoration: InputDecoration(labelText: strings.t('studentName')),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () async {
                final name = _studentNameController.text.trim();
                if (name.isEmpty) return;
                final number = await state.db.getNextStudentNumber(
                  widget.classId,
                );
                await state.db.insertStudent(
                  classId: widget.classId,
                  number: number,
                  name: name,
                );
                _studentNameController.clear();
                setState(() {});
              },
              child: Text(strings.t('addStudent')),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () async {
                final names = _bulkController.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                if (names.isEmpty) return;
                var number = await state.db.getNextStudentNumber(widget.classId);
                for (final name in names) {
                  await state.db.insertStudent(
                    classId: widget.classId,
                    number: number,
                    name: name,
                  );
                  number += 1;
                }
                _bulkController.clear();
                setState(() {});
              },
              child: Text(strings.t('addStudentsBulk')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bulkController,
          decoration: InputDecoration(labelText: strings.t('addStudentsBulk')),
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<Map<String, Object?>>>(
            future: state.db.getStudents(widget.classId),
            builder: (context, snapshot) {
              final students = snapshot.data ?? [];
              if (students.isEmpty) {
                return Center(child: Text(strings.t('noStudents')));
              }
              return ListView.separated(
                itemCount: students.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final student = students[index];
                  return ListTile(
                    leading: Text('${student['numara']}'),
                    title: Text(student['ad_soyad'] as String),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final updated = await _showEditStudentDialog(
                              context,
                              student['ad_soyad'] as String,
                              student['numara'] as int,
                            );
                            if (updated != null) {
                              await state.db.updateStudent(
                                studentId: student['id'] as int,
                                number: updated['number']!,
                                name: updated['name']!,
                              );
                              setState(() {});
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await state.db.deleteStudent(
                              student['id'] as int,
                            );
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScoresSection(
    AppState state,
    AppLocalizations strings, {
    required String type,
    required String titleLabel,
    required String clearLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final name = await _showColumnTitleDialog(
                    context,
                    title: strings.t('addColumn'),
                    label: titleLabel,
                  );
                  if (name == null) return;
                  await state.db.insertScoreColumn(
                    classId: widget.classId,
                    name: name,
                    type: type,
                  );
                  setState(() {});
                },
                icon: const Icon(Icons.add),
                label: Text(strings.t('addColumn')),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await _showClearTypeScoresDialog(
                    context,
                    clearLabel,
                  );
                  if (confirmed != true) return;
                  await state.db.clearStudentScoresForType(
                    classId: widget.classId,
                    type: type,
                  );
                  setState(() {});
                },
                icon: const Icon(Icons.delete_sweep),
                label: Text(clearLabel),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<Map<String, Object?>>>(
            future: state.db.getStudents(widget.classId),
            builder: (context, snapshot) {
              final students = snapshot.data ?? [];
              return FutureBuilder<List<Map<String, Object?>>>(
                future: state.db.getScoreColumns(widget.classId),
                builder: (context, colSnap) {
                  final columns = (colSnap.data ?? [])
                      .where((col) => col['tur'] == type)
                      .toList();
                  return FutureBuilder<List<Map<String, Object?>>>(
                    future: state.db.getStudentScores(widget.classId),
                    builder: (context, scoreSnap) {
                      final scores = scoreSnap.data ?? [];
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text(strings.t('studentNumber'))),
                            DataColumn(label: Text(strings.t('studentName'))),
                            ...columns.map(
                              (col) => DataColumn(
                                label: Row(
                                  children: [
                                    Text(col['ad'] as String),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 16),
                                      onPressed: () async {
                                        final updated =
                                            await _showColumnTitleDialog(
                                          context,
                                          title: strings.t('edit'),
                                          label: titleLabel,
                                          initialName: col['ad'] as String,
                                        );
                                        if (updated != null) {
                                          await state.db.updateScoreColumn(
                                            columnId: col['id'] as int,
                                            name: updated,
                                            type: col['tur'] as String,
                                          );
                                          setState(() {});
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 16),
                                      onPressed: () async {
                                        await state.db
                                            .deleteScoreColumn(col['id'] as int);
                                        setState(() {});
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cleaning_services,
                                        size: 16,
                                      ),
                                      onPressed: () async {
                                        final confirmed =
                                            await _showClearColumnScoresDialog(
                                          context,
                                          col['ad'] as String,
                                        );
                                        if (confirmed != true) return;
                                        await state.db
                                            .clearStudentScoresForColumn(
                                          col['id'] as int,
                                        );
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const DataColumn(label: Text('')),
                          ],
                          rows: students.map((student) {
                            final studentId = student['id'] as int;
                            return DataRow(cells: [
                              DataCell(Text('${student['numara']}')),
                              DataCell(Text(student['ad_soyad'] as String)),
                              ...columns.map((col) {
                                final columnId = col['id'] as int;
                                final columnType = col['tur'] as String;
                                final score = scores.firstWhere(
                                  (row) =>
                                      row['ogrenci_id'] == studentId &&
                                      row['kolon_id'] == columnId,
                                  orElse: () => {
                                    'not_deger': null,
                                    'yapildi': null,
                                  },
                                );
                                final scoreValue = score['not_deger'] as int?;
                                final done = (score['yapildi'] as int?) == 1;
                                return DataCell(
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: TextField(
                                          decoration: const InputDecoration(
                                            isDense: true,
                                          ),
                                          controller: TextEditingController(
                                            text: scoreValue?.toString() ?? '',
                                          ),
                                          onSubmitted: (val) {
                                            final number = int.tryParse(val);
                                            if (number == null ||
                                                number < 1 ||
                                                number > 10) {
                                              return;
                                            }
                                            state.db.setStudentScore(
                                              studentId: studentId,
                                              columnId: columnId,
                                              score: number,
                                              done: done ? 1 : 0,
                                            );
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (columnType == 'homework' ||
                                          columnType == 'activity')
                                        Checkbox(
                                          value: done,
                                          onChanged: (value) {
                                            if (value == null) {
                                              return;
                                            }
                                            state.db.setStudentScore(
                                              studentId: studentId,
                                              columnId: columnId,
                                              score: scoreValue,
                                              done: value ? 1 : 0,
                                            );
                                            setState(() {});
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        final updated =
                                            await _showEditStudentDialog(
                                          context,
                                          student['ad_soyad'] as String,
                                          student['numara'] as int,
                                        );
                                        if (updated != null) {
                                          await state.db.updateStudent(
                                            studentId: studentId,
                                            number: updated['number']!,
                                            name: updated['name']!,
                                          );
                                          setState(() {});
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        await state.db.deleteStudent(studentId);
                                        setState(() {});
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cleaning_services),
                                      onPressed: () async {
                                        final confirmed =
                                            await _showClearStudentScoresDialog(
                                          context,
                                          student['ad_soyad'] as String,
                                        );
                                        if (confirmed != true) return;
                                        await state.db
                                            .clearStudentScoresForStudent(
                                          studentId,
                                        );
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<String?> _showColumnTitleDialog(
    BuildContext context, {
    required String title,
    required String label,
    String? initialName,
  }) async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController(text: initialName ?? '');
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.of(context).pop(name);
            },
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
  }


  Future<Map<String, String>?> _showEditClassDialog(
    BuildContext context,
    String currentName,
    String currentYear,
  ) async {
    final strings = AppLocalizations.of(context);
    final nameController = TextEditingController(text: currentName);
    final yearController = TextEditingController(text: currentYear);
    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('edit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: strings.t('studentClassName')),
            ),
            TextField(
              controller: yearController,
              decoration: InputDecoration(labelText: strings.t('academicYear')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final year = yearController.text.trim();
              if (name.isEmpty || year.isEmpty) {
                return;
              }
              Navigator.of(context).pop({'name': name, 'year': year});
            },
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showEditStudentDialog(
    BuildContext context,
    String currentName,
    int currentNumber,
  ) async {
    final strings = AppLocalizations.of(context);
    final nameController = TextEditingController(text: currentName);
    final numberController = TextEditingController(text: '$currentNumber');
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t('edit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: strings.t('studentNumber')),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: strings.t('studentName')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final number = int.tryParse(numberController.text.trim());
              if (name.isEmpty || number == null) {
                return;
              }
              Navigator.of(context).pop({'name': name, 'number': number});
            },
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showClearTypeScoresDialog(
    BuildContext context,
    String title,
  ) async {
    final strings = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(strings.t('clearTypeScoresConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.t('confirm')),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showClearColumnScoresDialog(
    BuildContext context,
    String columnName,
  ) async {
    final strings = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${strings.t('clearColumnScores')} - $columnName'),
        content: Text(strings.t('clearColumnScoresConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.t('confirm')),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showClearStudentScoresDialog(
    BuildContext context,
    String studentName,
  ) async {
    final strings = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${strings.t('clearStudentScores')} - $studentName'),
        content: Text(strings.t('clearStudentScoresConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.t('confirm')),
          ),
        ],
      ),
    );
  }
}

