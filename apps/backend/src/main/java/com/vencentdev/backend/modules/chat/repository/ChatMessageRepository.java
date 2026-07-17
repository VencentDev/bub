package com.vencentdev.backend.modules.chat.repository;

import com.vencentdev.backend.modules.chat.entity.ChatMessage;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, UUID> {

  @Query(
      """
      select message
      from ChatMessage message
      join fetch message.senderUser
      join fetch message.tetherConnection connection
      join fetch connection.userOne
      join fetch connection.userTwo
      left join fetch message.replyToMessage reply
      left join fetch reply.senderUser
      where connection.id = :connectionId
        and not exists (
          select deletion.id
          from ChatMessageDeletion deletion
          where deletion.message.id = message.id
            and deletion.user.id = :viewerId
        )
      order by message.createdAt asc, message.id asc
      """)
  List<ChatMessage> findThreadMessages(
      @Param("connectionId") UUID connectionId, @Param("viewerId") UUID viewerId);

  @Query(
      """
      select message
      from ChatMessage message
      join fetch message.senderUser
      join fetch message.tetherConnection connection
      join fetch connection.userOne
      join fetch connection.userTwo
      left join fetch message.replyToMessage reply
      left join fetch reply.senderUser
      where message.id = :messageId
      """)
  Optional<ChatMessage> findByIdWithGraph(@Param("messageId") UUID messageId);

  @Query(
      """
      select message
      from ChatMessage message
      join fetch message.senderUser
      where message.tetherConnection.id = :connectionId
        and message.createdAt <= :createdAt
        and message.senderUser.id <> :viewerId
      """)
  List<ChatMessage> findPartnerMessagesUpTo(
      @Param("connectionId") UUID connectionId,
      @Param("viewerId") UUID viewerId,
      @Param("createdAt") Instant createdAt);
}
