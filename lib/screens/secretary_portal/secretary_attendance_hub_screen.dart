import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../theme/app_spacing.dart';
import 'secretary_attendance_daily_screen.dart';
import 'secretary_attendance_history_screen.dart';
import 'secretary_ui/secretary_design.dart';

class SecretaryAttendanceHubScreen extends StatefulWidget {
  const SecretaryAttendanceHubScreen({super.key});

  @override
  State<SecretaryAttendanceHubScreen> createState() =>
      _SecretaryAttendanceHubScreenState();
}

class _SecretaryAttendanceHubScreenState
    extends State<SecretaryAttendanceHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    final initial = _appState.secretaryAttendanceTab;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initial.clamp(0, 1),
    );
    _tabController.addListener(_onTabChanged);
    _appState.addListener(_onAppStateChanged);
  }

  void _onAppStateChanged() {
    final tab = _appState.secretaryAttendanceTab;
    if (_tabController.index != tab && mounted) {
      _tabController.animateTo(tab);
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _appState.removeListener(_onAppStateChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: AppSpacing.pagePadding(width).copyWith(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SecretaryHubTabBar(
            controller: _tabController,
            tabs: [
              strings.t('secretaryAttendanceDaily'),
              strings.t('secretaryAttendanceHistory'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _tabController.index == 0
                  ? const SecretaryAttendanceDailyScreen(
                      key: ValueKey('attendance-daily'),
                      embedded: true,
                    )
                  : const SecretaryAttendanceHistoryScreen(
                      key: ValueKey('attendance-history'),
                      embedded: true,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
