package com.vencentdev.backend.modules.bub.controller;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.auth.CurrentUser;
import com.vencentdev.backend.modules.bub.dto.BubSendResponse;
import com.vencentdev.backend.modules.bub.service.BubService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/bubs")
public class BubController {

  private final BubService bubService;

  public BubController(BubService bubService) {
    this.bubService = bubService;
  }

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  @Operation(operationId = "sendBub")
  public BubSendResponse send(@Parameter(hidden = true) @CurrentUser AuthenticatedUser user) {
    return bubService.send(user);
  }
}
