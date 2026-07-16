package com.vencentdev.backend.modules.user.service;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.user.dto.UserResponse;
import com.vencentdev.backend.modules.user.dto.UserUpdateRequest;
import java.util.UUID;

public interface UserService {

  UserResponse findOrProvision(AuthenticatedUser principal);

  UserResponse getMe(AuthenticatedUser principal);

  UserResponse updateMe(AuthenticatedUser principal, UserUpdateRequest request);

  UUID resolveInternalId(AuthenticatedUser principal);
}
