import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_state.dart';
import '../../services/authorization_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/secretary_navigation.dart';
import 'secretary_ui/secretary_design.dart';
import 'secretary_ui/secretary_parent_form.dart';

class SecretaryParentAddScreen extends StatelessWidget {
  const SecretaryParentAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final auth = AuthorizationService(context.watch<AppState>());
    if (!auth.canCreateParent) {
      return Center(child: Text(strings.t('secretaryAccessDenied')));
    }
    final width = MediaQuery.sizeOf(context).width;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding(width),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SecretaryGlassCard(
            blur: false,
            child: SecretaryParentForm(
              onSaved: () {
                navigateSecretarySection(
                  context,
                  SecretaryNavSection.studentsParents,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
