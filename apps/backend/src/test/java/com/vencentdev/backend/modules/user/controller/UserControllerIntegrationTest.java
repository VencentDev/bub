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
        .andExpect(jsonPath("$.displayName").value("Old Name"))
        .andExpect(jsonPath("$.themeMode").value("system"))
        .andExpect(jsonPath("$.language").value("en"))
        .andExpect(jsonPath("$.age").value(nullValue()))
        .andExpect(jsonPath("$.discoveredAppVia").value(nullValue()))
        .andExpect(jsonPath("$.relationshipStatus").value(nullValue()))
        .andExpect(jsonPath("$.relationshipLength").value(nullValue()))
        .andExpect(jsonPath("$.termsAcceptedAt").value(nullValue()))
        .andExpect(jsonPath("$.profileOnboardingComplete").value(false));
  }

  @Test
  void existingUsersWithCompletedOnboardingSkipProfileStepper() throws Exception {
    User existing = user("subject-16", "old@example.com", "Old Name");
    existing.setProfileOnboardingCompletedAt(java.time.Instant.parse("2026-01-01T00:00:00Z"));
    repository.save(existing);

    mockMvc
        .perform(get("/api/v1/users/me").with(currentUser("subject-16")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.profileOnboardingComplete").value(true));
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

  @Test
  void patchWithPreferencesUpdatesThemeAndLanguage() throws Exception {
    repository.save(user("subject-7", "old@example.com", "Old Name"));

    mockMvc
        .perform(patchMe("subject-7", "{\"themeMode\":\"dark\",\"language\":\"en\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.email").value("old@example.com"))
        .andExpect(jsonPath("$.displayName").value("Old Name"))
        .andExpect(jsonPath("$.themeMode").value("dark"))
        .andExpect(jsonPath("$.language").value("en"));
  }

  @Test
  void patchWithProfileOnboardingFieldsCompletesProfile() throws Exception {
    repository.save(user("subject-10", "old@example.com", "Old Name"));

    mockMvc
        .perform(
            patchMe(
                "subject-10",
                """
                {
                  "displayName":"Alice Reyes",
                  "age":24,
                  "discoveredAppVia":"tiktok",
                  "relationshipStatus":"dating",
                  "relationshipLength":"1_to_3_years",
                  "termsAccepted":true
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.displayName").value("Alice Reyes"))
        .andExpect(jsonPath("$.age").value(24))
        .andExpect(jsonPath("$.discoveredAppVia").value("tiktok"))
        .andExpect(jsonPath("$.relationshipStatus").value("dating"))
        .andExpect(jsonPath("$.relationshipLength").value("1_to_3_years"))
        .andExpect(jsonPath("$.termsAcceptedAt").exists())
        .andExpect(jsonPath("$.profileOnboardingComplete").value(true));
  }

  @Test
  void patchWithUnderageProfileOnboardingReturnsBadRequest() throws Exception {
    repository.save(user("subject-11", "old@example.com", "Old Name"));

    mockMvc
        .perform(patchMe("subject-11", "{\"age\":12,\"termsAccepted\":true}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void patchWithInvalidDiscoveredAppViaReturnsBadRequest() throws Exception {
    repository.save(user("subject-12", "old@example.com", "Old Name"));

    mockMvc
        .perform(patchMe("subject-12", "{\"discoveredAppVia\":\"poster\"}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void patchWithInvalidRelationshipStatusReturnsBadRequest() throws Exception {
    repository.save(user("subject-14", "old@example.com", "Old Name"));

    mockMvc
        .perform(patchMe("subject-14", "{\"relationshipStatus\":\"complicated\"}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void patchWithInvalidRelationshipLengthReturnsBadRequest() throws Exception {
    repository.save(user("subject-15", "old@example.com", "Old Name"));

    mockMvc
        .perform(patchMe("subject-15", "{\"relationshipLength\":\"forever\"}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void patchWithRejectedTermsReturnsBadRequest() throws Exception {
    repository.save(user("subject-13", "old@example.com", "Old Name"));

    mockMvc
        .perform(patchMe("subject-13", "{\"termsAccepted\":false}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void patchWithInvalidThemeReturnsBadRequest() throws Exception {
    repository.save(user("subject-8", "old@example.com", "Old Name"));

    mockMvc
        .perform(patchMe("subject-8", "{\"themeMode\":\"midnight\"}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void patchWithInvalidLanguageReturnsBadRequest() throws Exception {
    repository.save(user("subject-9", "old@example.com", "Old Name"));

    mockMvc
        .perform(patchMe("subject-9", "{\"language\":\"tl\"}"))
        .andExpect(status().isBadRequest());
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
