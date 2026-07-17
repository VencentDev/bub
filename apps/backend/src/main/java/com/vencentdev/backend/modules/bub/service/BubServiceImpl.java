package com.vencentdev.backend.modules.bub.service;

import com.vencentdev.backend.common.exception.ConflictException;
import com.vencentdev.backend.common.exception.ResourceNotFoundException;
import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.bub.dto.BubSendResponse;
import com.vencentdev.backend.modules.bub.entity.BubEvent;
import com.vencentdev.backend.modules.bub.repository.BubEventRepository;
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
  private final UserRepository users;
  private final UserService userService;

  public BubServiceImpl(
      TetherConnectionRepository connections,
      BubEventRepository bubEvents,
      UserRepository users,
      UserService userService) {
    this.connections = connections;
    this.bubEvents = bubEvents;
    this.users = users;
    this.userService = userService;
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
