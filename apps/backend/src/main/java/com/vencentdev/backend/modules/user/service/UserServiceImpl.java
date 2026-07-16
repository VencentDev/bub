package com.vencentdev.backend.modules.user.service;

import com.vencentdev.backend.common.exception.ResourceNotFoundException;
import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.user.dto.UserResponse;
import com.vencentdev.backend.modules.user.dto.UserUpdateRequest;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.enums.KycStatus;
import com.vencentdev.backend.modules.user.enums.Role;
import com.vencentdev.backend.modules.user.enums.UserType;
import com.vencentdev.backend.modules.user.mapper.UserMapper;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserServiceImpl implements UserService {

  private final UserRepository repository;
  private final UserMapper mapper;

  public UserServiceImpl(UserRepository repository, UserMapper mapper) {
    this.repository = repository;
    this.mapper = mapper;
  }

  @Override
  @Transactional
  public UserResponse findOrProvision(AuthenticatedUser principal) {
    return repository
        .findByExternalId(principal.subject())
        .map(mapper::toResponse)
        .orElseGet(() -> mapper.toResponse(repository.save(newUser(principal))));
  }

  @Override
  @Transactional(readOnly = true)
  public UserResponse getMe(AuthenticatedUser principal) {
    return mapper.toResponse(findByPrincipal(principal));
  }

  @Override
  @Transactional
  public UserResponse updateMe(AuthenticatedUser principal, UserUpdateRequest request) {
    User user = findByPrincipal(principal);
    mapper.applyUpdate(request, user);
    return mapper.toResponse(user);
  }

  @Override
  @Transactional
  public UUID resolveInternalId(AuthenticatedUser principal) {
    return repository
        .findByExternalId(principal.subject())
        .orElseGet(() -> repository.save(newUser(principal)))
        .getId();
  }

  private User findByPrincipal(AuthenticatedUser principal) {
    return repository
        .findByExternalId(principal.subject())
        .orElseThrow(() -> new ResourceNotFoundException("User not found"));
  }

  private User newUser(AuthenticatedUser principal) {
    return User.builder()
        .externalId(principal.subject())
        .email(principal.email())
        .displayName(principal.displayName())
        .role(Role.USER)
        .userType(UserType.INDIVIDUAL)
        .kycStatus(KycStatus.NONE)
        .build();
  }
}
