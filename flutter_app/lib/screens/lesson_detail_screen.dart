import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../services/isar_service.dart';
import '../services/profile_service.dart';
import 'sandbox_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  final IsarService isarService;
  final ProfileService profile;
  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.isarService,
    required this.profile,
  });
  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool _busy = false;
  int _step = 0;
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _step = widget.profile
        .stepForLesson(widget.lesson.id)
        .clamp(0, widget.lesson.steps.length - 1);
  }

  Future<void> _run(Future<void> Function() task) async {
    setState(() {
      _busy = true;
    });
    try {
      await task();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update your lesson. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _start() async {
    await widget.profile.startLesson(widget.lesson.id);
    final id = widget.profile.buildForLesson(widget.lesson.id);
    final saved = id == null ? null : await widget.isarService.getBuild(id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SandboxScreen(
          isarService: widget.isarService,
          initialBuildJson: saved?.sceneDataJson,
          existingBuildId: saved?.id,
          buildName: saved?.buildName ?? widget.lesson.title,
          lesson: widget.lesson,
          profile: widget.profile,
          onSaved: (buildId) =>
              widget.profile.saveLessonBuild(widget.lesson.id, buildId),
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _step = widget.profile
            .stepForLesson(widget.lesson.id)
            .clamp(0, widget.lesson.steps.length - 1);
      });
    }
  }

  Future<void> _change(int step) async {
    try {
      await widget.profile.saveLessonStep(widget.lesson.id, step);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your lesson step. Please retry.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _step = step;
    });
    _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final complete = widget.profile.completed.contains(lesson.id);
    final step = lesson.steps[_step];
    final reference = step['image'] as String? ?? lesson.image;
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Step ${_step + 1} of ${lesson.steps.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_step + 1) / lesson.steps.length,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (step['title'] is String) ...[
                    Text(
                      step['title'] as String,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    step['text'] as String,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (step['check'] is String)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Look for: ${step['check']}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (reference != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _image(reference),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                onPressed: _step == 0 ? null : () => _change(_step - 1),
                child: const Text('Previous'),
              ),
              if (_step < lesson.steps.length - 1)
                FilledButton(
                  onPressed: () => _change(_step + 1),
                  child: const Text('Next step'),
                ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _busy ? null : () => _run(_start),
            icon: const Icon(Icons.view_in_ar_rounded),
            label: Text(
              widget.profile.buildForLesson(lesson.id) != null
                  ? 'Continue building'
                  : complete
                  ? 'Build again'
                  : 'Start building',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Save in the sandbox to keep your lesson work.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (_step == lesson.steps.length - 1 || complete)
            OutlinedButton.icon(
              onPressed: _busy || complete
                  ? null
                  : () => _run(() async {
                      await widget.isarService.completeLesson(lesson.title);
                      await widget.profile.completeLesson(lesson.id);
                    }),
              icon: Icon(
                complete
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              label: Text(complete ? 'Completed' : 'Mark lesson complete'),
            ),
        ],
      ),
    );
  }

  Widget _image(String path) => Semantics(
    label: 'Building reference. Tap to enlarge.',
    button: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: AspectRatio(
            aspectRatio: .8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                InteractiveViewer(
                  minScale: .5,
                  maxScale: 4,
                  child: Image.asset(path, fit: BoxFit.contain),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton(
                    tooltip: 'Close reference',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(path, height: 220, fit: BoxFit.contain),
      ),
    ),
  );
}
