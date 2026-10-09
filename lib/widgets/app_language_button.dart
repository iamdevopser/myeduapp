import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

/// Header action that switches the whole app's display language.
class AppLanguageButton extends StatelessWidget {
  const AppLanguageButton({super.key, this.color, this.onSelected});

  final Color? color;

  /// Called after the app language changes (e.g. to sync local overrides).
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final current = context.watch<AppState>().locale.languageCode;
    final fg = color ?? AppColors.textPrimary;

    return PopupMenuButton<String>(
      tooltip: strings.t('language'),
      initialValue: current,
      onSelected: (code) async {
        await context.read<AppState>().setDisplayLocale(Locale(code));
        onSelected?.call(code);
      },
      itemBuilder: (context) => [
        for (final locale in AppLocalizations.supportedLocales)
          PopupMenuItem<String>(
            value: locale.languageCode,
            child: Text(
              AppLocalizations.languageNames[locale.languageCode] ??
                  locale.languageCode,
            ),
          ),
      ],
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate, size: 20, color: fg),
              const SizedBox(width: 4),
              Text(
                current.toUpperCase(),
                semanticsLabel: AppLocalizations.languageNames[current],
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
