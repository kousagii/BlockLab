import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_flutter/models/isar_models.dart';
import 'package:unity_flutter/services/isar_service.dart';
import 'package:unity_flutter/services/profile_service.dart';
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
