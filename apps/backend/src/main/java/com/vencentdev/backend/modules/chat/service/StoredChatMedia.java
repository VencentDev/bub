package com.vencentdev.backend.modules.chat.service;

public record StoredChatMedia(
    String publicUrl, String storageObjectPath, String contentType, long sizeBytes) {}
