package com.vencentdev.backend.modules.chat.controller;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.vencentdev.backend.IntegrationTestBase;
import com.vencentdev.backend.modules.chat.live.ChatLiveEventType;
import com.vencentdev.backend.modules.chat.live.ChatLivePublisher;
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
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;

class ChatControllerIntegrationTest extends IntegrationTestBase {

  @Autowired private MockMvc mockMvc;
  @Autowired private TetherConnectionRepository connections;
  @Autowired private TetherInvitationRepository invitations;
  @Autowired private UserRepository users;
  @MockitoSpyBean private ChatLivePublisher chatLivePublisher;

  @BeforeEach
  void setUp() {
    connections.deleteAll();
    invitations.deleteAll();
    users.deleteAll();
  }

  @Test
  void untetheredThreadReturnsExplicitEmptyStateAndMutationsConflict() throws Exception {
    users.save(user("alice", "alice@example.com", "Alice"));

    mockMvc
        .perform(get("/api/v1/chat/thread").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.hasActiveTether").value(false))
        .andExpect(jsonPath("$.messages", hasSize(0)));

    mockMvc
        .perform(
            post("/api/v1/chat/messages")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"type\":\"TEXT\",\"body\":\"hi\"}")
                .with(currentUser("alice")))
        .andExpect(status().isConflict());
  }

