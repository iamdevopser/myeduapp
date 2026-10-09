import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_system.dart';
import 'design_surface_card.dart';

/// Tasarım 06 — ay başlığı, gün şeridi, günlük ders zaman çizelgesi.
class DesignAcademicCalendarView extends StatefulWidget {
  const DesignAcademicCalendarView({
    super.key,
    required this.dayLessons,
    this.periodTimes,
  });

  /// [dayOfWeek] 1=Mon … 5=Fri → lessons sorted by period.
  final Map<int, List<DesignCalendarLesson>> dayLessons;

  /// period index 1-based → (start, end) time labels.
  final Map<int, ({String start, String end})>? periodTimes;

  @override
  State<DesignAcademicCalendarView> createState() =>
      _DesignAcademicCalendarViewState();
}

class DesignCalendarLesson {
  const DesignCalendarLesson({
    required this.title,
    required this.subtitle,
    required this.period,
    this.accent = AppColors.primaryBlue,
  });

  final String title;
  final String subtitle;
  final int period;
  final Color accent;
}

class _DesignAcademicCalendarViewState extends State<DesignAcademicCalendarView> {
  late DateTime _focused;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focused = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  int _schoolDayIndex(DateTime date) {
    final w = date.weekday;
    if (w >= DateTime.monday && w <= DateTime.friday) return w;
    return DateTime.monday;
  }

  List<DateTime> _weekDays() {
    final start = _selected.subtract(
      Duration(days: _selected.weekday - DateTime.monday),
    );
    return List.generate(
      5,
      (i) => start.add(Duration(days: i)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat.yMMMM(locale).format(_focused);
    final weekDays = _weekDays();
    final dayIndex = _schoolDayIndex(_selected);
    final lessons = widget.dayLessons[dayIndex] ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignSurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: strings.t('previousMonth'),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _focused = DateTime(
                            _focused.year,
                            _focused.month - 1,
                          );
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: DesignSystem.sectionTitle(context),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: strings.t('nextMonth'),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _focused = DateTime(
                            _focused.year,
                            _focused.month + 1,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final day in weekDays)
                    Expanded(
                      child: _DayChip(
                        date: day,
                        selected: _sameDay(day, _selected),
                        hasEvents: (widget.dayLessons[_schoolDayIndex(day)]
                                    ?.isNotEmpty ??
                                false),
                        onTap: () => setState(() => _selected = day),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: lessons.isEmpty
              ? Center(
                  child: Text(
                    strings.t('noEvents'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: lessons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    final times = widget.periodTimes?[lesson.period];
                    final timeLabel = times != null
                        ? '${times.start} - ${times.end}'
                        : '';
                    return _TimelineLessonCard(
                      lesson: lesson,
                      timeLabel: timeLabel,
                    );
                  },
                ),
        ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.selected,
    required this.hasEvents,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool hasEvents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dayName = DateFormat.E(locale).format(date);
    return Semantics(
      button: true,
      selected: selected,
      label: DateFormat.yMMMd(locale).format(date),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Text(
                dayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryBlue
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.navy,
                  ),
                ),
              ),
              if (hasEvents)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineLessonCard extends StatelessWidget {
  const _TimelineLessonCard({
    required this.lesson,
    required this.timeLabel,
  });

  final DesignCalendarLesson lesson;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return DesignSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: lesson.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.menu_book_outlined, color: lesson.accent),
              ),
              Container(
                width: 2,
                height: 24,
                color: lesson.accent.withValues(alpha: 0.35),
              ),
            ],
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
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (timeLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    timeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                ],
                if (lesson.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    lesson.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
