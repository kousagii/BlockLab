import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_flutter/design/app_theme.dart';
import 'package:unity_flutter/models/lesson.dart';
import 'package:unity_flutter/screens/lesson_guide.dart';
import 'package:unity_flutter/services/profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'expanded beginner steps show explanations, checks and reachable navigation',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final profile = ProfileService(await SharedPreferences.getInstance());
      final catalog = await Lesson.load();
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      for (final scale in [1.0, 2.0]) {
        for (final lesson in catalog.where(
          (l) => l.id == 'basics' || l.id == 'dimensions',
        )) {
          for (var index = 0; index < lesson.steps.length; index++) {
            await profile.saveLessonStep(lesson.id, index);
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.build(
                  scale == 1 ? Brightness.light : Brightness.dark,
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: Column(
                    children: [
                      LessonGuide(
                        key: ValueKey('${lesson.id}-$index-$scale'),
                        lesson: lesson,
                        profile: profile,
                        onComplete: () async {},
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final step = lesson.steps[index];
            expect(find.text(step['title'] as String), findsOneWidget);
            expect(find.text('Look for: ${step['check']}'), findsOneWidget);
            await tester.ensureVisible(
              find.text(
                index == lesson.steps.length - 1 ? 'Mark complete' : 'Next',
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${lesson.id} step $index at scale $scale',
            );
          }
        }
      }
    },
  );
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
