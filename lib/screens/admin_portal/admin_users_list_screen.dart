import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/app_account.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_role.dart';
import '../../providers/app_state.dart';
import '../../services/account_service.dart';
import '../../services/authorization_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';

class AdminUsersListScreen extends StatefulWidget {
  const AdminUsersListScreen({super.key});

  @override
  State<AdminUsersListScreen> createState() => _AdminUsersListScreenState();
}

class _AdminUsersListScreenState extends State<AdminUsersListScreen> {
  String _query = '';
  AppRole? _roleFilter;
  int _reload = 0;

  String _roleLabel(AppLocalizations strings, AppRole role) {
    return switch (role) {
      AppRole.admin => strings.t('adminRoleAdmin'),
      AppRole.teacher => strings.t('adminRoleTeacher'),
      AppRole.secretary => strings.t('adminRoleSecretary'),
      AppRole.student => strings.t('adminRoleStudent'),
      AppRole.parent => strings.t('adminRoleParent'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final auth = AuthorizationService(state);
    if (!auth.canManageAccounts || state.sessionAccountId == null) {
      return Center(child: Text(strings.t('adminAccessDenied')));
    }
    final service =
        AccountService(state.db, actorAccountId: state.sessionAccountId!);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < AppSpacing.phoneBreakpoint;

    return FutureBuilder<List<AppAccount>>(
      key: ValueKey(
        'users-${state.adminAccountsRevision}-$_reload-$_query-$_roleFilter',
      ),
      future: service.listAccounts(
        roleFilter: _roleFilter,
        search: _query.isEmpty ? null : _query,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        return SingleChildScrollView(
          padding: AppSpacing.pagePadding(width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: strings.t('adminUserSearch'),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _query = v.trim()),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fieldW = constraints.maxWidth < 420
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 12) / 2;
                        return SizedBox(
                          width: fieldW,
                          child: DropdownButtonFormField<AppRole?>(
                            isExpanded: true,
                            value: _roleFilter,
                            decoration: InputDecoration(
                              labelText: strings.t('adminAccountRole'),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(strings.t('filterAll')),
                              ),
                              ...AppRole.values.map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    _roleLabel(strings, r),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _roleFilter = v),
                          ),
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
                    child: Center(child: Text(strings.t('adminUsersEmpty'))),
                  ),
                )
              else if (isPhone)
                ...items.map((a) => _userCard(context, strings, service, a))
              else
                AppCard(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 48,
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 52,
                      columnSpacing: 20,
                      horizontalMargin: 16,
                      columns: [
                        DataColumn(label: Text(strings.t('adminAccountName'))),
                        DataColumn(label: Text(strings.t('adminAccountUsername'))),
                        DataColumn(label: Text(strings.t('adminAccountRole'))),
                        DataColumn(label: Text(strings.t('adminAccountStatus'))),
                        DataColumn(label: Text(strings.t('adminAccountActions'))),
                      ],
                      rows: items
                          .map((a) => _dataRow(context, strings, service, a))
                          .toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  DataRow _dataRow(
    BuildContext context,
    AppLocalizations strings,
    AccountService service,
    AppAccount a,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(a.fullName)),
        DataCell(Text(a.username)),
        DataCell(Text(_roleLabel(strings, a.role))),
        DataCell(Text(
          a.active ? strings.t('adminAccountActive') : strings.t('adminAccountInactive'),
        )),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: _actionButtons(context, strings, service, a, table: true),
          ),
        ),
      ],
    );
  }

  Widget _userCard(
    BuildContext context,
    AppLocalizations strings,
    AccountService service,
    AppAccount a,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: ListTile(
          title: Text(a.fullName),
          subtitle: Text(
            '${a.username} · ${_roleLabel(strings, a.role)}\n'
            '${a.active ? strings.t('adminAccountActive') : strings.t('adminAccountInactive')}',
          ),
          isThreeLine: true,
          trailing: _actionButtons(context, strings, service, a),
        ),
      ),
    );
  }

  Widget _actionButtons(
    BuildContext context,
    AppLocalizations strings,
    AccountService service,
    AppAccount a, {
    bool table = false,
  }) {
    final iconSize = table ? 20.0 : 24.0;
    final constraints = table
        ? const BoxConstraints(minWidth: 36, minHeight: 36)
        : const BoxConstraints(minWidth: 48, minHeight: 48);
    final padding = table ? const EdgeInsets.all(6) : null;

    Widget btn({
      required String tooltip,
      required IconData icon,
      required VoidCallback onPressed,
    }) {
      return IconButton(
        tooltip: tooltip,
        icon: Icon(icon, size: iconSize),
        padding: padding,
        visualDensity: table ? VisualDensity.compact : VisualDensity.standard,
        constraints: constraints,
        onPressed: onPressed,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(
          tooltip: strings.t('adminPasswordReset'),
          icon: Icons.lock_reset_outlined,
          onPressed: () => _resetPassword(context, strings, service, a),
        ),
        btn(
          tooltip: a.active
              ? strings.t('adminDeactivateAccount')
              : strings.t('adminActivateAccount'),
          icon: a.active ? Icons.pause_circle_outline : Icons.play_circle_outline,
          onPressed: () => _toggleActive(context, strings, service, a),
        ),
      ],
    );
  }

  Future<void> _resetPassword(
    BuildContext context,
    AppLocalizations strings,
    AccountService service,
    AppAccount a,
  ) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.t('adminPasswordReset')),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(labelText: strings.t('adminNewPassword')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.t('save')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await service.resetPassword(
        accountId: a.id,
        newPasswordPlain: controller.text,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t('adminPasswordResetDone'))),
        );
      }
    } on AccountValidationException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t(e.messageKey))),
        );
      }
    }
  }

  Future<void> _toggleActive(
    BuildContext context,
    AppLocalizations strings,
    AccountService service,
    AppAccount a,
  ) async {
    try {
      await service.setActive(accountId: a.id, active: !a.active);
      setState(() => _reload++);
    } on LastAdminProtectionException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t('adminLastAdminBlocked'))),
        );
      }
    }
  }
}
