import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/global_search_screen.dart';
import 'screens/question_bank_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_guide_screen.dart';

class MyEduApp extends StatelessWidget {
  const MyEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return MaterialApp(
          title: 'MyEduApp',
          locale: state.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: state.themeMode,
          routes: {
            '/': (_) => const HomeScreen(),
            SettingsScreen.routeName: (_) => const SettingsScreen(),
            QuestionBankScreen.routeName: (_) => const QuestionBankScreen(),
            GlobalSearchScreen.routeName: (_) => const GlobalSearchScreen(),
            UserGuideScreen.routeName: (_) => const UserGuideScreen(),
          },
        );
      },
    );
  }
}

