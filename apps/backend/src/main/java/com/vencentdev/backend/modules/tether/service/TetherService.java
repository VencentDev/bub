package com.vencentdev.backend.modules.tether.service;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.tether.dto.TetherAcceptRequest;
import com.vencentdev.backend.modules.tether.dto.TetherInvitationResponse;
import com.vencentdev.backend.modules.tether.dto.TetherStatusResponse;

public interface TetherService {

  TetherStatusResponse getStatus(AuthenticatedUser principal);

  TetherInvitationResponse generateInvitation(AuthenticatedUser principal);

  TetherStatusResponse acceptInvitation(AuthenticatedUser principal, TetherAcceptRequest request);

  TetherStatusResponse removeTether(AuthenticatedUser principal);
}
