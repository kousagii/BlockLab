import 'dart:ffi';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_flutter/models/isar_models.dart';
import 'package:unity_flutter/services/isar_service.dart';
import 'package:unity_flutter/services/profile_service.dart';
import 'package:unity_flutter/models/lesson.dart';
import 'package:unity_flutter/screens/lesson_guide.dart';
import 'package:unity_flutter/design/app_theme.dart';
import 'scene_document_test.dart' show fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final config = File('.dart_tool/package_config.json');
    final packages =
        jsonDecode(await config.readAsString())['packages'] as List;
    final package =
        packages.singleWhere(
              (dynamic p) => p['name'] == 'isar_community_flutter_libs',
            )
            as Map;
    final uri = package['rootUri'] as String;
    final root = config.absolute.uri.resolve(uri.endsWith('/') ? uri : '$uri/');
    final native = Platform.isWindows
        ? 'windows/libisar.dll'
        : 'linux/libisar.so';
    final library = File.fromUri(root.resolve(native)).path;
    await Isar.initializeIsarCore(libraries: {Abi.current(): library});
  });
  test(
    'genuine Isar 3.1 database opens with preserved work and lesson status',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'blocklab_legacy_',
      );
      Isar? database;
      try {
        await File(
          'test/fixtures/isar3/default.isar',
        ).copy('${directory.path}/default.isar');
        database = await Isar.open(
          [BlockBuildSchema, UserProgressSchema],
          directory: directory.path,
          inspector: false,
        );
        final store = IsarService(database: Future.value(database));
        final work = (await store.getAllBuilds()).single;
        expect(work.buildName, 'Legacy house');
        expect(work.saveDate, DateTime(2025, 1, 2));
        expect(
          (await database.userProgress.where().findFirst())!
              .finishedLessonNames,
          ['The Basics'],
        );
        await store.completeLesson('Dimensions and shapes');
        expect(
          (await database.userProgress.where().findFirst())!
              .finishedLessonNames,
          ['The Basics', 'Dimensions and shapes'],
        );
        await store.updateBuild(work.id, fixture(), null);
        expect((await store.getAllBuilds()).single.id, work.id);
      } finally {
        await database?.close();
        await directory.delete(recursive: true);
      }
    },
  );
  test('profile persists name, acceptance and unique completion', () async {
    SharedPreferences.setMockInitialValues({});
    final profile = ProfileService(await SharedPreferences.getInstance());
    await profile.onboard('  Alex  ');
    await profile.startLesson('house');
    await profile.completeLesson('house');
    await profile.completeLesson('house');
    final reopened = ProfileService(await SharedPreferences.getInstance());
    expect(reopened.name, 'Alex');
    expect(reopened.accepted, isTrue);
    expect(reopened.lastLesson, 'house');
    expect(reopened.completed, ['house']);
  });

  test(
    'lesson completion appends to stored progress, stays unique and survives reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'blocklab_completion_',
      );
      Isar? database;
      try {
        database = await Isar.open(
          [BlockBuildSchema, UserProgressSchema],
          directory: directory.path,
          name: 'completion',
          inspector: false,
        );
        var store = IsarService(database: Future.value(database));
        final buildId = await store.saveNewBuild(
          'Lesson work',
          fixture(),
          null,
        );
        await store.completeLesson('The Basics');
        await store.completeLesson('The Basics');
        await store.completeLesson('Dimensions and shapes');
        expect(
          (await database.userProgress.where().findFirst())!
              .finishedLessonNames,
          ['The Basics', 'Dimensions and shapes'],
        );
        await database.close();
        database = await Isar.open(
          [BlockBuildSchema, UserProgressSchema],
          directory: directory.path,
          name: 'completion',
          inspector: false,
        );
        store = IsarService(database: Future.value(database));
        final progress = (await database.userProgress.where().findFirst())!;
        expect(progress.finishedLessonNames, [
          'The Basics',
          'Dimensions and shapes',
        ]);
        expect(progress.totalBuildsCreated, 1);
        expect((await store.getAllBuilds()).single.id, buildId);
      } finally {
        await database?.close();
        await directory.delete(recursive: true);
      }
    },
  );

  testWidgets(
    'Mark complete persists through the real database and profile without an error',
    (tester) async {
      Directory? directory;
      Isar? database;
      late IsarService store;
      late ProfileService profile;
      late Completer<void> completed;
      try {
        await tester.runAsync(() async {
          directory = await Directory.systemTemp.createTemp(
            'blocklab_complete_ui_',
          );
          database = await Isar.open(
            [BlockBuildSchema, UserProgressSchema],
            directory: directory!.path,
            name: 'complete-ui',
            inspector: false,
          );
          // Create the database future in the real I/O zone, not the widget clock.
          store = IsarService(database: Future.value(database!));
          await store.saveNewBuild('Saved lesson', fixture(), null);
          SharedPreferences.setMockInitialValues({});
          profile = ProfileService(await SharedPreferences.getInstance());
          completed = Completer<void>();
        });
        final lesson = Lesson({
          'id': 'basics',
          'title': 'The Basics',
          'difficulty': 'Easy',
          'source': 'Synthetic test',
          'steps': [
            {'text': 'Finish the exercise.'},
          ],
        });
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.build(Brightness.light),
            home: Scaffold(
              body: LessonGuide(
                lesson: lesson,
                profile: profile,
                onComplete: () async {
                  try {
                    await store.completeLesson(lesson.title);
                    await profile.completeLesson(lesson.id);
                  } finally {
                    completed.complete();
                  }
                },
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          await tester.tap(find.text('Mark complete'));
          await completed.future.timeout(const Duration(seconds: 30));
        });
        await tester.pumpAndSettle();
        expect(
          find.text('Could not update lesson completion. Please retry.'),
          findsNothing,
        );
        expect(
          find.text('Lesson marked complete. You can keep building.'),
          findsOneWidget,
        );
        expect(profile.completed, contains('basics'));
        final stored = await tester.runAsync(
          () => database!.userProgress.where().findFirst(),
        );
        expect(stored!.finishedLessonNames, ['The Basics']);
        await tester.pumpWidget(const SizedBox());
      } finally {
        await tester.runAsync(() async {
          await database?.close();
          if (directory != null) await directory!.delete(recursive: true);
        });
      }
    },
  );

  test(
    'native database saves, updates same ID, reopens, renames and deletes',
    () async {
      final directory = await Directory.systemTemp.createTemp('blocklab_test_');
      Isar? database;
      try {
        database = await Isar.open(
          [BlockBuildSchema, UserProgressSchema],
          directory: directory.path,
          name: 'test',
          inspector: false,
        );
        var store = IsarService(database: Future.value(database));
        final id = await store.saveNewBuild('My work', fixture(), null);
        await store.updateBuild(id, fixture(), null);
        await store.updateBuild(id, fixture(), null);
        expect((await store.getAllBuilds()).length, 1);
        expect(
          (await store.getAllBuilds()).single.saveDate.year,
          greaterThan(2020),
        );
        await expectLater(
          store.updateBuild(id, '{"blocks":[{}]}', null),
          throwsFormatException,
        );
        expect((await store.getAllBuilds()).single.buildName, 'My work');
        await database.close();
        database = await Isar.open(
          [BlockBuildSchema, UserProgressSchema],
          directory: directory.path,
          name: 'test',
          inspector: false,
        );
        store = IsarService(database: Future.value(database));
        expect((await store.getAllBuilds()).single.id, id);
        await store.renameBuild(id, 'Renamed');
        expect((await store.getAllBuilds()).single.buildName, 'Renamed');
        await store.deleteBuild(id);
        expect(await store.getAllBuilds(), isEmpty);
      } finally {
        await database?.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
