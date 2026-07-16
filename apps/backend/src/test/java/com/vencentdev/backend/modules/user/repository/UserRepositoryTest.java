package com.vencentdev.backend.modules.user.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.vencentdev.backend.IntegrationTestBase;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.enums.KycStatus;
import com.vencentdev.backend.modules.user.enums.Role;
import com.vencentdev.backend.modules.user.enums.UserType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class UserRepositoryTest extends IntegrationTestBase {

  @Autowired private UserRepository repository;

  @BeforeEach
  void setUp() {
    repository.deleteAll();
  }

  @Test
  void findByExternalIdReturnsUser() {
    User user = repository.save(user("external-1", "user@example.com"));

    assertThat(repository.findByExternalId("external-1")).contains(user);
  }

  @Test
  void existsByEmailReturnsTrueForStoredEmail() {
    repository.save(user("external-2", "duplicate@example.com"));

    assertThat(repository.existsByEmail("duplicate@example.com")).isTrue();
    assertThat(repository.existsByEmail("missing@example.com")).isFalse();
  }

  private User user(String externalId, String email) {
    return User.builder()
        .externalId(externalId)
        .email(email)
        .displayName("User")
        .role(Role.USER)
        .userType(UserType.INDIVIDUAL)
        .kycStatus(KycStatus.NONE)
        .build();
  }
}
