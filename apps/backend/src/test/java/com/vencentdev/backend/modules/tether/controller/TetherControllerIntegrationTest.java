package com.vencentdev.backend.modules.tether.controller;

import static org.hamcrest.Matchers.matchesPattern;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.vencentdev.backend.IntegrationTestBase;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.tether.entity.TetherInvitation;
import com.vencentdev.backend.modules.tether.repository.TetherConnectionRepository;
import com.vencentdev.backend.modules.tether.repository.TetherInvitationRepository;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.enums.KycStatus;
import com.vencentdev.backend.modules.user.enums.Role;
import com.vencentdev.backend.modules.user.enums.UserType;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import java.time.Instant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

class TetherControllerIntegrationTest extends IntegrationTestBase {

  @Autowired private MockMvc mockMvc;
  @Autowired private TetherConnectionRepository connections;
  @Autowired private TetherInvitationRepository invitations;
  @Autowired private UserRepository users;
  @Autowired private JdbcTemplate jdbc;

  @BeforeEach
  void setUp() {
    connections.deleteAll();
    invitations.deleteAll();
    users.deleteAll();
  }

  @Test
  void statusWithoutTetherReturnsUntetheredState() throws Exception {
    users.save(user("alice", "alice@example.com"));

    mockMvc
        .perform(get("/api/v1/tether/me").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.hasActiveTether").value(false))
        .andExpect(jsonPath("$.partnerUserId").doesNotExist());
  }

  @Test
  void statusWithTetherReturnsPartner() throws Exception {
    User alice = users.save(user("alice", "alice@example.com"));
    User bob = users.save(user("bob", "bob@example.com"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());

    mockMvc
        .perform(get("/api/v1/tether/me").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.hasActiveTether").value(true))
        .andExpect(jsonPath("$.partnerUserId").value(bob.getId().toString()));
  }

  @Test
  void generateInvitationReturnsCodeAndQrPayload() throws Exception {
    users.save(user("alice", "alice@example.com"));

    mockMvc
        .perform(post("/api/v1/tether/invitations").with(currentUser("alice")))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.code").value(matchesPattern("BUB-[A-Z0-9]{4}-[A-Z0-9]{4}")))
        .andExpect(
            jsonPath("$.qrPayload")
                .value(matchesPattern("bub://tether/accept\\?code=BUB-[A-Z0-9]{4}-[A-Z0-9]{4}")))
        .andExpect(jsonPath("$.expiresAt").exists());
  }

  @Test
  void acceptInvitationCreatesActiveTetherAndConsumesCode() throws Exception {
    User alice = users.save(user("alice", "alice@example.com"));
    users.save(user("bob", "bob@example.com"));
    invitations.save(invitation("BUB-7KQ2-XH19", alice, Instant.now().plusSeconds(3600)));

    mockMvc
        .perform(accept("bob", "BUB-7KQ2-XH19"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.hasActiveTether").value(true))
        .andExpect(jsonPath("$.partnerUserId").value(alice.getId().toString()));
  }

  @Test
  void acceptInvitationRejectsSelfTethering() throws Exception {
    User alice = users.save(user("alice", "alice@example.com"));
    invitations.save(invitation("BUB-7KQ2-XH19", alice, Instant.now().plusSeconds(3600)));

    mockMvc.perform(accept("alice", "BUB-7KQ2-XH19")).andExpect(status().isBadRequest());
  }

  @Test
  void acceptInvitationRejectsAlreadyTetheredUsers() throws Exception {
    User alice = users.save(user("alice", "alice@example.com"));
    User bob = users.save(user("bob", "bob@example.com"));
    User charlie = users.save(user("charlie", "charlie@example.com"));
    connections.save(TetherConnection.builder().userOne(bob).userTwo(charlie).active(true).build());
    invitations.save(invitation("BUB-7KQ2-XH19", alice, Instant.now().plusSeconds(3600)));

    mockMvc.perform(accept("bob", "BUB-7KQ2-XH19")).andExpect(status().isConflict());
  }

  @Test
  void acceptInvitationRejectsExpiredCode() throws Exception {
    User alice = users.save(user("alice", "alice@example.com"));
    users.save(user("bob", "bob@example.com"));
    invitations.save(invitation("BUB-7KQ2-XH19", alice, Instant.now().minusSeconds(60)));

    mockMvc.perform(accept("bob", "BUB-7KQ2-XH19")).andExpect(status().isBadRequest());
  }

  @Test
  void acceptInvitationRejectsConsumedCode() throws Exception {
    User alice = users.save(user("alice", "alice@example.com"));
    User bob = users.save(user("bob", "bob@example.com"));
    users.save(user("charlie", "charlie@example.com"));
    invitations.save(
        TetherInvitation.builder()
            .code("BUB-7KQ2-XH19")
            .creator(alice)
            .expiresAt(Instant.now().plusSeconds(3600))
            .consumedAt(Instant.now())
            .acceptedUser(bob)
            .build());

    mockMvc.perform(accept("charlie", "BUB-7KQ2-XH19")).andExpect(status().isBadRequest());
  }

  @Test
  void removeTetherDeletesSharedDataAndUntethersBothUsers() throws Exception {
    User alice = users.save(user("alice", "alice@example.com"));
    User bob = users.save(user("bob", "bob@example.com"));
    TetherConnection connection =
        connections.save(
            TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    insertSharedData(connection, alice, bob);

    mockMvc
        .perform(delete("/api/v1/tether/me").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.hasActiveTether").value(false))
        .andExpect(jsonPath("$.partnerUserId").doesNotExist());

    mockMvc
        .perform(get("/api/v1/tether/me").with(currentUser("bob")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.hasActiveTether").value(false));
    assertTableCount("tether_connections", 0);
    assertTableCount("bub_events", 0);
    assertTableCount("home_daily_moments", 0);
    assertTableCount("safe_vault_access", 0);
    assertTableCount("safe_media_items", 0);
    assertTableCount("chat_messages", 0);
    assertTableCount("chat_message_reactions", 0);
    assertTableCount("chat_message_reads", 0);
  }

  @Test
  void removeTetherRejectsUntetheredUser() throws Exception {
    users.save(user("alice", "alice@example.com"));

    mockMvc
        .perform(delete("/api/v1/tether/me").with(currentUser("alice")))
        .andExpect(status().isBadRequest());
  }

  private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder accept(
      String subject, String code) {
    return post("/api/v1/tether/accept")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"code\":\"" + code + "\"}")
        .with(currentUser(subject));
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

  private TetherInvitation invitation(String code, User creator, Instant expiresAt) {
    return TetherInvitation.builder().code(code).creator(creator).expiresAt(expiresAt).build();
  }

  private void insertSharedData(TetherConnection connection, User alice, User bob) {
    jdbc.update(
        """
        insert into bub_events (tether_connection_id, sender_user_id, receiver_user_id)
        values (?, ?, ?)
        """,
        connection.getId(),
        alice.getId(),
        bob.getId());
    jdbc.update(
        """
        insert into home_daily_moments
          (tether_connection_id, created_by_user_id, local_date, photo_url, expires_at)
        values (?, ?, current_date, 'https://example.com/photo.jpg', now() + interval '1 day')
        """,
        connection.getId(),
        alice.getId());
    jdbc.update(
        """
        insert into safe_vault_access (tether_connection_id, user_id, pin_hash)
        values (?, ?, 'hash')
        """,
        connection.getId(),
        alice.getId());
    jdbc.update(
        """
        insert into safe_media_items
          (tether_connection_id, uploaded_by_user_id, media_type, url, storage_object_path,
           content_type, size_bytes)
        values (?, ?, 'IMAGE', 'https://example.com/safe.jpg', 'safe.jpg', 'image/jpeg', 10)
        """,
        connection.getId(),
        alice.getId());
    jdbc.update(
        """
        insert into chat_messages (tether_connection_id, sender_user_id, message_type, body)
        values (?, ?, 'TEXT', 'hello')
        """,
        connection.getId(),
        alice.getId());
    var messageId =
        jdbc.queryForObject(
            "select id from chat_messages where tether_connection_id = ?",
            java.util.UUID.class,
            connection.getId());
    jdbc.update(
        "insert into chat_message_reactions (message_id, user_id, reaction) values (?, ?, '❤️')",
        messageId,
        bob.getId());
    jdbc.update(
        "insert into chat_message_reads (message_id, user_id) values (?, ?)",
        messageId,
        bob.getId());
  }

  private void assertTableCount(String table, int expected) {
    Integer count = jdbc.queryForObject("select count(*) from " + table, Integer.class);
    org.assertj.core.api.Assertions.assertThat(count).isEqualTo(expected);
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
