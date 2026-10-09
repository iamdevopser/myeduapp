import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../screens/notifications/notification_center_screen.dart';
import '../services/authorization_service.dart';
import '../theme/app_colors.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key, this.iconColor});

  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final auth = AuthorizationService(state);
    if (!auth.canViewOwnNotifications) return const SizedBox.shrink();

    final color = iconColor ?? AppColors.textPrimary;
    final badge = state.cachedUnreadNotificationCount;

    return IconButton(
      tooltip: strings.t('notificationsMenu'),
      onPressed: () async {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => const NotificationCenterScreen(),
          ),
        );
        if (context.mounted) {
          await context.read<AppState>().refreshUnreadNotifications();
        }
      },
      icon: Badge(
        isLabelVisible: badge > 0,
        label: Text(badge > 99 ? '99+' : '$badge'),
        child: Icon(Icons.notifications_outlined, color: color),
      ),
    );
  }
}
