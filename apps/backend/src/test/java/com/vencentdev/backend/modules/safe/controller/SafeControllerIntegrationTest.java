package com.vencentdev.backend.modules.safe.controller;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.vencentdev.backend.IntegrationTestBase;
import com.vencentdev.backend.modules.safe.repository.SafeVaultAccessRepository;
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
import org.springframework.test.web.servlet.MockMvc;

class SafeControllerIntegrationTest extends IntegrationTestBase {

  @Autowired private MockMvc mockMvc;
  @Autowired private SafeVaultAccessRepository safeAccess;
  @Autowired private TetherConnectionRepository connections;
  @Autowired private TetherInvitationRepository invitations;
  @Autowired private UserRepository users;

  @BeforeEach
  void setUp() {
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
