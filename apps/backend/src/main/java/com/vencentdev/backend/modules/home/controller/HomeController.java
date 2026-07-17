package com.vencentdev.backend.modules.home.controller;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.auth.CurrentUser;
import com.vencentdev.backend.modules.home.dto.HomeDashboardResponse;
import com.vencentdev.backend.modules.home.dto.HomeMomentReactionRequest;
import com.vencentdev.backend.modules.home.dto.HomeMoodRequest;
import com.vencentdev.backend.modules.home.dto.HomeMoodSummaryResponse;
import com.vencentdev.backend.modules.home.dto.HomeTodayMomentRequest;
import com.vencentdev.backend.modules.home.dto.HomeTodayMomentResponse;
import com.vencentdev.backend.modules.home.service.HomeService;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/home")
public class HomeController {

  private final HomeService homeService;

  public HomeController(HomeService homeService) {
    this.homeService = homeService;
  }

  @GetMapping("/dashboard")
  public HomeDashboardResponse dashboard(@CurrentUser AuthenticatedUser user) {
    return homeService.dashboard(user);
  }

  @PutMapping("/today-moment")
  public HomeTodayMomentResponse putTodayMoment(
      @CurrentUser AuthenticatedUser user, @Valid @RequestBody HomeTodayMomentRequest request) {
    return homeService.upsertTodayMoment(user, request);
  }

  @PostMapping("/today-moment/{momentId}/reaction")
  public HomeTodayMomentResponse reactToMoment(
      @CurrentUser AuthenticatedUser user,
      @PathVariable UUID momentId,
      @Valid @RequestBody HomeMomentReactionRequest request) {
    return homeService.reactToMoment(user, momentId, request);
  }

  @PutMapping("/mood")
  public HomeMoodSummaryResponse putMood(
      @CurrentUser AuthenticatedUser user, @Valid @RequestBody HomeMoodRequest request) {
    return homeService.putMood(user, request);
  }
}
