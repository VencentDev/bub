package com.vencentdev.backend.modules.auth;

import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.core.MethodParameter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

@Component
public class CurrentUserArgumentResolver implements HandlerMethodArgumentResolver {

  @Override
  public boolean supportsParameter(MethodParameter parameter) {
    return parameter.hasParameterAnnotation(CurrentUser.class)
        && parameter.getParameterType().equals(AuthenticatedUser.class);
  }

  @Override
  public Object resolveArgument(
      MethodParameter parameter,
      ModelAndViewContainer mavContainer,
      NativeWebRequest webRequest,
      WebDataBinderFactory binderFactory) {
    var authentication = SecurityContextHolder.getContext().getAuthentication();
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
