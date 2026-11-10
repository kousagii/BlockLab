import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_flutter/design/app_theme.dart';
import 'package:unity_flutter/models/isar_models.dart';
import 'package:unity_flutter/models/lesson.dart';
import 'package:unity_flutter/screens/home_screen.dart';
import 'package:unity_flutter/screens/name_input_screen.dart';
import 'package:unity_flutter/screens/settings_screen.dart';
import 'package:unity_flutter/screens/works_screen.dart';
import 'package:unity_flutter/screens/lessons_screen.dart';
import 'package:unity_flutter/screens/lesson_detail_screen.dart';
import 'package:unity_flutter/screens/lesson_guide.dart';
import 'package:unity_flutter/services/appearance_controller.dart';
import 'package:unity_flutter/services/isar_service.dart';
import 'package:unity_flutter/services/profile_service.dart';
import 'scene_document_test.dart' show fixture;

class PreviewStore extends IsarService {
  PreviewStore() : super(database: Completer<Isar>().future);
  @override
  Future<List<BlockBuild>> getAllBuilds() async => [
    BlockBuild()
      ..id = 1
      ..buildName = 'My colorful little city'
      ..saveDate = DateTime(2026, 11, 11)
      ..sceneDataJson = fixture(),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'appearance survives restart and missing preferences default to system',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final appearance = AppearanceController(preferences);
      expect(appearance.mode, ThemeMode.system);
      await appearance.setMode(ThemeMode.dark);
      expect(AppearanceController(preferences).mode, ThemeMode.dark);
      await appearance.setMode(ThemeMode.light);
      expect(AppearanceController(preferences).mode, ThemeMode.light);
    },
  );
  testWidgets('theme changes retain the current route and its edits', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceController(
      await SharedPreferences.getInstance(),
    );
    await tester.pumpWidget(
      AppearanceScope(
        controller: appearance,
        child: ListenableBuilder(
          listenable: appearance,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.build(Brightness.light),
            darkTheme: AppTheme.build(Brightness.dark),
            themeMode: appearance.mode,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: TextField()),
                    ),
                  ),
                  child: const Text('Edit'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Unsaved idea');
    final editor = tester.state(find.byType(TextField));
    await appearance.setMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(TextField)), same(editor));
    expect(find.text('Unsaved idea'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(TextField))).brightness,
      Brightness.dark,
    );
  });
  testWidgets('phone layouts remain readable at normal and double text size', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'profile.name': 'Alex',
      'profile.accepted': true,
    });
    final preferences = await SharedPreferences.getInstance();
    final profile = ProfileService(preferences), store = PreviewStore();
    final appearance = AppearanceController(preferences);
    final lessons = await Lesson.load();
    final font = FontLoader('Nunito');
    for (final weight in [400, 600, 700, 800]) {
      font.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final brightness in Brightness.values) {
      for (final width in [320.0, 390.0, 760.0]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          final pages = <String, Widget>{
            'home': HomeScreen(isarService: store, profile: profile),
            'works': Scaffold(body: WorksScreen(isarService: store)),
            'lessons': Scaffold(
              body: LessonsScreen(isarService: store, profile: profile),
            ),
            'lesson': LessonDetailScreen(
              lesson: lessons.first,
              isarService: store,
              profile: profile,
            ),
            'settings': const SettingsScreen(),
            'onboarding': NameInputScreen(isarService: store, profile: profile),
            'lesson-guide': Scaffold(
              body: Column(
                children: [
                  LessonGuide(
                    lesson: lessons.first,
                    profile: profile,
                    onComplete: () async {},
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          };
          for (final page in pages.entries) {
            final key = GlobalKey();
            await tester.pumpWidget(
              AppearanceScope(
                controller: appearance,
                child: MaterialApp(
                  theme: AppTheme.build(brightness),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: RepaintBoundary(key: key, child: page.value),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${page.key}: $brightness, width $width, scale $scale',
            );
            if (width == 390 &&
                scale == 1 &&
                const bool.fromEnvironment('CAPTURE_DESIGN')) {
              final boundary =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              await tester.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: 2);
                final png = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final output = File(
                  '../docs/screenshots/${page.key}-${brightness.name}.png',
                );
                await output.parent.create(recursive: true);
                await output.writeAsBytes(png!.buffer.asUint8List());
                image.dispose();
              });
            }
          }
        }
      }
    }
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}
