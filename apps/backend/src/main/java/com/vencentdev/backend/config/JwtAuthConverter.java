package com.vencentdev.backend.config;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

@Component
public class JwtAuthConverter implements Converter<Jwt, AbstractAuthenticationToken> {

  @Override
  public AbstractAuthenticationToken convert(Jwt jwt) {
    Map<String, Object> realmAccess = jwt.getClaim("realm_access");
    Collection<GrantedAuthority> authorities =
        realmAccess == null ? List.of() : authoritiesFromRealmAccess(realmAccess);
    return new JwtAuthenticationToken(jwt, authorities, jwt.getSubject());
  }

  private Collection<GrantedAuthority> authoritiesFromRealmAccess(Map<String, Object> realmAccess) {
    Object rolesClaim = realmAccess.getOrDefault("roles", List.of());
    if (!(rolesClaim instanceof Collection<?> roles)) {
      return List.of();
    }

    return roles.stream()
        .filter(String.class::isInstance)
        .map(String.class::cast)
        .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
        .map(GrantedAuthority.class::cast)
        .toList();
  }
}
