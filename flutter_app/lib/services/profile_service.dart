import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  final SharedPreferences preferences;
  ProfileService(this.preferences);
  String? get name => preferences.getString('profile.name');
  bool get accepted => preferences.getBool('profile.accepted') ?? false;
  String? get lastLesson => preferences.getString('lesson.last');
  int? buildForLesson(String id) => preferences.getInt('lesson.build.$id');
  int stepForLesson(String id) => preferences.getInt('lesson.step.$id') ?? 0;
  Future<void> saveLessonStep(String id, int step) async {
    if (step < 0) throw ArgumentError.value(step, 'step');
    if (!await preferences.setInt('lesson.step.$id', step)) {
      throw StateError('Could not save lesson progress.');
    }
  }

  Future<void> saveLessonBuild(String id, int buildId) async {
    await preferences.setInt('lesson.build.$id', buildId);
  }

  List<String> get completed =>
      preferences.getStringList('lesson.completed') ?? [];
  Future<void> onboard(String name) async {
    await preferences.setString('profile.name', name.trim());
    await preferences.setBool('profile.accepted', true);
  }

  Future<void> startLesson(String id) =>
      preferences.setString('lesson.last', id);
  Future<void> completeLesson(String id) async {
    await preferences.setStringList(
      'lesson.completed',
      {...completed, id}.toList(),
    );
  }
}
