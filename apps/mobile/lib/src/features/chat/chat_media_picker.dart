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
      filterOption: FilterOptionGroup(
        orders: const [
          OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
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
        items.add(
          ChatMediaItem(
            id: asset.id,
            createdAt: asset.createDateTime,
            isVideo: asset.type == AssetType.video,
            resolveFile: () => asset.file,
            loadThumbnail: () =>
                asset.thumbnailDataWithSize(const ThumbnailSize.square(240)),
          ),
        );
      }
    }
    items.sort((first, second) {
      final firstDate = first.createdAt;
      final secondDate = second.createdAt;
      if (firstDate == null && secondDate == null) {
        return 0;
      }
      if (firstDate == null) {
        return 1;
      }
      if (secondDate == null) {
        return -1;
      }
      return secondDate.compareTo(firstDate);
    });
    return items;
  }
}

final chatMediaPickerProvider = Provider<ChatMediaPicker>(
  (ref) => DeviceChatMediaPicker(),
);
