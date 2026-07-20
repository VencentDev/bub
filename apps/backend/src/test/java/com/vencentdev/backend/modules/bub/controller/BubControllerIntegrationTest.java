package com.vencentdev.backend.modules.bub.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.vencentdev.backend.IntegrationTestBase;
import com.vencentdev.backend.modules.bub.repository.BubEventRepository;
import com.vencentdev.backend.modules.chat.entity.ChatMessageType;
import com.vencentdev.backend.modules.chat.repository.ChatMessageRepository;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.tether.repository.TetherConnectionRepository;
import com.vencentdev.backend.modules.tether.repository.TetherInvitationRepository;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.enums.KycStatus;
import com.vencentdev.backend.modules.user.enums.Role;
import com.vencentdev.backend.modules.user.enums.UserType;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

class BubControllerIntegrationTest extends IntegrationTestBase {

  @Autowired private MockMvc mockMvc;
  @Autowired private BubEventRepository bubEvents;
  @Autowired private ChatMessageRepository chatMessages;
  @Autowired private TetherConnectionRepository connections;
  @Autowired private TetherInvitationRepository invitations;
  @Autowired private UserRepository users;

  @BeforeEach
  void setUp() {
    chatMessages.deleteAll();
    bubEvents.deleteAll();
    connections.deleteAll();
    invitations.deleteAll();
    users.deleteAll();
  }

  @Test
  void tetheredUserCanSendBub() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    TetherConnection connection =
        connections.save(
            TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());

    mockMvc
        .perform(post("/api/v1/bubs").with(currentUser("alice")))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.bubId").exists())
        .andExpect(jsonPath("$.tetherConnectionId").value(connection.getId().toString()))
        .andExpect(jsonPath("$.senderUserId").value(alice.getId().toString()))
        .andExpect(jsonPath("$.receiverUserId").value(bob.getId().toString()))
        .andExpect(jsonPath("$.sentAt").exists());

    assertThat(bubEvents.findAll())
        .singleElement()
        .satisfies(
            event -> {
              assertThat(event.getTetherConnection().getId()).isEqualTo(connection.getId());
              assertThat(event.getSenderUser().getId()).isEqualTo(alice.getId());
              assertThat(event.getReceiverUser().getId()).isEqualTo(bob.getId());
              assertThat(event.getCreatedAt()).isNotNull();
            });
    assertThat(chatMessages.findAll())
        .singleElement()
        .satisfies(
            message -> {
              assertThat(message.getTetherConnection().getId()).isEqualTo(connection.getId());
              assertThat(message.getSenderUser().getId()).isEqualTo(alice.getId());
              assertThat(message.getType()).isEqualTo(ChatMessageType.BUB);
              assertThat(message.getBody()).isNull();
              assertThat(message.getDeliveredAt()).isNotNull();
            });
  }

  @Test
  void sentBubAppearsInChatWithViewerSpecificNicknameCopy() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(
        TetherConnection.builder()
            .userOne(alice)
            .userTwo(bob)
            .userTwoPartnerNickname("Bubba")
            .active(true)
            .build());

    mockMvc
        .perform(post("/api/v1/bubs").with(currentUser("alice")))
        .andExpect(status().isCreated());

    mockMvc
        .perform(
            org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(
                    "/api/v1/chat/thread")
                .with(currentUser("bob")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.messages[0].type").value("BUB"))
        .andExpect(jsonPath("$.messages[0].viewerMessage").value(false))
        .andExpect(jsonPath("$.messages[0].body").value("Bubba bubbed you"));

    mockMvc
        .perform(
            org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(
                    "/api/v1/chat/thread")
                .with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.messages[0].type").value("BUB"))
        .andExpect(jsonPath("$.messages[0].viewerMessage").value(true))
        .andExpect(jsonPath("$.messages[0].body").value("You bubbed Bob"));
  }

  @Test
  void untetheredUserCannotSendBub() throws Exception {
    users.save(user("alice", "alice@example.com", "Alice"));

    mockMvc
        .perform(post("/api/v1/bubs").with(currentUser("alice")))
        .andExpect(status().isConflict());

    assertThat(bubEvents.findAll()).isEmpty();
  }

  @Test
  void sendBubRequiresAuthentication() throws Exception {
    mockMvc.perform(post("/api/v1/bubs")).andExpect(status().isUnauthorized());
  }

  private org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors
          .JwtRequestPostProcessor
      currentUser(String subject) {
    return jwt()
        .jwt(
            token ->
                token
                    .subject(subject)
                    .claim("email", subject + "@example.com")
                    .claim("name", subject))
        .authorities(() -> "ROLE_USER");
  }

  private User user(String externalId, String email, String displayName) {
    return User.builder()
        .externalId(externalId)
        .email(email)
        .displayName(displayName)
        .role(Role.USER)
        .userType(UserType.INDIVIDUAL)
        .kycStatus(KycStatus.NONE)
        .build();
  }
}
