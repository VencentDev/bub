package com.vencentdev.backend.modules.safe.service;

import com.vencentdev.backend.common.exception.BadRequestException;
import com.vencentdev.backend.common.exception.ResourceNotFoundException;
import com.vencentdev.backend.common.exception.StorageException;
import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.chat.entity.ChatMessage;
import com.vencentdev.backend.modules.chat.entity.ChatMessageType;
import com.vencentdev.backend.modules.chat.live.ChatLiveEventType;
import com.vencentdev.backend.modules.chat.live.ChatLivePublisher;
import com.vencentdev.backend.modules.chat.repository.ChatMessageRepository;
import com.vencentdev.backend.modules.safe.dto.SafeChatNoticeResponse;
import com.vencentdev.backend.modules.safe.dto.SafeMediaDeleteResponse;
import com.vencentdev.backend.modules.safe.dto.SafeMediaItemResponse;
import com.vencentdev.backend.modules.safe.dto.SafeMediaListResponse;
import com.vencentdev.backend.modules.safe.dto.SafeMediaUploadResponse;
import com.vencentdev.backend.modules.safe.entity.SafeMediaItem;
import com.vencentdev.backend.modules.safe.entity.SafeMediaType;
import com.vencentdev.backend.modules.safe.repository.SafeMediaItemRepository;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

@Service
public class SafeMediaServiceImpl implements SafeMediaService {

  private static final Logger log = LoggerFactory.getLogger(SafeMediaServiceImpl.class);
  private static final long MAX_MEDIA_BYTES = 25L * 1024L * 1024L;
  private static final Set<String> IMAGE_PREFIXES = Set.of("image/");
  private static final Set<String> VIDEO_PREFIXES = Set.of("video/");

  private final SafeAccessService safeAccess;
  private final SafeMediaItemRepository mediaItems;
  private final SafeMediaStorageService storage;
  private final UserRepository users;
  private final ChatMessageRepository chatMessages;
  private final ChatLivePublisher livePublisher;

  public SafeMediaServiceImpl(
      SafeAccessService safeAccess,
      SafeMediaItemRepository mediaItems,
      SafeMediaStorageService storage,
      UserRepository users,
      ChatMessageRepository chatMessages,
      ChatLivePublisher livePublisher) {
    this.safeAccess = safeAccess;
    this.mediaItems = mediaItems;
    this.storage = storage;
    this.users = users;
    this.chatMessages = chatMessages;
    this.livePublisher = livePublisher;
  }

  @Override
  @Transactional
  public SafeMediaUploadResponse upload(
      AuthenticatedUser principal, String pin, List<MultipartFile> files) {
    if (files == null || files.isEmpty()) {
      throw new BadRequestException("At least one Safe media file is required");
    }
    SafeAccessService.SafeVaultContext context = safeAccess.verifyPin(principal, pin);
    TetherConnection connection = context.tetherConnection();
    User uploader =
        users
            .findById(context.userId())
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));

    List<SafeMediaItem> saved = new ArrayList<>();
    for (MultipartFile file : files) {
      SafeMediaType type = mediaType(file);
      StoredSafeMedia stored = storage.uploadSafeMedia(connection.getId(), uploader.getId(), file);
      saved.add(
          mediaItems.save(
              SafeMediaItem.builder()
                  .tetherConnection(connection)
                  .uploadedByUser(uploader)
                  .type(type)
                  .url(stored.publicUrl())
                  .storageObjectPath(stored.storageObjectPath())
                  .contentType(stored.contentType())
                  .sizeBytes(stored.sizeBytes())
                  .originalFilename(trimNullable(file.getOriginalFilename()))
                  .build()));
    }

    ChatMessage notice =
        chatMessages.save(
            ChatMessage.builder()
                .tetherConnection(connection)
                .senderUser(uploader)
                .type(ChatMessageType.SAFE_NOTICE)
                .safeItemCount(saved.size())
                .deliveredAt(Instant.now())
                .build());
    publishToConnection(connection);
    return new SafeMediaUploadResponse(
        saved.stream().map(this::toResponse).toList(),
        new SafeChatNoticeResponse(
            notice.getId(),
            notice.getType(),
            notice.getSafeItemCount(),
            notice.getSenderUser().getId(),
            notice.getCreatedAt()));
  }

  @Override
  @Transactional(readOnly = true)
  public SafeMediaListResponse list(AuthenticatedUser principal, String pin) {
    SafeAccessService.SafeVaultContext context = safeAccess.verifyPin(principal, pin);
    return new SafeMediaListResponse(
        mediaItems
            .findByTetherConnectionIdAndDeletedAtIsNullOrderByCreatedAtDescIdDesc(
                context.tetherConnection().getId())
            .stream()
            .map(this::toResponse)
            .toList());
  }

  @Override
  @Transactional
  public SafeMediaDeleteResponse delete(AuthenticatedUser principal, String pin, UUID mediaId) {
    SafeAccessService.SafeVaultContext context = safeAccess.verifyPin(principal, pin);
    SafeMediaItem item =
        mediaItems
            .findByIdAndTetherConnectionId(mediaId, context.tetherConnection().getId())
            .orElseThrow(() -> new ResourceNotFoundException("Safe media not found"));
    if (item.getDeletedAt() == null) {
      item.setDeletedAt(Instant.now());
      try {
        storage.deleteSafeMedia(item.getStorageObjectPath());
      } catch (StorageException exception) {
        log.warn("Safe media storage delete failed for item={}", item.getId(), exception);
      }
    }
    return new SafeMediaDeleteResponse(item.getId(), true);
  }

  private SafeMediaType mediaType(MultipartFile file) {
    if (file == null || file.isEmpty()) {
      throw new BadRequestException("Safe media file cannot be empty");
    }
    if (file.getSize() > MAX_MEDIA_BYTES) {
      throw new BadRequestException("Safe media file exceeds the 25 MB limit");
    }
    String contentType = trimNullable(file.getContentType());
    if (contentType == null) {
      throw new BadRequestException("Safe media content type is required");
    }
    String normalized = contentType.toLowerCase();
    if (IMAGE_PREFIXES.stream().anyMatch(normalized::startsWith)) {
      return SafeMediaType.IMAGE;
    }
    if (VIDEO_PREFIXES.stream().anyMatch(normalized::startsWith)) {
      return SafeMediaType.VIDEO;
    }
    throw new BadRequestException("Unsupported Safe media content type");
  }

  private SafeMediaItemResponse toResponse(SafeMediaItem item) {
    return new SafeMediaItemResponse(
        item.getId(),
        item.getType(),
        item.getUrl(),
        item.getContentType(),
        item.getSizeBytes(),
        item.getOriginalFilename(),
        item.getUploadedByUser().getId(),
        item.getCreatedAt());
  }

  private void publishToConnection(TetherConnection connection) {
    livePublisher.publish(connection.getUserOne().getId(), ChatLiveEventType.MESSAGE_CREATED);
    livePublisher.publish(connection.getUserTwo().getId(), ChatLiveEventType.MESSAGE_CREATED);
  }

  private String trimNullable(String value) {
    if (!StringUtils.hasText(value)) {
      return null;
    }
    return value.trim();
  }
}
