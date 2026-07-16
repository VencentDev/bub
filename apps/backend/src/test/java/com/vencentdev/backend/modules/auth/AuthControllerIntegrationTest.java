package com.vencentdev.backend.modules.auth;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.vencentdev.backend.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

class AuthControllerIntegrationTest extends IntegrationTestBase {

  @Autowired private MockMvc mockMvc;

  @Test
  void meRejectsUnauthenticatedRequests() throws Exception {
    mockMvc.perform(get("/api/v1/auth/me")).andExpect(status().isUnauthorized());
  }

  @Test
  void meReturnsCurrentUserFromJwt() throws Exception {
    mockMvc
        .perform(
            get("/api/v1/auth/me")
                .with(jwt().jwt(token -> token.subject("user-1").claim("email", "u@example.com"))))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.email").value("u@example.com"));
  }

  @Test
  void adminEndpointRejectsUserRole() throws Exception {
    mockMvc
        .perform(
            get("/api/v1/admin/ping")
                .with(
                    jwt()
                        .jwt(token -> token.subject("user-1").claim("email", "u@example.com"))
                        .authorities(() -> "ROLE_USER")))
        .andExpect(status().isForbidden());
  }

  @Test
  void adminEndpointAcceptsAdminRole() throws Exception {
    mockMvc
        .perform(
            get("/api/v1/admin/ping")
                .with(
                    jwt()
                        .jwt(token -> token.subject("admin-1").claim("email", "a@example.com"))
                        .authorities(() -> "ROLE_ADMIN")))
        .andExpect(status().isOk())
        .andExpect(content().string("ok"));
  }
}
