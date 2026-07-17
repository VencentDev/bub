package com.vencentdev.backend.modules.home.service;

import com.vencentdev.backend.common.exception.BadRequestException;
import com.vencentdev.backend.common.exception.ForbiddenException;
import com.vencentdev.backend.common.exception.ResourceNotFoundException;
import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.home.dto.HomeDashboardResponse;
import com.vencentdev.backend.modules.home.dto.HomeLatestBubResponse;
import com.vencentdev.backend.modules.home.dto.HomeMomentReactionRequest;
import com.vencentdev.backend.modules.home.dto.HomeMoodRequest;
import com.vencentdev.backend.modules.home.dto.HomeMoodSummaryResponse;
import com.vencentdev.backend.modules.home.dto.HomeTetherCardResponse;
import com.vencentdev.backend.modules.home.dto.HomeTodayMomentRequest;
import com.vencentdev.backend.modules.home.dto.HomeTodayMomentResponse;
import com.vencentdev.backend.modules.home.entity.HomeDailyMoment;
import com.vencentdev.backend.modules.home.entity.HomeMood;
import com.vencentdev.backend.modules.home.repository.HomeDailyMomentRepository;
import com.vencentdev.backend.modules.home.repository.HomeMoodRepository;
import com.vencentdev.backend.modules.home.service.MomentStorageService.StoredMomentPhoto;
import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import com.vencentdev.backend.modules.tether.repository.TetherConnectionRepository;
import com.vencentdev.backend.modules.user.entity.User;
import com.vencentdev.backend.modules.user.repository.UserRepository;
import com.vencentdev.backend.modules.user.service.UserService;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
public class HomeServiceImpl implements HomeService {

  private static final String TETHER_CTA = "Tether with someone";
  private static final String NO_BUBS_COPY = "No Bubs yet";
  private static final String MOOD_COPY = "How are you feeling?";
  private static final String HEART_REACTION = "❤️";
  private static final Duration MOMENT_TTL = Duration.ofHours(24);

  private final TetherConnectionRepository connections;
  private final HomeDailyMomentRepository moments;
  private final HomeMoodRepository moods;
  private final UserRepository users;
  private final UserService userService;
  private final MomentStorageService momentStorageService;
  private final Clock clock;

  @Autowired
  public HomeServiceImpl(
      TetherConnectionRepository connections,
      HomeDailyMomentRepository moments,
      HomeMoodRepository moods,
      UserRepository users,
      UserService userService,
      MomentStorageService momentStorageService) {
    this(connections, moments, moods, users, userService, momentStorageService, Clock.systemUTC());
  }

  HomeServiceImpl(
      TetherConnectionRepository connections,
      HomeDailyMomentRepository moments,
      HomeMoodRepository moods,
      UserRepository users,
      UserService userService,
      MomentStorageService momentStorageService,
      Clock clock) {
    this.connections = connections;
    this.moments = moments;
    this.moods = moods;
    this.users = users;
    this.userService = userService;
    this.momentStorageService = momentStorageService;
    this.clock = clock;
  }

  @Override
  @Transactional(readOnly = true)
  public HomeDashboardResponse dashboard(AuthenticatedUser principal) {
    UUID userId = userService.resolveInternalId(principal);
    return connections
        .findActiveByUserId(userId)
        .map(connection -> dashboardForTetheredUser(connection, userId))
        .orElseGet(() -> dashboardForUntetheredUser(userId));
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
            .findByTetherConnectionIdAndCreatedByUserIdAndLocalDate(
                connection.getId(), userId, request.localDate())
            .orElseGet(
                () ->
                    HomeDailyMoment.builder()
                        .tetherConnection(connection)
                        .createdByUser(user)
                        .localDate(request.localDate())
                        .build());
    moment.setPhotoUrl(request.photoUrl());
    moment.setCreatedByUser(user);
    moment.setExpiresAt(expiresAt());
    moment.setPartnerReaction(null);
    return toMomentResponse(moments.save(moment), userId);
  }

