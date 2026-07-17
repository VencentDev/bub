package com.vencentdev.backend.modules.home.service;

import java.time.LocalDate;
import java.util.UUID;
import org.springframework.web.multipart.MultipartFile;

public interface MomentStorageService {

  StoredMomentPhoto uploadMoment(
      UUID tetherConnectionId, UUID userId, LocalDate localDate, MultipartFile photo);

  void deleteMoment(String objectPath);

  record StoredMomentPhoto(String publicUrl, String objectPath) {}
}
