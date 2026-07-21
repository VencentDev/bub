package com.vencentdev.backend.modules.safe.service;

import java.util.UUID;
import org.springframework.web.multipart.MultipartFile;

public interface SafeMediaStorageService {

  StoredSafeMedia uploadSafeMedia(UUID connectionId, UUID uploaderUserId, MultipartFile file);

  void deleteSafeMedia(String storageObjectPath);
}
