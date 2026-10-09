import '../data/models/parent_guardian_model.dart';
import '../l10n/app_localizations.dart';

extension ParentRelationTypeLabel on ParentRelationType {
  String label(AppLocalizations strings) {
    return switch (this) {
      ParentRelationType.anne => strings.t('parentRelationAnne'),
      ParentRelationType.baba => strings.t('parentRelationBaba'),
      ParentRelationType.diger => strings.t('parentRelationOther'),
    };
  }
}
