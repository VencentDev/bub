package com.vencentdev.backend.modules.home.service;

import com.vencentdev.backend.modules.home.entity.HomeDailyMoment;
import com.vencentdev.backend.modules.home.entity.HomeMood;
import com.vencentdev.backend.modules.home.repository.HomeDailyMomentRepository;
import com.vencentdev.backend.modules.home.repository.HomeMoodRepository;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class HomeMomentExpiryCleanupService {

  private static final Logger log = LoggerFactory.getLogger(HomeMomentExpiryCleanupService.class);
  private static final Duration MOOD_TTL = Duration.ofHours(24);

  private final HomeDailyMomentRepository moments;
  private final HomeMoodRepository moods;
  private final MomentStorageService storage;
  private final Clock clock;

  @Autowired
  public HomeMomentExpiryCleanupService(
      HomeDailyMomentRepository moments, HomeMoodRepository moods, MomentStorageService storage) {
    this(moments, moods, storage, Clock.systemUTC());
  }

  HomeMomentExpiryCleanupService(
      HomeDailyMomentRepository moments,
      HomeMoodRepository moods,
      MomentStorageService storage,
      Clock clock) {
    this.moments = moments;
    this.moods = moods;
    this.storage = storage;
    this.clock = clock;
  }

  @Scheduled(fixedDelayString = "${app.home.moments.cleanup-interval-ms:900000}")
  @Transactional
  public void deleteExpiredMoments() {
    Instant cutoff = clock.instant();
    List<HomeDailyMoment> expiredMoments = moments.findByExpiresAtBefore(cutoff);
    if (expiredMoments.isEmpty()) {
      return;
    }

    for (HomeDailyMoment moment : expiredMoments) {
      if (StringUtils.hasText(moment.getStorageObjectPath())) {
        storage.deleteMoment(moment.getStorageObjectPath());
      }
      moments.delete(moment);
    }
    log.info("Deleted {} expired home daily moments", expiredMoments.size());
  }

  @Scheduled(fixedDelayString = "${app.home.moods.cleanup-interval-ms:900000}")
  @Transactional
  public void deleteExpiredMoods() {
    Instant cutoff = clock.instant().minus(MOOD_TTL);
    List<HomeMood> expiredMoods = moods.findByUpdatedAtBefore(cutoff);
    if (expiredMoods.isEmpty()) {
      return;
    }

    moods.deleteAll(expiredMoods);
    log.info("Deleted {} expired home moods", expiredMoods.size());
  }
}
