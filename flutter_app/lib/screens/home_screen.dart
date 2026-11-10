import 'dart:convert';
import 'package:flutter/material.dart';
import '../design/widgets.dart';
import '../models/isar_models.dart';
import '../models/lesson.dart';
import '../services/isar_service.dart';
import '../services/profile_service.dart';
import 'works_screen.dart';
import 'lessons_screen.dart';
import 'lesson_detail_screen.dart';
import 'sandbox_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final IsarService isarService;
  final ProfileService profile;
  const HomeScreen({
    super.key,
    required this.isarService,
    required this.profile,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late final Future<List<Lesson>> _lessons = Lesson.load();
  late Future<List<BlockBuild>> _recent;
  @override
  void initState() {
    super.initState();
    _recent = widget.isarService.getAllBuilds();
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _recent = widget.isarService.getAllBuilds();
      });
    }
  }

  Future<void> _open([BlockBuild? build]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SandboxScreen(
          isarService: widget.isarService,
          existingBuildId: build?.id,
          initialBuildJson: build?.sceneDataJson,
          buildName: build?.buildName,
        ),
      ),
    );
    _refresh();
  }

  Future<void> _continue() async {
    try {
      final lessons = await _lessons;
      if (!mounted) return;
      final lesson = lessons.firstWhere(
        (l) => l.id == widget.profile.lastLesson,
        orElse: () => lessons.firstWhere(
          (l) => !widget.profile.completed.contains(l.id),
          orElse: () => lessons.first,
        ),
      );
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
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final home = SafeArea(
      child: ListView(
        children: [
          PageHeading(
            'Hi, ${widget.profile.name}!',
            subtitle: 'Open a build or start a lesson.',
            actions: [
              IconButton(
                tooltip: 'Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              color: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.view_in_ar_rounded,
                        size: 44,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Build with 3D shapes',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: colors.onPrimaryContainer),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add blocks, change their size, and choose their colors.',
                      style: TextStyle(color: colors.onPrimaryContainer),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _open,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Start building'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _continue,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.menu_book_rounded, color: colors.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Learn by building',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pick up a lesson, one shape at a time.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Recent works',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          FutureBuilder<List<BlockBuild>>(
            future: _recent,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextButton(
                    onPressed: _refresh,
                    child: const Text('Retry loading works'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: LinearProgressIndicator(),
                );
              }
              if (snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Text(
                    'No saved builds yet.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                );
              }
              return Column(
                children: [
                  for (final build in snapshot.data!.take(2))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: SizedBox(
                            width: 56,
                            height: 56,
                            child: _preview(build),
                          ),
                          title: Text(
                            build.buildName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: const Text('Continue building'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _open(build),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextButton(
                      onPressed: () => setState(() {
                        _tab = 1;
                      }),
                      child: const Text('See all works'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
    final pages = [
      home,
      WorksScreen(isarService: widget.isarService),
      LessonsScreen(isarService: widget.isarService, profile: widget.profile),
    ];
    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          setState(() {
            _tab = index;
          });
          if (index == 0) _refresh();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspaces_outlined),
            selectedIcon: Icon(Icons.workspaces_rounded),
            label: 'Works',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Lessons',
          ),
        ],
      ),
    );
  }

  Widget _preview(BlockBuild build) {
    try {
      if (build.imageBase64?.isNotEmpty == true) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(build.imageBase64!),
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) =>
                const Icon(Icons.view_in_ar_rounded),
          ),
        );
      }
    } catch (_) {
      /* Use the shape icon if an old thumbnail is corrupt. */
    }
    return const Icon(Icons.view_in_ar_rounded);
  }
}
