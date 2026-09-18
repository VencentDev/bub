package com.vencentdev.backend.modules.user.entity;

import com.vencentdev.backend.common.persistence.AuditableEntity;
import com.vencentdev.backend.modules.user.enums.KycStatus;
import com.vencentdev.backend.modules.user.enums.Role;
import com.vencentdev.backend.modules.user.enums.ThemeMode;
import com.vencentdev.backend.modules.user.enums.UserType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = false, onlyExplicitlyIncluded = true)
public class User extends AuditableEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.UUID)
  @EqualsAndHashCode.Include
  private UUID id;

  @Column(name = "external_id", nullable = false, unique = true)
  private String externalId;

  @Column(unique = true)
  private String email;

  @Column(name = "display_name", length = 120)
  private String displayName;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false)
  private Role role;

  @Enumerated(EnumType.STRING)
  @Column(name = "user_type", nullable = false)
  private UserType userType;

  @Enumerated(EnumType.STRING)
  @Column(name = "kyc_status", nullable = false)
  private KycStatus kycStatus;

  @Builder.Default
  @Enumerated(EnumType.STRING)
  @Column(name = "theme_mode", nullable = false)
  private ThemeMode themeMode = ThemeMode.SYSTEM;

  @Builder.Default
  @Column(nullable = false, length = 16)
  private String language = "en";

  @Column private Integer age;

  @Column(name = "discovered_app_via")
  private String discoveredAppVia;

  @Column(name = "relationship_status")
  private String relationshipStatus;

  @Column(name = "relationship_length")
  private String relationshipLength;

  @Column(name = "terms_accepted_at")
  private Instant termsAcceptedAt;

  @Column(name = "profile_onboarding_completed_at")
  private Instant profileOnboardingCompletedAt;

  public boolean isProfileOnboardingComplete() {
    return profileOnboardingCompletedAt != null;
  }
}
