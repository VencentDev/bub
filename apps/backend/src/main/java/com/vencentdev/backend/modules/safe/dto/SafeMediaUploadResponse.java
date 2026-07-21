package com.vencentdev.backend.modules.safe.dto;

import java.util.List;

public record SafeMediaUploadResponse(
    List<SafeMediaItemResponse> items, SafeChatNoticeResponse chatNotice) {}
