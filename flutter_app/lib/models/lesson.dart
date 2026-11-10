import 'dart:convert';
import 'package:flutter/services.dart';

class Lesson {
  final String id, title, difficulty, source;
  final List<Map<String, dynamic>> steps;
  final String? image;
  Lesson(Map<String, dynamic> json)
    : id = json['id'] as String,
      title = json['title'] as String,
      difficulty = json['difficulty'] as String,
      source = json['source'] as String,
      steps = (json['steps'] as List).cast<Map<String, dynamic>>(),
      image = json['image'] as String?;
  static Future<List<Lesson>> load() async {
    final data =
        jsonDecode(await rootBundle.loadString('assets/lessons/catalog.json'))
            as List;
    return data.map((json) => Lesson(json as Map<String, dynamic>)).toList();
  }
}
