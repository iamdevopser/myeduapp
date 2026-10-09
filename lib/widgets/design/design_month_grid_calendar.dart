import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/design_system.dart';
import 'design_surface_card.dart';

/// Tasarım 09 — tam ay ızgarası + gün seçimi (06/09 ortak).
class DesignMonthGridCalendar extends StatefulWidget {
  const DesignMonthGridCalendar({
    super.key,
    this.hasEventsOnWeekday,
    this.hasEventsOnDate,
    this.selectedDate,
    this.onSelected,
  });

  /// [weekday] 1=Mon … 7=Sun — haftalık program günleri için işaret.
  final bool Function(int weekday)? hasEventsOnWeekday;

  /// Tam tarih için etkinlik işareti (sınav vb.).
  final bool Function(DateTime day)? hasEventsOnDate;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onSelected;

  @override
  State<DesignMonthGridCalendar> createState() =>
      _DesignMonthGridCalendarState();
}

class _DesignMonthGridCalendarState extends State<DesignMonthGridCalendar> {
  late DateTime _focusedMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = widget.selectedDate ?? DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  @override
  void didUpdateWidget(covariant DesignMonthGridCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != null &&
        widget.selectedDate != oldWidget.selectedDate) {
      final d = widget.selectedDate!;
      _selected = DateTime(d.year, d.month, d.day);
      _focusedMonth = DateTime(d.year, d.month);
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + delta,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat.yMMMM(locale).format(_focusedMonth);
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final startOffset = first.weekday - DateTime.monday;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    const weekdayLabels = ['Pzt', 'Sa', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return DesignSurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: strings.t('previousMonth'),
                child: IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shiftMonth(-1),
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
                  onPressed: () => _shiftMonth(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final label in weekdayLabels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < rows; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _buildDayCell(
                      context,
                      row: row,
                      col: col,
                      startOffset: startOffset,
                      daysInMonth: daysInMonth,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context, {
    required int row,
    required int col,
    required int startOffset,
    required int daysInMonth,
  }) {
    final index = row * 7 + col;
    if (index < startOffset || index >= startOffset + daysInMonth) {
      return const SizedBox(height: 40);
    }
    final day = index - startOffset + 1;
    final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    final selected = _sameDay(date, _selected);
    final hasEvents = widget.hasEventsOnDate != null
        ? widget.hasEventsOnDate!(date)
        : (widget.hasEventsOnWeekday?.call(date.weekday) ?? false);
    final locale = Localizations.localeOf(context).toString();

    return Semantics(
      button: true,
      selected: selected,
      label: DateFormat.yMMMd(locale).format(date),
      child: InkWell(
        onTap: () {
          setState(() => _selected = date);
          widget.onSelected?.call(date);
        },
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryBlue : null,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? Colors.white : AppColors.navy,
                  ),
                ),
              ),
              if (hasEvents)
                Container(
                  margin: const EdgeInsets.only(top: 2),
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

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
