import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../screens/settings_screen.dart';
import '../services/authorization_service.dart';

/// Role-aware Settings route (`/settings`).
void openAppSettings(BuildContext context) {
  final auth = AuthorizationService(context.read<AppState>());
  if (!auth.canManageLocaleAndTheme) {
    return;
  }
  Navigator.of(context).pushNamed(SettingsScreen.routeName);
}
