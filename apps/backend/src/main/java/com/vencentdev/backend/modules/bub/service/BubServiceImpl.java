package com.vencentdev.backend.modules.bub.service;

import com.vencentdev.backend.common.exception.ConflictException;
import com.vencentdev.backend.common.exception.ResourceNotFoundException;
import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.bub.dto.BubSendResponse;
import com.vencentdev.backend.modules.bub.entity.BubEvent;
import com.vencentdev.backend.modules.bub.repository.BubEventRepository;
import com.vencentdev.backend.modules.chat.entity.ChatMessage;
import com.vencentdev.backend.modules.chat.entity.ChatMessageType;
import com.vencentdev.backend.modules.chat.live.ChatLiveEventType;
import com.vencentdev.backend.modules.chat.live.ChatLivePublisher;
import com.vencentdev.backend.modules.chat.repository.ChatMessageRepository;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.tether.repository.TetherConnectionRepository;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import com.vencentdev.backend.modules.user.service.UserService;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BubServiceImpl implements BubService {

  private final TetherConnectionRepository connections;
  private final BubEventRepository bubEvents;
  private final ChatMessageRepository chatMessages;
  private final UserRepository users;
  private final UserService userService;
  private final ChatLivePublisher livePublisher;

  public BubServiceImpl(
      TetherConnectionRepository connections,
      BubEventRepository bubEvents,
      ChatMessageRepository chatMessages,
      UserRepository users,
      UserService userService,
      ChatLivePublisher livePublisher) {
    this.connections = connections;
    this.bubEvents = bubEvents;
    this.chatMessages = chatMessages;
    this.users = users;
    this.userService = userService;
    this.livePublisher = livePublisher;
  }

  @Override
  @Transactional
  public BubSendResponse send(AuthenticatedUser principal) {
    UUID userId = userService.resolveInternalId(principal);
    TetherConnection connection =
        connections
            .findActiveByUserId(userId)
            .orElseThrow(() -> new ConflictException("An active tether is required"));
    User sender =
        users.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    User receiver = partner(connection, userId);
    BubEvent event =
        bubEvents.save(
            BubEvent.builder()
                .tetherConnection(connection)
                .senderUser(sender)
                .receiverUser(receiver)
                .build());
    chatMessages.save(
        ChatMessage.builder()
            .tetherConnection(connection)
            .senderUser(sender)
            .type(ChatMessageType.BUB)
            .deliveredAt(event.getCreatedAt())
            .build());
    livePublisher.publish(sender.getId(), ChatLiveEventType.MESSAGE_CREATED);
    livePublisher.publish(receiver.getId(), ChatLiveEventType.MESSAGE_CREATED);

    return new BubSendResponse(
        event.getId(), connection.getId(), sender.getId(), receiver.getId(), event.getCreatedAt());
  }

  private User partner(TetherConnection connection, UUID userId) {
    if (connection.getUserOne().getId().equals(userId)) {
      return connection.getUserTwo();
    }
    return connection.getUserOne();
  }
}
