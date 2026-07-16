package com.vencentdev.backend.config;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import java.util.Optional;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.AuditorAware;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;

@Configuration
@EnableJpaAuditing
public class JpaAuditingConfig {

  @Bean
  AuditorAware<String> auditorAware() {
    return () -> {
      Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
      if (authentication == null || !authentication.isAuthenticated()) {
        return Optional.of("system");
      }
      Object principal = authentication.getPrincipal();
      if (principal instanceof AuthenticatedUser user) {
        return Optional.of(user.subject());
      }
      if (principal instanceof Jwt jwt) {
        return Optional.ofNullable(jwt.getSubject()).or(() -> Optional.of("system"));
      }
      return Optional.ofNullable(authentication.getName()).or(() -> Optional.of("system"));
    };
  }
}
