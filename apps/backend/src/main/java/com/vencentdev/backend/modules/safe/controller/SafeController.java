package com.vencentdev.backend.modules.safe.controller;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.auth.CurrentUser;
import com.vencentdev.backend.modules.safe.dto.SafeMediaDeleteResponse;
import com.vencentdev.backend.modules.safe.dto.SafeMediaListResponse;
import com.vencentdev.backend.modules.safe.dto.SafeMediaUploadResponse;
import com.vencentdev.backend.modules.safe.dto.SafePinSetupRequest;
import com.vencentdev.backend.modules.safe.dto.SafeStatusResponse;
import com.vencentdev.backend.modules.safe.dto.SafeUnlockRequest;
import com.vencentdev.backend.modules.safe.dto.SafeUnlockResponse;
import com.vencentdev.backend.modules.safe.service.SafeAccessService;
import com.vencentdev.backend.modules.safe.service.SafeMediaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/safe")
public class SafeController {

  private final SafeAccessService safeAccessService;
  private final SafeMediaService safeMediaService;

  public SafeController(SafeAccessService safeAccessService, SafeMediaService safeMediaService) {
    this.safeAccessService = safeAccessService;
    this.safeMediaService = safeMediaService;
  }

  @GetMapping("/status")
  public SafeStatusResponse status(@CurrentUser AuthenticatedUser principal) {
    return safeAccessService.status(principal);
  }

  @PostMapping("/pin")
  @ResponseStatus(HttpStatus.CREATED)
  public SafeStatusResponse setupPin(
      @CurrentUser AuthenticatedUser principal, @Valid @RequestBody SafePinSetupRequest request) {
    return safeAccessService.setupPin(principal, request.pin());
  }

  @PostMapping("/unlock")
  public SafeUnlockResponse unlock(
      @CurrentUser AuthenticatedUser principal, @Valid @RequestBody SafeUnlockRequest request) {
    return safeAccessService.unlock(principal, request.pin());
  }

  @PostMapping(value = "/media", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  @ResponseStatus(HttpStatus.CREATED)
  @Operation(operationId = "uploadSafeMedia")
  public SafeMediaUploadResponse uploadMedia(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser principal,
      @RequestHeader("X-Bub-Safe-Pin") String pin,
      @RequestParam("files") List<MultipartFile> files) {
    return safeMediaService.upload(principal, pin, files);
  }

  @GetMapping("/media")
  @Operation(operationId = "listSafeMedia")
  public SafeMediaListResponse listMedia(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser principal,
      @RequestHeader("X-Bub-Safe-Pin") String pin) {
    return safeMediaService.list(principal, pin);
  }

  @DeleteMapping("/media/{mediaId}")
  @Operation(operationId = "deleteSafeMedia")
  public SafeMediaDeleteResponse deleteMedia(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser principal,
      @RequestHeader("X-Bub-Safe-Pin") String pin,
      @PathVariable UUID mediaId) {
    return safeMediaService.delete(principal, pin, mediaId);
  }
}
