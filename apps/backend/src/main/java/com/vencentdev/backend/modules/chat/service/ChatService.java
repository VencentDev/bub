package com.vencentdev.backend.modules.chat.service;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.chat.dto.ChatEditMessageRequest;
import com.vencentdev.backend.modules.chat.dto.ChatMessageResponse;
import com.vencentdev.backend.modules.chat.dto.ChatReactionRequest;
import com.vencentdev.backend.modules.chat.dto.ChatReadRequest;
import com.vencentdev.backend.modules.chat.dto.ChatSendMessageRequest;
import com.vencentdev.backend.modules.chat.dto.ChatStateResponse;
import com.vencentdev.backend.modules.chat.dto.ChatThreadResponse;
import com.vencentdev.backend.modules.chat.dto.ChatTypingRequest;
import java.util.UUID;

public interface ChatService {
  ChatThreadResponse thread(AuthenticatedUser principal);

  ChatMessageResponse send(AuthenticatedUser principal, ChatSendMessageRequest request);

  ChatMessageResponse edit(
      AuthenticatedUser principal, UUID messageId, ChatEditMessageRequest request);

  void deleteForMe(AuthenticatedUser principal, UUID messageId);

  ChatMessageResponse deleteForEveryone(AuthenticatedUser principal, UUID messageId);

  ChatMessageResponse react(
      AuthenticatedUser principal, UUID messageId, ChatReactionRequest request);

  ChatMessageResponse removeReaction(AuthenticatedUser principal, UUID messageId);

  ChatStateResponse markRead(AuthenticatedUser principal, ChatReadRequest request);

  ChatStateResponse setTyping(AuthenticatedUser principal, ChatTypingRequest request);

  ChatStateResponse state(AuthenticatedUser principal);
}
