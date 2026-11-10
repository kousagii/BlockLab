import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:unity_flutter/models/lesson.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('every catalog reference exists with exact asset case', () async {
    final lessons = await Lesson.load();
    expect(lessons.length, 7);
    expect(lessons.map((l) => l.id).toSet().length, 7);
    for (final lesson in lessons) {
      expect(lesson.steps, isNotEmpty);
      for (final image in [
        lesson.image,
        ...lesson.steps.map((s) => s['image'] as String?),
      ]) {
        if (image != null) {
          expect(File(image).existsSync(), isTrue, reason: image);
        }
      }
    }
  });
}
