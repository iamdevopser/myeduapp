import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum LessonPlatformTab {
  courses,
  units,
  topics,
  documents,
  content,
}

extension LessonPlatformTabLabels on LessonPlatformTab {
  String label(AppLocalizations strings) {
    return switch (this) {
      LessonPlatformTab.courses => strings.t('courses'),
      LessonPlatformTab.units => strings.t('units'),
      LessonPlatformTab.topics => strings.t('topics'),
      LessonPlatformTab.documents => strings.t('documents'),
      LessonPlatformTab.content => strings.t('contentTab'),
    };
  }
}

List<LessonPlatformTab> tabsForSubjectDetail() => const [
      LessonPlatformTab.courses,
      LessonPlatformTab.units,
      LessonPlatformTab.topics,
      LessonPlatformTab.documents,
    ];

List<LessonPlatformTab> tabsForCourseDetail() => const [
      LessonPlatformTab.units,
      LessonPlatformTab.topics,
      LessonPlatformTab.documents,
    ];

List<LessonPlatformTab> tabsForUnitDetail() => const [
      LessonPlatformTab.topics,
      LessonPlatformTab.documents,
    ];

List<LessonPlatformTab> tabsForTopicDetail() => const [
      LessonPlatformTab.content,
    ];

class LessonPlatformTabBar extends StatelessWidget {
  const LessonPlatformTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<LessonPlatformTab> tabs;
  final LessonPlatformTab selected;
  final ValueChanged<LessonPlatformTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tabs.map((tab) {
              final isSelected = tab == selected;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(tab.label(strings)),
                  selected: isSelected,
                  onSelected: (_) => onSelected(tab),
                  selectedColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
