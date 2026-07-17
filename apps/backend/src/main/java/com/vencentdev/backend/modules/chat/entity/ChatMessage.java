package com.vencentdev.backend.modules.chat.entity;

import com.vencentdev.backend.common.persistence.AuditableEntity;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.user.entity.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
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
@Table(name = "chat_messages")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = false, onlyExplicitlyIncluded = true)
public class ChatMessage extends AuditableEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.UUID)
  @EqualsAndHashCode.Include
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "tether_connection_id", nullable = false)
  private TetherConnection tetherConnection;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "sender_user_id", nullable = false)
  private User senderUser;

  @Enumerated(EnumType.STRING)
  @Column(name = "message_type", nullable = false, length = 16)
  private ChatMessageType type;

  @Column(columnDefinition = "TEXT")
  private String body;

  @Column(name = "gif_url", columnDefinition = "TEXT")
  private String gifUrl;

  @Column(name = "gif_provider_id")
  private String gifProviderId;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "reply_to_message_id")
  private ChatMessage replyToMessage;

  @Column(name = "edited_at")
  private Instant editedAt;

  @Column(name = "deleted_for_everyone_at")
  private Instant deletedForEveryoneAt;

  @Column(name = "delivered_at", nullable = false)
  private Instant deliveredAt;
}
