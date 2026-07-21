import 'package:flutter/material.dart';

import '../safe_controller.dart';

class SafeMediaViewer extends StatefulWidget {
  const SafeMediaViewer({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.deleting,
    required this.onClose,
    required this.onDelete,
  });

  final List<SafeMediaItem> items;
  final int initialIndex;
  final bool deleting;
  final VoidCallback onClose;
  final Future<void> Function(int index) onDelete;

  @override
  State<SafeMediaViewer> createState() => _SafeMediaViewerState();
}

class _SafeMediaViewerState extends State<SafeMediaViewer> {
  late final PageController _pageController;
  late var _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('safe-media-viewer'),
      color: Colors.black.withValues(alpha: 0.94),
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                if (item.mediaType == SafeMediaType.video) {
                  return const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 76,
                    ),
                  );
                }
                return InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      item.url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                color: Colors.white,
                tooltip: 'Close',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                key: const Key('safe-delete-action'),
                color: Colors.white,
                tooltip: 'Delete',
                onPressed: widget.deleting
                    ? null
                    : () => widget.onDelete(_index),
                icon: widget.deleting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
