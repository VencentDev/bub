package com.vencentdev.backend.modules.user.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.user.dto.UserUpdateRequest;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.enums.KycStatus;
import com.vencentdev.backend.modules.user.enums.Role;
import com.vencentdev.backend.modules.user.enums.UserType;
import com.vencentdev.backend.modules.user.mapper.UserMapperImpl;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.openapitools.jackson.nullable.JsonNullable;

class UserServiceTest {

  private final UserRepository repository = Mockito.mock(UserRepository.class);
  private final UserService service = new UserServiceImpl(repository, new UserMapperImpl());

  @Test
  void findOrProvisionInsertsOnceAndReturnsExistingAfterward() {
    AuthenticatedUser principal =
        new AuthenticatedUser("subject-1", "user@example.com", "Example User", Set.of("USER"));
    User stored = user("subject-1", "user@example.com", "Example User");
    stored.setId(UUID.randomUUID());
    when(repository.findByExternalId("subject-1"))
        .thenReturn(Optional.empty(), Optional.of(stored));
    when(repository.save(any(User.class)))
        .thenAnswer(
            invocation -> {
              User user = invocation.getArgument(0);
              user.setId(stored.getId());
              return user;
            });

    var first = service.findOrProvision(principal);
    var second = service.findOrProvision(principal);

    assertThat(first.email()).isEqualTo("user@example.com");
    assertThat(first.displayName()).isEqualTo("Example User");
    assertThat(second.id()).isEqualTo(first.id());
    verify(repository).save(any(User.class));
  }

  @Test
  void updateMeAppliesOnlyPresentFields() {
    AuthenticatedUser principal =
        new AuthenticatedUser("subject-2", "user@example.com", "Example User", Set.of("USER"));
    User stored = user("subject-2", "old@example.com", "Old Name");
    when(repository.findByExternalId("subject-2")).thenReturn(Optional.of(stored));

    var response =
        service.updateMe(
            principal,
            new UserUpdateRequest(JsonNullable.of("new@example.com"), JsonNullable.undefined()));

    assertThat(response.email()).isEqualTo("new@example.com");
    assertThat(response.displayName()).isEqualTo("Old Name");
    verify(repository, never()).save(any(User.class));
  }

  private User user(String externalId, String email, String displayName) {
    return User.builder()
        .externalId(externalId)
        .email(email)
        .displayName(displayName)
        .role(Role.USER)
        .userType(UserType.INDIVIDUAL)
        .kycStatus(KycStatus.NONE)
        .build();
  }
}
