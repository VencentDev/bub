package com.vencentdev.backend.modules.home.dto;

public record HomeDashboardResponse(
    HomeTetherCardResponse tether,
    HomeTodayMomentResponse todayMoment,
    HomeLatestBubResponse latestBub,
    HomeSafeSummaryResponse safe) {}
