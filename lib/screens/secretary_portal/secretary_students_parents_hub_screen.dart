import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../theme/app_spacing.dart';
import 'secretary_ui/secretary_parent_form.dart';
import 'secretary_parents_list_screen.dart';
import 'secretary_parent_detail_screen.dart';
import 'secretary_student_parents_screen.dart';
import 'secretary_students_list_screen.dart';
import 'secretary_ui/secretary_design.dart';
import 'secretary_ui/secretary_slide_panel.dart';
import 'secretary_ui/secretary_student_form.dart';

class SecretaryStudentsParentsHubScreen extends StatefulWidget {
  const SecretaryStudentsParentsHubScreen({super.key});

  @override
  State<SecretaryStudentsParentsHubScreen> createState() =>
      _SecretaryStudentsParentsHubScreenState();
}

class _SecretaryStudentsParentsHubScreenState
    extends State<SecretaryStudentsParentsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _parentsReload = 0;
  int _studentsReload = 0;

  late AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    final initial = _appState.secretaryStudentsParentsTab;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initial.clamp(0, 1),
    );
    _appState.addListener(_onAppStateChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _handlePendingActions(),
    );
  }

  void _onAppStateChanged() {
    final tab = _appState.secretaryStudentsParentsTab;
    if (_tabController.index != tab && mounted) {
      _tabController.animateTo(tab);
    }
    _handlePendingActions();
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handlePendingActions() async {
    if (!mounted) return;
    final state = context.read<AppState>();
    if (state.consumeSecretaryPendingStudentSheet()) {
      await _openStudentPanel();
    }
    if (state.consumeSecretaryPendingParentSheet()) {
      await _openParentCreate();
    }
    final parentId = state.secretaryFocusParentId;
    if (!mounted) return;
    if (parentId != null && state.secretaryShowParentDetailPanel) {
      state.clearSecretaryParentDetailPanelFlag();
      final strings = AppLocalizations.of(context);
      await showSecretaryEndPanel<void>(
        context: context,
        title: strings.t('secretaryParentDetail'),
        child: SecretaryParentDetailScreen(embedded: true),
      );
    }
    if (!mounted) return;
    final studentId = state.secretaryFocusStudentId;
    if (studentId != null && state.secretaryShowStudentParentsPanel) {
      state.clearSecretaryStudentParentsPanelFlag();
      final strings = AppLocalizations.of(context);
      await showSecretaryEndPanel<void>(
        context: context,
        title: strings.t('secretaryStudentParents'),
        child: const SecretaryStudentParentsScreen(embedded: true),
      );
    }
  }

  Future<void> _openStudentPanel() async {
    final saved = await showSecretaryStudentFormPanel(context);
    if (saved) setState(() => _studentsReload++);
  }

  Future<void> _openParentCreate() async {
    final saved = await showSecretaryParentFormPanel(context);
    if (saved) setState(() => _parentsReload++);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final auth = AuthorizationService(context.watch<AppState>());
    final width = MediaQuery.sizeOf(context).width;
    final padding = AppSpacing.pagePadding(width);

    return Padding(
      padding: padding.copyWith(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SecretaryHubTabBar(
            controller: _tabController,
            tabs: [
              strings.t('secretaryStudentList'),
              strings.t('secretaryParentList'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SecretaryStudentsListScreen(
                  key: ValueKey('stu-$_studentsReload'),
                  embedded: true,
                  onAddStudent: auth.canCreateStudent
                      ? _openStudentPanel
                      : null,
                ),
                SecretaryParentsListScreen(
                  key: ValueKey('par-$_parentsReload'),
                  embedded: true,
                  onAddParent: auth.canCreateParent ? _openParentCreate : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
