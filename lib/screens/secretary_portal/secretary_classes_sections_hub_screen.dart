import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_student_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/course_form_options.dart';
import '../../widgets/secretary_create_class_dialog.dart';
import 'secretary_ui/secretary_design.dart';

class SecretaryClassesSectionsHubScreen extends StatefulWidget {
  const SecretaryClassesSectionsHubScreen({super.key});

  @override
  State<SecretaryClassesSectionsHubScreen> createState() =>
      _SecretaryClassesSectionsHubScreenState();
}

class _SecretaryClassesSectionsHubScreenState
    extends State<SecretaryClassesSectionsHubScreen> {
  int _reloadToken = 0;
  final Set<int> _expandedGrades = {};

  Future<void> _reload() async => setState(() => _reloadToken++);

  Future<void> _addClass(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final service = SecretaryStudentService(context.read<AppState>().db);
    final created = await showSecretaryCreateClassDialog(
      context: context,
      service: service,
      strings: strings,
    );
    if (created) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final auth = AuthorizationService(context.watch<AppState>());
    if (!auth.canViewClasses) {
      return Center(child: Text(strings.t('secretaryAccessDenied')));
    }
    final service = SecretaryStudentService(context.read<AppState>().db);
    final width = MediaQuery.sizeOf(context).width;
    final padding = AppSpacing.pagePadding(width);

    return FutureBuilder(
      key: ValueKey(_reloadToken),
      future: Future.wait([
        service.listGradeSummaries(),
        service.listSectionSummaries(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final grades = snapshot.data![0] as List<SecretaryGradeSummary>;
        final sections = snapshot.data![1] as List<SecretarySectionSummary>;
        final byGrade = <int, List<SecretarySectionSummary>>{};
        for (final s in sections) {
          final grade =
              CourseFormOptions.parseGradeFromName(s.gradeLabel) ??
              CourseFormOptions.resolveGrade(s.gradeLabel);
          byGrade.putIfAbsent(grade, () => []).add(s);
        }

        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auth.canCreateStudent)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: SecretaryDesign.primary,
                    ),
                    onPressed: () => _addClass(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(strings.t('createNewClass')),
                  ),
                ),
              const SizedBox(height: 16),
              if (grades.isEmpty)
                SecretaryGlassCard(
                  blur: false,
                  child: Text(strings.t('noStudentClasses')),
                )
              else
                ...grades.map((g) {
                  final expanded = _expandedGrades.contains(g.grade);
                  final children = byGrade[g.grade] ?? [];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SecretaryGlassCard(
                      blur: false,
                      onTap: () {
                        setState(() {
                          if (expanded) {
                            _expandedGrades.remove(g.grade);
                          } else {
                            _expandedGrades.add(g.grade);
                          }
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  CourseFormOptions.gradeLabel(g.grade),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              SecretaryStatusBadge(
                                label:
                                    '${g.sectionCount} ${strings.t('secretarySectionCount')}',
                                tone: SecretaryBadgeTone.info,
                              ),
                              const SizedBox(width: 8),
                              SecretaryStatusBadge(
                                label: '${g.studentCount}',
                                tone: SecretaryBadgeTone.success,
                              ),
                              Icon(
                                expanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                            ],
                          ),
                          if (expanded && children.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            ...children.map(
                              (s) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${strings.t('studentClassSection')} ${s.section}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                    ),
                                    Text(
                                      s.year,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '${strings.t('studentCount')}: ${s.studentCount}',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
