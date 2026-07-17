package com.vencentdev.backend.modules.bub.service;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.bub.dto.BubSendResponse;

public interface BubService {

  BubSendResponse send(AuthenticatedUser principal);
}
