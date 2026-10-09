import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_student_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/secretary_create_class_dialog.dart';

class SecretarySectionsScreen extends StatefulWidget {
  const SecretarySectionsScreen({super.key});

  @override
  State<SecretarySectionsScreen> createState() =>
      _SecretarySectionsScreenState();
}

class _SecretarySectionsScreenState extends State<SecretarySectionsScreen> {
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
            future: service.listSectionSummaries(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final sections = snapshot.data!;
              if (sections.isEmpty) {
                return Center(child: Text(strings.t('noStudentClasses')));
              }
              return SingleChildScrollView(
                padding: AppSpacing.pagePadding(width),
                child: isPhone
                    ? Column(
                        children: sections
                            .map((s) => _SectionTile(s: s, strings: strings))
                            .toList(),
                      )
                    : AppCard(
                        padding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(
                                label: Text(strings.t('studentClassName')),
                              ),
                              DataColumn(
                                label: Text(strings.t('studentClassSection')),
                              ),
                              DataColumn(
                                label: Text(strings.t('academicYear')),
                              ),
                              DataColumn(
                                label: Text(strings.t('studentCount')),
                              ),
                            ],
                            rows: sections.map((s) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(s.gradeLabel)),
                                  DataCell(Text(s.section)),
                                  DataCell(Text(s.year)),
                                  DataCell(Text('${s.studentCount}')),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.s, required this.strings});

  final SecretarySectionSummary s;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: ListTile(
          title: Text('${s.gradeLabel} ${s.section}'),
          subtitle: Text(s.year),
          trailing: Text(
            '${strings.t('studentCount')}: ${s.studentCount}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
