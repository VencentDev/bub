package com.vencentdev.backend.modules.chat.live;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class ChatLiveWebSocketHandler extends TextWebSocketHandler implements ChatLivePublisher {

  private final ObjectMapper objectMapper;
  private final ConcurrentHashMap<UUID, Set<WebSocketSession>> sessionsByUserId =
      new ConcurrentHashMap<>();

  public ChatLiveWebSocketHandler() {
    this.objectMapper = new ObjectMapper();
  }

  @Override
  public void afterConnectionEstablished(WebSocketSession session) throws Exception {
    UUID userId = userId(session);
    if (userId == null) {
      session.close(CloseStatus.NOT_ACCEPTABLE.withReason("Authentication required"));
      return;
    }
    sessionsByUserId.computeIfAbsent(userId, ignored -> ConcurrentHashMap.newKeySet()).add(session);
  }

  @Override
  public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
    remove(session);
  }

  @Override
  public void handleTransportError(WebSocketSession session, Throwable exception) {
    remove(session);
  }

  @Override
  public void publish(UUID userId, ChatLiveEventType type) {
    Set<WebSocketSession> sessions = sessionsByUserId.get(userId);
    if (sessions == null || sessions.isEmpty()) {
      return;
    }
    TextMessage message = message(type);
    for (WebSocketSession session : sessions) {
      send(session, message);
    }
  }

  private TextMessage message(ChatLiveEventType type) {
    try {
      return new TextMessage(objectMapper.writeValueAsString(ChatLiveEvent.of(type)));
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("Unable to serialize chat live event", exception);
    }
  }

  private void send(WebSocketSession session, TextMessage message) {
    if (!session.isOpen()) {
      remove(session);
      return;
    }
    try {
      synchronized (session) {
        session.sendMessage(message);
      }
    } catch (IOException exception) {
      remove(session);
    }
  }

  private void remove(WebSocketSession session) {
    UUID userId = userId(session);
    if (userId == null) {
      return;
    }
    Set<WebSocketSession> sessions = sessionsByUserId.get(userId);
    if (sessions == null) {
      return;
    }
    sessions.remove(session);
    if (sessions.isEmpty()) {
      sessionsByUserId.remove(userId, sessions);
    }
  }

  private UUID userId(WebSocketSession session) {
    Object value = session.getAttributes().get(ChatLiveHandshakeInterceptor.USER_ID_ATTRIBUTE);
    return value instanceof UUID userId ? userId : null;
  }
}
