package com.vencentdev.backend.modules.auth.controller;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AdminPingController {

  @GetMapping("/api/v1/admin/ping")
  @PreAuthorize("hasRole('ADMIN')")
  public String adminPing() {
    return "ok";
  }
}
