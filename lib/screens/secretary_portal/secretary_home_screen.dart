import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/secretary_student_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';

class SecretaryHomeScreen extends StatelessWidget {
  const SecretaryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final service = SecretaryStudentService(context.read<AppState>().db);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < AppSpacing.phoneBreakpoint;

    return FutureBuilder<SecretaryDashboardStats>(
      future: service.loadDashboardStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snapshot.data!;
        final dateLabel = MaterialLocalizations.of(
          context,
        ).formatFullDate(stats.today);

        final cards = [
          StatCard(
            label: strings.t('secretaryTotalStudents'),
            value: '${stats.studentCount}',
            icon: Icons.people_outline,
          ),
          StatCard(
            label: strings.t('secretaryTotalClassSections'),
            value: '${stats.classSectionCount}',
            icon: Icons.class_outlined,
          ),
          StatCard(
            label: strings.t('secretaryTodayDate'),
            value: dateLabel,
            icon: Icons.calendar_today_outlined,
          ),
        ];

        return SingleChildScrollView(
          padding: AppSpacing.pagePadding(width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.t('secretaryPanelTitle'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.t('dashboardWelcome'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isPhone)
                Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      const SizedBox(height: 12),
                    ],
                  ],
                )
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: cards
                      .map((c) => SizedBox(width: 260, child: c))
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
