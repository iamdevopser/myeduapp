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

class SecretaryParentDetailScreen extends StatefulWidget {
  const SecretaryParentDetailScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SecretaryParentDetailScreen> createState() =>
      _SecretaryParentDetailScreenState();
}

class _SecretaryParentDetailScreenState
    extends State<SecretaryParentDetailScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final parentId = state.secretaryFocusParentId;
    final auth = AuthorizationService(state);
    if (!auth.canViewParents || parentId == null) {
      return Center(child: Text(strings.t('secretaryParentNotFound')));
    }
    final service = SecretaryParentService(state.db);
    final width = MediaQuery.sizeOf(context).width;

    return FutureBuilder(
      key: ValueKey('parent-detail-$parentId-$_reload'),
      future: Future.wait([
        service.getParent(parentId),
        service.studentsForParent(parentId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final parent = snapshot.data![0] as ParentGuardian?;
        final links = snapshot.data![1] as List<StudentParentLink>;
        if (parent == null) {
          return Center(child: Text(strings.t('secretaryParentNotFound')));
        }
        return SingleChildScrollView(
          padding: widget.embedded
              ? EdgeInsets.zero
              : AppSpacing.pagePadding(width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('${strings.t('parentPhone')}: ${parent.phone ?? '—'}'),
                    Text('${strings.t('parentEmail')}: ${parent.email ?? '—'}'),
                    if (parent.address != null && parent.address!.isNotEmpty)
                      Text('${strings.t('parentAddress')}: ${parent.address}'),
                    const SizedBox(height: 12),
                    if (auth.canEditParent)
                      FilledButton.icon(
                        onPressed: () async {
                          final data = await showParentGuardianFormDialog(
                            context,
                            titleKey: 'secretaryParentEdit',
                            initial: ParentGuardianFormData(
                              fullName: parent.fullName,
                              phone: parent.phone,
                              email: parent.email,
                              address: parent.address,
                              notes: parent.notes,
                            ),
                          );
                          if (data == null) return;
                          await service.updateParent(
                            id: parentId,
                            fullName: data.fullName,
                            phone: data.phone,
                            email: data.email,
                            address: data.address,
                            notes: data.notes,
                          );
                          if (mounted) setState(() => _reload++);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(strings.t('secretaryParentEdit')),
                      ),
                    if (auth.canEditParent && links.isEmpty)
                      TextButton(
                        onPressed: () async {
                          final ok = await service.tryDeleteParent(parentId);
                          if (!context.mounted) return;
                          if (ok) {
                            navigateSecretarySection(
                              context,
                              SecretaryNavSection.parentList,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  strings.t('secretaryParentDeleteBlocked'),
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(strings.t('delete')),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.t('secretaryLinkedStudents'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (links.isEmpty)
                AppCard(child: Text(strings.t('secretaryNoLinkedStudents')))
              else
                ...links.map(
                  (link) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: ListTile(
                        title: Text(link.studentName ?? ''),
                        subtitle: Text(
                          '${link.classLabel ?? ''} · ${link.relation.label(strings)}',
                        ),
                        trailing: auth.canManageStudentParentRelation
                            ? IconButton(
                                icon: const Icon(Icons.link_off_outlined),
                                onPressed: () async {
                                  await service.unlink(link.linkId);
                                  if (mounted) setState(() => _reload++);
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              if (links.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    strings.t('secretaryParentDeleteBlocked'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
