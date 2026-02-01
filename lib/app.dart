import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              secondary: Colors.teal,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF6F7FB),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E2A5A),
              foregroundColor: Colors.white,
              centerTitle: false,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E2A5A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E2A5A),
                side: const BorderSide(color: Color(0xFF1E2A5A)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: state.themeMode,
          routes: {
            '/': (_) => state.lockEnabled ? const LockScreen() : const HomeScreen(),
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

