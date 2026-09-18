package com.vencentdev.backend.modules.notification;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.vencentdev.backend.IntegrationTestBase;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.tether.repository.TetherConnectionRepository;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.enums.KycStatus;
import com.vencentdev.backend.modules.user.enums.Role;
import com.vencentdev.backend.modules.user.enums.UserType;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

class NotificationControllerIntegrationTest extends IntegrationTestBase {

  @Autowired private MockMvc mockMvc;
  @Autowired private JdbcTemplate jdbc;
  @Autowired private TetherConnectionRepository connections;
  @Autowired private UserRepository users;

  private User alice;
  private User bob;
  private TetherConnection connection;

  @BeforeEach
  void setUp() {
    jdbc.update("delete from notifications");
    connections.deleteAll();
    users.deleteAll();
    alice = users.save(user("alice", "alice@example.com"));
    bob = users.save(user("bob", "bob@example.com"));
    connection =
        connections.save(
            TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
  }

  @Test
  void summaryReturnsOnlyAuthenticatedUsersUnreadNotifications() throws Exception {
    insertNotification(alice, "MESSAGE", "New message", "Bob sent a message", "/chat", null);
    UUID aliceLatest = insertNotification(alice, "BUB", "Bub", "Bob sent a Bub", "/home", "now()");
    insertNotification(bob, "MESSAGE", "Alice message", "Alice sent a message", "/chat", null);

    mockMvc
        .perform(get("/api/v1/notifications/summary").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.unreadCount").value(1))
        .andExpect(jsonPath("$.latest.id").value(aliceLatest.toString()))
        .andExpect(jsonPath("$.latest.title").value("Bub"));
  }

  @Test
  void listReturnsNewestNotificationsForAuthenticatedUserOnly() throws Exception {
    insertNotification(bob, "MESSAGE", "Bob only", "Hidden from Alice", "/chat", null);
    insertNotification(alice, "MESSAGE", "Older", "Older body", "/chat", null);
    UUID newest =
        insertNotification(
            alice, "SAFE", "Safe updated", "A memory was added to Safe", "/safe", null);

    mockMvc
        .perform(get("/api/v1/notifications?limit=20").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.items.length()").value(2))
        .andExpect(jsonPath("$.items[0].id").value(newest.toString()))
        .andExpect(jsonPath("$.items[0].category").value("SAFE"))
        .andExpect(jsonPath("$.items[0].body").value("A memory was added to Safe"))
        .andExpect(jsonPath("$.items[0].url").doesNotExist())
        .andExpect(jsonPath("$.items[0].thumbnailUrl").doesNotExist());
  }

  @Test
  void markReadAndReadAllAffectOnlyAuthenticatedUsersNotifications() throws Exception {
    UUID aliceFirst = insertNotification(alice, "MESSAGE", "First", "First body", "/chat", null);
    insertNotification(alice, "BUB", "Second", "Second body", "/home", null);
    UUID bobNotification = insertNotification(bob, "MESSAGE", "Bob", "Bob body", "/chat", null);

    mockMvc
        .perform(post("/api/v1/notifications/{id}/read", aliceFirst).with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.read").value(true));

    mockMvc
        .perform(get("/api/v1/notifications/summary").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.unreadCount").value(1));

    mockMvc
        .perform(post("/api/v1/notifications/read-all").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.updatedCount").value(1));

    mockMvc
        .perform(get("/api/v1/notifications/summary").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.unreadCount").value(0));

    Integer bobUnread =
        jdbc.queryForObject(
            "select count(*) from notifications where recipient_user_id = ? and read_at is null",
            Integer.class,
            bob.getId());
    org.assertj.core.api.Assertions.assertThat(bobUnread).isEqualTo(1);
    org.assertj.core.api.Assertions.assertThat(bobNotification).isNotNull();
  }

  private UUID insertNotification(
      User recipient,
      String category,
      String title,
      String body,
      String linkPath,
      String readAtExpression) {
    String readAtSql = readAtExpression == null ? "null" : readAtExpression;
    return jdbc.queryForObject(
        """
        insert into notifications
          (recipient_user_id, tether_connection_id, category, title, body, link_path, read_at)
        values (?, ?, ?, ?, ?, ?, %s)
        returning id
        """
            .formatted(readAtSql),
        UUID.class,
        recipient.getId(),
        connection.getId(),
        category,
        title,
        body,
        linkPath);
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
