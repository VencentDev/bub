package com.vencentdev.backend.modules.tether.repository;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.vencentdev.backend.IntegrationTestBase;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.tether.entity.TetherInvitation;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.enums.KycStatus;
import com.vencentdev.backend.modules.user.enums.Role;
import com.vencentdev.backend.modules.user.enums.UserType;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import java.time.Instant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;

class TetherRepositoryTest extends IntegrationTestBase {

  @Autowired private TetherConnectionRepository connections;
  @Autowired private TetherInvitationRepository invitations;
  @Autowired private UserRepository users;

  private User alice;
  private User bob;
  private User charlie;

  @BeforeEach
  void setUp() {
    connections.deleteAll();
    invitations.deleteAll();
    users.deleteAll();
    alice = users.save(user("alice", "alice@example.com"));
    bob = users.save(user("bob", "bob@example.com"));
    charlie = users.save(user("charlie", "charlie@example.com"));
  }

  @Test
  void findsActiveTetherForEitherParticipant() {
    TetherConnection connection =
        connections.save(
            TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());

    assertThat(connections.findActiveByUserId(alice.getId())).contains(connection);
    assertThat(connections.findActiveByUserId(bob.getId())).contains(connection);
    assertThat(connections.existsActiveByUserId(charlie.getId())).isFalse();
  }

  @Test
  void databaseRejectsSelfTethering() {
    assertThatThrownBy(
            () ->
                connections.saveAndFlush(
                    TetherConnection.builder().userOne(alice).userTwo(alice).active(true).build()))
        .isInstanceOf(DataIntegrityViolationException.class);
  }

  @Test
  void invitationCodeIsUnique() {
    invitations.save(invitation("BUB-7KQ2-XH19", alice));

    assertThatThrownBy(() -> invitations.saveAndFlush(invitation("BUB-7KQ2-XH19", bob)))
        .isInstanceOf(DataIntegrityViolationException.class);
  }

  private TetherInvitation invitation(String code, User creator) {
    return TetherInvitation.builder()
        .code(code)
        .creator(creator)
        .expiresAt(Instant.now().plusSeconds(3600))
        .build();
  }

  private User user(String externalId, String email) {
    return User.builder()
        .externalId(externalId)
        .email(email)
        .displayName("User")
        .role(Role.USER)
        .userType(UserType.INDIVIDUAL)
        .kycStatus(KycStatus.NONE)
        .build();
  }
}
