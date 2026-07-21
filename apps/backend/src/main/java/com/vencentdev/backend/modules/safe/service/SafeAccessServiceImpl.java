package com.vencentdev.backend.modules.safe.service;

import com.vencentdev.backend.common.exception.ConflictException;
import com.vencentdev.backend.common.exception.ForbiddenException;
import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.safe.dto.SafeStatusResponse;
import com.vencentdev.backend.modules.safe.dto.SafeUnlockResponse;
import com.vencentdev.backend.modules.safe.entity.SafeVaultAccess;
import com.vencentdev.backend.modules.safe.repository.SafeVaultAccessRepository;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.tether.repository.TetherConnectionRepository;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import com.vencentdev.backend.modules.user.service.UserService;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SafeAccessServiceImpl implements SafeAccessService {

  private final SafeVaultAccessRepository safeAccess;
  private final TetherConnectionRepository connections;
  private final UserRepository users;
  private final UserService userService;
  private final PasswordEncoder passwordEncoder;

  public SafeAccessServiceImpl(
      SafeVaultAccessRepository safeAccess,
      TetherConnectionRepository connections,
      UserRepository users,
      UserService userService,
      PasswordEncoder passwordEncoder) {
    this.safeAccess = safeAccess;
    this.connections = connections;
    this.users = users;
    this.userService = userService;
    this.passwordEncoder = passwordEncoder;
  }

  @Override
  @Transactional(readOnly = true)
  public SafeStatusResponse status(AuthenticatedUser principal) {
    UUID userId = userService.resolveInternalId(principal);
    return connections
        .findActiveByUserId(userId)
        .map(
            connection ->
                new SafeStatusResponse(
                    true,
                    safeAccess.existsByTetherConnectionIdAndUserId(connection.getId(), userId)))
        .orElseGet(() -> new SafeStatusResponse(false, false));
  }

  @Override
  @Transactional
  public SafeStatusResponse setupPin(AuthenticatedUser principal, String pin) {
    UUID userId = userService.resolveInternalId(principal);
    TetherConnection connection = activeConnection(userId);
    if (safeAccess.existsByTetherConnectionIdAndUserId(connection.getId(), userId)) {
      throw new ConflictException("Safe PIN already configured");
    }

    User user = users.getReferenceById(userId);
    safeAccess.save(
        SafeVaultAccess.builder()
            .tetherConnection(connection)
            .user(user)
            .pinHash(passwordEncoder.encode(pin))
            .build());
    return new SafeStatusResponse(true, true);
  }

  @Override
  @Transactional(readOnly = true)
  public SafeUnlockResponse unlock(AuthenticatedUser principal, String pin) {
    verifyPin(principal, pin);
    return new SafeUnlockResponse(true);
  }

  @Override
  @Transactional(readOnly = true)
  public SafeVaultContext verifyPin(AuthenticatedUser principal, String pin) {
    UUID userId = userService.resolveInternalId(principal);
    TetherConnection connection = activeConnection(userId);
    SafeVaultAccess access =
        safeAccess
            .findByTetherConnectionIdAndUserId(connection.getId(), userId)
            .orElseThrow(() -> new ForbiddenException("Safe PIN is not configured"));
    if (!passwordEncoder.matches(pin, access.getPinHash())) {
      throw new ForbiddenException("Invalid Safe PIN");
    }
    return new SafeVaultContext(connection, userId);
  }

  private TetherConnection activeConnection(UUID userId) {
    return connections
        .findActiveByUserId(userId)
        .orElseThrow(() -> new ForbiddenException("Safe requires an active tether"));
  }
}
