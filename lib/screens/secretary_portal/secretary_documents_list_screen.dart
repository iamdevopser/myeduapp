import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_document_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/secretary_navigation.dart';
import '../../widgets/app_card.dart';

class SecretaryDocumentsListScreen extends StatefulWidget {
  const SecretaryDocumentsListScreen({super.key});

  @override
  State<SecretaryDocumentsListScreen> createState() =>
      _SecretaryDocumentsListScreenState();
}

class _SecretaryDocumentsListScreenState
    extends State<SecretaryDocumentsListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _categoryFilter;
  bool? _archivedFilter;
  bool? _criticalFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  SecretaryDocumentService _service(AppState state) =>
      SecretaryDocumentService(state.db, state.fileService);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final auth = AuthorizationService(state);
    if (!auth.canViewDocuments) {
      return Center(child: Text(strings.t('secretaryAccessDenied')));
    }
    final service = _service(state);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < AppSpacing.phoneBreakpoint;

    return FutureBuilder(
      key: ValueKey(
        'doc-$_query-$_categoryFilter-$_archivedFilter-$_criticalFilter',
      ),
      future: Future.wait([
        service.list(
          search: _query.isEmpty ? null : _query,
          category: _categoryFilter,
          archived: _archivedFilter,
          critical: _criticalFilter,
        ),
        service.distinctCategories(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data![0] as List<SecretaryDocument>;
        final categories = snapshot.data![1] as List<String>;

        return SingleChildScrollView(
          padding: AppSpacing.pagePadding(width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: strings.t('documentSearch'),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: isPhone ? double.infinity : 180,
                          child: DropdownButtonFormField<String?>(
                            value: _categoryFilter,
                            decoration: InputDecoration(
                              labelText: strings.t('documentCategoryLabel'),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(strings.t('filterAll')),
                              ),
                              ...categories.map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _categoryFilter = v),
                          ),
                        ),
                        SizedBox(
                          width: isPhone ? double.infinity : 180,
                          child: DropdownButtonFormField<bool?>(
                            value: _archivedFilter,
                            decoration: InputDecoration(
                              labelText: strings.t('documentFilterArchived'),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(strings.t('filterAll')),
                              ),
                              DropdownMenuItem(
                                value: false,
                                child: Text(strings.t('documentStatusActive')),
                              ),
                              DropdownMenuItem(
                                value: true,
                                child: Text(
                                  strings.t('documentStatusArchived'),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _archivedFilter = v),
                          ),
                        ),
                        SizedBox(
                          width: isPhone ? double.infinity : 180,
                          child: DropdownButtonFormField<bool?>(
                            value: _criticalFilter,
                            decoration: InputDecoration(
                              labelText: strings.t('documentFilterCritical'),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(strings.t('filterAll')),
                              ),
                              DropdownMenuItem(
                                value: true,
                                child: Text(
                                  strings.t('documentFilterCriticalOnly'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: false,
                                child: Text(
                                  strings.t('documentFilterNonCritical'),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _criticalFilter = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(strings.t('documentEmpty'))),
                  ),
                )
              else if (isPhone)
                ...items.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      onTap: () => openSecretaryDocumentDetail(context, d.id),
                      child: ListTile(
                        title: Text(d.name),
                        subtitle: Text(
                          [
                            if (d.category != null && d.category!.isNotEmpty)
                              d.category!,
                            d.type,
                            if (d.critical) strings.t('documentCriticalLabel'),
                            if (d.archived) strings.t('documentStatusArchived'),
                          ].join(' · '),
                        ),
                        trailing: d.critical
                            ? const Icon(Icons.lock_outline, size: 20)
                            : null,
                      ),
                    ),
                  ),
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(
                          label: Text(strings.t('teacherAnnouncementsTitle')),
                        ),
                        DataColumn(
                          label: Text(strings.t('documentCategoryLabel')),
                        ),
                        DataColumn(label: Text(strings.t('documentTypeLabel'))),
                        DataColumn(
                          label: Text(strings.t('documentCriticalLabel')),
                        ),
                        DataColumn(
                          label: Text(strings.t('announcementUpdatedAt')),
                        ),
                      ],
                      rows: items.map((d) {
                        return DataRow(
                          onSelectChanged: (_) =>
                              openSecretaryDocumentDetail(context, d.id),
                          cells: [
                            DataCell(Text(d.name)),
                            DataCell(Text(d.category ?? '—')),
                            DataCell(Text(d.type)),
                            DataCell(
                              d.critical
                                  ? Text(strings.t('documentCriticalLabel'))
                                  : const Text('—'),
                            ),
                            DataCell(
                              Text(
                                d.updatedAt.toIso8601String().split('T').first,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
