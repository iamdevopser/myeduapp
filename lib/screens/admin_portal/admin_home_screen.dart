import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/admin_portal_service.dart';
import '../../services/authorization_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_design_tokens.dart';
import '../../theme/design_system.dart';
import '../../utils/admin_navigation.dart';
import '../../utils/design_academic_calendar_data.dart';
import '../../utils/student_announcement_meta.dart';
import '../../widgets/design/design_academic_calendar_view.dart';
import '../../widgets/design/design_mini_month_calendar.dart';
import '../../utils/student_portal_announcement_ui.dart';
import '../../widgets/design/design_feed_row.dart';
import '../../widgets/design/design_grouped_list_card.dart';
import '../../widgets/design/design_page_container.dart';
import '../../widgets/design/design_pill.dart';
import '../../widgets/design/design_stat_card.dart';
import '../../widgets/design/design_surface_card.dart';

/// KPI satırı: içerik genişliği bu değerin altındaysa 2x2, üstündeyse 4'lü.
const double _kpiFourColumnMinWidth = 600;

String _targetLabel(AppLocalizations strings, StudentAnnouncementTargetType t) {
  return switch (t) {
    StudentAnnouncementTargetType.allSchool =>
      strings.t('announcementTargetAllSchool'),
    StudentAnnouncementTargetType.grade => strings.t('announcementTargetGrade'),
    StudentAnnouncementTargetType.section =>
      strings.t('announcementTargetSection'),
  };
}

