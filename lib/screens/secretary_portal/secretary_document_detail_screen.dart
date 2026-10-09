import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_role.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_document_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/secretary_navigation.dart';
import '../../widgets/app_card.dart';

class SecretaryDocumentDetailScreen extends StatefulWidget {
  const SecretaryDocumentDetailScreen({super.key});

  @override
  State<SecretaryDocumentDetailScreen> createState() =>
      _SecretaryDocumentDetailScreenState();
}

class _SecretaryDocumentDetailScreenState
    extends State<SecretaryDocumentDetailScreen> {
  int _reload = 0;

  SecretaryDocumentService _service(AppState state) =>
      SecretaryDocumentService(state.db, state.fileService);

  Future<void> _tryDelete(
    BuildContext context,
    SecretaryDocument doc,
    AuthorizationService auth,
    AppState state,
  ) async {
    final strings = AppLocalizations.of(context);
    if (doc.critical || !auth.canDeleteCriticalDocument) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            doc.critical
                ? strings.t('documentCriticalDeleteBlocked')
                : strings.t('documentDeleteBlockedSecretary'),
          ),
        ),
      );
      return;
    }
    if (!auth.canPhysicallyDeleteDocument) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('documentDeleteBlockedSecretary'))),
      );
      return;
    }
    final ok = await _service(state).deleteForRole(doc.id, state.currentRole);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('documentDeleteBlockedSecretary'))),
      );
    } else if (context.mounted) {
      navigateSecretarySection(context, SecretaryNavSection.documentList);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final auth = AuthorizationService(state);
    final id = state.secretaryFocusDocumentId;
    if (!auth.canViewDocuments || id == null) {
      return Center(child: Text(strings.t('secretaryAccessDenied')));
    }
    final service = _service(state);
    final width = MediaQuery.sizeOf(context).width;

    return FutureBuilder<SecretaryDocument?>(
      key: ValueKey('doc-detail-$id-$_reload'),
      future: service.getById(id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final doc = snapshot.data;
        if (doc == null) {
          return Center(child: Text(strings.t('documentEmpty')));
        }

        return SingleChildScrollView(
          padding: AppSpacing.pagePadding(width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (doc.critical)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Chip(
                          avatar: const Icon(Icons.lock_outline, size: 18),
                          label: Text(strings.t('documentCriticalLabel')),
                        ),
                      ),
                    Text('${strings.t('documentTypeLabel')}: ${doc.type}'),
                    if (doc.category != null && doc.category!.isNotEmpty)
                      Text(
                        '${strings.t('documentCategoryLabel')}: ${doc.category}',
                      ),
                    if (doc.scope != null && doc.scope!.isNotEmpty)
                      Text('${strings.t('documentScopeLabel')}: ${doc.scope}'),
                    Text(
                      '${strings.t('announcementUpdatedAt')}: '
                      '${doc.updatedAt.toIso8601String().split('T').first}',
                    ),
                    if (doc.archived) Text(strings.t('documentStatusArchived')),
                    if (doc.description != null &&
                        doc.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(doc.description!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (auth.canOpenDocument)
                    FilledButton.icon(
                      onPressed: () async {
                        final ok = await service.openDocument(doc);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.t('documentFileRequired')),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: Text(strings.t('documentOpen')),
                    ),
                  if (auth.canDownloadDocument)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final target = await service.pickSaveCopyPath(doc);
                        if (target == null) return;
                        final ok = await service.copyToPath(doc, target);
                        if (context.mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(strings.t('documentSaved'))),
                          );
                        }
                      },
                      icon: const Icon(Icons.download_outlined),
                      label: Text(strings.t('documentDownload')),
                    ),
                  if (auth.canEditDocument)
                    OutlinedButton.icon(
                      onPressed: () {
                        state.setSecretaryFocusDocument(doc.id);
                        navigateSecretarySection(
                          context,
                          SecretaryNavSection.documentAdd,
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(strings.t('announcementEdit')),
                    ),
                  if (auth.canArchiveDocument && !doc.archived && !doc.critical)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await service.archiveForSecretary(
                          doc.id,
                          AppRole.secretary,
                        );
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                strings.t('documentArchiveBlockedCritical'),
                              ),
                            ),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.t('documentArchivedDone')),
                            ),
                          );
                          setState(() => _reload++);
                        }
                      },
                      icon: const Icon(Icons.archive_outlined),
                      label: Text(strings.t('documentArchive')),
                    ),
                  if (state.currentRole == AppRole.secretary)
                    OutlinedButton.icon(
                      onPressed: () => _tryDelete(context, doc, auth, state),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(strings.t('delete')),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
