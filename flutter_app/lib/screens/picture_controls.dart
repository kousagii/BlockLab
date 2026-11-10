import 'package:flutter/material.dart';

/// Shares the app theme and button styles used by the lesson guide.
class PictureControls extends StatelessWidget {
  final bool busy, ready;
  final VoidCallback onShare, onClose;
  final String closeLabel;

  const PictureControls({
    super.key,
    required this.busy,
    required this.ready,
    required this.onShare,
    required this.onClose,
    required this.closeLabel,
  });

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .4,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Drag to orbit. Pinch to zoom. Use two fingers to pan.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: ready && !busy ? onShare : null,
            icon: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded),
            label: Text(busy ? 'Sharing…' : 'Share picture'),
          ),
          TextButton(onPressed: busy ? null : onClose, child: Text(closeLabel)),
        ],
      ),
    ),
  );
}
