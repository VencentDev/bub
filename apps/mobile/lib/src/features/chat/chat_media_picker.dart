import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

class ChatMediaItem {
  const ChatMediaItem({
    required this.id,
    required this.file,
    this.isVideo = false,
  });

  final String id;
  final File file;
  final bool isVideo;
}

abstract class ChatMediaPicker {
  Future<List<ChatMediaItem>> recentMedia();
}

class DeviceChatMediaPicker implements ChatMediaPicker {
  static const _pageSize = 80;

  @override
  Future<List<ChatMediaItem>> recentMedia() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      return const [];
    }
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.common,
    );
    if (paths.isEmpty) {
      return const [];
    }
    final assetPath = paths.first;
    final totalAssets = await assetPath.assetCountAsync;
    final items = <ChatMediaItem>[];
    for (var page = 0; page * _pageSize < totalAssets; page += 1) {
      final assets = await assetPath.getAssetListPaged(
        page: page,
        size: _pageSize,
      );
      for (final asset in assets) {
        if (asset.type != AssetType.image && asset.type != AssetType.video) {
          continue;
        }
        final file = await asset.file;
        if (file == null) {
          continue;
        }
        items.add(
          ChatMediaItem(
            id: asset.id,
            file: file,
            isVideo: asset.type == AssetType.video,
          ),
        );
      }
    }
    return items;
  }
}

final chatMediaPickerProvider = Provider<ChatMediaPicker>(
  (ref) => DeviceChatMediaPicker(),
);
