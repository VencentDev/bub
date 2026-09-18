package com.vencentdev.backend.modules.user.mapper;

import com.vencentdev.backend.modules.user.dto.UserResponse;
import com.vencentdev.backend.modules.user.dto.UserUpdateRequest;
import com.vencentdev.backend.modules.user.entity.User;
import java.time.Clock;
import java.time.Instant;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public abstract class UserMapper {

  public abstract UserResponse toResponse(User user);

  public void applyUpdate(UserUpdateRequest request, User target) {
    if (request.email() != null && request.email().isPresent()) {
      target.setEmail(request.email().get());
    }
    if (request.displayName() != null && request.displayName().isPresent()) {
      target.setDisplayName(request.displayName().get());
    }
    if (request.themeMode() != null && request.themeMode().isPresent()) {
      target.setThemeMode(request.themeMode().get());
    }
    if (request.language() != null && request.language().isPresent()) {
      target.setLanguage(request.language().get());
    }
    if (request.age() != null && request.age().isPresent()) {
      target.setAge(request.age().get());
    }
    if (request.discoveredAppVia() != null && request.discoveredAppVia().isPresent()) {
      target.setDiscoveredAppVia(request.discoveredAppVia().get());
    }
    if (request.relationshipStatus() != null && request.relationshipStatus().isPresent()) {
      target.setRelationshipStatus(request.relationshipStatus().get());
    }
    if (request.relationshipLength() != null && request.relationshipLength().isPresent()) {
      target.setRelationshipLength(request.relationshipLength().get());
    }
    if (request.termsAccepted() != null && request.termsAccepted().isPresent()) {
      Instant acceptedAt = acceptedAt(request.termsAccepted().get(), Clock.systemUTC());
      target.setTermsAcceptedAt(acceptedAt);
      if (acceptedAt != null && target.getProfileOnboardingCompletedAt() == null) {
        target.setProfileOnboardingCompletedAt(acceptedAt);
      }
    }
  }

  Instant acceptedAt(Boolean accepted, Clock clock) {
    return Boolean.TRUE.equals(accepted) ? Instant.now(clock) : null;
  }
}
