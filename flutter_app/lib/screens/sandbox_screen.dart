import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import '../models/scene_document.dart';
import '../services/isar_service.dart';
import '../services/unity_bridge.dart';
import 'settings_screen.dart';

class SandboxScreen extends StatefulWidget {
  final IsarService isarService;
  final String? initialBuildJson, buildName;
  final int? existingBuildId;
  final Future<void> Function(int id)? onSaved;
  const SandboxScreen({
    super.key,
    required this.isarService,
    this.initialBuildJson,
    this.existingBuildId,
    this.buildName,
    this.onSaved,
  });
  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  late final UnityBridge _bridge;
  Timer? _poll, _deadline, _saveDeadline;
  String? _error, _appearance;
  bool _saving = false,
      _persisting = false,
      _dirty = false,
      _canUndo = false,
      _allowPop = false;
  int? _buildId;
  @override
  void initState() {
    super.initState();
    _buildId = widget.existingBuildId;
    _bridge = UnityBridge(
      sessionId: DateTime.now().microsecondsSinceEpoch.toString(),
      send: sendToUnity,
      scene: widget.initialBuildJson,
    );
    _connect();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    _appearance = jsonEncode({
      'mode': Theme.of(context).brightness.name,
      'textScale': media.textScaler.scale(16) / 16,
      'pixelRatio': media.devicePixelRatio,
    });
    _sendAppearance();
  }

  void _sendAppearance() {
    if (_bridge.started && _appearance != null) {
      sendToUnity('SaveLoadSystem', 'SetAppearance', _appearance!);
    }
  }

  void _connect() {
    _poll?.cancel();
    _deadline?.cancel();
    _poll = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _bridge.requestReady(),
    );
    _deadline = Timer(const Duration(seconds: 45), () {
      _poll?.cancel();
      if (mounted && !_bridge.started) {
        setState(() {
          _error = 'The workspace did not respond. Please retry.';
        });
      }
    });
  }

  void _notice(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _save() {
    if (!_bridge.started || _saving) return;
    setState(() {
      _saving = true;
    });
    _saveDeadline = Timer(const Duration(seconds: 15), () {
      if (mounted && !_persisting) {
        setState(() {
          _saving = false;
        });
        _notice('The workspace did not send your build. Tap Save to retry.');
      }
    });
    sendToUnity('SaveLoadSystem', 'RequestSave', '');
  }

  Future<void> _onUnityMessage(String message) async {
    final data = _bridge.receive(message);
    if (data == null || !mounted) return;
    switch (data['messageType']) {
      case 'SESSION_STARTED':
        _poll?.cancel();
        _deadline?.cancel();
        _sendAppearance();
        setState(() {
          _error = null;
        });
      case 'WORKSPACE_STATE':
        setState(() {
          _dirty = data['dirty'] == true;
          _canUndo = data['canUndo'] == true;
        });
      case 'ERROR':
        if (_bridge.started) {
          _saveDeadline?.cancel();
          if (!_persisting) {
            setState(() {
              _saving = false;
            });
          }
          _notice(
            data['message'] as String? ?? 'Something went wrong. Please retry.',
          );
        } else {
          _poll?.cancel();
          _deadline?.cancel();
          setState(() {
            _error = data['message'] as String? ?? 'Could not open this work.';
          });
        }
      case 'SAVE_BUILD':
        if (!_bridge.started || !_saving || _persisting) return;
        _persisting = true;
        _saveDeadline?.cancel();
        try {
          final scene = SceneDocument.parse(jsonEncode(data));
          if (_buildId == null) {
            _buildId = await widget.isarService.saveNewBuild(
              widget.buildName ??
                  'Build ${DateTime.now().toLocal().toString().substring(0, 16)}',
              scene.encode(),
              scene.thumbnail,
            );
          } else {
            await widget.isarService.updateBuild(
              _buildId!,
              scene.encode(),
              scene.thumbnail,
            );
          }
          sendToUnity(
            'SaveLoadSystem',
            'AcknowledgeSave',
            jsonEncode({
              'sessionId': _bridge.sessionId,
              'revision': data['revision'],
            }),
          );
          _notice('Build saved on this device.');
          try {
            await widget.onSaved?.call(_buildId!);
          } catch (_) {
            _notice(
              'Your build is saved. The lesson link could not be updated.',
            );
          }
        } catch (_) {
          _notice(
            'Could not save your build. Your changes are still here. Please retry.',
          );
        } finally {
          _persisting = false;
          if (mounted) {
            setState(() {
              _saving = false;
            });
          }
        }
    }
  }

  Future<void> _leave() async {
    if (_saving) {
      _notice('Please wait for saving to finish.');
      return;
    }
    if (_dirty) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave without saving?'),
          content: const Text('Your latest changes have not been saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep building'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (leave != true) return;
    }
    if (mounted) {
      setState(() {
        _allowPop = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  void _help() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Make yourself at home',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'Add a block\nOpen Shapes, then drag a shape sideways onto the grid. Scroll vertically to see more shapes.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Edit a block\nTap it or choose it in Objects. Adjust its size or color in the panel. Drag to move it.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Look around\nDrag empty space to orbit. Pinch to zoom; move two fingers to pan. Use Reset view to return.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Keep your creation\nTap Save before leaving. Share an editable copy from Works.',
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  void dispose() {
    _poll?.cancel();
    _deadline?.cancel();
    _saveDeadline?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _leave,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          titleSpacing: 0,
          title: Text(
            widget.buildName ?? 'Sandbox',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              tooltip: 'Undo',
              onPressed: _bridge.started && _canUndo && !_saving
                  ? () => sendToUnity('SaveLoadSystem', 'RequestUndo', '')
                  : null,
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton(
              tooltip: _saving ? 'Saving build' : 'Save build',
              onPressed: _bridge.started && !_saving ? _save : null,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.save_outlined,
                      color: _bridge.started ? colors.primary : null,
                    ),
            ),
            PopupMenuButton<String>(
              tooltip: 'More workspace options',
              onSelected: (value) {
                if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                }
                if (value == 'help') _help();
                if (value == 'reset') {
                  sendToUnity('SaveLoadSystem', 'ResetView', '');
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'help', child: Text('How to build')),
                PopupMenuItem(
                  value: 'reset',
                  enabled: _bridge.started,
                  child: const Text('Reset view'),
                ),
                const PopupMenuItem(value: 'settings', child: Text('Settings')),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(
              28 * MediaQuery.textScalerOf(context).scale(13) / 13,
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _saving
                    ? 'Saving…'
                    : !_bridge.started
                    ? 'Opening workspace…'
                    : _dirty
                    ? 'Unsaved changes'
                    : _buildId != null
                    ? 'Saved on this device'
                    : 'Ready to build',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              EmbedUnity(onMessageFromUnity: _onUnityMessage),
              if (!_bridge.started)
                ColoredBox(
                  color: colors.surface,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_error == null) const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(
                            _error ?? 'Opening your building workspace…',
                            textAlign: TextAlign.center,
                          ),
                          if (_error != null)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _error = null;
                                });
                                _connect();
                              },
                              child: const Text('Retry'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
