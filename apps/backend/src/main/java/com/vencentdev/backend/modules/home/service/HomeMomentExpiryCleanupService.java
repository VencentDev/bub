package com.vencentdev.backend.modules.home.service;

import com.vencentdev.backend.modules.home.entity.HomeDailyMoment;
import com.vencentdev.backend.modules.home.repository.HomeDailyMomentRepository;
import java.time.Clock;
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

  private final HomeDailyMomentRepository moments;
  private final MomentStorageService storage;
  private final Clock clock;

  @Autowired
  public HomeMomentExpiryCleanupService(
      HomeDailyMomentRepository moments, MomentStorageService storage) {
    this(moments, storage, Clock.systemUTC());
  }

  HomeMomentExpiryCleanupService(
      HomeDailyMomentRepository moments, MomentStorageService storage, Clock clock) {
    this.moments = moments;
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
}