Color _targetColor(StudentAnnouncementTargetType t) {
  return switch (t) {
    StudentAnnouncementTargetType.allSchool => AppColors.accentGreen,
    StudentAnnouncementTargetType.grade => AppColors.primaryBlue,
    StudentAnnouncementTargetType.section => AppColors.accentPurple,
  };
}

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final auth = AuthorizationService(state);
    if (!auth.canAccessAdminWorkspace || state.sessionAccountId == null) {
      return Center(child: Text(strings.t('adminAccessDenied')));
    }

    final service = AdminPortalService(
      state.db,
      actorAccountId: state.sessionAccountId!,
    );
    final width = context.layoutWidth;
    final isWide = width >= 1024;

    return FutureBuilder<_AdminHomeData>(
      future: _AdminHomeData.load(state, service),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final displayName = data.displayName.isEmpty
            ? strings.t('homeRoleAdminTitle')
            : data.displayName;

        final kpiRow = LayoutBuilder(
          builder: (context, constraints) {
            // 2x2 dar içerikte, 4'lü satır yeterli genişlikte (taşma yok).
            final cross = constraints.maxWidth >= _kpiFourColumnMinWidth ? 4 : 2;
            const gap = AppSpacing.md;
            final tileW = (constraints.maxWidth - gap * (cross - 1)) / cross;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: tileW,
                  child: DesignStatCard(
                    label: strings.t('secretaryTotalStudents'),
                    value: '${data.stats.studentCount}',
                    icon: Icons.school_outlined,
                    tint: AppColors.accentGreen,
                  ),
                ),
                SizedBox(
                  width: tileW,
                  child: DesignStatCard(
                    label: strings.t('parentPortalChildren'),
                    value: '${data.stats.parentGuardianCount}',
                    icon: Icons.family_restroom_outlined,
                    tint: AppColors.brandPrimary,
                  ),
                ),
                SizedBox(
                  width: tileW,
                  child: DesignStatCard(
                    label: strings.t('adminRecentAnnouncements'),
                    value: '${data.announcements.length}',
                    icon: Icons.campaign_outlined,
                    tint: AppColors.warning,
                  ),
                ),
                SizedBox(
                  width: tileW,
                  child: DesignStatCard(
                    label: strings.t('adminUpcomingEvents'),
                    value: '${data.todayLessons.length}',
                    icon: Icons.event_outlined,
                    tint: AppColors.accentPurple,
                  ),
                ),
              ],
            );
          },
        );

        final announcementsCard = DesignSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesignSectionHeader(
                title: strings.t('adminRecentAnnouncements'),
              ),
              const SizedBox(height: AppSpacing.md),
              if (data.announcements.isEmpty)
                Text(
                  strings.t('teacherAnnouncementsEmpty'),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                DesignGroupedListCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  children: [
                    for (var i = 0; i < data.announcements.take(5).length; i++)
                      Builder(
                        builder: (context) {
                          final row = data.announcements.take(5).elementAt(i);
                          final preview = announcementBodyPreview(
                            row['icerik'] as String? ?? '',
                          );
                          final date =
                              (row['yayin_tarihi'] as String?)?.split('T').first ??
                                  (row['olusturma_tarihi'] as String?)
                                      ?.split('T')
                                      .first ??
                                  '';
                          final target = StudentAnnouncementTargetTypeDb.fromDb(
                            row['hedef_tur'] as String?,
                          );
                          final targetLabel = _targetLabel(strings, target);
                          final title = row['baslik'] as String? ?? '';
                          return DesignFeedRow(
                            title: title,
                            subtitle: preview,
                            dateLabel: announcementShortDate(date),
                            icon: Icons.campaign_outlined,
                            iconBackground: announcementFeedAccent(i),
                            semanticsLabel: '$title, $targetLabel',
                            badge: DesignPill(
                              label: targetLabel,
                              color: _targetColor(target),
                            ),
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
        );

        final eventsCard = DesignSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesignSectionHeader(title: strings.t('adminUpcomingEvents')),
              const SizedBox(height: AppSpacing.md),
              if (data.todayLessons.isEmpty)
                Text(strings.t('noEvents'))
              else
                for (final lesson in data.todayLessons.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 36,
                          decoration: BoxDecoration(
                            color: lesson.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (lesson.subtitle.isNotEmpty)
                                Text(
                                  lesson.subtitle,
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        );

        return DesignPageContainer(
          maxWidth: AppSpacing.contentMaxWidth,
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  strings
                      .t('adminWelcomeNamed')
                      .replaceAll('{name}', displayName),
                  style: DesignSystem.pageTitle(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                strings.t('adminTodaySummary'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.tokens.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              kpiRow,
              const SizedBox(height: AppSpacing.xl),
              if (isWide)
                // Yaklaşık 2:1 (duyurular : takvim + etkinlikler).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: announcementsCard),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        children: [
                          const DesignMiniMonthCalendar(),
                          const SizedBox(height: AppSpacing.lg),
                          eventsCard,
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                announcementsCard,
                const SizedBox(height: AppSpacing.lg),
                const DesignMiniMonthCalendar(),
                const SizedBox(height: AppSpacing.lg),
                eventsCard,
              ],
              const SizedBox(height: AppSpacing.lg),
              DesignSurfaceCard(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.people_outline, size: 18),
                      label: Text(strings.t('adminUsersMenu')),
                      onPressed: () => navigateAdminSection(
                        context,
                        AdminNavSection.users,
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.person_add_alt_1, size: 18),
                      label: Text(strings.t('adminUserAdd')),
                      onPressed: () => navigateAdminSection(
                        context,
                        AdminNavSection.userAdd,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminHomeData {
  _AdminHomeData({
    required this.stats,
    required this.displayName,
    required this.announcements,
    required this.todayLessons,
  });

  final AdminDashboardStats stats;
  final String displayName;
  final List<Map<String, Object?>> announcements;
  final List<DesignCalendarLesson> todayLessons;

  static Future<_AdminHomeData> load(
    AppState state,
    AdminPortalService service,
  ) async {
    final stats = await service.loadDashboardStats();
    final account = await state.db.getAccountById(state.sessionAccountId!);
    final displayName = account?['gorunen_ad'] as String? ??
        account?['kullanici_adi'] as String? ??
        '';
    final announcements = await state.db.listAnnouncementsForSecretary();
    final calendar = await DesignAcademicCalendarData.load(state.db);
    final today = DateTime.now().weekday;
    final lessons = calendar.dayLessons[today] ?? [];
    return _AdminHomeData(
      stats: stats,
      displayName: displayName.trim(),
      announcements: announcements.take(8).toList(),
      todayLessons: lessons,
    );
  }
}

