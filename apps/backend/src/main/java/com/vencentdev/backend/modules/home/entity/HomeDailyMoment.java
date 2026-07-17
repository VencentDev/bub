package com.vencentdev.backend.modules.home.entity;

import com.vencentdev.backend.common.persistence.AuditableEntity;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.user.entity.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "home_daily_moments",
    uniqueConstraints =
        @UniqueConstraint(
            name = "uq_home_daily_moments_tether_user_date",
            columnNames = {"tether_connection_id", "created_by_user_id", "local_date"}))
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = false, onlyExplicitlyIncluded = true)
public class HomeDailyMoment extends AuditableEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.UUID)
  @EqualsAndHashCode.Include
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "tether_connection_id", nullable = false)
  private TetherConnection tetherConnection;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "created_by_user_id", nullable = false)
  private User createdByUser;

  @Column(name = "local_date", nullable = false)
  private LocalDate localDate;

  @Column(name = "photo_url", nullable = false, columnDefinition = "text")
  private String photoUrl;

  @Column(name = "storage_object_path", columnDefinition = "text")
  private String storageObjectPath;

  @Column(name = "expires_at", nullable = false)
  private Instant expiresAt;

  @Column(name = "partner_reaction", length = 16)
  private String partnerReaction;
}
