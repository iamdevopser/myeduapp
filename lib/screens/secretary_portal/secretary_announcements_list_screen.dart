import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../services/secretary_announcement_service.dart';
import '../../services/secretary_student_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/secretary_navigation.dart';
import '../../utils/student_announcement_meta.dart';
import '../../widgets/app_card.dart';
import 'secretary_announcement_ui.dart';

class SecretaryAnnouncementsListScreen extends StatefulWidget {
  const SecretaryAnnouncementsListScreen({super.key});

  @override
  State<SecretaryAnnouncementsListScreen> createState() =>
      _SecretaryAnnouncementsListScreenState();
}

class _SecretaryAnnouncementsListScreenState
    extends State<SecretaryAnnouncementsListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  StudentAnnouncementStatus? _statusFilter;
  StudentAnnouncementTargetType? _targetFilter;
  int _reload = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _targetDisplay(
    AppLocalizations strings,
    SecretaryAnnouncementService service,
    SecretaryAnnouncement item,
    List<Map<String, Object?>> classes,
  ) {
    if (item.targetType == StudentAnnouncementTargetType.allSchool) {
      return strings.t('announcementTargetAllSchool');
    }
    return service.targetGradeSectionLabel(item, classes);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final auth = AuthorizationService(context.watch<AppState>());
    if (!auth.canViewAnnouncements) {
      return Center(child: Text(strings.t('secretaryAccessDenied')));
    }
    final db = context.read<AppState>().db;
    final service = SecretaryAnnouncementService(db);
    final classService = SecretaryStudentService(db);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < AppSpacing.phoneBreakpoint;

    return FutureBuilder(
      key: ValueKey('ann-$_reload-$_query-$_statusFilter-$_targetFilter'),
      future: Future.wait([
        service.list(
          search: _query.isEmpty ? null : _query,
          statusFilter: _statusFilter,
          targetFilter: _targetFilter,
        ),
        classService.listStudentClasses(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data![0] as List<SecretaryAnnouncement>;
        final classes = snapshot.data![1] as List<Map<String, Object?>>;

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
                        labelText: strings.t('announcementSearch'),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final maxW = constraints.maxWidth;
                        final stacked = isPhone || maxW < 420;
                        final fieldW = stacked ? maxW : (maxW - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              width: fieldW,
                              child:
                                  DropdownButtonFormField<
                                    StudentAnnouncementStatus?
                                  >(
                                    isExpanded: true,
                                    value: _statusFilter,
                                    decoration: InputDecoration(
                                      labelText: strings.t(
                                        'announcementStatusLabel',
                                      ),
                                    ),
                                    selectedItemBuilder: (context) => [
                                      Text(
                                        strings.t('filterAll'),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      ...StudentAnnouncementStatus.values.map(
                                        (s) => Text(
                                          announcementStatusLabel(strings, s),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                    items: [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          strings.t('filterAll'),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      ...StudentAnnouncementStatus.values.map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            announcementStatusLabel(strings, s),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _statusFilter = v),
                                  ),
                            ),
                            SizedBox(
                              width: fieldW,
                              child:
                                  DropdownButtonFormField<
                                    StudentAnnouncementTargetType?
                                  >(
                                    isExpanded: true,
                                    value: _targetFilter,
                                    decoration: InputDecoration(
                                      labelText: strings.t(
                                        'announcementTargetLabel',
                                      ),
                                    ),
                                    selectedItemBuilder: (context) => [
                                      Text(
                                        strings.t('filterAll'),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      ...StudentAnnouncementTargetType.values
                                          .map(
                                            (t) => Text(
                                              announcementTargetLabel(
                                                strings,
                                                t,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                    ],
                                    items: [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          strings.t('filterAll'),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      ...StudentAnnouncementTargetType.values
                                          .map(
                                            (t) => DropdownMenuItem(
                                              value: t,
                                              child: Text(
                                                announcementTargetLabel(
                                                  strings,
                                                  t,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _targetFilter = v),
                                  ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(strings.t('teacherAnnouncementsEmpty')),
                    ),
                  ),
                )
              else if (isPhone)
                ...items.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      onTap: () =>
                          openSecretaryAnnouncementDetail(context, a.id),
                      child: ListTile(
                        title: Text(a.title),
                        subtitle: Text(
                          '${_targetDisplay(strings, service, a, classes)}\n'
                          '${announcementStatusLabel(strings, a.status)}',
                        ),
                        isThreeLine: true,
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
                          label: Text(strings.t('announcementTargetLabel')),
                        ),
                        DataColumn(
                          label: Text(strings.t('announcementStatusLabel')),
                        ),
                        DataColumn(
                          label: Text(strings.t('announcementPublishedAt')),
                        ),
                        DataColumn(
                          label: Text(strings.t('announcementUpdatedAt')),
                        ),
                      ],
                      rows: items.map((a) {
                        return DataRow(
                          onSelectChanged: (_) =>
                              openSecretaryAnnouncementDetail(context, a.id),
                          cells: [
                            DataCell(Text(a.title)),
                            DataCell(
                              Text(
                                _targetDisplay(strings, service, a, classes),
                              ),
                            ),
                            DataCell(
                              Text(announcementStatusLabel(strings, a.status)),
                            ),
                            DataCell(
                              Text(_dateOnly(a.publishedAt ?? a.createdAt)),
                            ),
                            DataCell(
                              Text(_dateOnly(a.updatedAt ?? a.createdAt)),
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

  String _dateOnly(String iso) => iso.split('T').first;
}
