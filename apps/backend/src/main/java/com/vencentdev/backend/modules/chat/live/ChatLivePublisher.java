package com.vencentdev.backend.modules.chat.live;

import java.util.UUID;

public interface ChatLivePublisher {

  void publish(UUID userId, ChatLiveEventType type);
}
