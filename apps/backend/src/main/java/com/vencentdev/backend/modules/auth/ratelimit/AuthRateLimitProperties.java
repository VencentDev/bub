package com.vencentdev.backend.modules.auth.ratelimit;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.rate-limit.auth")
public class AuthRateLimitProperties {
  private boolean enabled = true;
  private int capacity = 60;
  private Duration refillPeriod = Duration.ofMinutes(1);

  public boolean isEnabled() {
    return enabled;
  }

  public void setEnabled(boolean enabled) {
    this.enabled = enabled;
  }

  public int getCapacity() {
    return capacity;
  }

  public void setCapacity(int capacity) {
    this.capacity = capacity;
  }

  public Duration getRefillPeriod() {
    return refillPeriod;
  }

  public void setRefillPeriod(Duration refillPeriod) {
    this.refillPeriod = refillPeriod;
  }
}
