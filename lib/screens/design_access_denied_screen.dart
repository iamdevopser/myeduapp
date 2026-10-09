import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/app_navigation.dart';

/// Tasarım: `16_hata_erisim_yok.png`
class DesignAccessDeniedScreen extends StatelessWidget {
  const DesignAccessDeniedScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final body = Padding(
      padding: AppSpacing.pagePadding(MediaQuery.sizeOf(context).width),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: strings.t('designAccessDeniedTitle'),
            child: Icon(
              Icons.shield_outlined,
              size: 96,
              color: AppColors.primaryBlue.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            strings.t('designAccessDeniedTitle'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            strings.t('designAccessDeniedBody'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Semantics(
            button: true,
            label: strings.t('goHome'),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => logoutToLogin(context),
                child: Text(strings.t('goHome')),
              ),
            ),
          ),
        ],
      ),
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('designAccessDeniedTitle')),
      ),
      body: body,
    );
  }
}
