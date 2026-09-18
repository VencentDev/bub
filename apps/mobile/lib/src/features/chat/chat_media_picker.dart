import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

class ChatMediaItem {
  const ChatMediaItem({
    required this.id,
    this.file,
    this.createdAt,
    this.isVideo = false,
    Future<File?> Function()? resolveFile,
    Future<Uint8List?> Function()? loadThumbnail,
  }) : _resolveFile = resolveFile,
       _loadThumbnail = loadThumbnail;

  final String id;
  final File? file;
  final DateTime? createdAt;
  final bool isVideo;
  final Future<File?> Function()? _resolveFile;
  final Future<Uint8List?> Function()? _loadThumbnail;

  Future<File?> resolveFile() => _resolveFile?.call() ?? Future.value(file);

  Future<Uint8List?> loadThumbnail() =>
      _loadThumbnail?.call() ?? Future.value(null);
}

abstract class ChatMediaPicker {
  /// Recent camera-roll items for the inline picker.
  ///
  /// Keep [limit] modest so opening the drawer stays snappy.
  Future<List<ChatMediaItem>> recentMedia({int limit = 36});
}

class DeviceChatMediaPicker implements ChatMediaPicker {
  static const _thumbnailSize = ThumbnailSize.square(120);

  @override
  Future<List<ChatMediaItem>> recentMedia({int limit = 36}) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      return const [];
    }
    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        orders: const [
          OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
    if (paths.isEmpty) {
      return const [];
    }

    final pageSize = limit.clamp(1, 80);
    final assets = await paths.first.getAssetListPaged(page: 0, size: pageSize);
    final items = <ChatMediaItem>[];
    for (final asset in assets) {
      if (asset.type != AssetType.image && asset.type != AssetType.video) {
        continue;
      }
      items.add(
        ChatMediaItem(
          id: asset.id,
          createdAt: asset.createDateTime,
          isVideo: asset.type == AssetType.video,
          resolveFile: () => asset.file,
          loadThumbnail: () => asset.thumbnailDataWithSize(_thumbnailSize),
        ),
      );
    }
    return items;
  }
}

final chatMediaPickerProvider = Provider<ChatMediaPicker>(
  (ref) => DeviceChatMediaPicker(),
);
