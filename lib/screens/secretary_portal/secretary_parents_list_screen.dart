import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../data/models/parent_guardian_model.dart';
import '../../services/secretary_parent_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/secretary_navigation.dart';
import '../../widgets/design/design_list_page_header.dart';
import '../../widgets/design/design_surface_card.dart';
import '../../theme/design_system.dart';
import 'secretary_ui/secretary_design.dart';
import 'secretary_ui/secretary_paginated_table.dart';

class SecretaryParentsListScreen extends StatefulWidget {
  const SecretaryParentsListScreen({
    super.key,
    this.embedded = false,
    this.onAddParent,
  });

  final bool embedded;
  final VoidCallback? onAddParent;

  @override
  State<SecretaryParentsListScreen> createState() =>
      _SecretaryParentsListScreenState();
}

class _SecretaryParentsListScreenState
    extends State<SecretaryParentsListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _reload = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final auth = AuthorizationService(context.watch<AppState>());
    if (!auth.canViewParents) {
      return Center(child: Text(strings.t('secretaryAccessDenied')));
    }
    final service = SecretaryParentService(context.read<AppState>().db);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < AppSpacing.phoneBreakpoint;

    return FutureBuilder(
      key: ValueKey('parents-$_reload-$_query'),
      future: service.listParents(search: _query.isEmpty ? null : _query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final parents = snapshot.data!;
        final filters = DesignSurfaceCard(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: strings.t('secretaryParentSearch'),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: DesignSystem.cardBorder),
              ),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        );

        final results = _buildParentResults(
          context: context,
          strings: strings,
          parents: parents,
          isPhone: isPhone,
          fillHeight: widget.embedded,
        );

        if (widget.embedded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              filters,
              const SizedBox(height: 16),
              Expanded(child: results),
            ],
          );
        }

        return SingleChildScrollView(
          padding: AppSpacing.pagePadding(width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesignListPageHeader(
                title: strings.t('secretaryParentsMenu'),
                primaryAction: widget.onAddParent != null
                    ? FilledButton.icon(
                        onPressed: widget.onAddParent,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(strings.t('secretaryParentAdd')),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              filters,
              const SizedBox(height: 16),
              results,
            ],
          ),
        );
      },
    );
  }

  Widget _buildParentResults({
    required BuildContext context,
    required AppLocalizations strings,
    required List<ParentGuardian> parents,
    required bool isPhone,
    required bool fillHeight,
  }) {
    if (parents.isEmpty) {
      return SecretaryGlassCard(
        blur: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(strings.t('secretaryParentNotFound')),
          ),
        ),
      );
    }

    if (isPhone) {
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: parents.length,
        itemBuilder: (context, index) {
          final p = parents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SecretaryGlassCard(
              blur: false,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              onTap: () => openSecretaryParentDetail(context, p.id),
              child: ListTile(
                title: Text(p.fullName),
                subtitle: Text(
                  '${p.phone ?? '—'} · ${p.email ?? '—'}\n'
                  '${strings.t('secretaryLinkedStudents')}: ${p.linkedStudentCount}',
                ),
                isThreeLine: true,
              ),
            ),
          );
        },
      );
    }

    return SecretaryPaginatedTable(
      fillHeight: fillHeight,
      columns: [
        DataColumn(label: Text(strings.t('parentFullName'))),
        DataColumn(label: Text(strings.t('parentPhone'))),
        DataColumn(label: Text(strings.t('parentEmail'))),
        DataColumn(label: Text(strings.t('secretaryLinkedStudents'))),
        DataColumn(label: Text(strings.t('edit'))),
      ],
      rowCount: parents.length,
      rowBuilder: (context, index) {
        final p = parents[index];
        return DataRow(
          cells: [
            DataCell(Text(p.fullName)),
            DataCell(Text(p.phone ?? '—')),
            DataCell(Text(p.email ?? '—')),
            DataCell(Text('${p.linkedStudentCount}')),
            DataCell(
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: strings.t('secretaryParentDetail'),
                onPressed: () => openSecretaryParentDetail(context, p.id),
              ),
            ),
          ],
        );
      },
    );
  }
}
