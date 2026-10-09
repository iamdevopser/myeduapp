import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/course_form_options.dart';
import '../utils/mentorship_helpers.dart';
import '../widgets/app_card.dart';
import '../widgets/app_empty_state.dart';
import 'mentorship_event_dialogs.dart';

class MentorshipStudentDetailScreen extends StatefulWidget {
  const MentorshipStudentDetailScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  final int classId;
  final int studentId;

  @override
  State<MentorshipStudentDetailScreen> createState() =>
      _MentorshipStudentDetailScreenState();
}

class _MentorshipStudentDetailScreenState
    extends State<MentorshipStudentDetailScreen> {
  Map<String, Object?>? _student;
  Map<String, Object?>? _classRow;
  List<Map<String, Object?>> _students = [];
  List<Map<String, Object?>> _events = [];
  List<Map<String, Object?>> _behaviorReports = [];
  List<Map<String, Object?>> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = context.read<AppState>().db;
    final students = await db.getStudents(widget.classId);
    _students = students;
    _student = null;
    for (final row in students) {
      if (row['id'] == widget.studentId) {
        _student = row;
        break;
      }
    }
    final classes = await db.getStudentClasses();
    _classRow = null;
    for (final row in classes) {
      if (row['id'] == widget.classId) {
        _classRow = row;
        break;
      }
    }
    _events = await db.getMentorshipEvents(
      classId: widget.classId,
      studentId: widget.studentId,
    );
    _behaviorReports = await db.getMentorshipBehaviorReports(
      classId: widget.classId,
      studentId: widget.studentId,
    );
    _notes = await db.getMentorshipNotes(
      classId: widget.classId,
      studentId: widget.studentId,
    );
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _addNote() async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('addNote')),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(labelText: strings.t('note')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.t('cancelSimple')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
    if (saved != true || controller.text.trim().isEmpty) {
      controller.dispose();
      return;
    }
    await context.read<AppState>().db.insertMentorshipNote(
      classId: widget.classId,
      studentId: widget.studentId,
      text: controller.text.trim(),
    );
    controller.dispose();
    await _load();
  }

  Future<void> _addEvent() async {
    await showMentorshipEventDialog(
      context: context,
      db: context.read<AppState>().db,
      classId: widget.classId,
      students: _students,
      initialStudentId: widget.studentId,
      onSaved: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isPhone = MediaQuery.sizeOf(context).width < AppSpacing.phoneBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_student?['ad_soyad'] as String? ?? strings.t('studentName')),
        actions: [
          FilledButton.icon(
            onPressed: _addEvent,
            icon: const Icon(Icons.add, size: 18),
            label: Text(strings.t('addEvent')),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(isPhone ? AppSpacing.md : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              AppColors.primaryBlue.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _student?['ad_soyad'] as String? ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                _classRow == null
                                    ? ''
                                    : CourseFormOptions.studentClassLabel(
                                        _classRow!['ad'] as String,
                                        _classRow!['yil'] as String,
                                        section:
                                            _classRow!['sube'] as String?,
                                      ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          TabBar(
                            tabs: [
                              Tab(text: strings.t('eventsTab')),
                              Tab(text: strings.t('behaviorReportsTab')),
                              Tab(text: strings.t('notesTab')),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _eventsTab(strings),
                                _behaviorTab(strings),
                                _notesTab(strings),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _eventsTab(AppLocalizations strings) {
    if (_events.isEmpty) {
      return AppEmptyState(
        icon: Icons.event_outlined,
        title: strings.t('noEvents'),
      );
    }
    return ListView.separated(
      itemCount: _events.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final event = _events[index];
        return AppCard(
          child: ListTile(
            leading: Icon(
              mentorshipEventTypeIcon(event['tur'] as String),
            ),
            title: Text(event['baslik'] as String),
            subtitle: Text(
              '${event['tarih']} ${event['saat']} · ${mentorshipEventTypeLabel(strings, event['tur'] as String)} · ${mentorshipStatusLabel(strings, event['durum'] as String)}',
            ),
          ),
        );
      },
    );
  }

  Widget _behaviorTab(AppLocalizations strings) {
    if (_behaviorReports.isEmpty) {
      return AppEmptyState(
        icon: Icons.psychology_outlined,
        title: strings.t('noBehaviorReports'),
      );
    }
    return ListView.separated(
      itemCount: _behaviorReports.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final report = _behaviorReports[index];
        return AppCard(
          child: ListTile(
            title: Text(
              mentorshipBehaviorTypeLabel(strings, report['tur'] as String),
            ),
            subtitle: Text(
              '${report['tarih']}\n${report['davranis'] ?? ''}\n${report['aciklama'] ?? ''}',
            ),
          ),
        );
      },
    );
  }

  Widget _notesTab(AppLocalizations strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _addNote,
            icon: const Icon(Icons.note_add_outlined, size: 18),
            label: Text(strings.t('addNote')),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: _notes.isEmpty
              ? AppEmptyState(
                  icon: Icons.sticky_note_2_outlined,
                  title: strings.t('noNotes'),
                )
              : ListView.separated(
                  itemCount: _notes.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return AppCard(
                      child: Text(note['metin'] as String),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
