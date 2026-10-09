import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/l10n/app_localizations.dart';
import 'package:my_edu_app/l10n/login_hero_texts.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/screens/design_access_denied_screen.dart';
import 'package:my_edu_app/screens/home/design_login_layout.dart';
import 'package:my_edu_app/screens/home/login_hero_layout.dart';
import 'package:my_edu_app/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('tr'),
    theme: AppTheme.light(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  testWidgets('DesignAccessDeniedScreen shows title and home button', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const DesignAccessDeniedScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Erişim Reddedildi'), findsWidgets);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  for (final width in const [360.0, 390.0]) {
    testWidgets('DesignLoginLayout shows all five role tabs at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _wrap(
          DesignLoginLayout(
            onSubmit: (_, _, _, _) async {},
            onMessage: (_, _) {},
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      for (final label in const [
        'Öğrenci',
        'Veli',
        'Öğretmen',
        'Yönetici',
        'Sekreter',
      ]) {
        expect(find.text(label), findsOneWidget);
        expect(
          tester
              .getSize(
                find
                    .ancestor(
                      of: find.text(label),
                      matching: find.byType(InkWell),
                    )
                    .first,
              )
              .height,
          greaterThanOrEqualTo(48),
        );
      }
      expect(find.text('Giriş Yap'), findsOneWidget);
      expect(find.text('Sekreter / Yönetici ve diğer girişler'), findsNothing);
    });
  }

  testWidgets('DesignLoginLayout submits with the selected role', (
    tester,
  ) async {
    final submitted = <(AppRole, String, String)>[];
    await tester.pumpWidget(
      _wrap(
        DesignLoginLayout(
          onSubmit: (_, role, user, pass) async =>
              submitted.add((role, user, pass)),
          onMessage: (_, _) {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Sekreter'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), ' sek1 ');
    await tester.enterText(find.byType(TextField).at(1), 'pw');
    await tester.tap(find.text('Giriş Yap'));
    await tester.pump();

    await tester.tap(find.text('Yönetici'));
    await tester.pump();
    await tester.tap(find.text('Giriş Yap'));
    await tester.pump();

    expect(submitted, [
      (AppRole.secretary, 'sek1', 'pw'),
      (AppRole.admin, 'sek1', 'pw'),
    ]);
  });

  for (final size in const [
    Size(1024, 640),
    Size(1366, 768),
    Size(1920, 1080),
  ]) {
    testWidgets('LoginHeroLayout renders info panel and form at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await _pumpHero(tester);

      expect(tester.takeException(), isNull);
      expect(
        find.text('Eğitimin dijital dünyadaki en güçlü yardımcınız.'),
        findsOneWidget,
      );
      expect(find.text('Keşfetmeye Hazır mısınız?'), findsOneWidget);
      expect(find.text('Giriş Yap'), findsOneWidget);
      expect(find.text('Veli'), findsOneWidget);
      expect(find.text('Yönetici'), findsOneWidget);
      expect(find.text('Sekreter'), findsOneWidget);
      expect(find.text('Sekreter / Yönetici ve diğer girişler'), findsNothing);
    });
  }

  testWidgets('LoginHeroLayout left panel follows device language (German)', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 768);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _pumpHero(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Bereit zum Entdecken?'), findsOneWidget);
    // Form stays in the app locale.
    expect(find.text('Giriş Yap'), findsOneWidget);
  });

  testWidgets('LoginHeroLayout renders Arabic panel right-to-left', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 768);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('ar')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _pumpHero(tester);

    expect(tester.takeException(), isNull);
    final cta = find.text('هل أنت مستعد للاستكشاف؟');
    expect(cta, findsOneWidget);
    expect(Directionality.of(tester.element(cta)), TextDirection.rtl);
  });

  testWidgets('LoginHeroLayout language picker overrides detected language', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 768);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _pumpHero(tester);

    await tester.tap(find.byTooltip('Metin dili'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Español').last);
    await tester.pumpAndSettle();

    expect(find.text('¿Listo para explorar?'), findsOneWidget);
    expect(find.text('Keşfetmeye Hazır mısınız?'), findsNothing);
  });

  test('LoginHeroTexts.detect picks first supported language', () {
    expect(
      LoginHeroTexts.detect(const [
        Locale('ja'),
        Locale('fr', 'CA'),
      ]).languageCode,
      'fr',
    );
    expect(
      LoginHeroTexts.detect(const [
        Locale('ja'),
      ], fallback: const Locale('en')).languageCode,
      'en',
    );
    expect(LoginHeroTexts.detect(const [Locale('ja')]).languageCode, 'tr');
  });
}

Future<void> _pumpHero(WidgetTester tester) async {
  await tester.pumpWidget(
    _wrap(
      Scaffold(
        body: LoginHeroLayout(
          onSubmit: (_, _, _, _) async {},
          onMessage: (_, _) {},
        ),
      ),
    ),
  );
  await tester.pump();
}
