package com.vencentdev.backend.modules.auth.ratelimit;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class AuthRateLimitFilter extends OncePerRequestFilter {
  private final AuthRateLimitProperties properties;
  private final Clock clock;
  private final Map<String, TokenBucket> buckets = new ConcurrentHashMap<>();

  @Autowired
  public AuthRateLimitFilter(AuthRateLimitProperties properties) {
    this(properties, Clock.systemUTC());
  }

  AuthRateLimitFilter(AuthRateLimitProperties properties, Clock clock) {
    this.properties = properties;
    this.clock = clock;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    if (!properties.isEnabled() || !isLimitedEndpoint(request)) {
      filterChain.doFilter(request, response);
      return;
    }

    TokenBucket bucket =
        buckets.computeIfAbsent(
            clientKey(request),
            ignored ->
                new TokenBucket(
                    properties.getCapacity(),
                    properties.getRefillPeriod().toMillis(),
                    clock.millis()));

    if (bucket.tryConsume(clock.millis())) {
      filterChain.doFilter(request, response);
      return;
    }

    response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    response.setHeader("Retry-After", String.valueOf(properties.getRefillPeriod().toSeconds()));
    response
        .getWriter()
        .write(
            """
            {"status":429,"code":"RATE_LIMITED","message":"Too many requests","traceId":%s,"timestamp":"%s","errors":[]}
            """
                .formatted(jsonStringOrNull(MDC.get("traceId")), Instant.now(clock)));
  }

  private boolean isLimitedEndpoint(HttpServletRequest request) {
    String method = request.getMethod();
    String path = request.getRequestURI();
    return ("GET".equals(method) && "/api/v1/auth/me".equals(path))
        || ("PATCH".equals(method) && "/api/v1/users/me".equals(path));
  }

  private String clientKey(HttpServletRequest request) {
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    if (authentication != null && authentication.isAuthenticated()) {
      return "sub:" + authentication.getName();
    }

    return "ip:" + request.getRemoteAddr();
  }

  private String jsonStringOrNull(String value) {
    if (value == null) {
      return "null";
    }

    return "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
  }

  private static final class TokenBucket {
    private final int capacity;
    private final long refillPeriodMillis;
    private int tokens;
    private long refillAtMillis;

    private TokenBucket(int capacity, long refillPeriodMillis, long nowMillis) {
      this.capacity = Math.max(1, capacity);
      this.refillPeriodMillis = Math.max(1, refillPeriodMillis);
      this.tokens = this.capacity;
      this.refillAtMillis = nowMillis + this.refillPeriodMillis;
    }

    private synchronized boolean tryConsume(long nowMillis) {
      refillIfNeeded(nowMillis);
      if (tokens <= 0) {
        return false;
      }

      tokens--;
      return true;
    }

    private void refillIfNeeded(long nowMillis) {
      if (nowMillis < refillAtMillis) {
        return;
      }

      tokens = capacity;
      long elapsedPeriods = ((nowMillis - refillAtMillis) / refillPeriodMillis) + 1;
      refillAtMillis += elapsedPeriods * refillPeriodMillis;
    }
  }
}
