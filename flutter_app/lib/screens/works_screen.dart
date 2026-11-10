import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/isar_models.dart';
import '../design/widgets.dart';
import '../models/scene_document.dart';
import '../services/isar_service.dart';
import '../services/sharing_service.dart';
import 'sandbox_screen.dart';

class WorksScreen extends StatefulWidget {
  final IsarService isarService;
  const WorksScreen({super.key, required this.isarService});
  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends State<WorksScreen> {
  late Future<List<BlockBuild>> _works;
  final _sharing = SharingService();
  @override
  void initState() {
    super.initState();
    _works = widget.isarService.getAllBuilds();
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _works = widget.isarService.getAllBuilds();
      });
    }
  }

  Future<void> _run(Future<void> Function() work) async {
    try {
      await work();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _open([BlockBuild? work]) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SandboxScreen(
          isarService: widget.isarService,
          initialBuildJson: work?.sceneDataJson,
          existingBuildId: work?.id,
          buildName: work?.buildName,
        ),
      ),
    );
    _refresh();
  }

  Future<void> _rename(BlockBuild work) async {
    final controller = TextEditingController(text: work.buildName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename build'),
        content: TextField(
          controller: controller,
          maxLength: 80,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // Dispose after the dialog's exit animation releases its TextField.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (name != null) {
      await widget.isarService.renameBuild(work.id, name);
      _refresh();
    }
  }

  Future<void> _delete(BlockBuild work) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete build?'),
        content: Text('Permanently delete "${work.buildName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await widget.isarService.deleteBuild(work.id);
      _refresh();
    }
  }

  Future<void> _import() async {
    final scene = await _sharing.import();
    if (scene == null) return;
    await widget.isarService.saveNewBuild(
      'Imported build',
      scene.encode(),
      scene.thumbnail,
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        PageHeading(
          'My works',
          subtitle: 'Open, share, or import a build.',
          actions: [
            IconButton(
              tooltip: 'Import build',
              onPressed: () => _run(_import),
              icon: const Icon(Icons.file_open_outlined),
            ),
            IconButton(
              tooltip: 'New build',
              onPressed: () => _run(_open),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<List<BlockBuild>>(
            future: _works,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Could not open your works',
                  message: 'Please try again.',
                  action: FilledButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final works = snapshot.data!;
              if (works.isEmpty) {
                return EmptyState(
                  icon: Icons.view_in_ar_rounded,
                  title: 'No saved builds yet',
                  message: 'Start a build to save it here.',
                  action: FilledButton.icon(
                    onPressed: () => _run(_open),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Start building'),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: works.length,
                separatorBuilder: (_, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final work = works[index];
                  int? count;
                  try {
                    count = SceneDocument.parse(work.sceneDataJson).blockCount;
                  } catch (_) {
                    /* Open reports corrupt data. */
                  }
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 2,
                              child: ColoredBox(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerLow,
                                child: work.imageBase64?.isNotEmpty == true
                                    ? _thumbnail(work.imageBase64!)
                                    : Icon(
                                        Icons.view_in_ar_rounded,
                                        size: 48,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            work.buildName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${count == null ? 'Saved work' : '$count blocks'} · ${work.saveDate.day}/${work.saveDate.month}/${work.saveDate.year}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _run(() => _open(work)),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit build'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                tooltip: 'Options for ${work.buildName}',
                                onSelected: (value) => _run(() async {
                                  if (value == 'share') {
                                    await _sharing.share(work);
                                  }
                                  if (value == 'rename') await _rename(work);
                                  if (value == 'delete') await _delete(work);
                                }),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'share',
                                    child: Text('Share editable build'),
                                  ),
                                  PopupMenuItem(
                                    value: 'rename',
                                    child: Text('Rename'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
  Widget _thumbnail(String text) {
    try {
      return Image.memory(
        base64Decode(text),
        fit: BoxFit.cover,
        errorBuilder: (_, error, stack) =>
            const Icon(Icons.broken_image_outlined),
      );
    } catch (_) {
      return const Icon(Icons.broken_image_outlined);
    }
  }
}
