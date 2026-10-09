// Screenshot-only tool (NOT part of the app). Renders the three FAZ B hub
// screens inside their real workspace/AppShell and saves PNGs.
//
// Run: flutter test tool/design_screenshots/hub_screenshots_test.dart
//
// Uses an in-memory sqlite DB seeded with fixture data. Nothing under lib/ is
// modified.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_edu_app/data/local/app_database.dart';
import 'package:my_edu_app/l10n/app_localizations.dart';
import 'package:my_edu_app/models/app_role.dart';
import 'package:my_edu_app/providers/app_state.dart';
import 'package:my_edu_app/screens/admin_portal/admin_home_screen.dart';
import 'package:my_edu_app/screens/admin_portal/admin_tab_workspace.dart';
import 'package:my_edu_app/screens/secretary_portal/secretary_dashboard_screen.dart';
import 'package:my_edu_app/screens/secretary_portal/secretary_tab_workspace.dart';
import 'package:my_edu_app/screens/teacher_menu_screen.dart';
import 'package:my_edu_app/services/account_service.dart';
import 'package:my_edu_app/theme/app_spacing.dart';
import 'package:my_edu_app/theme/app_theme.dart';
import 'package:my_edu_app/widgets/app_workspace_background.dart';
import 'package:my_edu_app/widgets/design/design_page_container.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String _outDir = 'docs/design/screenshots/fazb';
const String _fontDir = r'C:\flutter\bin\cache\artifacts\material_fonts';

final GlobalKey _boundaryKey = GlobalKey();
final List<String> _fontReport = <String>[];
final List<String> _measureLines = <String>[];
final List<String> _flutterErrors = <String>[];

Widget _harness(AppState state, Widget home) {
  return RepaintBoundary(
    key: _boundaryKey,
    child: ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
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
    ),
  );
}

Future<void> _loadFonts() async {
  Future<ByteData?> read(String file) async {
    final f = File('$_fontDir\\$file');
    if (!f.existsSync()) {
      _fontReport.add('MISSING: ${f.path}');
      return null;
    }
    final bytes = f.readAsBytesSync();
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  final roboto = FontLoader('Roboto');
  for (final name in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-light.ttf',
  ]) {
    final data = await read(name);
    if (data != null) {
      roboto.addFont(Future.value(data));
      _fontReport.add('loaded Roboto <- $name');
    }
  }
  await roboto.load();

  final icons = FontLoader('MaterialIcons');
  final iconData = await read('materialicons-regular.otf');
  if (iconData != null) {
    icons.addFont(Future.value(iconData));
    _fontReport.add('loaded MaterialIcons <- materialicons-regular.otf');
  }
  await icons.load();
}

/// sqflite ffi uses real async I/O; wait outside FakeAsync.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(seconds: 1));
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  } catch (_) {
    // Infinite animation (e.g. progress indicator): fall back to fixed pumps.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }
}

Future<void> _pumpAt(
  WidgetTester tester,
  AppState state,
  Widget home,
  Size size,
) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  await tester.pumpWidget(_harness(state, home));
  await tester.pump();
  await _settle(tester);
}

