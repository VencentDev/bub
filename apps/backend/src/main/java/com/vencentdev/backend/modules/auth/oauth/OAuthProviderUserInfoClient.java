package com.vencentdev.backend.modules.auth.oauth;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import java.util.Arrays;
import java.util.Set;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class OAuthProviderUserInfoClient {

  private final RestClient restClient;

  public OAuthProviderUserInfoClient() {
    this.restClient = RestClient.create();
  }

  public AuthenticatedUser resolve(String accessToken) {
    AuthenticatedUser googleUser = resolveGoogle(accessToken);
    if (googleUser != null) {
      return googleUser;
    }

    return resolveGitHub(accessToken);
  }

  private AuthenticatedUser resolveGoogle(String accessToken) {
    try {
      GoogleUserInfo userInfo =
          restClient
              .get()
              .uri("https://www.googleapis.com/oauth2/v3/userinfo")
              .header(HttpHeaders.AUTHORIZATION, bearer(accessToken))
              .retrieve()
              .onStatus(HttpStatusCode::isError, (request, response) -> {})
              .body(GoogleUserInfo.class);

      if (userInfo == null || userInfo.sub() == null || userInfo.sub().isBlank()) {
        return null;
      }

      return new AuthenticatedUser(
          "google:" + userInfo.sub(), userInfo.email(), userInfo.name(), Set.of("USER"));
    } catch (RestClientException ex) {
      return null;
    }
  }

  private AuthenticatedUser resolveGitHub(String accessToken) {
    try {
      GitHubUserInfo userInfo =
          restClient
              .get()
              .uri("https://api.github.com/user")
              .header(HttpHeaders.AUTHORIZATION, bearer(accessToken))
              .header(HttpHeaders.ACCEPT, "application/vnd.github+json")
              .retrieve()
              .onStatus(HttpStatusCode::isError, (request, response) -> {})
              .body(GitHubUserInfo.class);

      if (userInfo == null || userInfo.id() == null) {
        return null;
      }

      String email =
          userInfo.email() == null ? resolveGitHubPrimaryEmail(accessToken) : userInfo.email();
      String displayName =
          userInfo.name() == null || userInfo.name().isBlank() ? userInfo.login() : userInfo.name();

      return new AuthenticatedUser("github:" + userInfo.id(), email, displayName, Set.of("USER"));
    } catch (RestClientException ex) {
      return null;
    }
  }

  private String resolveGitHubPrimaryEmail(String accessToken) {
    try {
      GitHubEmail[] emails =
          restClient
              .get()
              .uri("https://api.github.com/user/emails")
              .header(HttpHeaders.AUTHORIZATION, bearer(accessToken))
              .header(HttpHeaders.ACCEPT, "application/vnd.github+json")
              .retrieve()
              .onStatus(HttpStatusCode::isError, (request, response) -> {})
              .body(GitHubEmail[].class);

      if (emails == null) {
        return null;
      }

      return Arrays.stream(emails)
          .filter(email -> email.primary() && email.verified())
          .map(GitHubEmail::email)
          .findFirst()
          .orElse(null);
    } catch (RestClientException ex) {
      return null;
    }
  }

  private String bearer(String accessToken) {
    return "Bearer " + accessToken;
  }

  @JsonIgnoreProperties(ignoreUnknown = true)
  private record GoogleUserInfo(String sub, String email, String name) {}

  @JsonIgnoreProperties(ignoreUnknown = true)
  private record GitHubUserInfo(Long id, String login, String name, String email) {}

  @JsonIgnoreProperties(ignoreUnknown = true)
  private record GitHubEmail(String email, boolean primary, boolean verified) {}
}
