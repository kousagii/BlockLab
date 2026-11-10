import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../services/profile_service.dart';

/// Flutter owns lesson instructions; Unity keeps the same runtime and session.
class LessonGuide extends StatefulWidget {
  final Lesson lesson;
  final ProfileService profile;
  final Future<void> Function() onComplete;
  final ValueChanged<bool>? onModalChanged;
  const LessonGuide({
    super.key,
    required this.lesson,
    required this.profile,
    required this.onComplete,
    this.onModalChanged,
  });
  @override
  State<LessonGuide> createState() => _LessonGuideState();
}

class _LessonGuideState extends State<LessonGuide> {
  late int _step;
  bool _expanded = true, _busy = false;
  @override
  void initState() {
    super.initState();
    _step = widget.profile
        .stepForLesson(widget.lesson.id)
        .clamp(0, widget.lesson.steps.length - 1);
  }

  Future<void> _change(int value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.profile.saveLessonStep(widget.lesson.id, value);
      if (mounted) setState(() => _step = value);
    } catch (_) {
      _notice('Could not save your lesson step. Please retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _reference(String path) async {
    widget.onModalChanged?.call(true);
    try {
      await showDialog<void>(
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
      );
    } finally {
      widget.onModalChanged?.call(false);
    }
  }

  Future<void> _complete() async {
    setState(() => _busy = true);
    try {
      await widget.onComplete();
      if (mounted) setState(() => _expanded = false);
      _notice('Lesson marked complete. You can keep building.');
    } catch (_) {
      _notice('Could not update lesson completion. Please retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson, step = lesson.steps[_step];
    final reference = step['image'] as String? ?? lesson.image;
    final complete = widget.profile.completed.contains(lesson.id);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            minVerticalPadding: 4,
            title: Text(
              'Lesson · Step ${_step + 1} of ${lesson.steps.length}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            trailing: IconButton(
              tooltip: _expanded ? 'Collapse lesson' : 'Expand lesson',
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
              ),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.min(
                  240,
                  MediaQuery.sizeOf(context).height * .3,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      step['text'] as String,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        if (reference != null)
                          TextButton.icon(
                            onPressed: () => _reference(reference),
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Reference'),
                          ),
                        OutlinedButton(
                          onPressed: _busy || _step == 0
                              ? null
                              : () => _change(_step - 1),
                          child: const Text('Previous'),
                        ),
                        if (_step < lesson.steps.length - 1)
                          FilledButton(
                            onPressed: _busy ? null : () => _change(_step + 1),
                            child: const Text('Next'),
                          )
                        else
                          FilledButton(
                            onPressed: _busy || complete ? null : _complete,
                            child: Text(
                              complete ? 'Completed' : 'Mark complete',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
