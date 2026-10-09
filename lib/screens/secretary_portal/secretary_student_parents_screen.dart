import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/parent_guardian_model.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_parent_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/parent_relation_labels.dart';
import '../../utils/secretary_navigation.dart';
import '../../widgets/app_card.dart';
import '../../widgets/parent_guardian_form_dialog.dart';

class SecretaryStudentParentsScreen extends StatefulWidget {
  const SecretaryStudentParentsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SecretaryStudentParentsScreen> createState() =>
      _SecretaryStudentParentsScreenState();
}

class _SecretaryStudentParentsScreenState
    extends State<SecretaryStudentParentsScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final studentId = state.secretaryFocusStudentId;
    final auth = AuthorizationService(state);
    if (!auth.canManageStudentParentRelation || studentId == null) {
      return Center(child: Text(strings.t('secretaryAccessDenied')));
    }
    final service = SecretaryParentService(state.db);
    final width = MediaQuery.sizeOf(context).width;

    return FutureBuilder(
      key: ValueKey('stu-parents-$studentId-$_reload'),
      future: Future.wait([
        state.db.getStudentById(studentId),
        service.parentsForStudent(studentId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final student = snapshot.data![0] as Map<String, Object?>?;
        final links = snapshot.data![1] as List<StudentParentLink>;
        final studentName = student?['ad_soyad'] as String? ?? '';

        return SingleChildScrollView(
          padding: widget.embedded
              ? EdgeInsets.zero
              : AppSpacing.pagePadding(width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$studentName — ${strings.t('secretaryStudentParents')}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _linkParent(context, studentId, service),
                      icon: const Icon(Icons.add),
                      label: Text(strings.t('secretaryLinkParent')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (links.isEmpty)
                AppCard(child: Text(strings.t('secretaryNoParentsForStudent')))
              else
                ...links.map(
                  (link) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      onTap: () =>
                          openSecretaryParentDetail(context, link.parentId),
                      child: ListTile(
                        title: Text(link.parentName),
                        subtitle: Text(
                          '${link.relation.label(strings)}\n'
                          '${link.parentPhone ?? '—'} · ${link.parentEmail ?? '—'}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.link_off_outlined),
                          onPressed: () async {
                            await service.unlink(link.linkId);
                            if (mounted) setState(() => _reload++);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _linkParent(
    BuildContext context,
    int studentId,
    SecretaryParentService service,
  ) async {
    final strings = AppLocalizations.of(context);
    final parents = await service.listParents();
    if (!context.mounted) return;

    var relation = ParentRelationType.anne;
    int? selectedParentId = parents.isNotEmpty ? parents.first.id : null;

    final linked = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(strings.t('secretaryLinkParent')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (parents.isEmpty)
                    Text(strings.t('secretaryParentNotFound'))
                  else
                    DropdownButtonFormField<int>(
                      value: selectedParentId,
                      decoration: InputDecoration(
                        labelText: strings.t('secretarySelectParent'),
                      ),
                      items: parents
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.fullName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() => selectedParentId = v),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ParentRelationType>(
                    value: relation,
                    decoration: InputDecoration(
                      labelText: strings.t('parentRelationType'),
                    ),
                    items: ParentRelationType.values
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.label(strings)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => relation = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(strings.t('cancelSimple')),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext, false);
                    final data = await showParentGuardianFormDialog(
                      context,
                      titleKey: 'secretaryParentAdd',
                    );
                    if (data == null) return;
                    final newId = await service.createParent(
                      fullName: data.fullName,
                      phone: data.phone,
                      email: data.email,
                      address: data.address,
                      notes: data.notes,
                    );
                    try {
                      await service.linkToStudent(
                        studentId: studentId,
                        parentId: newId,
                        relation: ParentRelationType.diger,
                      );
                      if (mounted) setState(() => _reload++);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              strings.t('secretaryLinkParentFailed'),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(strings.t('secretaryParentAddNew')),
                ),
                FilledButton(
                  onPressed: selectedParentId == null
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: Text(strings.t('save')),
                ),
              ],
            );
          },
        );
      },
    );

    if (linked != true || selectedParentId == null) return;
    try {
      await service.linkToStudent(
        studentId: studentId,
        parentId: selectedParentId!,
        relation: relation,
      );
      if (mounted) setState(() => _reload++);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t('secretaryLinkParentFailed'))),
        );
      }
    }
  }
}
