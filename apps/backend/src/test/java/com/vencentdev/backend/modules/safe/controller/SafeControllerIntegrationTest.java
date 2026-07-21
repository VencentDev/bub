package com.vencentdev.backend.modules.safe.controller;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vencentdev.backend.IntegrationTestBase;
import com.vencentdev.backend.modules.chat.repository.ChatMessageRepository;
import com.vencentdev.backend.modules.safe.repository.SafeMediaItemRepository;
import com.vencentdev.backend.modules.safe.repository.SafeVaultAccessRepository;
import com.vencentdev.backend.modules.safe.service.SafeMediaStorageService;
import com.vencentdev.backend.modules.safe.service.StoredSafeMedia;
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
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.multipart.MultipartFile;

class SafeControllerIntegrationTest extends IntegrationTestBase {

  @Autowired private MockMvc mockMvc;
  private final ObjectMapper objectMapper = new ObjectMapper();
  @Autowired private SafeVaultAccessRepository safeAccess;
  @Autowired private SafeMediaItemRepository safeMedia;
  @Autowired private ChatMessageRepository chatMessages;
  @Autowired private TetherConnectionRepository connections;
  @Autowired private TetherInvitationRepository invitations;
  @Autowired private UserRepository users;

  @BeforeEach
  void setUp() {
    chatMessages.deleteAll();
    safeMedia.deleteAll();
    safeAccess.deleteAll();
    connections.deleteAll();
    invitations.deleteAll();
    users.deleteAll();
  }

