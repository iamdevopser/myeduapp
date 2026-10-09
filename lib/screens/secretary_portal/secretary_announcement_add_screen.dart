import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_announcement_service.dart';
import '../../services/secretary_student_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/course_form_options.dart';
import '../../utils/secretary_navigation.dart';
import '../../utils/student_announcement_meta.dart';
import '../../widgets/app_card.dart';

class SecretaryAnnouncementAddScreen extends StatefulWidget {
  const SecretaryAnnouncementAddScreen({super.key});

  @override
  State<SecretaryAnnouncementAddScreen> createState() =>
      _SecretaryAnnouncementAddScreenState();
}

class _SecretaryAnnouncementAddScreenState
    extends State<SecretaryAnnouncementAddScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  StudentAnnouncementTargetType _targetType =
      StudentAnnouncementTargetType.allSchool;
  int? _classId;
  int? _gradeLevel;
  bool _loading = true;
  bool _saving = false;
  int? _editId;
  String? _coverImagePath;
  bool _clearCoverOnSave = false;

  @override
  void initState() {
    super.initState();
    _editId = context.read<AppState>().secretaryFocusAnnouncementId;
    _load();
  }

  Future<void> _load() async {
    if (_editId == null) {
      setState(() => _loading = false);
      return;
    }
    final service = SecretaryAnnouncementService(context.read<AppState>().db);
    final item = await service.getById(_editId!);
    if (item != null && mounted) {
      _titleController.text = item.title;
      _bodyController.text = item.body;
      _targetType = item.targetType;
      _classId = item.classId;
      _gradeLevel = item.targetGradeLevel;
      _coverImagePath = item.coverImagePath;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.path == null) return;
    setState(() {
      _coverImagePath = file.path;
      _clearCoverOnSave = false;
    });
  }

  void _removeCoverImage() {
    setState(() {
      _coverImagePath = null;
      _clearCoverOnSave = true;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save({required bool asDraft}) async {
    final strings = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('announcementValidation'))),
      );
      return;
    }
    if (_targetType == StudentAnnouncementTargetType.grade &&
        _gradeLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('announcementPickGrade'))),
      );
      return;
    }
    if (_targetType == StudentAnnouncementTargetType.section &&
        _classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('announcementPickSection'))),
      );
      return;
    }

    setState(() => _saving = true);
    final service = SecretaryAnnouncementService(context.read<AppState>().db);
    try {
      if (_editId == null) {
        final id = await service.create(
          title: title,
          body: body,
          targetType: _targetType,
          classId: _classId,
          targetGradeLevel: _gradeLevel,
          status: StudentAnnouncementStatus.draft,
          coverImagePath: _coverImagePath,
        );
        if (!asDraft) await service.publish(id);
      } else {
        await service.update(
          id: _editId!,
          title: title,
          body: body,
          targetType: _targetType,
          classId: _classId,
          targetGradeLevel: _gradeLevel,
          coverImagePath: _coverImagePath,
          clearCoverImage: _clearCoverOnSave,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.t('announcementSaved'))));
        navigateSecretarySection(context, SecretaryNavSection.announcementList);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final auth = AuthorizationService(context.watch<AppState>());
    if (!auth.canCreateAnnouncement) {
      return Center(child: Text(strings.t('secretaryAccessDenied')));
    }
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < AppSpacing.phoneBreakpoint;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<Map<String, Object?>>>(
      future: SecretaryStudentService(
        context.read<AppState>().db,
      ).listStudentClasses(),
      builder: (context, snapshot) {
        final classes = snapshot.data ?? [];
        final gradeOptions = <int>{};
        for (final c in classes) {
          gradeOptions.add(CourseFormOptions.resolveGrade(c['ad'] as String?));
        }
        final grades = gradeOptions.toList()..sort();

        return SingleChildScrollView(
          padding: AppSpacing.pagePadding(width),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: strings.t('teacherAnnouncementsTitle'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  minLines: 4,
                  maxLines: 10,
                  decoration: InputDecoration(
                    labelText: strings.t('teacherAnnouncementsBody'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.t('designAnnouncementCoverImage'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickCoverImage,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(strings.t('documentPickFile')),
                    ),
                    if (_coverImagePath != null && _coverImagePath!.isNotEmpty)
                      TextButton(
                        onPressed: _saving ? null : _removeCoverImage,
                        child: Text(strings.t('delete')),
                      ),
                  ],
                ),
                if (_coverImagePath != null && _coverImagePath!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _coverImagePath!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StudentAnnouncementTargetType>(
                  value: _targetType,
                  decoration: InputDecoration(
                    labelText: strings.t('announcementTargetLabel'),
                  ),
                  items: StudentAnnouncementTargetType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(switch (t) {
                            StudentAnnouncementTargetType.allSchool =>
                              strings.t('announcementTargetAllSchool'),
                            StudentAnnouncementTargetType.grade => strings.t(
                              'announcementTargetGrade',
                            ),
                            StudentAnnouncementTargetType.section => strings.t(
                              'announcementTargetSection',
                            ),
                          }),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _targetType = v);
                  },
                ),
                if (_targetType == StudentAnnouncementTargetType.grade) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: _gradeLevel,
                    decoration: InputDecoration(
                      labelText: strings.t('studentClassName'),
                    ),
                    items: grades
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(CourseFormOptions.gradeLabel(g)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _gradeLevel = v),
                  ),
                ],
                if (_targetType == StudentAnnouncementTargetType.section) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: isPhone ? double.infinity : 320,
                    child: DropdownButtonFormField<int?>(
                      value: _classId,
                      decoration: InputDecoration(
                        labelText: strings.t('studentClassSection'),
                      ),
                      items: classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c['id'] as int,
                              child: Text(
                                '${CourseFormOptions.resolveGrade(c['ad'] as String?)} '
                                '${CourseFormOptions.resolveSection(c['sube'] as String?)}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _classId = v),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _saving ? null : () => _save(asDraft: true),
                      child: Text(strings.t('announcementSaveDraft')),
                    ),
                    if (_editId == null)
                      FilledButton.tonal(
                        onPressed: _saving ? null : () => _save(asDraft: false),
                        child: Text(strings.t('announcementPublish')),
                      ),
                    if (auth.canEditAnnouncement && _editId != null)
                      FilledButton.tonal(
                        onPressed: _saving ? null : () => _save(asDraft: true),
                        child: Text(strings.t('save')),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
