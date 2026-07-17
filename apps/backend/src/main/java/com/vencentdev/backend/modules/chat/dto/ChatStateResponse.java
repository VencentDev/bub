package com.vencentdev.backend.modules.chat.dto;

public record ChatStateResponse(boolean partnerTyping, ChatPresenceResponse partnerPresence) {}