  @Override
  @Transactional
  public HomeTodayMomentResponse uploadTodayMomentPhoto(
      AuthenticatedUser principal, MultipartFile photo) {
    if (photo == null || photo.isEmpty()) {
      throw new BadRequestException("Moment photo is required");
    }

    UUID userId = userService.resolveInternalId(principal);
    User user =
        users.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    TetherConnection connection = activeConnection(userId);
    LocalDate localDate = LocalDate.now(clock);
    HomeDailyMoment moment =
        moments
            .findByTetherConnectionIdAndCreatedByUserIdAndLocalDate(
                connection.getId(), userId, localDate)
            .orElseGet(
                () ->
                    HomeDailyMoment.builder()
                        .tetherConnection(connection)
                        .createdByUser(user)
                        .localDate(localDate)
                        .build());
    String previousObjectPath = moment.getStorageObjectPath();
    StoredMomentPhoto storedPhoto =
        momentStorageService.uploadMoment(connection.getId(), userId, localDate, photo);
    moment.setPhotoUrl(storedPhoto.publicUrl());
    moment.setStorageObjectPath(storedPhoto.objectPath());
    moment.setCreatedByUser(user);
    moment.setExpiresAt(expiresAt());
    moment.setPartnerReaction(null);
    HomeTodayMomentResponse response = toMomentResponse(moments.save(moment), userId);
    if (previousObjectPath != null && !previousObjectPath.equals(storedPhoto.objectPath())) {
      momentStorageService.deleteMoment(previousObjectPath);
    }
    return response;
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

  @Override
  @Transactional
  public HomeMoodSummaryResponse putMood(AuthenticatedUser principal, HomeMoodRequest request) {
    UUID userId = userService.resolveInternalId(principal);
    User user =
        users.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    HomeMood mood =
        moods.findByUserId(userId).orElseGet(() -> HomeMood.builder().user(user).build());
    mood.setMood(request.mood().trim());
    return toMoodResponse(moods.save(mood));
  }

  private HomeDashboardResponse dashboardForTetheredUser(TetherConnection connection, UUID userId) {
    LocalDate today = LocalDate.now(clock);
    User partner = partner(connection, userId);
    HomeDailyMoment viewerMoment =
        moments
            .findByTetherConnectionIdAndCreatedByUserIdAndLocalDate(
                connection.getId(), userId, today)
            .orElse(null);
    HomeDailyMoment partnerMoment =
        moments
            .findByTetherConnectionIdAndCreatedByUserIdAndLocalDate(
                connection.getId(), partner.getId(), today)
            .orElse(null);
    HomeTodayMomentResponse todayMoment =
        viewerMoment == null && partnerMoment == null
            ? null
            : toMomentResponse(partnerMoment, viewerMoment);

    return new HomeDashboardResponse(
        tetherCard(connection, userId), todayMoment, noBubs(), moodForUser(userId));
  }

  private HomeDashboardResponse dashboardForUntetheredUser(UUID userId) {
    return new HomeDashboardResponse(
        new HomeTetherCardResponse(false, null, null, null, null, null, TETHER_CTA),
        null,
        noBubs(),
        moodForUser(userId));
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
        moment.getCreatedByUser().getId().equals(viewerId) ? moment.getPhotoUrl() : null,
        moment.getCreatedByUser().getId().equals(viewerId) ? null : moment.getCreatedAt(),
        moment.getLocalDate(),
        moment.getCreatedByUser().getId().equals(viewerId),
        moment.getPartnerReaction());
  }

  private HomeTodayMomentResponse toMomentResponse(
      HomeDailyMoment partnerMoment, HomeDailyMoment viewerMoment) {
    if (partnerMoment != null) {
      return new HomeTodayMomentResponse(
          partnerMoment.getId(),
          partnerMoment.getPhotoUrl(),
          viewerMoment == null ? null : viewerMoment.getPhotoUrl(),
          partnerMoment.getCreatedAt(),
          partnerMoment.getLocalDate(),
          viewerMoment != null,
          partnerMoment.getPartnerReaction());
    }

    return new HomeTodayMomentResponse(
        null, null, viewerMoment.getPhotoUrl(), null, viewerMoment.getLocalDate(), true, null);
  }

  private HomeLatestBubResponse noBubs() {
    return new HomeLatestBubResponse(false, NO_BUBS_COPY, null);
  }

  private HomeMoodSummaryResponse moodForUser(UUID userId) {
    return moods
        .findByUserId(userId)
        .map(this::toMoodResponse)
        .orElseGet(() -> new HomeMoodSummaryResponse(MOOD_COPY, null));
  }

  private HomeMoodSummaryResponse toMoodResponse(HomeMood mood) {
    return new HomeMoodSummaryResponse(MOOD_COPY, mood.getMood());
  }

  private Instant expiresAt() {
    return clock.instant().plus(MOMENT_TTL);
  }
}
