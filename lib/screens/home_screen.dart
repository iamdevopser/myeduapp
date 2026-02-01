import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import 'app_builder_screen.dart';
import 'app_viewer_screen.dart';
import 'student_platform_screen.dart';
import 'user_guide_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Consumer<AppState>(
      builder: (context, state, child) {
        return Scaffold(
          appBar: AppBar(title: Text(strings.t('appTitle'))),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E2A5A), Color(0xFF3B5BDB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        strings.t('welcome'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AppBuilderScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.build),
                      label: Text(strings.t('createApp')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AppViewerScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.apps),
                      label: Text(strings.t('goToApp')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StudentPlatformScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.school),
                      label: Text(strings.t('studentPlatform')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const UserGuideScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.help_outline),
                      label: Text(strings.t('userGuide')),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      strings.t('language'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<Locale>(
                      value: state.locale,
                      items: const [
                        DropdownMenuItem(
                          value: Locale('tr'),
                          child: Text('Türkçe'),
                        ),
                        DropdownMenuItem(
                          value: Locale('en'),
                          child: Text('English'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          state.setLocale(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

