package com.vencentdev.backend.modules.chat.service;

import com.vencentdev.backend.common.exception.BadRequestException;
import com.vencentdev.backend.common.exception.ConflictException;
import com.vencentdev.backend.common.exception.ForbiddenException;
import com.vencentdev.backend.common.exception.ResourceNotFoundException;
import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.chat.dto.ChatDeliveryState;
import com.vencentdev.backend.modules.chat.dto.ChatEditMessageRequest;
import com.vencentdev.backend.modules.chat.dto.ChatMessageResponse;
import com.vencentdev.backend.modules.chat.dto.ChatPresenceResponse;
import com.vencentdev.backend.modules.chat.dto.ChatPresenceStatus;
import com.vencentdev.backend.modules.chat.dto.ChatReactionRequest;
import com.vencentdev.backend.modules.chat.dto.ChatReactionSummaryResponse;
import com.vencentdev.backend.modules.chat.dto.ChatReadRequest;
import com.vencentdev.backend.modules.chat.dto.ChatReplyPreviewResponse;
import com.vencentdev.backend.modules.chat.dto.ChatSendMessageRequest;
import com.vencentdev.backend.modules.chat.dto.ChatStateResponse;
import com.vencentdev.backend.modules.chat.dto.ChatThreadResponse;
import com.vencentdev.backend.modules.chat.dto.ChatTypingRequest;
import com.vencentdev.backend.modules.chat.entity.ChatMessage;
import com.vencentdev.backend.modules.chat.entity.ChatMessageDeletion;
import com.vencentdev.backend.modules.chat.entity.ChatMessageReaction;
import com.vencentdev.backend.modules.chat.entity.ChatMessageRead;
import com.vencentdev.backend.modules.chat.entity.ChatMessageType;
import com.vencentdev.backend.modules.chat.entity.ChatPresenceState;
import com.vencentdev.backend.modules.chat.live.ChatLiveEventType;
import com.vencentdev.backend.modules.chat.live.ChatLivePublisher;
import com.vencentdev.backend.modules.chat.repository.ChatMessageDeletionRepository;
import com.vencentdev.backend.modules.chat.repository.ChatMessageReactionRepository;
import com.vencentdev.backend.modules.chat.repository.ChatMessageReadRepository;
import com.vencentdev.backend.modules.chat.repository.ChatMessageRepository;
import com.vencentdev.backend.modules.chat.repository.ChatPresenceStateRepository;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.tether.repository.TetherConnectionRepository;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import com.vencentdev.backend.modules.user.service.UserService;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ChatServiceImpl implements ChatService {

  private static final Duration EDIT_WINDOW = Duration.ofMinutes(10);
  private static final Duration TYPING_WINDOW = Duration.ofSeconds(12);
  private static final Duration ONLINE_WINDOW = Duration.ofMinutes(5);
  private static final Set<String> SUPPORTED_REACTIONS = Set.of("❤️", "😂", "🥺", "😭", "🔥");

  private final TetherConnectionRepository connections;
  private final ChatMessageRepository messages;
  private final ChatMessageDeletionRepository deletions;
  private final ChatMessageReactionRepository reactions;
  private final ChatMessageReadRepository reads;
  private final ChatPresenceStateRepository presenceStates;
  private final UserRepository users;
  private final UserService userService;
  private final ChatLivePublisher livePublisher;
  private final Clock clock;

  @Autowired
  public ChatServiceImpl(
      TetherConnectionRepository connections,
      ChatMessageRepository messages,
      ChatMessageDeletionRepository deletions,
      ChatMessageReactionRepository reactions,
      ChatMessageReadRepository reads,
      ChatPresenceStateRepository presenceStates,
      UserRepository users,
      UserService userService,
      ChatLivePublisher livePublisher) {
    this(
        connections,
        messages,
        deletions,
        reactions,
        reads,
        presenceStates,
        users,
        userService,
        livePublisher,
        Clock.systemUTC());
  }

  ChatServiceImpl(
      TetherConnectionRepository connections,
      ChatMessageRepository messages,
      ChatMessageDeletionRepository deletions,
      ChatMessageReactionRepository reactions,
      ChatMessageReadRepository reads,
      ChatPresenceStateRepository presenceStates,
      UserRepository users,
      UserService userService,
      ChatLivePublisher livePublisher,
      Clock clock) {
    this.connections = connections;
    this.messages = messages;
    this.deletions = deletions;
    this.reactions = reactions;
    this.reads = reads;
    this.presenceStates = presenceStates;
    this.users = users;
    this.userService = userService;
    this.livePublisher = livePublisher;
    this.clock = clock;
  }

  @Override
  @Transactional(readOnly = true)
  public ChatThreadResponse thread(AuthenticatedUser principal) {
    UUID userId = userService.resolveInternalId(principal);
    return connections
        .findActiveByUserId(userId)
        .map(connection -> threadForConnection(connection, userId))
        .orElseGet(() -> new ChatThreadResponse(false, null, null, null, List.of()));
  }

  @Override
  @Transactional
  public ChatMessageResponse send(AuthenticatedUser principal, ChatSendMessageRequest request) {
    UUID userId = userService.resolveInternalId(principal);
    TetherConnection connection = activeConnection(userId);
    User sender =
        users.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    ChatMessage reply = replyTarget(request.replyToMessageId(), connection.getId());
    Instant now = Instant.now(clock);
    ChatMessage message =
        ChatMessage.builder()
            .tetherConnection(connection)
            .senderUser(sender)
            .type(request.type())
            .body(bodyFor(request))
            .gifUrl(gifUrlFor(request))
            .gifProviderId(gifProviderIdFor(request))
            .replyToMessage(reply)
            .deliveredAt(now)
            .build();
    touchPresence(connection, sender, false, now);
    ChatMessageResponse response =
        toResponse(messages.save(message), userId, responseContext(List.of(message), userId, now));
    publishToConnection(connection, ChatLiveEventType.MESSAGE_CREATED);
    return response;
  }

  @Override
  @Transactional
  public ChatMessageResponse edit(
      AuthenticatedUser principal, UUID messageId, ChatEditMessageRequest request) {
    UUID userId = userService.resolveInternalId(principal);
    TetherConnection connection = activeConnection(userId);
    ChatMessage message = messageInConnection(messageId, connection.getId());
    if (!message.getSenderUser().getId().equals(userId)) {
      throw new ForbiddenException("Only the sender can edit this message");
    }
    if (message.getDeletedForEveryoneAt() != null) {
      throw new BadRequestException("Deleted messages cannot be edited");
    }
    Instant now = Instant.now(clock);
    if (message.getCreatedAt() != null && message.getCreatedAt().plus(EDIT_WINDOW).isBefore(now)) {
      throw new BadRequestException("Message can no longer be edited");
    }
    message.setBody(trimRequired(request.body(), "Body is required"));
    message.setEditedAt(now);
    touchPresence(connection, message.getSenderUser(), false, now);
    ChatMessageResponse response =
        toResponse(message, userId, responseContext(List.of(message), userId, now));
    publishToConnection(connection, ChatLiveEventType.MESSAGE_UPDATED);
    return response;
  }

  @Override
  @Transactional
  public void deleteForMe(AuthenticatedUser principal, UUID messageId) {
    UUID userId = userService.resolveInternalId(principal);
    TetherConnection connection = activeConnection(userId);
    ChatMessage message = messageInConnection(messageId, connection.getId());
    deletions
        .findByMessageIdAndUserId(message.getId(), userId)
        .orElseGet(
            () ->
                deletions.save(
                    ChatMessageDeletion.builder()
                        .message(message)
                        .user(
                            users
                                .findById(userId)
                                .orElseThrow(() -> new ResourceNotFoundException("User not found")))
                        .build()));
    touchPresence(connection, partnerOrSelf(connection, userId, userId), false, Instant.now(clock));
  }

  @Override
  @Transactional
  public ChatMessageResponse deleteForEveryone(AuthenticatedUser principal, UUID messageId) {
    UUID userId = userService.resolveInternalId(principal);
    TetherConnection connection = activeConnection(userId);
    ChatMessage message = messageInConnection(messageId, connection.getId());
    if (!message.getSenderUser().getId().equals(userId)) {
      throw new ForbiddenException("Only the sender can delete this message for everyone");
    }
    message.setDeletedForEveryoneAt(Instant.now(clock));
    ChatMessageResponse response =
        toResponse(message, userId, responseContext(List.of(message), userId, Instant.now(clock)));
    publishToConnection(connection, ChatLiveEventType.MESSAGE_UPDATED);
    return response;
  }

  @Override
  @Transactional
  public ChatMessageResponse react(
      AuthenticatedUser principal, UUID messageId, ChatReactionRequest request) {
    UUID userId = userService.resolveInternalId(principal);
    TetherConnection connection = activeConnection(userId);
    ChatMessage message = messageInConnection(messageId, connection.getId());
    if (message.getDeletedForEveryoneAt() != null) {
      throw new BadRequestException("Deleted messages cannot be reacted to");
    }
    String reaction = request.reaction().trim();
    if (!SUPPORTED_REACTIONS.contains(reaction)) {
      throw new BadRequestException("Unsupported reaction");
    }
    User user =
        users.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    ChatMessageReaction entity =
        reactions
            .findByMessageIdAndUserId(messageId, userId)
            .orElseGet(() -> ChatMessageReaction.builder().message(message).user(user).build());
    entity.setReaction(reaction);
    reactions.save(entity);
    ChatMessageResponse response =
        toResponse(message, userId, responseContext(List.of(message), userId, Instant.now(clock)));
    publishToConnection(connection, ChatLiveEventType.MESSAGE_UPDATED);
    return response;
  }

  @Override
  @Transactional
  public ChatMessageResponse removeReaction(AuthenticatedUser principal, UUID messageId) {
    UUID userId = userService.resolveInternalId(principal);
    TetherConnection connection = activeConnection(userId);
    ChatMessage message = messageInConnection(messageId, connection.getId());
    reactions.findByMessageIdAndUserId(messageId, userId).ifPresent(reactions::delete);
    ChatMessageResponse response =
        toResponse(message, userId, responseContext(List.of(message), userId, Instant.now(clock)));
    publishToConnection(connection, ChatLiveEventType.MESSAGE_UPDATED);
    return response;
  }

  @Override
  @Transactional
  public ChatStateResponse markRead(AuthenticatedUser principal, ChatReadRequest request) {
    UUID userId = userService.resolveInternalId(principal);
    TetherConnection connection = activeConnection(userId);
    ChatMessage target = messageInConnection(request.upToMessageId(), connection.getId());
    if (target.getSenderUser().getId().equals(userId)) {
      throw new BadRequestException("Cannot mark your own message as seen");
    }
    User user =
        users.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    Instant now = Instant.now(clock);
    messages.findPartnerMessagesUpTo(connection.getId(), userId, target.getCreatedAt()).stream()
        .filter(message -> message.getDeletedForEveryoneAt() == null)
        .forEach(
            message ->
                reads
                    .findByMessageIdAndUserId(message.getId(), userId)
                    .orElseGet(
                        () ->
                            reads.save(
                                ChatMessageRead.builder()
                                    .message(message)
                                    .user(user)
                                    .seenAt(now)
                                    .build())));
    touchPresence(connection, user, false, now);
    ChatStateResponse response = stateFor(connection, userId, now);
    publishToConnection(connection, ChatLiveEventType.STATE_UPDATED);
    return response;
  }

  @Override
  @Transactional
  public ChatStateResponse setTyping(AuthenticatedUser principal, ChatTypingRequest request) {
    UUID userId = userService.resolveInternalId(principal);
    TetherConnection connection = activeConnection(userId);
    User user =
        users.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    Instant now = Instant.now(clock);
    touchPresence(connection, user, request.typing(), now);
    ChatStateResponse response = stateFor(connection, userId, now);
    publishToConnection(connection, ChatLiveEventType.TYPING_UPDATED);
    return response;
  }

  @Override
  @Transactional(readOnly = true)
  public ChatStateResponse state(AuthenticatedUser principal) {
    UUID userId = userService.resolveInternalId(principal);
    TetherConnection connection = activeConnection(userId);
    return stateFor(connection, userId, Instant.now(clock));
  }

  private ChatThreadResponse threadForConnection(TetherConnection connection, UUID userId) {
    List<ChatMessage> threadMessages = messages.findThreadMessages(connection.getId(), userId);
    ResponseContext context = responseContext(threadMessages, userId, Instant.now(clock));
    return new ChatThreadResponse(
        true,
        connection.getId(),
        partner(connection, userId).getDisplayName(),
        stateFor(connection, userId, context.now()),
        threadMessages.stream().map(message -> toResponse(message, userId, context)).toList());
  }

  private TetherConnection activeConnection(UUID userId) {
    return connections
        .findActiveByUserId(userId)
        .orElseThrow(() -> new ConflictException("An active tether is required"));
  }

  private ChatMessage messageInConnection(UUID messageId, UUID connectionId) {
    ChatMessage message =
        messages
            .findByIdWithGraph(messageId)
            .orElseThrow(() -> new ResourceNotFoundException("Message not found"));
    if (!message.getTetherConnection().getId().equals(connectionId)) {
      throw new BadRequestException("Message is not part of your tether");
    }
    return message;
  }

  private ChatMessage replyTarget(UUID replyToMessageId, UUID connectionId) {
    if (replyToMessageId == null) {
      return null;
    }
    return messageInConnection(replyToMessageId, connectionId);
  }

  private String bodyFor(ChatSendMessageRequest request) {
    if (request.type() == ChatMessageType.TEXT || request.type() == ChatMessageType.EMOJI) {
      return trimRequired(request.body(), "Body is required");
    }
    return null;
  }

  private String gifUrlFor(ChatSendMessageRequest request) {
    if (request.type() != ChatMessageType.GIF) {
      return null;
    }
    String gifUrl = trimNullable(request.gifUrl());
    String providerId = trimNullable(request.gifProviderId());
    if (gifUrl == null && providerId == null) {
      throw new BadRequestException("GIF URL or provider id is required");
    }
    return gifUrl;
  }

  private String gifProviderIdFor(ChatSendMessageRequest request) {
    if (request.type() != ChatMessageType.GIF) {
      return null;
    }
    gifUrlFor(request);
    return trimNullable(request.gifProviderId());
  }

  private String trimRequired(String value, String message) {
    String trimmed = trimNullable(value);
    if (trimmed == null) {
      throw new BadRequestException(message);
    }
    return trimmed;
  }

  private String trimNullable(String value) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    return trimmed.isEmpty() ? null : trimmed;
  }

  private ChatStateResponse stateFor(TetherConnection connection, UUID viewerId, Instant now) {
    User partner = partner(connection, viewerId);
    ChatPresenceState partnerState =
        presenceStates
            .findByTetherConnectionIdAndUserId(connection.getId(), partner.getId())
            .orElse(null);
    boolean typing =
        partnerState != null
            && partnerState.isTyping()
            && partnerState.getTypingUpdatedAt() != null
            && !partnerState.getTypingUpdatedAt().plus(TYPING_WINDOW).isBefore(now);
    Instant lastSeenAt = partnerState == null ? null : partnerState.getLastSeenAt();
    ChatPresenceStatus status =
        lastSeenAt != null && !lastSeenAt.plus(ONLINE_WINDOW).isBefore(now)
            ? ChatPresenceStatus.ONLINE
            : ChatPresenceStatus.OFFLINE;
    return new ChatStateResponse(typing, new ChatPresenceResponse(status, lastSeenAt));
  }

  private void touchPresence(
      TetherConnection connection, User user, boolean typing, Instant timestamp) {
    ChatPresenceState state =
        presenceStates
            .findByTetherConnectionIdAndUserId(connection.getId(), user.getId())
            .orElseGet(
                () ->
                    ChatPresenceState.builder()
                        .tetherConnection(connection)
                        .user(user)
                        .lastSeenAt(timestamp)
                        .build());
    state.setTyping(typing);
    state.setTypingUpdatedAt(timestamp);
    state.setLastSeenAt(timestamp);
    presenceStates.save(state);
  }

  private User partner(TetherConnection connection, UUID viewerId) {
    if (connection.getUserOne().getId().equals(viewerId)) {
      return connection.getUserTwo();
    }
    return connection.getUserOne();
  }

  private User partnerOrSelf(TetherConnection connection, UUID viewerId, UUID fallbackUserId) {
    if (connection.getUserOne().getId().equals(viewerId)) {
      return connection.getUserOne();
    }
    if (connection.getUserTwo().getId().equals(viewerId)) {
      return connection.getUserTwo();
    }
    return users
        .findById(fallbackUserId)
        .orElseThrow(() -> new ResourceNotFoundException("User not found"));
  }

  private void publishToConnection(TetherConnection connection, ChatLiveEventType type) {
    livePublisher.publish(connection.getUserOne().getId(), type);
    livePublisher.publish(connection.getUserTwo().getId(), type);
  }

  private ChatMessageResponse toResponse(
      ChatMessage message, UUID viewerId, ResponseContext context) {
    boolean deleted = message.getDeletedForEveryoneAt() != null;
    boolean viewerMessage = message.getSenderUser().getId().equals(viewerId);
    return new ChatMessageResponse(
        message.getId(),
        message.getSenderUser().getId(),
        viewerMessage,
        message.getType(),
        deleted ? null : message.getBody(),
        deleted ? null : message.getGifUrl(),
        deleted ? null : message.getGifProviderId(),
        replyPreview(message.getReplyToMessage()),
        message.getCreatedAt(),
        message.getUpdatedAt(),
        message.getEditedAt(),
        deleted,
        deliveryState(message, viewerMessage, context.readsByMessageId()),
        editable(message, viewerMessage, context.now()),
        viewerMessage && !deleted,
        context.viewerReactionsByMessageId().get(message.getId()),
        context.reactionsByMessageId().getOrDefault(message.getId(), List.of()));
  }

  private ChatReplyPreviewResponse replyPreview(ChatMessage reply) {
    if (reply == null) {
      return null;
    }
    boolean deleted = reply.getDeletedForEveryoneAt() != null;
    return new ChatReplyPreviewResponse(
        reply.getId(), reply.getSenderUser().getId(), deleted ? null : snippet(reply), deleted);
  }

  private String snippet(ChatMessage message) {
    if (message.getType() == ChatMessageType.GIF) {
      return "GIF";
    }
    String body = message.getBody();
    if (body == null || body.length() <= 48) {
      return body;
    }
    return body.substring(0, 48);
  }

  private ChatDeliveryState deliveryState(
      ChatMessage message,
      boolean viewerMessage,
      Map<UUID, List<ChatMessageRead>> readsByMessageId) {
    if (!viewerMessage) {
      return null;
    }
    return readsByMessageId.getOrDefault(message.getId(), List.of()).isEmpty()
        ? ChatDeliveryState.DELIVERED
        : ChatDeliveryState.SEEN;
  }

  private boolean editable(ChatMessage message, boolean viewerMessage, Instant now) {
    return viewerMessage
        && message.getDeletedForEveryoneAt() == null
        && message.getCreatedAt() != null
        && !message.getCreatedAt().plus(EDIT_WINDOW).isBefore(now);
  }

  private ResponseContext responseContext(
      List<ChatMessage> sourceMessages, UUID viewerId, Instant now) {
    List<UUID> ids =
        sourceMessages.stream().map(ChatMessage::getId).filter(id -> id != null).toList();
    if (ids.isEmpty()) {
      return new ResponseContext(Map.of(), Map.of(), Map.of(), now);
    }

    Map<UUID, List<ChatMessageRead>> readsByMessageId =
        reads.findByMessageIdIn(ids).stream()
            .collect(Collectors.groupingBy(read -> read.getMessage().getId()));
    List<ChatMessageReaction> reactionRows = reactions.findByMessageIdIn(ids);
    Map<UUID, String> viewerReactions =
        reactionRows.stream()
            .filter(reaction -> reaction.getUser().getId().equals(viewerId))
            .collect(
                Collectors.toMap(
                    reaction -> reaction.getMessage().getId(),
                    ChatMessageReaction::getReaction,
                    (left, right) -> right));
    Map<UUID, List<ChatReactionSummaryResponse>> reactionSummaries = reactionSummary(reactionRows);
    return new ResponseContext(readsByMessageId, viewerReactions, reactionSummaries, now);
  }

  private Map<UUID, List<ChatReactionSummaryResponse>> reactionSummary(
      List<ChatMessageReaction> reactionRows) {
    Map<UUID, Map<String, Integer>> counts = new LinkedHashMap<>();
    for (ChatMessageReaction row : reactionRows) {
      counts
          .computeIfAbsent(row.getMessage().getId(), ignored -> new LinkedHashMap<>())
          .merge(row.getReaction(), 1, Integer::sum);
    }

    Map<UUID, List<ChatReactionSummaryResponse>> summaries = new LinkedHashMap<>();
    counts.forEach(
        (messageId, byReaction) -> {
          List<ChatReactionSummaryResponse> rows = new ArrayList<>();
          byReaction.forEach(
              (reaction, count) -> rows.add(new ChatReactionSummaryResponse(reaction, count)));
          rows.sort(Comparator.comparing(ChatReactionSummaryResponse::reaction));
          summaries.put(messageId, rows);
        });
    return summaries;
  }

  private record ResponseContext(
      Map<UUID, List<ChatMessageRead>> readsByMessageId,
      Map<UUID, String> viewerReactionsByMessageId,
      Map<UUID, List<ChatReactionSummaryResponse>> reactionsByMessageId,
      Instant now) {}
}