Future<void> _capture(WidgetTester tester, String path) async {
  final boundary = _boundaryKey.currentContext!.findRenderObject()!
      as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

String _hex(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

String _fmt(Size s) => '${s.width.toStringAsFixed(1)} x ${s.height.toStringAsFixed(1)}';

Finder _byTypeName(String name) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

void _measure(
  WidgetTester tester,
  String screen,
  int width,
  Type screenType,
) {
  final b = StringBuffer();
  b.writeln('### $screen @ $width');
  b.writeln();
  final ctx = tester.element(find.byType(Scaffold).first);
  b.writeln('- Viewport width: $width');
  b.writeln(
    '- theme colorScheme.primary: ${_hex(Theme.of(ctx).colorScheme.primary)}',
  );
  final sidebar = _byTypeName('_AppSidebar');
  if (sidebar.evaluate().isNotEmpty) {
    b.writeln('- Sidebar (_AppSidebar) size: ${_fmt(tester.getSize(sidebar.first))}');
  } else {
    b.writeln('- Sidebar: not rendered inline (mobile drawer layout)');
  }
  final bg = find.byType(AppWorkspaceBackground);
  if (bg.evaluate().isNotEmpty) {
    b.writeln(
      '- AppShell content area (AppWorkspaceBackground): ${_fmt(tester.getSize(bg.first))}',
    );
  }
  final screenFinder = screenType == TeacherMenuScreen
      ? _byTypeName('_DashboardBody')
      : find.byType(screenType);
  if (screenFinder.evaluate().isNotEmpty) {
    final r = tester.getRect(screenFinder.first);
    b.writeln(
      '- Constrained content (AppShell `constrainContent` child, cap '
      '${AppSpacing.contentMaxWidth.toInt()}): ${_fmt(r.size)} '
      '(left=${r.left.toStringAsFixed(1)})',
    );
  }
  final pc = find.byType(DesignPageContainer);
  if (pc.evaluate().isNotEmpty) {
    b.writeln('- First DesignPageContainer size: ${_fmt(tester.getSize(pc.first))}');
  }

  void buttons(String label, Finder f) {
    final els = f.evaluate().toList();
    if (els.isEmpty) {
      b.writeln('- $label: none found');
      return;
    }
    final sizes = <String>[];
    for (var i = 0; i < els.length && i < 4; i++) {
      sizes.add(_fmt(tester.getSize(f.at(i))));
    }
    b.writeln('- $label (count ${els.length}, first ${sizes.length}): ${sizes.join('; ')}');
  }

  buttons('FilledButton', find.byWidgetPredicate((w) => w is FilledButton));
  buttons('OutlinedButton', find.byWidgetPredicate((w) => w is OutlinedButton));
  buttons('TextButton', find.byWidgetPredicate((w) => w is TextButton));
  buttons('IconButton', find.byWidgetPredicate((w) => w is IconButton));
  b.writeln();
  _measureLines.add(b.toString());
}

Future<void> _seed(AppDatabase db) async {
  final classIds = <String, int>{};
  const classes = <(String, String)>[
    ('9', 'A'),
    ('9', 'B'),
    ('10', 'A'),
    ('10', 'B'),
  ];
  for (final (name, section) in classes) {
    classIds['$name$section'] =
        await db.insertStudentClass(name, '2025', section: section);
  }
  const names = <String>[
    'Ayşe Yılmaz',
    'Mehmet Demir',
    'Elif Kaya',
    'Can Öztürk',
    'Zeynep Şahin',
    'Burak Çelik',
    'Selin Aydın',
    'Emre Arslan',
  ];
  var n = 0;
  for (final id in classIds.values) {
    for (var i = 1; i <= 4 + (n % 3); i++) {
      await db.insertStudent(
        classId: id,
        number: i,
        name: names[(n + i) % names.length],
      );
    }
    n++;
  }

  // 3 published announcements, different hedef_tur.
  await db.insertSecretaryAnnouncement(
    title: 'Veli Toplantısı Hakkında',
    body: 'Dönem sonu veli toplantısı Cuma günü yapılacaktır.',
    status: 'yayinda',
    targetType: 'tum_okul',
  );
  await db.insertSecretaryAnnouncement(
    title: '9. Sınıflar Gezi Duyurusu',
    body: 'Bilim müzesi gezisi için izin belgeleri toplanacaktır.',
    status: 'yayinda',
    targetType: 'sinif',
    targetGradeLevel: 9,
  );
  await db.insertSecretaryAnnouncement(
    title: '10-A Matematik Sınavı',
    body: 'Pazartesi günü 2. ders yazılı sınav yapılacaktır.',
    status: 'yayinda',
    targetType: 'sube',
    classId: classIds['10A'],
  );

  // A few weekly schedule lessons for today.
  final today = DateTime.now().weekday;
  const slots = <(int, String, String, String, String)>[
    (1, '08:30', '09:10', 'Matematik', '9A'),
    (2, '09:20', '10:00', 'Matematik', '9B'),
    (3, '10:10', '10:50', 'Geometri', '10A'),
    (4, '11:00', '11:40', 'Matematik', '10B'),
  ];
  for (final (period, start, end, subject, cls) in slots) {
    await db.insertWeeklyScheduleEntry(
      dayOfWeek: today,
      periodNumber: period,
      startTime: start,
      endTime: end,
      studentClassId: classIds[cls],
      subjectLabel: subject,
      classLabel: cls,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late AppState state;

  setUpAll(() async {
    await _loadFonts();
  });

  setUp(() async {
    db = AppDatabase(inMemoryDatabasePath);
    await db.open();
    state = await AppState.createWithDatabase(db);
    await _seed(db);
    final prevHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      _flutterErrors.add(details.exceptionAsString());
      prevHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = prevHandler);
  });

  tearDown(() async {
    await db.close();
  });

  tearDownAll(() async {
    final out = StringBuffer()
      ..writeln('# FAZ B hub screenshots — measurements')
      ..writeln()
      ..writeln('Generated by `tool/design_screenshots/hub_screenshots_test.dart`.')
      ..writeln('devicePixelRatio forced to 1.0 (logical px == image px).')
      ..writeln(
        'Sidebar note: `_AppSidebar` is collapsed (${AppSpacing.sidebarCollapsed.toInt()} px) '
        'by default on desktop and only expands to ${AppSpacing.sidebarWidth.toInt()} px on hover/tap.',
      )
      ..writeln()
      ..writeln('## Fonts')
      ..writeln();
    for (final l in _fontReport) {
      out.writeln('- $l');
    }
    out
      ..writeln()
      ..writeln('## Measurements')
      ..writeln();
    for (final l in _measureLines) {
      out.write(l);
    }
    out
      ..writeln('## Flutter errors during capture')
      ..writeln();
    if (_flutterErrors.isEmpty) {
      out.writeln('None.');
    } else {
      for (final e in _flutterErrors) {
        out
          ..writeln('```')
          ..writeln(e)
          ..writeln('```');
      }
    }
    final f = File('$_outDir/measurements.md');
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(out.toString());
  });

  const widths = <(int, int)>[(390, 844), (1024, 768), (1280, 800), (1920, 1080)];

  final screens = <String, ({Widget Function() build, Type type, Future<void> Function() session})>{
    'admin': (
      build: () => const AdminTabWorkspace(),
      type: AdminHomeScreen,
      session: () async {
        final adminId = await AccountService(db, actorAccountId: 0)
            .createBootstrapAdmin(
          username: 'admin.shots',
          fullName: 'Sistem Yöneticisi',
          passwordPlain: 'AdminPass123!',
        );
        state.setUnlocked(true, role: AppRole.admin);
        state.setAccountSession(adminId);
        await state.refreshUnreadNotifications();
      },
    ),
    'teacher': (
      build: () => const TeacherMenuScreen(),
      type: TeacherMenuScreen,
      session: () async {
        state.setUnlocked(true, role: AppRole.teacher);
        await state.refreshUnreadNotifications();
      },
    ),
    'secretary': (
      build: () => const SecretaryTabWorkspace(),
      type: SecretaryDashboardScreen,
      session: () async {
        state.setUnlocked(true, role: AppRole.secretary);
        await state.refreshUnreadNotifications();
      },
    ),
  };

  for (final entry in screens.entries) {
    final name = entry.key;
    final cfg = entry.value;
    group(name, () {
    setUp(() async => cfg.session());
    for (final (w, h) in widths) {
      testWidgets('$name screenshot ${w}x$h', (tester) async {
        addTearDown(tester.view.reset);
        await _pumpAt(tester, state, cfg.build(), Size(w.toDouble(), h.toDouble()));
        await _capture(tester, '$_outDir/${name}_$w.png');
        // Surface (but do not fail on) layout exceptions such as overflows.
        final ex = tester.takeException();
        if (ex != null) _flutterErrors.add('[$name @ $w] $ex');
      });
    }
    for (final w in <int>[1920, 1440]) {
      testWidgets('$name measurements @ $w', (tester) async {
        addTearDown(tester.view.reset);
        await _pumpAt(tester, state, cfg.build(), Size(w.toDouble(), 1000));
        _measure(tester, name, w, cfg.type);
        final ex = tester.takeException();
        if (ex != null) _flutterErrors.add('[$name measure @ $w] $ex');
      });
    }
    });
  }
}
