package com.vencentdev.backend.modules.user.controller;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.auth.CurrentUser;
import com.vencentdev.backend.modules.user.dto.UserResponse;
import com.vencentdev.backend.modules.user.dto.UserUpdateRequest;
import com.vencentdev.backend.modules.user.service.UserService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

  private final UserService users;

  public UserController(UserService users) {
    this.users = users;
  }

  @GetMapping("/me")
  public UserResponse me(@CurrentUser AuthenticatedUser user) {
    return users.getMe(user);
  }

  @PatchMapping("/me")
  public UserResponse updateMe(
      @CurrentUser AuthenticatedUser user, @Valid @RequestBody UserUpdateRequest request) {
    return users.updateMe(user, request);
  }
}