  @Test
  void statusForUntetheredUserReturnsUnavailableSafe() throws Exception {
    users.save(user("alice", "alice@example.com"));

    mockMvc
        .perform(get("/api/v1/safe/status").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.tethered").value(false))
        .andExpect(jsonPath("$.pinConfigured").value(false));
  }

  @Test
  void statusForTetheredUserWithoutPinReturnsPinNotConfigured() throws Exception {
    tetheredUsers();

    mockMvc
        .perform(get("/api/v1/safe/status").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.tethered").value(true))
        .andExpect(jsonPath("$.pinConfigured").value(false));
  }

  @Test
  void pinSetupStoresHashAndEnablesUnlock() throws Exception {
    tetheredUsers();

    mockMvc
        .perform(pinSetup("alice", "1234"))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.tethered").value(true))
        .andExpect(jsonPath("$.pinConfigured").value(true))
        .andExpect(jsonPath("$.pin").doesNotExist())
        .andExpect(jsonPath("$.pinHash").doesNotExist());

    var access = safeAccess.findAll().getFirst();
    org.assertj.core.api.Assertions.assertThat(access.getPinHash())
        .isNotEqualTo("1234")
        .startsWith("$2");

    mockMvc
        .perform(unlock("alice", "1234"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.unlocked").value(true))
        .andExpect(jsonPath("$.pin").doesNotExist())
        .andExpect(jsonPath("$.pinHash").doesNotExist());
  }

  @Test
  void duplicatePinSetupIsRejected() throws Exception {
    tetheredUsers();

    mockMvc.perform(pinSetup("alice", "1234")).andExpect(status().isCreated());

    mockMvc
        .perform(pinSetup("alice", "5678"))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.message", startsWith("Safe PIN already configured")));
  }

  @Test
  void partnersConfigureIndependentSafePins() throws Exception {
    tetheredUsers();

    mockMvc.perform(pinSetup("alice", "1234")).andExpect(status().isCreated());
    mockMvc.perform(pinSetup("bob", "9876")).andExpect(status().isCreated());

    mockMvc.perform(unlock("alice", "1234")).andExpect(status().isOk());
    mockMvc.perform(unlock("bob", "9876")).andExpect(status().isOk());

    mockMvc
        .perform(unlock("alice", "9876"))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.message").value("Invalid Safe PIN"));
    mockMvc
        .perform(unlock("bob", "1234"))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.message").value("Invalid Safe PIN"));
  }

  @Test
  void unlockRejectsIncorrectPin() throws Exception {
    tetheredUsers();
    mockMvc.perform(pinSetup("alice", "1234")).andExpect(status().isCreated());

    mockMvc
        .perform(unlock("alice", "9999"))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.message").value("Invalid Safe PIN"));
  }

  @Test
  void malformedPinIsRejected() throws Exception {
    tetheredUsers();

    mockMvc
        .perform(pinSetup("alice", "12ab"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.errors[0].field", not("")))
        .andExpect(jsonPath("$.pin").doesNotExist())
        .andExpect(jsonPath("$.pinHash").doesNotExist());
  }

  @Test
  void setupRequiresActiveTether() throws Exception {
    users.save(user("alice", "alice@example.com"));

    mockMvc
        .perform(pinSetup("alice", "1234"))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.message").value("Safe requires an active tether"));
  }

  @Test
  void uploadRequiresCorrectSafePin() throws Exception {
    tetheredUsers();
    mockMvc.perform(pinSetup("alice", "1234")).andExpect(status().isCreated());

    MockMultipartFile photo =
        new MockMultipartFile("files", "safe.jpg", MediaType.IMAGE_JPEG_VALUE, "photo".getBytes());

    mockMvc
        .perform(
            multipart("/api/v1/safe/media")
                .file(photo)
                .header("X-Bub-Safe-Pin", "9999")
                .with(currentUser("alice")))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.message").value("Invalid Safe PIN"));
  }

  @Test
  void uploadStoresSafeMediaAndCreatesPrivateChatNotice() throws Exception {
    tetheredUsers();
    mockMvc.perform(pinSetup("alice", "1234")).andExpect(status().isCreated());

    MockMultipartFile photo =
        new MockMultipartFile("files", "safe.jpg", MediaType.IMAGE_JPEG_VALUE, "photo".getBytes());
    MockMultipartFile video =
        new MockMultipartFile("files", "safe.mp4", "video/mp4", "video".getBytes());

    mockMvc
        .perform(
            multipart("/api/v1/safe/media")
                .file(photo)
                .file(video)
                .header("X-Bub-Safe-Pin", "1234")
                .with(currentUser("alice")))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.items.length()").value(2))
        .andExpect(jsonPath("$.items[0].type").value("IMAGE"))
        .andExpect(jsonPath("$.items[1].type").value("VIDEO"))
        .andExpect(jsonPath("$.chatNotice.type").value("SAFE_NOTICE"))
        .andExpect(jsonPath("$.chatNotice.safeItemCount").value(2));

    mockMvc
        .perform(get("/api/v1/chat/thread").with(currentUser("bob")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.messages[0].type").value("SAFE_NOTICE"))
        .andExpect(jsonPath("$.messages[0].safeItemCount").value(2))
        .andExpect(jsonPath("$.messages[0].attachments.length()").value(0));
  }

  @Test
  void galleryListsRecentFirstAndExcludesDeletedItems() throws Exception {
    tetheredUsers();
    mockMvc.perform(pinSetup("alice", "1234")).andExpect(status().isCreated());
    mockMvc.perform(pinSetup("bob", "1234")).andExpect(status().isCreated());
    String firstId =
        firstUploadedItemId(
            uploadFile("alice", "1234", "one.jpg", MediaType.IMAGE_JPEG_VALUE, "one")
                .andReturn()
                .getResponse()
                .getContentAsString());
    String secondId =
        firstUploadedItemId(
            uploadFile("alice", "1234", "two.jpg", MediaType.IMAGE_JPEG_VALUE, "two")
                .andReturn()
                .getResponse()
                .getContentAsString());

    mockMvc
        .perform(
            get("/api/v1/safe/media").header("X-Bub-Safe-Pin", "1234").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.items[0].id").value(secondId))
        .andExpect(jsonPath("$.items[1].id").value(firstId));

    mockMvc
        .perform(
            delete("/api/v1/safe/media/{id}", secondId)
                .header("X-Bub-Safe-Pin", "1234")
                .with(currentUser("bob")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.deleted").value(true));

    mockMvc
        .perform(
            get("/api/v1/safe/media").header("X-Bub-Safe-Pin", "1234").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.items.length()").value(1))
        .andExpect(jsonPath("$.items[0].id").value(firstId));
  }

  private void tetheredUsers() {
    User alice = users.save(user("alice", "alice@example.com"));
    User bob = users.save(user("bob", "bob@example.com"));
    connections.save(TetherConnection.builder().userOne(alice).userTwo(bob).active(true).build());
  }

  private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder pinSetup(
      String subject, String pin) {
    return post("/api/v1/safe/pin")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"pin\":\"" + pin + "\"}")
        .with(currentUser(subject));
  }

  private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder unlock(
      String subject, String pin) {
    return post("/api/v1/safe/unlock")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"pin\":\"" + pin + "\"}")
        .with(currentUser(subject));
  }

  private org.springframework.test.web.servlet.ResultActions uploadFile(
      String subject, String pin, String filename, String contentType, String body)
      throws Exception {
    MockMultipartFile file = new MockMultipartFile("files", filename, contentType, body.getBytes());
    return mockMvc.perform(
        multipart("/api/v1/safe/media")
            .file(file)
            .header("X-Bub-Safe-Pin", pin)
            .with(currentUser(subject)));
  }

  private String firstUploadedItemId(String responseBody) throws Exception {
    return objectMapper.readTree(responseBody).path("items").get(0).path("id").asText();
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

  @TestConfiguration
  static class SafeTestConfig {

    @Bean
    @Primary
    SafeMediaStorageService safeMediaStorageService() {
      return new SafeMediaStorageService() {
        @Override
        public StoredSafeMedia uploadSafeMedia(
            java.util.UUID connectionId, java.util.UUID uploaderUserId, MultipartFile file) {
          String filename =
              file.getOriginalFilename() == null ? "file" : file.getOriginalFilename();
          return new StoredSafeMedia(
              "https://cdn.example.com/safe/" + filename,
              "safe/" + connectionId + "/" + uploaderUserId + "/" + filename,
              file.getContentType(),
              file.getSize());
        }

        @Override
        public void deleteSafeMedia(String storageObjectPath) {}
      };
    }
  }
}
