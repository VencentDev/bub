package com.vencentdev.backend.modules.chat.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vencentdev.backend.IntegrationTestBase;
import com.vencentdev.backend.modules.chat.live.ChatLiveEventType;
import com.vencentdev.backend.modules.chat.live.ChatLivePublisher;
import com.vencentdev.backend.modules.chat.service.ChatMediaStorageService;
import com.vencentdev.backend.modules.chat.service.StoredChatMedia;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.tether.repository.TetherConnectionRepository;
import com.vencentdev.backend.modules.tether.repository.TetherInvitationRepository;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.enums.KycStatus;
import com.vencentdev.backend.modules.user.enums.Role;
import com.vencentdev.backend.modules.user.enums.UserType;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.servlet.autoconfigure.MultipartProperties;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.util.unit.DataSize;
import org.springframework.web.multipart.MultipartFile;

class ChatControllerIntegrationTest extends IntegrationTestBase {

  private static final ObjectMapper objectMapper = new ObjectMapper();

  @Autowired private MockMvc mockMvc;
  @Autowired private TetherConnectionRepository connections;
  @Autowired private TetherInvitationRepository invitations;
  @Autowired private UserRepository users;
  @Autowired private MultipartProperties multipartProperties;
  @MockitoSpyBean private ChatLivePublisher chatLivePublisher;

  @BeforeEach
  void setUp() {
    connections.deleteAll();
    invitations.deleteAll();
    users.deleteAll();
    StorageTestConfig.uploadCounter.set(0);
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
        messageId(
            send("alice", "{\"type\":\"TEXT\",\"body\":\"  hi bub  \"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.body").value("hi bub"))
                .andExpect(jsonPath("$.deliveryState").value("DELIVERED"))
                .andReturn()
                .getResponse()
                .getContentAsString());

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
        messageId(
            send("carol", "{\"type\":\"TEXT\",\"body\":\"other tether\"}")
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString());

    send(
            "alice",
            "{\"type\":\"TEXT\",\"body\":\"nope\",\"replyToMessageId\":\"" + otherMessageId + "\"}")
        .andExpect(status().isBadRequest());
  }

  @Test
  void multipartLimitsAllowMobileMediaUploads() {
    assertThat(multipartProperties.getMaxFileSize()).isEqualTo(DataSize.ofMegabytes(25));
    assertThat(multipartProperties.getMaxRequestSize()).isEqualTo(DataSize.ofMegabytes(100));
  }

  @Test
  void uploadsImagesAsGroupedMediaAndVideosAsSeparateMessages() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());

    MockMultipartFile imageOne =
        new MockMultipartFile("files", "one.jpg", "image/jpeg", "one".getBytes());
    MockMultipartFile imageTwo =
        new MockMultipartFile("files", "two.png", "image/png", "two".getBytes());
    MockMultipartFile video =
        new MockMultipartFile("files", "clip.mp4", "video/mp4", "video".getBytes());

    mockMvc
        .perform(
            multipart("/api/v1/chat/messages/media")
                .file(imageOne)
                .file(imageTwo)
                .file(video)
                .with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$", hasSize(2)))
        .andExpect(jsonPath("$[0].type").value("MEDIA"))
        .andExpect(jsonPath("$[0].attachments", hasSize(2)))
        .andExpect(jsonPath("$[0].attachments[0].type").value("IMAGE"))
        .andExpect(jsonPath("$[0].attachments[0].position").value(0))
        .andExpect(jsonPath("$[0].attachments[1].type").value("IMAGE"))
        .andExpect(jsonPath("$[0].attachments[1].position").value(1))
        .andExpect(jsonPath("$[1].type").value("MEDIA"))
        .andExpect(jsonPath("$[1].attachments", hasSize(1)))
        .andExpect(jsonPath("$[1].attachments[0].type").value("VIDEO"));
    verify(chatLivePublisher).publish(eq(alice.getId()), eq(ChatLiveEventType.MESSAGE_CREATED));
    verify(chatLivePublisher).publish(eq(bob.getId()), eq(ChatLiveEventType.MESSAGE_CREATED));

    mockMvc
        .perform(get("/api/v1/chat/thread").with(currentUser("bob")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.messages", hasSize(2)))
        .andExpect(jsonPath("$.messages[0].attachments", hasSize(2)))
        .andExpect(jsonPath("$.messages[1].attachments", hasSize(1)));
  }

  @Test
  void mediaReplySnippetAndDeleteHideAttachmentsAndReactions() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());

    String mediaId =
        firstMessageId(
            mockMvc
                .perform(
                    multipart("/api/v1/chat/messages/media")
                        .file(
                            new MockMultipartFile(
                                "files", "one.jpg", "image/jpeg", "one".getBytes()))
                        .file(
                            new MockMultipartFile(
                                "files", "two.jpg", "image/jpeg", "two".getBytes()))
                        .with(currentUser("alice")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].attachments", hasSize(2)))
                .andReturn()
                .getResponse()
                .getContentAsString());

    send("bob", "{\"type\":\"TEXT\",\"body\":\"nice\",\"replyToMessageId\":\"" + mediaId + "\"}")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.reply.snippet").value("2 photos"));

    mockMvc
        .perform(
            post("/api/v1/chat/messages/{messageId}/reaction", mediaId)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"reaction\":\"🔥\"}")
                .with(currentUser("bob")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.reactions", hasSize(1)));

    mockMvc
        .perform(
            delete("/api/v1/chat/messages/{messageId}/everyone", mediaId)
                .with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.deletedForEveryone").value(true))
        .andExpect(jsonPath("$.attachments", hasSize(0)))
        .andExpect(jsonPath("$.reactions", hasSize(0)))
        .andExpect(jsonPath("$.viewerReaction").value(nullValue()));
  }

  @Test
  void editDeleteReactionReadTypingAndPresenceRulesAreEnforced() throws Exception {
    User alice = users.save(user("alice", "alice@example.com", "Alice"));
    User bob = users.save(user("bob", "bob@example.com", "Bob"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());

    String messageId =
        messageId(
            send("alice", "{\"type\":\"TEXT\",\"body\":\"draft\"}")
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString());
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

  private String messageId(String json) throws Exception {
    return objectMapper.readTree(json).get("id").asText();
  }

  private String firstMessageId(String json) throws Exception {
    JsonNode root = objectMapper.readTree(json);
    return root.get(0).get("id").asText();
  }

  @TestConfiguration
  static class StorageTestConfig {
    static final AtomicInteger uploadCounter = new AtomicInteger();

    @Bean
    @Primary
    ChatMediaStorageService chatMediaStorageService() {
      return new ChatMediaStorageService() {
        @Override
        public StoredChatMedia uploadChatMedia(
            UUID connectionId, UUID senderUserId, MultipartFile file) {
          int uploadNumber = uploadCounter.incrementAndGet();
          String contentType =
              file.getContentType() == null ? "application/octet-stream" : file.getContentType();
          return new StoredChatMedia(
              "https://cdn.example.com/chat-media-" + uploadNumber,
              "chat/uploaded-" + uploadNumber,
              contentType,
              file.getSize());
        }
      };
    }
  }
}
