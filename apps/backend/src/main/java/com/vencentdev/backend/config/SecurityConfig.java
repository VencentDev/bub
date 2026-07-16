package com.vencentdev.backend.config;

import com.vencentdev.backend.modules.auth.oauth.OAuthProviderAuthenticationFilter;
import com.vencentdev.backend.modules.auth.ratelimit.AuthRateLimitFilter;
import com.vencentdev.backend.modules.auth.ratelimit.AuthRateLimitProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableMethodSecurity
@EnableConfigurationProperties(AuthRateLimitProperties.class)
public class SecurityConfig {

  @Bean
  SecurityFilterChain securityFilterChain(
      HttpSecurity http,
      OAuthProviderAuthenticationFilter oauthProviderAuthenticationFilter,
      AuthRateLimitFilter authRateLimitFilter)
      throws Exception {
    return http.csrf(csrf -> csrf.disable())
        .cors(Customizer.withDefaults())
        .sessionManagement(
            session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .exceptionHandling(
            exceptions ->
                exceptions.authenticationEntryPoint(
                    new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
        .authorizeHttpRequests(
            authorize ->
                authorize
                    .requestMatchers(
                        "/actuator/health",
                        "/actuator/info",
                        "/v3/api-docs",
                        "/v3/api-docs/**",
                        "/swagger-ui.html",
                        "/swagger-ui/**")
                    .permitAll()
                    .anyRequest()
                    .authenticated())
        .addFilterBefore(
            oauthProviderAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
        .addFilterAfter(authRateLimitFilter, OAuthProviderAuthenticationFilter.class)
        .build();
  }
}
