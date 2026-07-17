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
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/home")
public class HomeController {

  private final HomeService homeService;

  public HomeController(HomeService homeService) {
    this.homeService = homeService;
  }

  @GetMapping("/dashboard")
  @Operation(operationId = "getHomeDashboard")
  public HomeDashboardResponse dashboard(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user) {
    return homeService.dashboard(user);
  }

  @PutMapping("/today-moment")
  @Operation(operationId = "putTodayMoment")
  public HomeTodayMomentResponse putTodayMoment(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user,
      @Valid @RequestBody HomeTodayMomentRequest request) {
    return homeService.upsertTodayMoment(user, request);
  }

  @PostMapping(value = "/today-moment/photo", consumes = "multipart/form-data")
  @Operation(operationId = "uploadTodayMomentPhoto")
  public HomeTodayMomentResponse uploadTodayMomentPhoto(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user,
      @RequestPart("file") MultipartFile file) {
    return homeService.uploadTodayMomentPhoto(user, file);
  }

  @PostMapping("/today-moment/{momentId}/reaction")
  @Operation(operationId = "reactToTodayMoment")
  public HomeTodayMomentResponse reactToMoment(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user,
      @PathVariable UUID momentId,
      @Valid @RequestBody HomeMomentReactionRequest request) {
    return homeService.reactToMoment(user, momentId, request);
  }

  @PutMapping("/mood")
  @Operation(operationId = "putMood")
  public HomeMoodSummaryResponse putMood(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user,
      @Valid @RequestBody HomeMoodRequest request) {
    return homeService.putMood(user, request);
  }
}
