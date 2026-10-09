import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/l10n/app_localizations.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/screens/admin_portal/admin_home_screen.dart';
import 'package:my_edu_app/screens/secretary_portal/secretary_dashboard_screen.dart';
import 'package:my_edu_app/screens/teacher_menu_screen.dart';
import 'package:my_edu_app/services/account_service.dart';
import 'package:my_edu_app/theme/app_spacing.dart';
import 'package:my_edu_app/theme/app_theme.dart';
import 'package:my_edu_app/widgets/design/design_class_grid_card.dart';
import 'package:my_edu_app/widgets/design/design_feed_row.dart';
import 'package:my_edu_app/widgets/design/design_hub_tile.dart';
import 'package:my_edu_app/widgets/design/design_mini_month_calendar.dart';
import 'package:my_edu_app/widgets/design/design_pill.dart';
import 'package:my_edu_app/widgets/design/design_stat_card.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Widget _harness(AppState state, Widget home) {
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
      home: home,
    ),
  );
}

Future<void> _pumpAt(
  WidgetTester tester,
  AppState state,
  Widget home,
  Size size,
) async {
  // Varsayılan test DPR'si 3.0; mantıksal genişlik = fiziksel / DPR olduğundan
  // QA genişliklerini gerçekten uygulamak için DPR 1.0 kullanılır.
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(state, home));
  await tester.pump();
  await _settle(tester);
}

/// sqflite ffi gerçek asenkron I/O kullanır; FakeAsync dışında bekle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(seconds: 1));
}

