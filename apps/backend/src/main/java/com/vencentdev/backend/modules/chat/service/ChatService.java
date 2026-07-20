package com.vencentdev.backend.modules.chat.service;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.chat.dto.ChatEditMessageRequest;
import com.vencentdev.backend.modules.chat.dto.ChatMessageResponse;
import com.vencentdev.backend.modules.chat.dto.ChatPartnerNicknameRequest;
import com.vencentdev.backend.modules.chat.dto.ChatReactionRequest;
import com.vencentdev.backend.modules.chat.dto.ChatReadRequest;
import com.vencentdev.backend.modules.chat.dto.ChatSendMessageRequest;
import com.vencentdev.backend.modules.chat.dto.ChatStateResponse;
import com.vencentdev.backend.modules.chat.dto.ChatThreadResponse;
import com.vencentdev.backend.modules.chat.dto.ChatTypingRequest;
import java.util.List;
import java.util.UUID;
import org.springframework.web.multipart.MultipartFile;

public interface ChatService {
  ChatThreadResponse thread(AuthenticatedUser principal);

  ChatMessageResponse send(AuthenticatedUser principal, ChatSendMessageRequest request);

  List<ChatMessageResponse> uploadMedia(
      AuthenticatedUser principal, List<MultipartFile> files, UUID replyToMessageId);

  ChatMessageResponse edit(
      AuthenticatedUser principal, UUID messageId, ChatEditMessageRequest request);

  void deleteForMe(AuthenticatedUser principal, UUID messageId);

  ChatMessageResponse deleteForEveryone(AuthenticatedUser principal, UUID messageId);

  ChatMessageResponse react(
      AuthenticatedUser principal, UUID messageId, ChatReactionRequest request);

  ChatMessageResponse removeReaction(AuthenticatedUser principal, UUID messageId);

  ChatThreadResponse updatePartnerNickname(
      AuthenticatedUser principal, ChatPartnerNicknameRequest request);

  ChatStateResponse markRead(AuthenticatedUser principal, ChatReadRequest request);

  ChatStateResponse setTyping(AuthenticatedUser principal, ChatTypingRequest request);

  ChatStateResponse state(AuthenticatedUser principal);
}
