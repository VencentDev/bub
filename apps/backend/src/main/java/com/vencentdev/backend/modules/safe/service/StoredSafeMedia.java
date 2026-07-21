package com.vencentdev.backend.modules.safe.service;

public record StoredSafeMedia(
    String publicUrl, String storageObjectPath, String contentType, long sizeBytes) {}
