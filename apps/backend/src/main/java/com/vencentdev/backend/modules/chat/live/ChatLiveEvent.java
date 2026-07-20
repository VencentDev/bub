package com.vencentdev.backend.modules.chat.live;

public record ChatLiveEvent(String type) {

  public static ChatLiveEvent of(ChatLiveEventType type) {
    return new ChatLiveEvent(type.name());
  }
}
