import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';

/// Dialog wrapper that keeps forms usable on phone/tablet widths.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final maxWidth = AppSpacing.dialogMaxWidth(MediaQuery.sizeOf(context).width);
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: context.isMobileLayout ? AppSpacing.md : AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: builder(dialogContext),
        ),
      );
    },
  );
}

Future<bool> confirmLeavePage(BuildContext context) async {
  final strings = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(strings.t('exitConfirm')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(strings.t('no')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(strings.t('yes')),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Back: previous screen when the stack has one, otherwise login.
void popToPreviousOrLogin(BuildContext context) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
  } else {
    nav.pushNamedAndRemoveUntil('/', (route) => false);
  }
}

/// Home: teacher/student session root (first route after login), or login.
void popToSessionHome(BuildContext context) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.popUntil((route) => route.isFirst);
  } else {
    nav.pushNamedAndRemoveUntil('/', (route) => false);
  }
}

void logoutToLogin(BuildContext context) {
  final nav = Navigator.of(context, rootNavigator: true);
  nav.pushNamedAndRemoveUntil('/', (route) => false);
}

/// Oturum geçersiz workspace ekranında (tek route) ana sayfaya dönmek için.
void leaveWorkspaceToLogin(BuildContext context) {
  logoutToLogin(context);
}

/// Back button for screens pushed on top of the dashboard (e.g. Hızlı İşlemler).
Widget? buildPushedScreenBackLeading(BuildContext context) {
  if (!Navigator.of(context).canPop()) return null;
  final strings = AppLocalizations.of(context);
  return IconButton(
    icon: const Icon(Icons.arrow_back),
    tooltip: strings.t('goHome'),
    onPressed: () async {
      final confirmed = await confirmLeavePage(context);
      if (confirmed && context.mounted) {
        Navigator.of(context).pop();
      }
    },
  );
}
