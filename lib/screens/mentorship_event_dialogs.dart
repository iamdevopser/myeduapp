import 'package:flutter/material.dart';

import '../data/local/app_database.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_navigation.dart';
import '../utils/mentorship_helpers.dart';

Future<void> showMentorshipEventDialog({
  required BuildContext context,
  required AppDatabase db,
  required int classId,
  required List<Map<String, Object?>> students,
  int? initialStudentId,
  DateTime? initialDate,
  VoidCallback? onSaved,
}) async {
  final strings = AppLocalizations.of(context);
  var eventType = MentorshipEventType.individual;
  var status = MentorshipEventStatus.planned;
  var selectedStudentId = initialStudentId;
  var allClass = true;
  final selectedStudentIds = <int>{};
  var selectedDate = initialDate ?? DateTime.now();
  var selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();

  await showAppDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(strings.t('newEvent')),
            content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: eventType,
                      decoration:
                          InputDecoration(labelText: strings.t('eventType')),
                      items: [
                        DropdownMenuItem(
                          value: MentorshipEventType.individual,
                          child: Text(strings.t('individualMeeting')),
                        ),
                        DropdownMenuItem(
                          value: MentorshipEventType.group,
                          child: Text(strings.t('groupEvent')),
                        ),
                        DropdownMenuItem(
                          value: MentorshipEventType.parentMeeting,
                          child: Text(strings.t('parentMeetingEvent')),
                        ),
                        DropdownMenuItem(
                          value: 'behavior',
                          child: Text(strings.t('behaviorReport')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => eventType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    if (eventType == MentorshipEventType.individual)
                      DropdownButtonFormField<int>(
                        initialValue: selectedStudentId,
                        decoration:
                            InputDecoration(labelText: strings.t('studentName')),
                        items: students
                            .map(
                              (row) => DropdownMenuItem(
                                value: row['id'] as int,
                                child: Text(
                                  '${row['numara']} ${row['ad_soyad']}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => selectedStudentId = value),
                      ),
                    if (eventType == MentorshipEventType.group) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.t('allClass')),
                        value: allClass,
                        onChanged: (value) =>
                            setDialogState(() => allClass = value),
                      ),
                      if (!allClass)
                        ...students.map(
                          (row) {
                            final id = row['id'] as int;
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '${row['numara']} ${row['ad_soyad']}',
                              ),
                              value: selectedStudentIds.contains(id),
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    selectedStudentIds.add(id);
                                  } else {
                                    selectedStudentIds.remove(id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                    ],
                    if (eventType == 'behavior')
                      DropdownButtonFormField<int>(
                        initialValue: selectedStudentId,
                        decoration:
                            InputDecoration(labelText: strings.t('studentName')),
                        items: students
                            .map(
                              (row) => DropdownMenuItem(
                                value: row['id'] as int,
                                child: Text(
                                  '${row['numara']} ${row['ad_soyad']}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => selectedStudentId = value),
                      ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppDatabase.scoreDateKey(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(mentorshipTimeLabel(selectedTime)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                    ),
                    if (eventType != 'behavior') ...[
                      TextField(
                        controller: titleCtrl,
                        decoration:
                            InputDecoration(labelText: strings.t('eventTitle')),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionCtrl,
                        decoration: InputDecoration(
                          labelText: strings.t('eventDescription'),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration:
                            InputDecoration(labelText: strings.t('eventStatus')),
                        items: [
                          DropdownMenuItem(
                            value: MentorshipEventStatus.planned,
                            child: Text(strings.t('planned')),
                          ),
                          DropdownMenuItem(
                            value: MentorshipEventStatus.completed,
                            child: Text(strings.t('completed')),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => status = value);
                          }
                        },
                      ),
                    ],
                  ],
                ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(strings.t('cancelSimple')),
              ),
              FilledButton(
                onPressed: () async {
                  if (eventType == 'behavior') {
                    if (selectedStudentId == null) return;
                    Navigator.pop(dialogContext);
                    await showMentorshipBehaviorDialog(
                      context: context,
                      db: db,
                      classId: classId,
                      students: students,
                      initialStudentId: selectedStudentId,
                      initialDate: selectedDate,
                      onSaved: onSaved,
                    );
                    return;
                  }
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  if (eventType == MentorshipEventType.individual &&
                      selectedStudentId == null) {
                    return;
                  }
                  if (eventType == MentorshipEventType.group &&
                      !allClass &&
                      selectedStudentIds.isEmpty) {
                    return;
                  }
                  await db.insertMentorshipEvent(
                    classId: classId,
                    type: eventType,
                    title: title,
                    description: descriptionCtrl.text.trim().isEmpty
                        ? null
                        : descriptionCtrl.text.trim(),
                    date: AppDatabase.scoreDateKey(selectedDate),
                    time: mentorshipTimeLabel(selectedTime),
                    status: status,
                    allClass:
                        eventType == MentorshipEventType.group && allClass,
                    studentIds: eventType == MentorshipEventType.individual
                        ? [selectedStudentId!]
                        : selectedStudentIds.toList(),
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  onSaved?.call();
                },
                child: Text(strings.t('save')),
              ),
            ],
          );
        },
      );
    },
  );

  titleCtrl.dispose();
  descriptionCtrl.dispose();
}

Future<void> showMentorshipBehaviorDialog({
  required BuildContext context,
  required AppDatabase db,
  required int classId,
  required List<Map<String, Object?>> students,
  int? initialStudentId,
  DateTime? initialDate,
  VoidCallback? onSaved,
}) async {
  final strings = AppLocalizations.of(context);
  var selectedStudentId = initialStudentId;
  var behaviorType = MentorshipBehaviorType.positive;
  var selectedDate = initialDate ?? DateTime.now();
  final behaviorCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final levelCtrl = TextEditingController();
  final teacherNoteCtrl = TextEditingController();

  await showAppDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(strings.t('behaviorReport')),
            content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedStudentId,
                      decoration:
                          InputDecoration(labelText: strings.t('studentName')),
                      items: students
                          .map(
                            (row) => DropdownMenuItem(
                              value: row['id'] as int,
                              child: Text(
                                '${row['numara']} ${row['ad_soyad']}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedStudentId = value),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: behaviorType,
                      decoration:
                          InputDecoration(labelText: strings.t('behaviorType')),
                      items: [
                        DropdownMenuItem(
                          value: MentorshipBehaviorType.positive,
                          child: Text(strings.t('positiveBehavior')),
                        ),
                        DropdownMenuItem(
                          value: MentorshipBehaviorType.improvement,
                          child: Text(strings.t('needsImprovement')),
                        ),
                        DropdownMenuItem(
                          value: MentorshipBehaviorType.attention,
                          child: Text(strings.t('needsAttention')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => behaviorType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppDatabase.scoreDateKey(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                    TextField(
                      controller: behaviorCtrl,
                      decoration: InputDecoration(
                        labelText: strings.t('behaviorDescription'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionCtrl,
                      decoration: InputDecoration(
                        labelText: strings.t('observationNote'),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: levelCtrl,
                      decoration: InputDecoration(
                        labelText: strings.t('importanceLevel'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: teacherNoteCtrl,
                      decoration: InputDecoration(
                        labelText: strings.t('teacherNote'),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(strings.t('cancelSimple')),
              ),
              FilledButton(
                onPressed: () async {
                  if (selectedStudentId == null) return;
                  await db.insertMentorshipBehaviorReport(
                    classId: classId,
                    studentId: selectedStudentId!,
                    date: AppDatabase.scoreDateKey(selectedDate),
                    type: behaviorType,
                    behavior: behaviorCtrl.text.trim().isEmpty
                        ? null
                        : behaviorCtrl.text.trim(),
                    description: descriptionCtrl.text.trim().isEmpty
                        ? null
                        : descriptionCtrl.text.trim(),
                    level: levelCtrl.text.trim().isEmpty
                        ? null
                        : levelCtrl.text.trim(),
                    teacherNote: teacherNoteCtrl.text.trim().isEmpty
                        ? null
                        : teacherNoteCtrl.text.trim(),
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  onSaved?.call();
                },
                child: Text(strings.t('save')),
              ),
            ],
          );
        },
      );
    },
  );

  behaviorCtrl.dispose();
  descriptionCtrl.dispose();
  levelCtrl.dispose();
  teacherNoteCtrl.dispose();
}
