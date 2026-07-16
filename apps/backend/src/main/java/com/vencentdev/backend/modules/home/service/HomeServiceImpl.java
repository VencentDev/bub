package com.vencentdev.backend.modules.home.service;

import com.vencentdev.backend.common.exception.BadRequestException;
import com.vencentdev.backend.common.exception.ForbiddenException;
import com.vencentdev.backend.common.exception.ResourceNotFoundException;
import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.home.dto.HomeDashboardResponse;
import com.vencentdev.backend.modules.home.dto.HomeLatestBubResponse;
import com.vencentdev.backend.modules.home.dto.HomeMomentReactionRequest;
import com.vencentdev.backend.modules.home.dto.HomeSafeSummaryResponse;
import com.vencentdev.backend.modules.home.dto.HomeTetherCardResponse;
import com.vencentdev.backend.modules.home.dto.HomeTodayMomentRequest;
import com.vencentdev.backend.modules.home.dto.HomeTodayMomentResponse;
import com.vencentdev.backend.modules.home.entity.HomeDailyMoment;
import com.vencentdev.backend.modules.home.repository.HomeDailyMomentRepository;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.tether.repository.TetherConnectionRepository;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import com.vencentdev.backend.modules.user.service.UserService;
import java.time.Clock;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class HomeServiceImpl implements HomeService {

  private static final String TETHER_CTA = "Tether with someone";
  private static final String NO_BUBS_COPY = "No Bubs yet";
  private static final String SAFE_COPY = "Keep important details ready when you need them.";
  private static final String SAFE_CTA = "Open Safe";
  private static final String HEART_REACTION = "❤️";

  private final TetherConnectionRepository connections;
  private final HomeDailyMomentRepository moments;
  private final UserRepository users;
  private final UserService userService;
  private final Clock clock;

  @Autowired
  public HomeServiceImpl(
      TetherConnectionRepository connections,
      HomeDailyMomentRepository moments,
      UserRepository users,
      UserService userService) {
    this(connections, moments, users, userService, Clock.systemUTC());
  }

  HomeServiceImpl(
      TetherConnectionRepository connections,
      HomeDailyMomentRepository moments,
      UserRepository users,
      UserService userService,
      Clock clock) {
    this.connections = connections;
    this.moments = moments;
    this.users = users;
    this.userService = userService;
    this.clock = clock;
  }

  @Override
  @Transactional(readOnly = true)
  public HomeDashboardResponse dashboard(AuthenticatedUser principal) {
    UUID userId = userService.resolveInternalId(principal);
    return connections
        .findActiveByUserId(userId)
        .map(connection -> dashboardForTetheredUser(connection, userId))
        .orElseGet(this::dashboardForUntetheredUser);
  }

  @Override
  @Transactional
  public HomeTodayMomentResponse upsertTodayMoment(
      AuthenticatedUser principal, HomeTodayMomentRequest request) {
    UUID userId = userService.resolveInternalId(principal);
    User user =
        users.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    TetherConnection connection = activeConnection(userId);
    HomeDailyMoment moment =
        moments
            .findByTetherConnectionIdAndLocalDate(connection.getId(), request.localDate())
            .orElseGet(
                () ->
                    HomeDailyMoment.builder()
                        .tetherConnection(connection)
                        .createdByUser(user)
                        .localDate(request.localDate())
                        .build());
    moment.setPhotoUrl(request.photoUrl());
    moment.setCreatedByUser(user);
    moment.setPartnerReaction(null);
    return toMomentResponse(moments.save(moment), userId);
  }

  @Override
  @Transactional
  public HomeTodayMomentResponse reactToMoment(
      AuthenticatedUser principal, UUID momentId, HomeMomentReactionRequest request) {
    if (!HEART_REACTION.equals(request.reaction())) {
      throw new BadRequestException("Unsupported reaction");
    }

    UUID userId = userService.resolveInternalId(principal);
    HomeDailyMoment moment =
        moments
            .findByIdWithTetherAndUsers(momentId)
            .orElseThrow(() -> new ResourceNotFoundException("Moment not found"));
    TetherConnection connection = moment.getTetherConnection();
    if (!participates(connection, userId)) {
      throw new ForbiddenException("Moment is not part of your tether");
    }
    if (moment.getCreatedByUser().getId().equals(userId)) {
      throw new BadRequestException("You cannot react to your own moment");
    }

    moment.setPartnerReaction(request.reaction());
    return toMomentResponse(moment, userId);
  }

  private HomeDashboardResponse dashboardForTetheredUser(TetherConnection connection, UUID userId) {
    HomeTodayMomentResponse todayMoment =
        moments
            .findByTetherConnectionIdAndLocalDate(connection.getId(), LocalDate.now(clock))
            .map(moment -> toMomentResponse(moment, userId))
            .orElse(null);

    return new HomeDashboardResponse(
        tetherCard(connection, userId),
        todayMoment,
        noBubs(),
        new HomeSafeSummaryResponse(true, SAFE_COPY, SAFE_CTA));
  }

  private HomeDashboardResponse dashboardForUntetheredUser() {
    return new HomeDashboardResponse(
        new HomeTetherCardResponse(false, null, null, null, null, null, TETHER_CTA),
        null,
        noBubs(),
        new HomeSafeSummaryResponse(true, SAFE_COPY, SAFE_CTA));
  }

  private TetherConnection activeConnection(UUID userId) {
    return connections
        .findActiveByUserId(userId)
        .orElseThrow(() -> new BadRequestException("An active tether is required"));
  }

  private HomeTetherCardResponse tetherCard(TetherConnection connection, UUID userId) {
    User partner = partner(connection, userId);
    return new HomeTetherCardResponse(
        true,
        partner.getId(),
        partner.getDisplayName(),
        null,
        null,
        connection.getCreatedAt(),
        null);
  }

  private User partner(TetherConnection connection, UUID userId) {
    if (connection.getUserOne().getId().equals(userId)) {
      return connection.getUserTwo();
    }
    return connection.getUserOne();
  }

  private boolean participates(TetherConnection connection, UUID userId) {
    return connection.getUserOne().getId().equals(userId)
        || connection.getUserTwo().getId().equals(userId);
  }

  private HomeTodayMomentResponse toMomentResponse(HomeDailyMoment moment, UUID viewerId) {
    return new HomeTodayMomentResponse(
        moment.getId(),
        moment.getPhotoUrl(),
        moment.getLocalDate(),
        moment.getCreatedByUser().getId().equals(viewerId),
        moment.getPartnerReaction());
  }

  private HomeLatestBubResponse noBubs() {
    return new HomeLatestBubResponse(false, NO_BUBS_COPY, null);
  }
}
