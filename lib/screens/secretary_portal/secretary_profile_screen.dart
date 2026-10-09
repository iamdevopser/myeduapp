import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/secretary_student_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/app_navigation.dart';
import 'secretary_ui/secretary_design.dart';

class SecretaryProfileScreen extends StatefulWidget {
  const SecretaryProfileScreen({super.key});

  @override
  State<SecretaryProfileScreen> createState() => _SecretaryProfileScreenState();
}

class _SecretaryProfileScreenState extends State<SecretaryProfileScreen> {
  bool _emailNotifications = true;
  bool _inAppNotifications = true;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppSpacing.desktopBreakpoint;
    final service = SecretaryStudentService(state.db);

    return FutureBuilder(
      future: Future.wait([
        _resolveDisplayName(state, strings),
        service.loadDashboardStats(),
      ]),
      builder: (context, snapshot) {
        final displayName = snapshot.hasData
            ? snapshot.data![0] as String
            : strings.t('adminRoleSecretary');
        final stats = snapshot.hasData
            ? snapshot.data![1] as SecretaryDashboardStats
            : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _ProfileMainCard(
                        strings: strings,
                        displayName: displayName,
                        stats: stats,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: _ProfileActionsColumn(
                        strings: strings,
                        state: state,
                        emailNotifications: _emailNotifications,
                        inAppNotifications: _inAppNotifications,
                        onEmailChanged: (v) =>
                            setState(() => _emailNotifications = v),
                        onInAppChanged: (v) =>
                            setState(() => _inAppNotifications = v),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileMainCard(
                      strings: strings,
                      displayName: displayName,
                      stats: stats,
                    ),
                    const SizedBox(height: 16),
                    _ProfileActionsColumn(
                      strings: strings,
                      state: state,
                      emailNotifications: _emailNotifications,
                      inAppNotifications: _inAppNotifications,
                      onEmailChanged: (v) =>
                          setState(() => _emailNotifications = v),
                      onInAppChanged: (v) =>
                          setState(() => _inAppNotifications = v),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<String> _resolveDisplayName(
    AppState state,
    AppLocalizations strings,
  ) async {
    final accountId = state.sessionAccountId;
    if (accountId != null) {
      final row = await state.db.getAccountById(accountId);
      final name = row?['ad_soyad'] as String?;
      if (name != null && name.trim().isNotEmpty) return name.trim();
      final username = row?['kullanici_adi'] as String?;
      if (username != null && username.trim().isNotEmpty) return username;
    }
    return strings.t('adminRoleSecretary');
  }
}

class _ProfileMainCard extends StatelessWidget {
  const _ProfileMainCard({
    required this.strings,
    required this.displayName,
    required this.stats,
  });

  final AppLocalizations strings;
  final String displayName;
  final SecretaryDashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    return SecretaryGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: SecretaryDesign.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 36,
                  color: SecretaryDesign.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                    const SizedBox(height: 8),
                    SecretaryStatusBadge(
                      label: strings.t('adminRoleSecretary'),
                      tone: SecretaryBadgeTone.info,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            strings.t('secretaryProfileSchoolBranch'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            strings.t('secretaryProfileSchoolBranchHint'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Text(
            strings.t('secretaryProfileActivitySummary'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (stats == null)
            const LinearProgressIndicator(minHeight: 2)
          else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatChip(
                  icon: Icons.people_outline,
                  label: strings.t('secretaryTotalStudents'),
                  value: '${stats!.studentCount}',
                ),
                _StatChip(
                  icon: Icons.class_outlined,
                  label: strings.t('secretaryTotalClassSections'),
                  value: '${stats!.classSectionCount}',
                ),
                _StatChip(
                  icon: Icons.calendar_today_outlined,
                  label: strings.t('secretaryTodayDate'),
                  value: MaterialLocalizations.of(
                    context,
                  ).formatShortDate(stats!.today),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SecretaryDesign.workspaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SecretaryDesign.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: SecretaryDesign.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileActionsColumn extends StatelessWidget {
  const _ProfileActionsColumn({
    required this.strings,
    required this.state,
    required this.emailNotifications,
    required this.inAppNotifications,
    required this.onEmailChanged,
    required this.onInAppChanged,
  });

  final AppLocalizations strings;
  final AppState state;
  final bool emailNotifications;
  final bool inAppNotifications;
  final ValueChanged<bool> onEmailChanged;
  final ValueChanged<bool> onInAppChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SecretaryGlassCard(
          blur: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.t('secretaryProfileSecurity'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.lock_outline,
                  color: SecretaryDesign.primary,
                ),
                title: Text(strings.t('secretaryProfileChangePassword')),
                subtitle: Text(strings.t('secretaryProfileChangePasswordHint')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        strings.t('secretaryProfilePasswordContactAdmin'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SecretaryGlassCard(
          blur: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.t('secretaryProfileNotifications'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                strings.t('secretaryProfileNotificationsHint'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.t('secretaryProfileNotifyInApp')),
                value: inAppNotifications,
                onChanged: onInAppChanged,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.t('secretaryProfileNotifyEmail')),
                value: emailNotifications,
                onChanged: onEmailChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            state.clearSession();
            leaveWorkspaceToLogin(context);
          },
          icon: const Icon(Icons.logout),
          label: Text(strings.t('secretaryProfileEndSession')),
        ),
      ],
    );
  }
}
