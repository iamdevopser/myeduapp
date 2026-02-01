import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import 'home_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Consumer<AppState>(
      builder: (context, state, child) {
        return Scaffold(
          body: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.t('password'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _controller,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: strings.t('password'),
                          errorText: _error,
                        ),
                        onSubmitted: (_) => _handleUnlock(state),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => _handleUnlock(state),
                        child: Text(strings.t('unlock')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleUnlock(AppState state) {
    final strings = AppLocalizations.of(context);
    final password = _controller.text;
    if (state.verifyPassword(password)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _error = strings.t('wrongPassword');
      });
    }
  }
}



