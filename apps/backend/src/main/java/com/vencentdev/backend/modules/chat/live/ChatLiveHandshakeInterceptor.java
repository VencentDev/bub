package com.vencentdev.backend.modules.chat.live;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.user.service.UserService;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

@Component
public class ChatLiveHandshakeInterceptor implements HandshakeInterceptor {

  public static final String USER_ID_ATTRIBUTE = "chatLiveUserId";

  private final UserService userService;

  public ChatLiveHandshakeInterceptor(UserService userService) {
    this.userService = userService;
  }

  @Override
  public boolean beforeHandshake(
      ServerHttpRequest request,
      ServerHttpResponse response,
      WebSocketHandler wsHandler,
      Map<String, Object> attributes) {
    AuthenticatedUser user = currentUser();
    if (user == null) {
      return false;
    }
    UUID userId = userService.resolveInternalId(user);
    attributes.put(USER_ID_ATTRIBUTE, userId);
    return true;
  }

  @Override
  public void afterHandshake(
      ServerHttpRequest request,
      ServerHttpResponse response,
      WebSocketHandler wsHandler,
      Exception exception) {}

  private AuthenticatedUser currentUser() {
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    if (authentication != null && authentication.getPrincipal() instanceof AuthenticatedUser user) {
      return user;
    }
    if (!(authentication instanceof JwtAuthenticationToken token)) {
      return null;
    }
    Jwt jwt = token.getToken();
    Set<String> roles =
        token.getAuthorities().stream()
            .map(GrantedAuthority::getAuthority)
            .map(authority -> authority.startsWith("ROLE_") ? authority.substring(5) : authority)
            .collect(Collectors.toSet());
    return new AuthenticatedUser(
        jwt.getSubject(), jwt.getClaimAsString("email"), jwt.getClaimAsString("name"), roles);
  }
}