  @Test
  void tetheredUsersCanSendTextEmojiGifAndReplyInChronologicalThread() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());

    String textId =
        send("alice", "{\"type\":\"TEXT\",\"body\":\"  hi bub  \"}")
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.body").value("hi bub"))
            .andExpect(jsonPath("$.deliveryState").value("DELIVERED"))
            .andReturn()
            .getResponse()
            .getContentAsString()
            .replaceAll(".*\"id\":\"([^\"]+)\".*", "$1");

    send("bob", "{\"type\":\"EMOJI\",\"body\":\"❤️\"}")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.type").value("EMOJI"));

    send("alice", "{\"type\":\"GIF\",\"gifUrl\":\"https://cdn.example.com/cat.gif\"}")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.type").value("GIF"));

    send("bob", "{\"type\":\"TEXT\",\"body\":\"replying\",\"replyToMessageId\":\"" + textId + "\"}")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.reply.id").value(textId))
        .andExpect(jsonPath("$.reply.snippet").value("hi bub"));

    mockMvc
        .perform(get("/api/v1/chat/thread").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.hasActiveTether").value(true))
        .andExpect(jsonPath("$.partnerDisplayName").value("Bob"))
        .andExpect(jsonPath("$.messages", hasSize(4)))
        .andExpect(jsonPath("$.messages[0].body").value("hi bub"))
        .andExpect(jsonPath("$.messages[3].reply.snippet").value("hi bub"));
  }

  @Test
  void rejectsInvalidSendsAndCrossTetherReplies() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    User carol = users.save(user("carol", "carol@example.com", "Carol"));
    User dana = users.save(user("dana", "dana@example.com", "Dana"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
    connections.save(TetherConnection.builder().userOne(carol).userTwo(dana).active(true).build());

    mockMvc
        .perform(
            post("/api/v1/chat/messages")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"type\":\"TEXT\",\"body\":\"   \"}")
                .with(currentUser("alice")))
        .andExpect(status().isBadRequest());

    mockMvc
        .perform(
            post("/api/v1/chat/messages")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"type\":\"GIF\"}")
                .with(currentUser("alice")))
        .andExpect(status().isBadRequest());

    String otherMessageId =
        send("carol", "{\"type\":\"TEXT\",\"body\":\"other tether\"}")
            .andExpect(status().isOk())
            .andReturn()
            .getResponse()
            .getContentAsString()
            .replaceAll(".*\"id\":\"([^\"]+)\".*", "$1");

    send(
            "alice",
            "{\"type\":\"TEXT\",\"body\":\"nope\",\"replyToMessageId\":\"" + otherMessageId + "\"}")
        .andExpect(status().isBadRequest());
  }

  @Test
  void editDeleteReactionReadTypingAndPresenceRulesAreEnforced() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());

    String messageId =
        send("alice", "{\"type\":\"TEXT\",\"body\":\"draft\"}")
            .andExpect(status().isOk())
            .andReturn()
            .getResponse()
            .getContentAsString()
            .replaceAll(".*\"id\":\"([^\"]+)\".*", "$1");
    verify(chatLivePublisher).publish(eq(alice.getId()), eq(ChatLiveEventType.MESSAGE_CREATED));
    verify(chatLivePublisher).publish(eq(bob.getId()), eq(ChatLiveEventType.MESSAGE_CREATED));
    clearInvocations(chatLivePublisher);

    mockMvc
        .perform(
            patch("/api/v1/chat/messages/{messageId}", messageId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"edited\"}")
                .with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.body").value("edited"))
        .andExpect(jsonPath("$.editedAt").exists());
    verify(chatLivePublisher).publish(eq(alice.getId()), eq(ChatLiveEventType.MESSAGE_UPDATED));
    verify(chatLivePublisher).publish(eq(bob.getId()), eq(ChatLiveEventType.MESSAGE_UPDATED));
    clearInvocations(chatLivePublisher);

    mockMvc
        .perform(
            patch("/api/v1/chat/messages/{messageId}", messageId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"partner edit\"}")
                .with(currentUser("bob")))
        .andExpect(status().isForbidden());

    mockMvc
        .perform(
            post("/api/v1/chat/messages/{messageId}/reaction", messageId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"reaction\":\"🔥\"}")
                .with(currentUser("bob")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.viewerReaction").value("🔥"));
    verify(chatLivePublisher).publish(eq(alice.getId()), eq(ChatLiveEventType.MESSAGE_UPDATED));
    verify(chatLivePublisher).publish(eq(bob.getId()), eq(ChatLiveEventType.MESSAGE_UPDATED));
    clearInvocations(chatLivePublisher);

    mockMvc
        .perform(
            post("/api/v1/chat/read")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"upToMessageId\":\"" + messageId + "\"}")
                .with(currentUser("bob")))
        .andExpect(status().isOk());
    verify(chatLivePublisher).publish(eq(alice.getId()), eq(ChatLiveEventType.STATE_UPDATED));
    verify(chatLivePublisher).publish(eq(bob.getId()), eq(ChatLiveEventType.STATE_UPDATED));
    clearInvocations(chatLivePublisher);

    mockMvc
        .perform(get("/api/v1/chat/thread").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.messages[0].deliveryState").value("SEEN"));

    mockMvc
        .perform(
            post("/api/v1/chat/typing")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"typing\":true}")
                .with(currentUser("bob")))
        .andExpect(status().isOk());
    verify(chatLivePublisher).publish(eq(alice.getId()), eq(ChatLiveEventType.TYPING_UPDATED));
    verify(chatLivePublisher).publish(eq(bob.getId()), eq(ChatLiveEventType.TYPING_UPDATED));
    clearInvocations(chatLivePublisher);

    mockMvc
        .perform(get("/api/v1/chat/state").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.partnerTyping").value(true))
        .andExpect(jsonPath("$.partnerPresence.status").value("ONLINE"));

    mockMvc
        .perform(delete("/api/v1/chat/messages/{messageId}/me", messageId).with(currentUser("bob")))
        .andExpect(status().isNoContent());

    mockMvc
        .perform(get("/api/v1/chat/thread").with(currentUser("bob")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.messages", hasSize(0)));

    mockMvc
        .perform(
            delete("/api/v1/chat/messages/{messageId}/everyone", messageId)
                .with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.deletedForEveryone").value(true))
        .andExpect(jsonPath("$.body").value(nullValue()));
    verify(chatLivePublisher).publish(eq(alice.getId()), eq(ChatLiveEventType.MESSAGE_UPDATED));
    verify(chatLivePublisher).publish(eq(bob.getId()), eq(ChatLiveEventType.MESSAGE_UPDATED));
  }

  private org.springframework.test.web.servlet.ResultActions send(String subject, String json)
      throws Exception {
    return mockMvc.perform(
        post("/api/v1/chat/messages")
            .contentType(MediaType.APPLICATION_JSON)
            .content(json)
            .with(currentUser(subject)));
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
