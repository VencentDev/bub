package com.vencentdev.backend.modules.user.mapper;

import com.vencentdev.backend.modules.user.dto.UserResponse;
import com.vencentdev.backend.modules.user.dto.UserUpdateRequest;
import com.vencentdev.backend.modules.user.entity.User;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public abstract class UserMapper {

  public abstract UserResponse toResponse(User user);

  public void applyUpdate(UserUpdateRequest request, User target) {
    if (request.email() != null && request.email().isPresent()) {
      target.setEmail(request.email().get());
    }
    if (request.displayName() != null && request.displayName().isPresent()) {
      target.setDisplayName(request.displayName().get());
    }
  }
}
