package com.vencentdev.backend.config;

import com.vencentdev.backend.modules.chat.live.ChatLiveHandshakeInterceptor;
import com.vencentdev.backend.modules.chat.live.ChatLiveWebSocketHandler;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

  private final ChatLiveWebSocketHandler chatLiveWebSocketHandler;
  private final ChatLiveHandshakeInterceptor chatLiveHandshakeInterceptor;
  private final CorsConfig.CorsProperties corsProperties;

  public WebSocketConfig(
      ChatLiveWebSocketHandler chatLiveWebSocketHandler,
      ChatLiveHandshakeInterceptor chatLiveHandshakeInterceptor,
      CorsConfig.CorsProperties corsProperties) {
    this.chatLiveWebSocketHandler = chatLiveWebSocketHandler;
    this.chatLiveHandshakeInterceptor = chatLiveHandshakeInterceptor;
    this.corsProperties = corsProperties;
  }

  @Override
  public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
    registry
        .addHandler(chatLiveWebSocketHandler, "/api/v1/chat/live")
        .addInterceptors(chatLiveHandshakeInterceptor)
        .setAllowedOrigins(corsProperties.allowedOrigins().toArray(String[]::new));
  }
}
