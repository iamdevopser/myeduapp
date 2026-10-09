import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/secretary_document_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_card.dart';

/// Sekreter belgesi — mobilde aksiyon taşmasını önler.
class ParentDocumentTile extends StatelessWidget {
  const ParentDocumentTile({
    super.key,
    required this.document,
    required this.onOpen,
    required this.onDownload,
  });

  final SecretaryDocument document;
  final VoidCallback onOpen;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (context.isMobileLayout) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(document.type),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(strings.t('documentOpen')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: Text(strings.t('documentDownload')),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(document.type),
              ],
            ),
          ),
          IconButton(
            tooltip: strings.t('documentOpen'),
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new),
          ),
          IconButton(
            tooltip: strings.t('documentDownload'),
            onPressed: onDownload,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
    );
  }
}
