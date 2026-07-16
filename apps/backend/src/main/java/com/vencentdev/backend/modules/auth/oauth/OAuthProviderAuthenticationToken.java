package com.vencentdev.backend.modules.auth.oauth;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import java.util.List;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

public class OAuthProviderAuthenticationToken extends AbstractAuthenticationToken {

  private final AuthenticatedUser principal;
  private final String credentials;

  public OAuthProviderAuthenticationToken(AuthenticatedUser principal, String credentials) {
    super(List.of(new SimpleGrantedAuthority("ROLE_USER")));
    this.principal = principal;
    this.credentials = credentials;
    setAuthenticated(true);
  }

  @Override
  public String getCredentials() {
    return credentials;
  }

  @Override
  public AuthenticatedUser getPrincipal() {
    return principal;
  }

  @Override
  public String getName() {
    return principal.subject();
  }
}
