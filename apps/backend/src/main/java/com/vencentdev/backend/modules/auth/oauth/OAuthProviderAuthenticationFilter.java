package com.vencentdev.backend.modules.auth.oauth;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class OAuthProviderAuthenticationFilter extends OncePerRequestFilter {

  private static final String BEARER_PREFIX = "Bearer ";

  private final OAuthProviderUserInfoClient userInfoClient;

  public OAuthProviderAuthenticationFilter(OAuthProviderUserInfoClient userInfoClient) {
    this.userInfoClient = userInfoClient;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    String accessToken = bearerToken(request);
    if (accessToken == null || SecurityContextHolder.getContext().getAuthentication() != null) {
      filterChain.doFilter(request, response);
      return;
    }

    AuthenticatedUser user = userInfoClient.resolve(accessToken);
    if (user == null) {
      response.sendError(HttpStatus.UNAUTHORIZED.value(), "Invalid OAuth access token");
      return;
    }

    SecurityContextHolder.getContext()
        .setAuthentication(new OAuthProviderAuthenticationToken(user, accessToken));
    filterChain.doFilter(request, response);
  }

  private String bearerToken(HttpServletRequest request) {
    String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);
    if (authorization == null || !authorization.startsWith(BEARER_PREFIX)) {
      return null;
    }

    String token = authorization.substring(BEARER_PREFIX.length()).trim();
    return token.isEmpty() ? null : token;
  }
}
