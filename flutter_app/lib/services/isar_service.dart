import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/isar_models.dart';
import '../models/scene_document.dart';

class IsarService {
  Future<BlockBuild?> getBuild(int id) async => (await db).blockBuilds.get(id);
  late final Future<Isar> db;
  IsarService({Future<Isar>? database}) {
    db = database ?? openDB();
  }
  Future<Isar> openDB() async {
    final existing = Isar.getInstance();
    if (existing != null) return existing;
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open([
      UserProgressSchema,
      BlockBuildSchema,
    ], directory: dir.path);
  }

  Future<int> saveNewBuild(String name, String json, String? image) async {
    final scene = SceneDocument.parse(json);
    final isar = await db;
    final build = BlockBuild()
      ..buildName = name
      ..saveDate = DateTime.now()
      ..sceneDataJson = scene.encode()
      ..imageBase64 = image ?? scene.thumbnail;
    return isar.writeTxn(() async {
      final id = await isar.blockBuilds.put(build);
      final progress =
          await isar.userProgress.where().findFirst() ?? UserProgress();
      progress.totalBuildsCreated++;
      await isar.userProgress.put(progress);
      return id;
    });
  }

  Future<void> updateBuild(int id, String json, String? image) async {
    final scene = SceneDocument.parse(json);
    final isar = await db;
    await isar.writeTxn(() async {
      final build = await isar.blockBuilds.get(id);
      if (build == null) {
        throw StateError('This work was deleted. Reopen the sandbox.');
      }
      build.sceneDataJson = scene.encode();
      build.imageBase64 = image ?? scene.thumbnail;
      build.saveDate = DateTime.now();
      await isar.blockBuilds.put(build);
    });
  }

  Future<List<BlockBuild>> getAllBuilds() async {
    final builds = await (await db).blockBuilds.where().findAll();
    builds.sort((a, b) => b.saveDate.compareTo(a.saveDate));
    return builds;
  }

  Future<void> completeLesson(String name) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final progress =
          await isar.userProgress.where().findFirst() ?? UserProgress();
      if (!progress.finishedLessonNames.contains(name)) {
        progress.finishedLessonNames.add(name);
      }
      await isar.userProgress.put(progress);
    });
  }

  Future<void> deleteBuild(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.blockBuilds.delete(id);
    });
  }

  Future<void> renameBuild(int id, String name) async {
    if (name.trim().isEmpty) throw const FormatException('Enter a name.');
    final isar = await db;
    await isar.writeTxn(() async {
      final build = await isar.blockBuilds.get(id);
      if (build == null) throw StateError('Work no longer exists.');
      build.buildName = name.trim();
      await isar.blockBuilds.put(build);
    });
  }
}
