package com.vencentdev.backend.modules.auth.ratelimit;

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
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

@TestPropertySource(
    properties = {"app.rate-limit.auth.capacity=2", "app.rate-limit.auth.refill-period=1m"})
class AuthRateLimitIntegrationTest extends IntegrationTestBase {

  @Autowired private MockMvc mockMvc;
  @Autowired private UserRepository repository;

  @Test
  void authMeReturnsTooManyRequestsAfterConfiguredLimit() throws Exception {
    mockMvc
        .perform(get("/api/v1/auth/me").with(currentUser("limited-auth")))
        .andExpect(status().isOk());
    mockMvc
        .perform(get("/api/v1/auth/me").with(currentUser("limited-auth")))
        .andExpect(status().isOk());

    mockMvc
        .perform(get("/api/v1/auth/me").with(currentUser("limited-auth")))
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.code").value("RATE_LIMITED"));
  }

  @Test
  void userPatchLimitIsIsolatedBySubject() throws Exception {
    repository.save(user("limited-user-1"));
    repository.save(user("limited-user-2"));

    mockMvc.perform(patchMe("limited-user-1")).andExpect(status().isOk());
    mockMvc.perform(patchMe("limited-user-1")).andExpect(status().isOk());
    mockMvc.perform(patchMe("limited-user-1")).andExpect(status().isTooManyRequests());

    mockMvc.perform(patchMe("limited-user-2")).andExpect(status().isOk());
  }

  private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder patchMe(
      String subject) {
    return patch("/api/v1/users/me")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{}")
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

  private User user(String externalId) {
    return User.builder()
        .externalId(externalId)
        .email(externalId + "@example.com")
        .displayName(externalId)
        .role(Role.USER)
        .userType(UserType.INDIVIDUAL)
        .kycStatus(KycStatus.NONE)
        .build();
  }
}
