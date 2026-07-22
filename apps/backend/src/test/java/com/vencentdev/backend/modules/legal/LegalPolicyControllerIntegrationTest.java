package com.vencentdev.backend.modules.legal;

import static org.hamcrest.Matchers.blankOrNullString;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.not;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.vencentdev.backend.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

class LegalPolicyControllerIntegrationTest extends IntegrationTestBase {

  @Autowired MockMvc mockMvc;

  @Test
  void policiesListsAllCurrentPolicies() throws Exception {
    mockMvc
        .perform(get("/api/v1/legal/policies").with(currentUser("alice")))
        .andExpect(status().isOk())
        .andExpect(
            jsonPath("$[*].slug")
                .value(containsInAnyOrder("terms-of-service", "privacy-policy", "cookies-policy")));
  }

  @Test
  void policyDetailsReturnVersionMetadataAndBody() throws Exception {
    for (String slug : new String[] {"terms-of-service", "privacy-policy", "cookies-policy"}) {
      mockMvc
          .perform(get("/api/v1/legal/policies/{slug}", slug).with(currentUser("alice")))
          .andExpect(status().isOk())
          .andExpect(jsonPath("$.slug").value(slug))
          .andExpect(jsonPath("$.title").value(not(blankOrNullString())))
          .andExpect(jsonPath("$.version").value("2026-07-22"))
          .andExpect(jsonPath("$.effectiveDate").value("2026-07-22"))
          .andExpect(jsonPath("$.body").value(not(blankOrNullString())));
    }
  }

  private static RequestPostProcessor currentUser(String subject) {
    return jwt()
        .jwt(
            jwt ->
                jwt.subject(subject)
                    .claim("email", subject + "@example.com")
                    .claim("name", subject));
  }
}
