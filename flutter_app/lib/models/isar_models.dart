import 'package:isar_community/isar.dart';
part 'isar_models.g.dart';

@collection
class UserProgress {
  Id id = Isar.autoIncrement;
  List<String> finishedLessonNames = [];

  int totalBuildsCreated = 0;
}

@collection
class BlockBuild {
  Id id = Isar.autoIncrement;

  late String buildName;
  late DateTime saveDate;
  String? imageBase64;

  // This will hold the JSON string sent from Unity
  // containing all block positions, colors, and sizes.
  late String sceneDataJson;
}
