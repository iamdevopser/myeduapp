import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/secretary_student_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_system.dart';
import '../../utils/secretary_navigation.dart';
import '../../widgets/design/design_hub_tile.dart';
import '../../widgets/design/design_page_container.dart';
import '../../widgets/design/design_surface_card.dart';

/// Tasarım 14 — Sekreter paneli: hub-first düzen (Öğrenci / Veli / Raporlar),
/// özet KPI şeridi ikincil (hub'ların altında).
class SecretaryDashboardScreen extends StatefulWidget {
  const SecretaryDashboardScreen({super.key});

  @override
  State<SecretaryDashboardScreen> createState() =>
      _SecretaryDashboardScreenState();
}

class _SecretaryDashboardScreenState extends State<SecretaryDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fade;
  late final Future<SecretaryDashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = SecretaryStudentService(
      context.read<AppState>().db,
    ).loadDashboardStats();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// 1 sütun (< 600), 2 sütun (tablet), 4 sütun (>= 1024).
  static int _hubColumns(double width) {
    if (width < AppSpacing.phoneBreakpoint) return 1;
    if (width < AppSpacing.desktopBreakpoint) return 2;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final columns = _hubColumns(width);

    return FadeTransition(
      opacity: _fade,
      child: DesignPageContainer(
        maxWidth: AppSpacing.contentMaxWidth,
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                strings.t('secretaryPanelTitle'),
                style: DesignSystem.pageTitle(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _HubSection(
              title: strings.t('secretaryHubStudentOps'),
              columns: columns,
              children: [
                DesignHubTile(
                  title: strings.t('secretaryStudentAdd'),
                  icon: Icons.person_add_outlined,
                  color: AppColors.accentGreen,
                  onTap: () => navigateSecretarySection(
                    context,
                    SecretaryNavSection.studentAdd,
                  ),
                ),
                DesignHubTile(
                  title: strings.t('secretaryStudentList'),
                  icon: Icons.edit_outlined,
                  color: AppColors.accentPurple,
                  onTap: () => navigateSecretarySection(
                    context,
                    SecretaryNavSection.studentList,
                  ),
                ),
                DesignHubTile(
                  title: strings.t('secretaryClassesMenu'),
                  icon: Icons.class_outlined,
                  color: AppColors.primaryBlue,
                  onTap: () => navigateSecretarySection(
                    context,
                    SecretaryNavSection.classesSections,
                  ),
                ),
                DesignHubTile(
                  title: strings.t('secretaryAttendanceDaily'),
                  icon: Icons.today_outlined,
                  color: AppColors.brandPrimary,
                  onTap: () => navigateSecretarySection(
                    context,
                    SecretaryNavSection.attendanceDaily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _HubSection(
              title: strings.t('secretaryHubParentOps'),
              columns: columns,
              children: [
                DesignHubTile(
                  title: strings.t('secretaryParentAdd'),
                  icon: Icons.person_add_alt_1_outlined,
                  color: AppColors.info,
                  onTap: () => navigateSecretarySection(
                    context,
                    SecretaryNavSection.parentAdd,
                  ),
                ),
                DesignHubTile(
                  title: strings.t('secretaryParentEdit'),
                  icon: Icons.edit_outlined,
                  color: AppColors.accentPurple,
                  onTap: () => navigateSecretarySection(
                    context,
                    SecretaryNavSection.parentList,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _HubSection(
              title: strings.t('secretaryHubReports'),
              columns: columns,
              children: [
                DesignHubTile(
                  title: strings.t('secretaryAttendanceReportsModule'),
                  icon: Icons.description_outlined,
                  color: AppColors.primaryBlue,
                  onTap: () => navigateSecretarySection(
                    context,
                    SecretaryNavSection.attendanceReports,
                  ),
                ),
                DesignHubTile(
                  title: strings.t('secretaryAnnouncementList'),
                  icon: Icons.campaign_outlined,
                  color: AppColors.brandPrimary,
                  onTap: () => navigateSecretarySection(
                    context,
                    SecretaryNavSection.announcementList,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _OverviewStrip(statsFuture: _statsFuture),
          ],
        ),
      ),
    );
  }
}

/// Başlık + sabit sütun sayılı hub grid'i (tüm kutular aynı genişlik/yükseklik).
class _HubSection extends StatelessWidget {
  const _HubSection({
    required this.title,
    required this.columns,
    required this.children,
  });

  final String title;
  final int columns;
  final List<Widget> children;

  static const double _gap = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignSectionHeader(title: title),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth =
                (constraints.maxWidth - _gap * (columns - 1)) / columns;
            return Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                for (final child in children)
                  SizedBox(width: tileWidth, child: child),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// İkincil özet şeridi: mevcut `loadDashboardStats` verisi, kompakt.
class _OverviewStrip extends StatelessWidget {
  const _OverviewStrip({required this.statsFuture});

  final Future<SecretaryDashboardStats> statsFuture;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return FutureBuilder<SecretaryDashboardStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        if (stats == null) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final dateLabel = MaterialLocalizations.of(
          context,
        ).formatFullDate(stats.today);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesignSectionHeader(title: strings.t('secretaryHubOverview')),
            const SizedBox(height: AppSpacing.md),
            DesignSurfaceCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.md,
                children: [
                  _OverviewItem(
                    label: strings.t('secretaryTotalStudents'),
                    value: '${stats.studentCount}',
                    icon: Icons.people_outline,
                    color: AppColors.brandPrimary,
                  ),
                  _OverviewItem(
                    label: strings.t('secretaryTotalClassSections'),
                    value: '${stats.classSectionCount}',
                    icon: Icons.class_outlined,
                    color: AppColors.primaryBlue,
                  ),
                  _OverviewItem(
                    label: strings.t('secretaryTodayDate'),
                    value: dateLabel,
                    icon: Icons.calendar_today_outlined,
                    color: AppColors.info,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
