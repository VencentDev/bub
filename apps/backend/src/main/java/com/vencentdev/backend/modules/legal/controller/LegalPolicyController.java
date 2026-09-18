package com.vencentdev.backend.modules.legal.controller;

import com.vencentdev.backend.modules.legal.dto.LegalPolicyResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpStatus;
import org.springframework.util.StreamUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/legal/policies")
public class LegalPolicyController {

  private static final String VERSION = "2026-07-22";
  private static final LocalDate EFFECTIVE_DATE = LocalDate.parse(VERSION);
  private static final List<PolicyDefinition> POLICIES =
      List.of(
          new PolicyDefinition("terms-of-service", "Terms of Service", "legal/terms-of-service.md"),
          new PolicyDefinition("privacy-policy", "Privacy Policy", "legal/privacy-policy.md"),
          new PolicyDefinition("cookies-policy", "Cookies Policy", "legal/cookies-policy.md"));

  @GetMapping
  public List<LegalPolicyResponse> policies() {
    return POLICIES.stream().map(this::response).toList();
  }

  @GetMapping("/{slug}")
  public LegalPolicyResponse policy(@PathVariable String slug) {
    return POLICIES.stream()
        .filter(policy -> policy.slug().equals(slug))
        .findFirst()
        .map(this::response)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Policy not found"));
  }

  private LegalPolicyResponse response(PolicyDefinition policy) {
    return new LegalPolicyResponse(
        policy.slug(), policy.title(), VERSION, EFFECTIVE_DATE, readBody(policy.resourcePath()));
  }

  private String readBody(String resourcePath) {
    try {
      return StreamUtils.copyToString(
          new ClassPathResource(resourcePath).getInputStream(), StandardCharsets.UTF_8);
    } catch (IOException exception) {
      throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Policy unavailable");
    }
  }

  private record PolicyDefinition(String slug, String title, String resourcePath) {}
}
