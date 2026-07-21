package com.vencentdev.backend.modules.safe.service;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.safe.dto.SafeStatusResponse;
import com.vencentdev.backend.modules.safe.dto.SafeUnlockResponse;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import java.util.UUID;

public interface SafeAccessService {

  SafeStatusResponse status(AuthenticatedUser principal);

  SafeStatusResponse setupPin(AuthenticatedUser principal, String pin);

  SafeUnlockResponse unlock(AuthenticatedUser principal, String pin);

  SafeVaultContext verifyPin(AuthenticatedUser principal, String pin);

  record SafeVaultContext(TetherConnection tetherConnection, UUID userId) {}
}
