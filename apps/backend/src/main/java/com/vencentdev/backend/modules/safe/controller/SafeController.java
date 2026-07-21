package com.vencentdev.backend.modules.safe.controller;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.auth.CurrentUser;
import com.vencentdev.backend.modules.safe.dto.SafePinSetupRequest;
import com.vencentdev.backend.modules.safe.dto.SafeStatusResponse;
import com.vencentdev.backend.modules.safe.dto.SafeUnlockRequest;
import com.vencentdev.backend.modules.safe.dto.SafeUnlockResponse;
import com.vencentdev.backend.modules.safe.service.SafeAccessService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/safe")
public class SafeController {

  private final SafeAccessService safeAccessService;

  public SafeController(SafeAccessService safeAccessService) {
    this.safeAccessService = safeAccessService;
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
}
