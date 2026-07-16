package com.vencentdev.backend.modules.user.controller;

import static org.hamcrest.Matchers.nullValue;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.vencentdev.backend.IntegrationTestBase;
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

class UserControllerIntegrationTest extends IntegrationTestBase {

  @Autowired private MockMvc mockMvc;
  @Autowired private UserRepository repository;

  @BeforeEach
  void setUp() {
    repository.deleteAll();
  }

  @Test
  void meReturnsCurrentPersistedUser() throws Exception {
    repository.save(user("subject-1", "old@example.com", "Old Name"));

    mockMvc
        .perform(get("/api/v1/users/me").with(currentUser("subject-1")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.email").value("old@example.com"))
        .andExpect(jsonPath("$.displayName").value("Old Name"));
  }

  @Test
  void patchWithEmptyObjectLeavesFieldsUntouched() throws Exception {
    repository.save(user("subject-2", "old@example.com", "Old Name"));

    mockMvc
        .perform(patchMe("subject-2", "{}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.email").value("old@example.com"))
        .andExpect(jsonPath("$.displayName").value("Old Name"));
  }

  @Test
  void patchWithNullEmailClearsEmail() throws Exception {
    repository.save(user("subject-3", "old@example.com", "Old Name"));

    mockMvc
        .perform(patchMe("subject-3", "{\"email\":null}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.email").value(nullValue()))
        .andExpect(jsonPath("$.displayName").value("Old Name"));
  }

  @Test
  void patchWithEmailValueUpdatesEmail() throws Exception {
    repository.save(user("subject-4", "old@example.com", "Old Name"));

    mockMvc
        .perform(patchMe("subject-4", "{\"email\":\"new@example.com\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.email").value("new@example.com"))
        .andExpect(jsonPath("$.displayName").value("Old Name"));
  }

  @Test
  void patchWithMissingDisplayNameLeavesDisplayNameUntouched() throws Exception {
    repository.save(user("subject-5", "old@example.com", "Old Name"));

    mockMvc
        .perform(patchMe("subject-5", "{\"email\":\"new@example.com\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.email").value("new@example.com"))
        .andExpect(jsonPath("$.displayName").value("Old Name"));
  }

  @Test
  void patchWithNullDisplayNameClearsDisplayName() throws Exception {
    repository.save(user("subject-6", "old@example.com", "Old Name"));

    mockMvc
        .perform(patchMe("subject-6", "{\"displayName\":null}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.email").value("old@example.com"))
        .andExpect(jsonPath("$.displayName").value(nullValue()));
  }

  private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder patchMe(
      String subject, String body) {
    return patch("/api/v1/users/me")
        .contentType(MediaType.APPLICATION_JSON)
        .content(body)
        .with(currentUser(subject));
  }

  private org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors
          .JwtRequestPostProcessor
      currentUser(String subject) {
    return jwt()
        .jwt(
            token ->
                token.subject(subject).claim("email", "jwt@example.com").claim("name", "JWT User"))
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
