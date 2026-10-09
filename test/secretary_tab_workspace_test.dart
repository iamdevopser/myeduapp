import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/l10n/app_localizations.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/screens/secretary_portal/secretary_tab_workspace.dart';
import 'package:my_edu_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Widget _secretaryHarness(AppState state) {
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
      home: const SecretaryTabWorkspace(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late AppState state;

  setUp(() async {
    db = AppDatabase('sec_tab_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
    state = await AppState.createWithDatabase(db);
    state.setUnlocked(true, role: AppRole.secretary);
    await state.refreshUnreadNotifications();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('renders on phone width without crash', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_secretaryHarness(state));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SecretaryTabWorkspace), findsOneWidget);
  });

  testWidgets('renders on desktop width without crash', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(_secretaryHarness(state));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SecretaryTabWorkspace), findsOneWidget);
  });
}
