package com.vencentdev.backend.modules.tether.controller;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.auth.CurrentUser;
import com.vencentdev.backend.modules.tether.dto.TetherAcceptRequest;
import com.vencentdev.backend.modules.tether.dto.TetherInvitationResponse;
import com.vencentdev.backend.modules.tether.dto.TetherStatusResponse;
import com.vencentdev.backend.modules.tether.service.TetherService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/tether")
public class TetherController {

  private final TetherService tetherService;

  public TetherController(TetherService tetherService) {
    this.tetherService = tetherService;
  }

  @GetMapping("/me")
  @Operation(operationId = "tetherMe")
  public TetherStatusResponse me(@Parameter(hidden = true) @CurrentUser AuthenticatedUser user) {
    return tetherService.getStatus(user);
  }

  @PostMapping("/invitations")
  @ResponseStatus(HttpStatus.CREATED)
  @Operation(operationId = "createTetherInvitation")
  public TetherInvitationResponse generateInvitation(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user) {
    return tetherService.generateInvitation(user);
  }

  @PostMapping("/accept")
  @Operation(operationId = "acceptTether")
  public TetherStatusResponse accept(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user,
      @Valid @RequestBody TetherAcceptRequest request) {
    return tetherService.acceptInvitation(user, request);
  }
}
