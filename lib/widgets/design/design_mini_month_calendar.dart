import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/design_system.dart';
import 'design_surface_card.dart';

/// Tasarım 02 — sağ kolon mini takvim.
class DesignMiniMonthCalendar extends StatelessWidget {
  const DesignMiniMonthCalendar({
    super.key,
    this.selectedDay,
  });

  final DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    final now = selectedDay ?? DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat.yMMMM(locale).format(now);
    final first = DateTime(now.year, now.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    // Pazartesi ilk sütun (başlıklarla aynı sıra): Pzt=1 -> 0 ... Paz=7 -> 6.
    final startWeekday = first.weekday - 1;
    // 2024-01-01 bir Pazartesi; yerel kısa gün adları.
    final weekdayFormat = DateFormat.E(locale);
    final weekdayLabels = [
      for (var i = 0; i < 7; i++) weekdayFormat.format(DateTime(2024, 1, 1 + i)),
    ];

    return DesignSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(monthLabel, style: DesignSystem.sectionTitle(context)),
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(weekdayLabels[i], style: _weekdayStyle),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox.shrink();
              final day = index - startWeekday + 1;
              final isToday = day == now.day;
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primaryBlue : null,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday ? Colors.white : AppColors.navy,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static const _weekdayStyle = TextStyle(
    fontSize: 11,
    color: Color(0xFF94A3B8),
    fontWeight: FontWeight.w600,
  );
}
