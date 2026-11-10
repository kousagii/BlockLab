import 'package:flutter/material.dart';
import '../design/widgets.dart';
import '../models/lesson.dart';
import '../services/isar_service.dart';
import '../services/profile_service.dart';
import 'lesson_detail_screen.dart';

class LessonsScreen extends StatefulWidget {
  final IsarService isarService;
  final ProfileService profile;
  const LessonsScreen({
    super.key,
    required this.isarService,
    required this.profile,
  });
  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  late final _lessons = Lesson.load();
  @override
  Widget build(BuildContext context) => SafeArea(
    child: FutureBuilder<List<Lesson>>(
      future: _lessons,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load lessons: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const PageHeading(
              'Lessons',
              subtitle: 'Learn one shape at a time.',
            ),
            for (final lesson in snapshot.data!)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    Icons.menu_book,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(lesson.title),
                  subtitle: Text(
                    '${lesson.difficulty} · ${widget.profile.completed.contains(lesson.id)
                        ? 'Completed'
                        : widget.profile.lastLesson == lesson.id
                        ? 'In progress'
                        : 'Not started'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => LessonDetailScreen(
                          lesson: lesson,
                          isarService: widget.isarService,
                          profile: widget.profile,
                        ),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
          ],
        );
      },
    ),
  );
}
