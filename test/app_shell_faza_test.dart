import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/l10n/app_localizations.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/theme/app_spacing.dart';
import 'package:my_edu_app/theme/app_theme.dart';
import 'package:my_edu_app/widgets/app_shell.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _childKey = Key('shell_child');

Widget _harness(AppState state, {bool constrainContent = true}) {
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(
      locale: const Locale('tr'),
      theme: AppTheme.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppShell(
        title: 'Test',
        teacherSection: TeacherNavSection.home,
        constrainContent: constrainContent,
        child: const SizedBox.expand(key: _childKey),
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, AppState state, double width,
    {bool constrainContent = true}) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  await tester.pumpWidget(_harness(state, constrainContent: constrainContent));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppState state;
  final homeLabel = AppLocalizations(const Locale('tr')).t('homePage');

  setUp(() async {
    final db = AppDatabase(
      'app_shell_faza_${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    await db.open();
    state = await AppState.createWithDatabase(db);
    state.setUnlocked(true, role: AppRole.teacher);
    await state.refreshUnreadNotifications();
  });

  tearDown(() async {
    await state.db.close();
  });

  testWidgets('AppShell renders at QA widths without exceptions',
      (tester) async {
    for (final w in [360.0, 430.0, 1024.0, 1920.0]) {
      await _pump(tester, state, w);
      expect(tester.takeException(), isNull, reason: 'width $w');
      expect(find.byKey(_childKey), findsOneWidget, reason: 'width $w');
    }
  });

  testWidgets('mobile uses drawer + bottom nav, desktop uses sidebar',
      (tester) async {
    await _pump(tester, state, 360);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text(homeLabel), findsWidgets);

    await _pump(tester, state, 1024);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(Drawer), findsNothing);
    // Collapsed sidebar exposes labels through tooltips.
    expect(find.byTooltip(homeLabel), findsOneWidget);
  });

  testWidgets('nav items expose button semantics and >= 48 px height',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, state, 1024);

    final item = find.bySemanticsLabel(homeLabel);
    expect(item, findsWidgets);
    expect(tester.getSize(item.first).height,
        greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    expect(
      tester.getSemantics(item.first),
      matchesSemantics(
        label: homeLabel,
        isButton: true,
        isSelected: true,
        hasTapAction: true,
        hasSelectedState: true,
        hasEnabledState: false,
        isFocusable: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('content is centered with max width only on large desktop',
      (tester) async {
    await _pump(tester, state, 1920);
    expect(tester.getSize(find.byKey(_childKey)).width,
        AppSpacing.contentMaxWidth);

    await _pump(tester, state, 1920, constrainContent: false);
    expect(tester.getSize(find.byKey(_childKey)).width,
        greaterThan(AppSpacing.contentMaxWidth));

    await _pump(tester, state, 1280);
    expect(tester.getSize(find.byKey(_childKey)).width,
        1280 - AppSpacing.sidebarCollapsed);
  });
}
