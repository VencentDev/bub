package com.vencentdev.backend.modules.chat.controller;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.auth.CurrentUser;
import com.vencentdev.backend.modules.chat.dto.ChatEditMessageRequest;
import com.vencentdev.backend.modules.chat.dto.ChatMessageResponse;
import com.vencentdev.backend.modules.chat.dto.ChatReactionRequest;
import com.vencentdev.backend.modules.chat.dto.ChatReadRequest;
import com.vencentdev.backend.modules.chat.dto.ChatSendMessageRequest;
import com.vencentdev.backend.modules.chat.dto.ChatStateResponse;
import com.vencentdev.backend.modules.chat.dto.ChatThreadResponse;
import com.vencentdev.backend.modules.chat.dto.ChatTypingRequest;
import com.vencentdev.backend.modules.chat.service.ChatService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/chat")
public class ChatController {

  private final ChatService chatService;

  public ChatController(ChatService chatService) {
    this.chatService = chatService;
  }

  @GetMapping("/thread")
  @Operation(operationId = "getChatThread")
  public ChatThreadResponse thread(@Parameter(hidden = true) @CurrentUser AuthenticatedUser user) {
    return chatService.thread(user);
  }

  @PostMapping("/messages")
  @Operation(operationId = "sendChatMessage")
  public ChatMessageResponse send(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user,
      @Valid @RequestBody ChatSendMessageRequest request) {
    return chatService.send(user, request);
  }

  @PostMapping(value = "/messages/media", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  @Operation(operationId = "uploadChatMediaMessage")
  public List<ChatMessageResponse> uploadMedia(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user,
      @RequestParam("files") List<MultipartFile> files,
      @RequestParam(value = "replyToMessageId", required = false) UUID replyToMessageId) {
    return chatService.uploadMedia(user, files, replyToMessageId);
  }

  @PatchMapping("/messages/{messageId}")
  @Operation(operationId = "editChatMessage")
  public ChatMessageResponse edit(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user,
      @PathVariable UUID messageId,
      @Valid @RequestBody ChatEditMessageRequest request) {
    return chatService.edit(user, messageId, request);
  }

  @DeleteMapping("/messages/{messageId}/me")
  @Operation(operationId = "deleteChatMessageForMe")
  public ResponseEntity<Void> deleteForMe(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user, @PathVariable UUID messageId) {
    chatService.deleteForMe(user, messageId);
    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/messages/{messageId}/everyone")
  @Operation(operationId = "deleteChatMessageForEveryone")
  public ChatMessageResponse deleteForEveryone(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user, @PathVariable UUID messageId) {
    return chatService.deleteForEveryone(user, messageId);
  }

  @PostMapping("/messages/{messageId}/reaction")
  @Operation(operationId = "reactToChatMessage")
  public ChatMessageResponse react(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user,
      @PathVariable UUID messageId,
      @Valid @RequestBody ChatReactionRequest request) {
    return chatService.react(user, messageId, request);
  }

  @DeleteMapping("/messages/{messageId}/reaction")
  @Operation(operationId = "removeChatMessageReaction")
  public ChatMessageResponse removeReaction(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user, @PathVariable UUID messageId) {
    return chatService.removeReaction(user, messageId);
  }

  @PostMapping("/read")
  @Operation(operationId = "markChatMessagesRead")
  public ChatStateResponse markRead(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user,
      @Valid @RequestBody ChatReadRequest request) {
    return chatService.markRead(user, request);
  }

  @PostMapping("/typing")
  @Operation(operationId = "setChatTyping")
  public ChatStateResponse setTyping(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user,
      @RequestBody ChatTypingRequest request) {
    return chatService.setTyping(user, request);
  }

  @GetMapping("/state")
  @Operation(operationId = "getChatState")
  public ChatStateResponse state(@Parameter(hidden = true) @CurrentUser AuthenticatedUser user) {
    return chatService.state(user);
  }
}
