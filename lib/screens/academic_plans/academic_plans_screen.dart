import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_shell.dart';
import '../app_viewer_screen.dart';
import 'annual_plans_panel.dart';
import 'daily_plans_panel.dart';
import '../../utils/design_academic_calendar_data.dart';
import '../../theme/design_system.dart';
import '../../widgets/design/design_academic_calendar_view.dart';
import '../../widgets/design/design_month_grid_calendar.dart';
import '../../widgets/design/design_surface_card.dart';
import 'weekly_schedule_panel.dart';

class AcademicPlansScreen extends StatefulWidget {
  const AcademicPlansScreen({super.key});

  @override
  State<AcademicPlansScreen> createState() => _AcademicPlansScreenState();
}

class _AcademicPlansScreenState extends State<AcademicPlansScreen> {
  AcademicPlansSidebarSection _section =
      AcademicPlansSidebarSection.weeklySchedule;
  AppState? _appState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyPendingSection();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<AppState>();
    if (_appState != next) {
      _appState?.removeListener(_onAppStateChanged);
      _appState = next;
      _appState!.addListener(_onAppStateChanged);
    }
  }

  @override
  void dispose() {
    _appState?.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() => _applyPendingSection();

  void _applyPendingSection() {
    final state = _appState ?? context.read<AppState>();
    final pending = state.takePendingAcademicPlansSection();
    if (pending != null && pending != _section) {
      setState(() => _section = pending);
    }
  }

  String _title(AppLocalizations strings) {
    return switch (_section) {
      AcademicPlansSidebarSection.weeklySchedule =>
        strings.t('weeklySchedule'),
      AcademicPlansSidebarSection.dailyPlans => strings.t('dailyPlans'),
      AcademicPlansSidebarSection.annualPlans => strings.t('annualPlans'),
      AcademicPlansSidebarSection.documents => strings.t('documents'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AppShell(
      teacherSection: TeacherNavSection.academicPlans,
      academicPlansSection: _section,
      onAcademicPlansSectionChanged: (section) {
        setState(() => _section = section);
      },
      title: strings.t('academicPlans'),
      subtitle: _title(strings),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (_section) {
          AcademicPlansSidebarSection.weeklySchedule => LayoutBuilder(
              builder: (context, _) {
                final width = MediaQuery.sizeOf(context).width;
                if (width < 1024) {
                  return const _TeacherMobileWeeklyCalendar();
                }
                return const WeeklySchedulePanel();
              },
            ),
          AcademicPlansSidebarSection.dailyPlans => const DailyPlansPanel(),
          AcademicPlansSidebarSection.annualPlans => const AnnualPlansPanel(),
          AcademicPlansSidebarSection.documents =>
            const AppViewerScreen(embeddedDocumentsMode: true),
        },
      ),
    );
  }
}

/// Tasarım 06 — öğretmen mobil haftalık program (ay + gün listesi).
class _TeacherMobileWeeklyCalendar extends StatefulWidget {
  const _TeacherMobileWeeklyCalendar();

  @override
  State<_TeacherMobileWeeklyCalendar> createState() =>
      _TeacherMobileWeeklyCalendarState();
}

class _TeacherMobileWeeklyCalendarState
    extends State<_TeacherMobileWeeklyCalendar> {
  DesignAcademicCalendarData? _data;
  bool _loading = true;
  DateTime _selected = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final data = await DesignAcademicCalendarData.load(
      context.read<AppState>().db,
    );
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  int _weekday(DateTime d) {
    final w = d.weekday;
    if (w >= DateTime.monday && w <= DateTime.friday) return w;
    return DateTime.monday;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_loading || _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final data = _data!;
    final lessons = data.dayLessons[_weekday(_selected)] ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignMonthGridCalendar(
          selectedDate: _selected,
          hasEventsOnDate: (d) {
            final w = d.weekday;
            return w >= DateTime.monday &&
                w <= DateTime.friday &&
                (data.dayLessons[w]?.isNotEmpty ?? false);
          },
          onSelected: (d) => setState(() => _selected = d),
        ),
        const SizedBox(height: 16),
        Text(
          strings.t('designSelectedDayEvents'),
          style: DesignSystem.sectionTitle(context),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: lessons.isEmpty
              ? Center(child: Text(strings.t('noEvents')))
              : ListView.separated(
                  itemCount: lessons.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    final times = data.periodTimes[lesson.period];
                    final timeLabel = times != null
                        ? '${times.start} - ${times.end}'
                        : '';
                    return Semantics(
                      label: '${lesson.title}, $timeLabel',
                      child: DesignSurfaceCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: lesson.accent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.event_note,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (timeLabel.isNotEmpty)
                                    Text(
                                      timeLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