/// Tüm QA genişliklerinde yeniden boyutlandır; hiçbir istisna olmamalı.
Future<void> _sweepQaWidths(WidgetTester tester) async {
  for (final w in AppSpacing.qaWidths) {
    tester.view.physicalSize = Size(w, 900);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull, reason: 'width $w');
  }
  await _settle(tester);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late AppState state;

  setUp(() async {
    db = AppDatabase('hub_fazb_${DateTime.now().microsecondsSinceEpoch}.sqlite');
    await db.open();
    state = await AppState.createWithDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('FAZ B — 14 Sekreter hub', () {
    setUp(() async {
      state.setUnlocked(true, role: AppRole.secretary);
      await state.refreshUnreadNotifications();
    });

    for (final w in <double>[360, 1440]) {
      testWidgets('renders hubs without exceptions at ${w.toInt()}', (
        tester,
      ) async {
        await _pumpAt(
          tester,
          state,
          const Scaffold(body: SecretaryDashboardScreen()),
          Size(w, 900),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Öğrenci İşlemleri'), findsOneWidget);
        expect(find.text('Veli İşlemleri'), findsOneWidget);
        expect(find.text('Raporlar'), findsOneWidget);
        // 4 öğrenci + 2 veli + 2 rapor (mevcut eylemler; hiçbiri silinmedi).
        expect(find.byType(DesignHubTile), findsNWidgets(8));
        // KPI verisi ikincil şeritte hâlâ yükleniyor.
        expect(find.text('Genel Bakış'), findsOneWidget);
        final firstTile = tester.getTopLeft(find.byType(DesignHubTile).first);
        final overview = tester.getTopLeft(find.text('Genel Bakış'));
        expect(firstTile.dy, lessThan(overview.dy));
      });
    }

    testWidgets('no overflow across all QA widths', (tester) async {
      await _pumpAt(
        tester,
        state,
        const Scaffold(body: SecretaryDashboardScreen()),
        const Size(360, 900),
      );
      await _sweepQaWidths(tester);
    });

    testWidgets('hub grid: 1 column at 360, 4 columns at 1440', (tester) async {
      await _pumpAt(
        tester,
        state,
        const Scaffold(body: SecretaryDashboardScreen()),
        const Size(360, 900),
      );
      var tiles = find.byType(DesignHubTile);
      expect(
        tester.getTopLeft(tiles.at(0)).dy,
        lessThan(tester.getTopLeft(tiles.at(1)).dy),
      );

      await _pumpAt(
        tester,
        state,
        const Scaffold(body: SecretaryDashboardScreen()),
        const Size(1440, 900),
      );
      tiles = find.byType(DesignHubTile);
      final y0 = tester.getTopLeft(tiles.at(0)).dy;
      expect(tester.getTopLeft(tiles.at(3)).dy, y0);
      // Tutarlı tile yüksekliği.
      expect(
        tester.getSize(tiles.at(0)).height,
        tester.getSize(tiles.at(5)).height,
      );
    });
  });

  group('FAZ B — 02 Admin dashboard', () {
    late int adminId;

    setUp(() async {
      adminId = await AccountService(db, actorAccountId: 0).createBootstrapAdmin(
        username: 'admin.fazb',
        fullName: 'Faz B Admin',
        passwordPlain: 'AdminPass123!',
      );
      state.setUnlocked(true, role: AppRole.admin);
      state.setAccountSession(adminId);
      await db.insertStudentAnnouncement(title: 'Okul Duyurusu', body: 'Metin');
    });

    for (final w in <double>[360, 1024, 1440]) {
      testWidgets('renders without exceptions at ${w.toInt()}', (tester) async {
        await _pumpAt(
          tester,
          state,
          const Scaffold(body: AdminHomeScreen()),
          Size(w, 900),
        );
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Hoş Geldiniz'), findsOneWidget);
        expect(find.byType(DesignStatCard), findsNWidgets(4));
        expect(find.byType(DesignMiniMonthCalendar), findsOneWidget);
        // Gerçek duyuru + hedef kitle hapı.
        expect(find.byType(DesignFeedRow), findsOneWidget);
        expect(find.byType(DesignPill), findsOneWidget);
        expect(find.text('Tüm Okul'), findsOneWidget);
      });
    }

    testWidgets('no overflow across all QA widths', (tester) async {
      await _pumpAt(
        tester,
        state,
        const Scaffold(body: AdminHomeScreen()),
        const Size(360, 900),
      );
      await _sweepQaWidths(tester);
    });

    testWidgets('KPI 2x2 at 360 and single row at 1440', (tester) async {
      await _pumpAt(
        tester,
        state,
        const Scaffold(body: AdminHomeScreen()),
        const Size(360, 900),
      );
      var cards = find.byType(DesignStatCard);
      expect(
        tester.getTopLeft(cards.at(0)).dy,
        tester.getTopLeft(cards.at(1)).dy,
      );
      expect(
        tester.getTopLeft(cards.at(2)).dy,
        greaterThan(tester.getTopLeft(cards.at(0)).dy),
      );

      await _pumpAt(
        tester,
        state,
        const Scaffold(body: AdminHomeScreen()),
        const Size(1440, 900),
      );
      cards = find.byType(DesignStatCard);
      final y = tester.getTopLeft(cards.at(0)).dy;
      for (var i = 1; i < 4; i++) {
        expect(tester.getTopLeft(cards.at(i)).dy, y);
      }
    });

    testWidgets('two columns at 1024, stacked at 360', (tester) async {
      await _pumpAt(
        tester,
        state,
        const Scaffold(body: AdminHomeScreen()),
        const Size(1024, 900),
      );
      final feed = find.byType(DesignFeedRow);
      final calendar = find.byType(DesignMiniMonthCalendar);
      // Sağ kolon: takvim, duyuruların sağında ve yaklaşık 2:1 oran.
      expect(
        tester.getTopLeft(calendar).dx,
        greaterThan(tester.getTopRight(feed).dx),
      );
      final feedCardW = tester.getSize(feed).width;
      final calW = tester.getSize(calendar).width;
      expect(feedCardW, greaterThan(calW));

      await _pumpAt(
        tester,
        state,
        const Scaffold(body: AdminHomeScreen()),
        const Size(360, 900),
      );
      // Dar: takvim duyuru satırıyla aynı sol hizada (alt alta).
      expect(
        tester.getTopLeft(find.byType(DesignMiniMonthCalendar)).dx,
        lessThan(40),
      );
      expect(
        tester.getTopLeft(find.byType(DesignMiniMonthCalendar)).dy,
        greaterThan(tester.getBottomLeft(find.byType(DesignFeedRow)).dy),
      );
    });
  });

  group('FAZ B — 13 Öğretmen paneli', () {
    setUp(() async {
      await db.insertStudentClass('8', '2025', section: 'A');
      await db.insertStudentClass('8', '2025', section: 'B');
      state.setUnlocked(true, role: AppRole.teacher);
      await state.refreshUnreadNotifications();
    });

    for (final w in <double>[360, 1440]) {
      testWidgets('primary row on top, no exceptions at ${w.toInt()}', (
        tester,
      ) async {
        await _pumpAt(tester, state, const TeacherMenuScreen(), Size(w, 900));
        expect(tester.takeException(), isNull);
        // KPI etiketi de "Sınıflarım" olabilir; birincil başlık ilk sıradadır.
        expect(find.text('Sınıflarım'), findsWidgets);
        expect(find.text('Güncel Dersler'), findsWidgets);
        expect(find.byType(DesignClassGridCard), findsNWidgets(2));
        // İkincil bölümler korunur (varsayılan açık) ve primary'nin altında.
        expect(find.text('Hızlı İşlemler'), findsOneWidget);
        expect(find.text('Son İşlemler'), findsOneWidget);
        expect(find.text('Sınıf Defterim'), findsOneWidget);
        final primary = tester.getTopLeft(find.text('Sınıflarım').first).dy;
        final secondary = tester.getTopLeft(find.text('Özet ve Duyurular')).dy;
        expect(primary, lessThan(secondary));
        expect(
          secondary,
          lessThan(tester.getTopLeft(find.text('Çalışma Alanı')).dy),
        );
      });
    }

    testWidgets('no overflow across all QA widths', (tester) async {
      await _pumpAt(
        tester,
        state,
        const TeacherMenuScreen(),
        const Size(360, 900),
      );
      await _sweepQaWidths(tester);
    });

    testWidgets('class cards are a 2x2 grid at 390', (tester) async {
      await _pumpAt(
        tester,
        state,
        const TeacherMenuScreen(),
        const Size(390, 900),
      );
      final cards = find.byType(DesignClassGridCard);
      expect(
        tester.getTopLeft(cards.at(0)).dy,
        tester.getTopLeft(cards.at(1)).dy,
      );
    });

    testWidgets('secondary sections can be collapsed and expanded', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        state,
        const TeacherMenuScreen(),
        const Size(1280, 900),
      );
      expect(find.text('Hızlı İşlemler'), findsOneWidget);
      await tester.tap(find.text('Çalışma Alanı'));
      await tester.pump();
      expect(find.text('Hızlı İşlemler'), findsNothing);
      // Birincil satır etkilenmez.
      expect(find.text('Sınıflarım'), findsWidgets);
      await tester.tap(find.text('Çalışma Alanı'));
      await tester.pump();
      expect(find.text('Hızlı İşlemler'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
