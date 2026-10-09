import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/l10n/app_localizations.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/screens/teacher_menu_screen.dart';
import 'package:my_edu_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Widget _teacherMenuHarness(AppState state) {
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
      home: const TeacherMenuScreen(),
    ),
  );
}

Future<AppDatabase> _openTestDb() async {
  final db = AppDatabase(
    'teacher_menu_${DateTime.now().microsecondsSinceEpoch}.sqlite',
  );
  await db.open();
  return db;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TeacherMenuScreen responsive (FAZ 8)', () {
    late AppState state;

    setUp(() async {
      state = await AppState.createWithDatabase(
        await _openTestDb(),
      );
      state.setUnlocked(true, role: AppRole.teacher);
      await state.refreshUnreadNotifications();
    });

    tearDown(() async {
      await state.db.close();
    });

    testWidgets('renders core sections on phone width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(_teacherMenuHarness(state));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Öğretmen Paneli'), findsOneWidget);
      expect(find.text('Güncel Dersler'), findsOneWidget);
      expect(find.text('Hızlı İşlemler'), findsOneWidget);
      expect(find.text('Sınıflarım'), findsOneWidget);
      expect(find.text('Son İşlemler'), findsOneWidget);
      expect(find.text('Sınıf Defterim'), findsOneWidget);
    });

    testWidgets('renders core sections on desktop width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(_teacherMenuHarness(state));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Öğretmen Paneli'), findsOneWidget);
      expect(find.text('Güncel Dersler'), findsOneWidget);
      expect(find.text('Hızlı İşlemler'), findsOneWidget);
      expect(find.text('Son İşlemler'), findsOneWidget);
    });
  });
}
