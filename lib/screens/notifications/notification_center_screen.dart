import 'package:flutter/material.dart';

import 'package:provider/provider.dart';



import '../../l10n/app_localizations.dart';

import '../../models/in_app_notification.dart';

import '../../providers/app_state.dart';

import '../../services/authorization_service.dart';

import '../../services/notification_service.dart';

import '../../theme/app_colors.dart';

import '../../theme/app_spacing.dart';

import '../../utils/notification_navigation.dart';

import '../../utils/workspace_app_shell.dart';



class NotificationCenterScreen extends StatelessWidget {

  const NotificationCenterScreen({super.key});



  String _typeLabel(AppLocalizations strings, InAppNotification n) {

    switch (n.type) {

      case 'duyuru':

        return strings.t('notificationTypeAnnouncement');

      case 'belge':

        return strings.t('notificationTypeDocument');

      default:

        return strings.t('notificationTypeGeneral');

    }

  }



  IconData _typeIcon(InAppNotification n) {

    switch (n.type) {

      case 'duyuru':

        return Icons.campaign_outlined;

      case 'belge':

        return Icons.description_outlined;

      default:

        return Icons.notifications_outlined;

    }

  }



  Future<void> _onTap(

    BuildContext context,

    InAppNotification n,

    AppState state,

  ) async {

    final service = NotificationService(state.db, state: state);

    await service.markAsRead(n.id);

    if (!context.mounted) return;

    if (n.referenceType != null && n.referenceId != null) {

      await openNotificationReference(context, n);

    } else {

      showNotificationReferenceMissing(context);

    }

  }



  Widget _markAllReadAction(

    BuildContext context,

    AppLocalizations strings,

    NotificationService service,

  ) {

    final narrow = MediaQuery.sizeOf(context).width < 400;

    if (narrow) {

      return IconButton(

        tooltip: strings.t('notificationMarkAllRead'),

        onPressed: () => service.markAllAsRead(),

        icon: const Icon(Icons.done_all),

      );

    }

    return TextButton.icon(

      onPressed: () => service.markAllAsRead(),

      icon: const Icon(Icons.done_all, size: 20),

      label: Text(strings.t('notificationMarkAllRead')),

    );

  }



  @override

  Widget build(BuildContext context) {

    final strings = AppLocalizations.of(context);

    final state = context.watch<AppState>();

    final auth = AuthorizationService(state);

    final width = MediaQuery.sizeOf(context).width;

    final service = NotificationService(state.db, state: state);



    if (!auth.canViewOwnNotifications) {

      return WorkspaceAppShell(

        title: strings.t('notificationCenterTitle'),

        child: Center(child: Text(strings.t('notificationAccessDenied'))),

      );

    }



    return WorkspaceAppShell(

      title: strings.t('notificationCenterTitle'),

      actions: [_markAllReadAction(context, strings, service)],

      child: FutureBuilder<List<InAppNotification>>(

        key: ValueKey(state.notificationRevision),

        future: service.listForCurrentUser(),

        builder: (context, snapshot) {

          if (snapshot.connectionState != ConnectionState.done) {

            return const Center(child: CircularProgressIndicator());

          }

          if (snapshot.hasError) {

            return Center(child: Text(strings.t('notificationAccessDenied')));

          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {

            return Center(

              child: Padding(

                padding: AppSpacing.pagePadding(width),

                child: Text(

                  strings.t('notificationEmpty'),

                  textAlign: TextAlign.center,

                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(

                        color: AppColors.textSecondary,

                      ),

                ),

              ),

            );

          }

          final allRead = items.every((n) => n.isRead);

          return ListView.separated(

            padding: AppSpacing.pagePadding(width),

            itemCount: items.length + (allRead ? 1 : 0),

            separatorBuilder: (_, _) => const SizedBox(height: 8),

            itemBuilder: (context, index) {

              if (allRead && index == 0) {

                return Padding(

                  padding: const EdgeInsets.only(bottom: 8),

                  child: Text(

                    strings.t('notificationAllRead'),

                    style: Theme.of(context).textTheme.bodySmall?.copyWith(

                          color: AppColors.textSecondary,

                        ),

                  ),

                );

              }

              final i = allRead ? index - 1 : index;

              final n = items[i];

              final unreadLabel = strings.t('notificationUnreadBadge');

              return Semantics(

                label: n.isRead

                    ? '${_typeLabel(strings, n)}: ${n.title}'

                    : '$unreadLabel. ${_typeLabel(strings, n)}: ${n.title}',

                button: true,

                child: Material(

                  color: n.isRead

                      ? AppColors.surface

                      : AppColors.surface.withValues(alpha: 0.92),

                  borderRadius: BorderRadius.circular(12),

                  child: InkWell(

                    borderRadius: BorderRadius.circular(12),

                    onTap: () => _onTap(context, n, state),

                    child: Container(

                      padding: EdgeInsets.symmetric(

                        horizontal: AppSpacing.md,

                        vertical: width < 600 ? 14 : 12,

                      ),

                      decoration: BoxDecoration(

                        borderRadius: BorderRadius.circular(12),

                        border: Border.all(

                          color: n.isRead

                              ? AppColors.border

                              : AppColors.primaryBlue.withValues(alpha: 0.35),

                        ),

                      ),

                      child: Row(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Icon(_typeIcon(n), color: AppColors.primaryBlue),

                          const SizedBox(width: 12),

                          Expanded(

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Text(

                                  _typeLabel(strings, n),

                                  style: Theme.of(context)

                                      .textTheme

                                      .labelSmall

                                      ?.copyWith(color: AppColors.textSecondary),

                                ),

                                Text(

                                  n.title,

                                  maxLines: 2,

                                  overflow: TextOverflow.ellipsis,

                                  style: Theme.of(context)

                                      .textTheme

                                      .titleSmall

                                      ?.copyWith(

                                        fontWeight: n.isRead

                                            ? FontWeight.w500

                                            : FontWeight.w700,

                                      ),

                                ),

                                if (n.body.isNotEmpty) ...[

                                  const SizedBox(height: 4),

                                  Text(

                                    n.body,

                                    maxLines: 2,

                                    overflow: TextOverflow.ellipsis,

                                    style: Theme.of(context)

                                        .textTheme

                                        .bodySmall

                                        ?.copyWith(

                                          color: AppColors.textSecondary,

                                        ),

                                  ),

                                ],

                                const SizedBox(height: 4),

                                Text(

                                  n.createdAt,

                                  style: Theme.of(context)

                                      .textTheme

                                      .labelSmall

                                      ?.copyWith(color: AppColors.textSecondary),

                                ),

                              ],

                            ),

                          ),

                          if (!n.isRead)

                            Container(

                              width: 8,

                              height: 8,

                              margin: const EdgeInsets.only(top: 6),

                              decoration: const BoxDecoration(

                                color: AppColors.primaryBlue,

                                shape: BoxShape.circle,

                              ),

                            ),

                        ],

                      ),

                    ),

                  ),

                ),

              );

            },

          );

        },

      ),

    );

  }

}


