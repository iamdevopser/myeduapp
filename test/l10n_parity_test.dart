import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/l10n/app_localizations.dart';

final _placeholder = RegExp(r'\{[a-zA-Z]+\}');

Set<String> _placeholders(String value) =>
    _placeholder.allMatches(value).map((m) => m.group(0)!).toSet();

void main() {
  final en = AppLocalizations.valuesFor('en')!;

  for (final locale in AppLocalizations.supportedLocales) {
    final code = locale.languageCode;

    test('$code has the same keys as en', () {
      final values = AppLocalizations.valuesFor(code)!;
      expect(
        en.keys.toSet().difference(values.keys.toSet()),
        isEmpty,
        reason: 'missing in $code',
      );
      expect(
        values.keys.toSet().difference(en.keys.toSet()),
        isEmpty,
        reason: 'extra in $code',
      );
    });

    test('$code keeps placeholders', () {
      final values = AppLocalizations.valuesFor(code)!;
      final broken = [
        for (final entry in en.entries)
          if (values[entry.key] != null &&
              !_setEquals(
                _placeholders(entry.value),
                _placeholders(values[entry.key]!),
              ))
            entry.key,
      ];
      expect(broken, isEmpty);
    });

    test('$code has a native language name', () {
      expect(AppLocalizations.languageNames[code], isNotNull);
    });
  }

  test('unknown key falls back to English, then to the key', () {
    final ro = AppLocalizations(const Locale('ro'));
    expect(ro.t('__missing__'), '__missing__');
  });
}

bool _setEquals(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
