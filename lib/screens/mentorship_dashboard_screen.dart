import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/local/app_database.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/course_form_options.dart';
import '../utils/mentorship_helpers.dart';
import '../utils/teacher_navigation.dart';
import '../widgets/app_card.dart';
import '../widgets/app_shell.dart';
import 'mentorship_behavior_reports_screen.dart';
import 'mentorship_class_select_screen.dart';
import 'mentorship_event_dialogs.dart';
import 'mentorship_student_detail_screen.dart';

class MentorshipDashboardScreen extends StatefulWidget {
  const MentorshipDashboardScreen({super.key, required this.classId});

  final int classId;

  @override
  State<MentorshipDashboardScreen> createState() =>
      _MentorshipDashboardScreenState();
}

class _MentorshipDashboardScreenState extends State<MentorshipDashboardScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _listView = false;
  List<Map<String, Object?>> _students = [];
  List<Map<String, Object?>> _events = [];
  List<Map<String, Object?>> _behaviorReports = [];
  Map<String, Object?>? _classRow;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = context.read<AppState>().db;
    final classes = await db.getMentorshipClasses();
    _classRow = null;
    for (final row in classes) {
      if (row['id'] == widget.classId) {
        _classRow = row;
        break;
      }
    }
    _students = await db.getStudents(widget.classId);
    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final monthEnd = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    _events = await db.getMentorshipEvents(
      classId: widget.classId,
      fromDate: AppDatabase.scoreDateKey(monthStart),
      toDate: AppDatabase.scoreDateKey(monthEnd),
    );
    _behaviorReports = await db.getMentorshipBehaviorReports(
      classId: widget.classId,
      limit: 5,
    );
    if (!mounted) return;
    setState(() => _loading = false);
  }

  List<_CalendarItem> _itemsForDay(DateTime day) {
    final key = AppDatabase.scoreDateKey(day);
    final items = <_CalendarItem>[];
    for (final event in _events) {
      if (event['tarih'] == key) {
        items.add(_CalendarItem.fromEvent(event));
      }
    }
    return items;
  }

  List<_CalendarItem> _todayItems() => _itemsForDay(DateTime.now());

  List<_CalendarItem> _upcomingItems() {
    final todayKey = AppDatabase.scoreDateKey(DateTime.now());
    final upcoming = _events
        .where((event) => (event['tarih'] as String).compareTo(todayKey) >= 0)
        .map(_CalendarItem.fromEvent)
        .toList();
    upcoming.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.time.compareTo(b.time);
    });
    return upcoming.take(6).toList();
  }

  void _changeClass() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MentorshipClassSelectScreen(),
      ),
    );
  }

  Future<void> _newEvent() async {
    await showMentorshipEventDialog(
      context: context,
      db: context.read<AppState>().db,
      classId: widget.classId,
      students: _students,
      initialDate: _selectedDay,
      onSaved: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < AppSpacing.phoneBreakpoint;
    final isWide = width >= AppSpacing.desktopBreakpoint;
    final className = _classRow?['ad'] as String? ?? '';
    final studentCount = _classRow?['ogrenci_sayisi'] ?? _students.length;

    return AppShell(
      teacherSection: TeacherNavSection.mentorship,
      title: strings.t('mentorship'),
      subtitle: strings.t('mentorshipDashboardSubtitle'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MentorshipBehaviorReportsScreen(
                  classId: widget.classId,
                ),
              ),
            );
          },
          icon: const Icon(Icons.psychology_outlined, size: 18),
          label: Text(strings.t('viewAllBehaviorReports')),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _newEvent,
          icon: const Icon(Icons.add, size: 18),
          label: Text(strings.t('newEvent')),
        ),
      ],
      child: ColoredBox(
        color: AppColors.background,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.all(isPhone ? AppSpacing.md : AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  className,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${CourseFormOptions.studentClassSubtitle(_classRow?['yil'] as String? ?? '', _classRow?['sube'] as String?)} · ${strings.t('studentCount')}: $studentCount',
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
                          OutlinedButton(
                            onPressed: _changeClass,
                            child: Text(strings.t('changeClass')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _mainContent(strings, isPhone),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  flex: 2,
                                  child: SingleChildScrollView(
                                    child: _sidePanel(strings),
                                  ),
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  _mainContent(strings, isPhone, scrollable: false),
                                  const SizedBox(height: AppSpacing.lg),
                                  _sidePanel(strings),
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

  Widget _mainContent(
    AppLocalizations strings,
    bool isPhone, {
    bool scrollable = true,
  }) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_listView)
          _EventListView(
            strings: strings,
            items: _events.map(_CalendarItem.fromEvent).toList(),
          )
        else
          _MonthCalendar(
            strings: strings,
            focusedMonth: _focusedMonth,
            selectedDay: _selectedDay,
            itemsForDay: _itemsForDay,
            onMonthChanged: (month) {
              setState(() => _focusedMonth = month);
              _load();
            },
            onDaySelected: (day) => setState(() => _selectedDay = day),
            onToday: () => setState(() {
              _focusedMonth = DateTime.now();
              _selectedDay = DateTime.now();
              _load();
            }),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          strings.t('mentorshipStudents'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _studentsList(),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(strings.t('calendarView')),
                  icon: const Icon(Icons.calendar_month, size: 18),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(strings.t('listView')),
                  icon: const Icon(Icons.list, size: 18),
                ),
              ],
              selected: {_listView},
              onSelectionChanged: (value) =>
                  setState(() => _listView = value.first),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (scrollable)
          Expanded(
            child: SingleChildScrollView(child: body),
          )
        else
          body,
      ],
    );
  }

  Widget _studentsList() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _students.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final student = _students[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
              child: const Icon(Icons.person, color: AppColors.primaryBlue),
            ),
            title: Text(student['ad_soyad'] as String),
            subtitle: Text('${student['numara']}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MentorshipStudentDetailScreen(
                    classId: widget.classId,
                    studentId: student['id'] as int,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _sidePanel(AppLocalizations strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelSection(
          title: strings.t('todayEvents'),
          child: _EventListView(strings: strings, items: _todayItems()),
        ),
        const SizedBox(height: AppSpacing.md),
        _PanelSection(
          title: strings.t('upcomingEvents'),
          child: _EventListView(strings: strings, items: _upcomingItems()),
        ),
        const SizedBox(height: AppSpacing.md),
        _PanelSection(
          title: strings.t('recentBehaviorReports'),
          child: _behaviorReports.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    strings.t('noBehaviorReports'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : Column(
                  children: _behaviorReports.map((report) {
                    return ListTile(
                      dense: true,
                      title: Text(report['ad_soyad'] as String),
                      subtitle: Text(
                        '${report['tarih']} · ${mentorshipBehaviorTypeLabel(strings, report['tur'] as String)}',
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _CalendarItem {
  _CalendarItem({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.time,
    required this.status,
  });

  final int id;
  final String type;
  final String title;
  final String date;
  final String time;
  final String status;

  factory _CalendarItem.fromEvent(Map<String, Object?> event) {
    return _CalendarItem(
      id: event['id'] as int,
      type: event['tur'] as String,
      title: event['baslik'] as String,
      date: event['tarih'] as String,
      time: event['saat'] as String,
      status: event['durum'] as String,
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.strings,
    required this.focusedMonth,
    required this.selectedDay,
    required this.itemsForDay,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.onToday,
  });

  final AppLocalizations strings;
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final List<_CalendarItem> Function(DateTime day) itemsForDay;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onToday;

  static const _weekdays = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final cells = <Widget>[];

    for (final label in _weekdays) {
      cells.add(
        Center(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedMonth.year, focusedMonth.month, day);
      final selected = AppDatabase.scoreDateKey(date) ==
          AppDatabase.scoreDateKey(selectedDay);
      final hasEvents = itemsForDay(date).isNotEmpty;
      cells.add(
        InkWell(
          onTap: () => onDaySelected(date),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryBlue
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (hasEvents)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: strings.t('previousMonth'),
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month - 1),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${focusedMonth.month.toString().padLeft(2, '0')}.${focusedMonth.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                tooltip: strings.t('nextMonth'),
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month + 1),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
              TextButton(
                onPressed: onToday,
                child: Text(strings.t('today')),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
          const SizedBox(height: AppSpacing.md),
          _EventListView(
            strings: strings,
            items: itemsForDay(selectedDay),
          ),
        ],
      ),
    );
  }
}

class _EventListView extends StatelessWidget {
  const _EventListView({required this.strings, required this.items});

  final AppLocalizations strings;
  final List<_CalendarItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          strings.t('noEvents'),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      children: items.map((item) {
        return ListTile(
          leading: Icon(mentorshipEventTypeIcon(item.type)),
          title: Text(item.title),
          subtitle: Text(
            '${item.date} ${item.time} · ${mentorshipEventTypeLabel(strings, item.type)} · ${mentorshipStatusLabel(strings, item.status)}',
          ),
        );
      }).toList(),
    );
  }
}

class _PanelSection extends StatelessWidget {
  const _PanelSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
