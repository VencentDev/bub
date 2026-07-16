package com.vencentdev.backend.modules.home.service;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.home.dto.HomeDashboardResponse;
import com.vencentdev.backend.modules.home.dto.HomeMomentReactionRequest;
import com.vencentdev.backend.modules.home.dto.HomeTodayMomentRequest;
import com.vencentdev.backend.modules.home.dto.HomeTodayMomentResponse;
import java.util.UUID;

public interface HomeService {

  HomeDashboardResponse dashboard(AuthenticatedUser principal);

  HomeTodayMomentResponse upsertTodayMoment(
      AuthenticatedUser principal, HomeTodayMomentRequest request);

  HomeTodayMomentResponse reactToMoment(
      AuthenticatedUser principal, UUID momentId, HomeMomentReactionRequest request);
}
