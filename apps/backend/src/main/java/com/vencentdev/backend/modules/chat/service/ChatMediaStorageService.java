package com.vencentdev.backend.modules.chat.service;

import java.util.UUID;
import org.springframework.web.multipart.MultipartFile;

public interface ChatMediaStorageService {

  StoredChatMedia uploadChatMedia(UUID connectionId, UUID senderUserId, MultipartFile file);
}
