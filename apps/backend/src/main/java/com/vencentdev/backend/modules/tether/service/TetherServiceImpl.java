package com.vencentdev.backend.modules.tether.service;

import com.vencentdev.backend.common.exception.BadRequestException;
import com.vencentdev.backend.common.exception.ConflictException;
import com.vencentdev.backend.common.exception.ResourceNotFoundException;
import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.tether.dto.TetherAcceptRequest;
import com.vencentdev.backend.modules.tether.dto.TetherInvitationResponse;
import com.vencentdev.backend.modules.tether.dto.TetherStatusResponse;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.tether.entity.TetherInvitation;
import com.vencentdev.backend.modules.tether.repository.TetherConnectionRepository;
import com.vencentdev.backend.modules.tether.repository.TetherInvitationRepository;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import com.vencentdev.backend.modules.user.service.UserService;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TetherServiceImpl implements TetherService {
  private static final Duration INVITATION_TTL = Duration.ofHours(24);
  private static final char[] CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".toCharArray();
  private static final String QR_PAYLOAD_TEMPLATE = "bub://tether/accept?code=%s";

  private final TetherConnectionRepository connections;
  private final TetherInvitationRepository invitations;
  private final UserRepository users;
  private final UserService userService;
  private final Clock clock;
  private final SecureRandom random;

  @Autowired
  public TetherServiceImpl(
      TetherConnectionRepository connections,
      TetherInvitationRepository invitations,
      UserRepository users,
      UserService userService) {
    this(connections, invitations, users, userService, Clock.systemUTC(), new SecureRandom());
  }

  TetherServiceImpl(
      TetherConnectionRepository connections,
      TetherInvitationRepository invitations,
      UserRepository users,
      UserService userService,
      Clock clock,
      SecureRandom random) {
    this.connections = connections;
    this.invitations = invitations;
    this.users = users;
    this.userService = userService;
    this.clock = clock;
    this.random = random;
  }

  @Override
  @Transactional
  public TetherStatusResponse getStatus(AuthenticatedUser principal) {
    UUID userId = userService.resolveInternalId(principal);
    return statusFor(userId);
  }

  @Override
  @Transactional
  public TetherInvitationResponse generateInvitation(AuthenticatedUser principal) {
    UUID userId = userService.resolveInternalId(principal);
    User creator =
        users.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    String code = generateUniqueCode();
    TetherInvitation invitation =
        invitations.save(
            TetherInvitation.builder()
                .code(code)
                .creator(creator)
                .expiresAt(Instant.now(clock).plus(INVITATION_TTL))
                .build());
    return toInvitationResponse(invitation);
  }

  @Override
  @Transactional
  public TetherStatusResponse acceptInvitation(
      AuthenticatedUser principal, TetherAcceptRequest request) {
    UUID accepterId = userService.resolveInternalId(principal);
    User accepter =
        users
            .findById(accepterId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    TetherInvitation invitation =
        invitations
            .findByCodeWithUsers(request.code())
            .orElseThrow(() -> new ResourceNotFoundException("Tether invitation not found"));
    User creator = invitation.getCreator();

    if (creator.getId().equals(accepterId)) {
      throw new BadRequestException("You cannot tether with yourself");
    }
    if (invitation.getConsumedAt() != null) {
      throw new BadRequestException("Tether invitation has already been used");
    }
    if (!invitation.getExpiresAt().isAfter(Instant.now(clock))) {
      throw new BadRequestException("Tether invitation has expired");
    }
    if (connections.existsActiveByUserId(creator.getId())
        || connections.existsActiveByUserId(accepterId)) {
      throw new ConflictException("A user already has an active tether");
    }

    connections.save(
        TetherConnection.builder().userOne(creator).userTwo(accepter).active(true).build());
    invitation.setConsumedAt(Instant.now(clock));
    invitation.setAcceptedUser(accepter);
    return statusFor(accepterId);
  }

  @Override
  @Transactional
  public TetherStatusResponse removeTether(AuthenticatedUser principal) {
    UUID userId = userService.resolveInternalId(principal);
    TetherConnection connection =
        connections
            .findActiveByUserId(userId)
            .orElseThrow(() -> new BadRequestException("No active tether to remove"));
    connections.delete(connection);
    return new TetherStatusResponse(false, null);
  }

  private TetherStatusResponse statusFor(UUID userId) {
    return connections
        .findActiveByUserId(userId)
        .map(connection -> new TetherStatusResponse(true, partnerId(connection, userId)))
        .orElseGet(() -> new TetherStatusResponse(false, null));
  }

  private UUID partnerId(TetherConnection connection, UUID userId) {
    UUID userOneId = connection.getUserOne().getId();
    return userOneId.equals(userId) ? connection.getUserTwo().getId() : userOneId;
  }

  private String generateUniqueCode() {
    String code;
    do {
      code = "BUB-" + randomBlock() + "-" + randomBlock();
    } while (invitations.existsByCode(code));
    return code;
  }

  private String randomBlock() {
    StringBuilder builder = new StringBuilder(4);
    for (int index = 0; index < 4; index++) {
      builder.append(CODE_ALPHABET[random.nextInt(CODE_ALPHABET.length)]);
    }
    return builder.toString();
  }

  private TetherInvitationResponse toInvitationResponse(TetherInvitation invitation) {
    return new TetherInvitationResponse(
        invitation.getId(),
        invitation.getCode(),
        invitation.getExpiresAt(),
        QR_PAYLOAD_TEMPLATE.formatted(invitation.getCode()));
  }
}
