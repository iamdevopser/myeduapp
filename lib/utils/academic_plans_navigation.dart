import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum AcademicPlansSidebarSection {
  weeklySchedule,
  dailyPlans,
  annualPlans,
  documents,
}

const List<AcademicPlansSidebarSection> academicPlansSidebarMenuOrder =
    <AcademicPlansSidebarSection>[
  AcademicPlansSidebarSection.weeklySchedule,
  AcademicPlansSidebarSection.dailyPlans,
  AcademicPlansSidebarSection.annualPlans,
  AcademicPlansSidebarSection.documents,
];

extension AcademicPlansSidebarSectionLabels on AcademicPlansSidebarSection {
  String label(AppLocalizations strings) {
    return switch (this) {
      AcademicPlansSidebarSection.weeklySchedule =>
        strings.t('weeklySchedule'),
      AcademicPlansSidebarSection.dailyPlans => strings.t('dailyPlans'),
      AcademicPlansSidebarSection.annualPlans => strings.t('annualPlans'),
      AcademicPlansSidebarSection.documents => strings.t('documents'),
    };
  }

  IconData get icon {
    return switch (this) {
      AcademicPlansSidebarSection.weeklySchedule =>
        Icons.calendar_view_week_outlined,
      AcademicPlansSidebarSection.dailyPlans =>
        Icons.today_outlined,
      AcademicPlansSidebarSection.annualPlans =>
        Icons.date_range_outlined,
      AcademicPlansSidebarSection.documents =>
        Icons.insert_drive_file_outlined,
    };
  }
}
