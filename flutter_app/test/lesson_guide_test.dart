import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_flutter/design/app_theme.dart';
import 'package:unity_flutter/models/lesson.dart';
import 'package:unity_flutter/screens/lesson_guide.dart';
import 'package:unity_flutter/services/profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Lesson lesson() => Lesson({
    'id': 'guide-test',
    'title': 'Build a tower',
    'difficulty': 'Beginner',
    'source': 'Synthetic test content',
    'steps': [
      {'text': 'Place a cube.'},
      {'text': 'Add a second cube.'},
    ],
  });
  testWidgets(
    'steps persist, collapse preserves progress, and completion remains explicit',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final profile = ProfileService(await SharedPreferences.getInstance());
      var completions = 0;
      Widget page() => MaterialApp(
        theme: AppTheme.build(Brightness.light),
        home: Scaffold(
          body: Column(
            children: [
              LessonGuide(
                lesson: lesson(),
                profile: profile,
                onComplete: () async {
                  completions++;
                  await profile.completeLesson('guide-test');
                },
              ),
              const Expanded(child: Center(child: Text('Building workspace'))),
            ],
          ),
        ),
      );
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.text('Place a cube.'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(profile.stepForLesson('guide-test'), 1);
      expect(completions, 0);
      await tester.tap(find.byTooltip('Collapse lesson'));
      await tester.pumpAndSettle();
      expect(find.text('Add a second cube.'), findsNothing);
      await tester.tap(find.byTooltip('Expand lesson'));
      await tester.pumpAndSettle();
      expect(find.text('Add a second cube.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.text('Lesson · Step 2 of 2'), findsOneWidget);
      await tester.tap(find.text('Mark complete'));
      await tester.pumpAndSettle();
      expect(completions, 1);
      expect(profile.completed, contains('guide-test'));
    },
  );
  testWidgets(
    'guide fits a narrow phone with doubled text without covering the workspace',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final profile = ProfileService(await SharedPreferences.getInstance());
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Column(
              children: [
                LessonGuide(
                  lesson: lesson(),
                  profile: profile,
                  onComplete: () async {},
                ),
                const Expanded(child: SizedBox(key: ValueKey('workspace'))),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('workspace'))).height,
        greaterThan(200),
      );
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
