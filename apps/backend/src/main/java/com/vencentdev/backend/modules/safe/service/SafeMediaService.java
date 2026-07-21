package com.vencentdev.backend.modules.safe.service;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.safe.dto.SafeMediaDeleteResponse;
import com.vencentdev.backend.modules.safe.dto.SafeMediaListResponse;
import com.vencentdev.backend.modules.safe.dto.SafeMediaUploadResponse;
import java.util.List;
import java.util.UUID;
import org.springframework.web.multipart.MultipartFile;

public interface SafeMediaService {

  SafeMediaUploadResponse upload(
      AuthenticatedUser principal, String pin, List<MultipartFile> files);

  SafeMediaListResponse list(AuthenticatedUser principal, String pin);

  SafeMediaDeleteResponse delete(AuthenticatedUser principal, String pin, UUID mediaId);
}
