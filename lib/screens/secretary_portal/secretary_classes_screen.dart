import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_student_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/course_form_options.dart';
import '../../widgets/app_card.dart';
import '../../widgets/secretary_create_class_dialog.dart';

class SecretaryClassesScreen extends StatefulWidget {
  const SecretaryClassesScreen({super.key});

  @override
  State<SecretaryClassesScreen> createState() => _SecretaryClassesScreenState();
}

class _SecretaryClassesScreenState extends State<SecretaryClassesScreen> {
  int _reloadToken = 0;

  Future<void> _reload() async {
    setState(() => _reloadToken++);
  }

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
    final isPhone = width < AppSpacing.phoneBreakpoint;
    final canCreate = auth.canCreateStudent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canCreate)
          Padding(
            padding: AppSpacing.pagePadding(width).copyWith(bottom: 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => _addClass(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(strings.t('createNewClass')),
              ),
            ),
          ),
        Expanded(
          child: FutureBuilder(
            key: ValueKey(_reloadToken),
            future: service.listGradeSummaries(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final grades = snapshot.data!;
              if (grades.isEmpty) {
                return Center(
                  child: Padding(
                    padding: AppSpacing.pagePadding(width),
                    child: Text(strings.t('noStudentClasses')),
                  ),
                );
              }
              return SingleChildScrollView(
                padding: AppSpacing.pagePadding(width),
                child: isPhone
                    ? Column(
                        children: grades
                            .map((g) => _GradeCard(g: g, strings: strings))
                            .toList(),
                      )
                    : Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: grades
                            .map(
                              (g) => SizedBox(
                                width: 280,
                                child: _GradeCard(g: g, strings: strings),
                              ),
                            )
                            .toList(),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.g, required this.strings});

  final SecretaryGradeSummary g;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CourseFormOptions.gradeLabel(g.grade),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          StatCard(
            label: strings.t('secretarySectionCount'),
            value: '${g.sectionCount}',
            icon: Icons.view_module_outlined,
          ),
          const SizedBox(height: 8),
          StatCard(
            label: strings.t('studentCount'),
            value: '${g.studentCount}',
            icon: Icons.people_outline,
          ),
        ],
      ),
    );
  }
}
