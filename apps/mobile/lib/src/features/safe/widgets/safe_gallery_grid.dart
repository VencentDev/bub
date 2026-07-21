import 'package:flutter/material.dart';

import '../safe_controller.dart';

class SafeGalleryGrid extends StatelessWidget {
  const SafeGalleryGrid({super.key, required this.items, required this.onOpen});

  final List<SafeMediaItem> items;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const Key('safe-gallery-grid'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 132),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _SafeGalleryTile(
          key: Key('safe-gallery-item-${item.id}'),
          item: item,
          onTap: () => onOpen(index),
        );
      },
    );
  }
}

class _SafeGalleryTile extends StatelessWidget {
  const _SafeGalleryTile({super.key, required this.item, required this.onTap});

  final SafeMediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.mediaType == SafeMediaType.image)
              Image.network(
                item.url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.image_rounded),
              )
            else
              const ColoredBox(
                color: Color(0xFF20242A),
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            if (item.mediaType == SafeMediaType.video)
              const Positioned(
                right: 6,
                bottom: 6,
                child: Icon(
                  Icons.videocam_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
