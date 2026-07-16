package com.vencentdev.backend.config;

import java.util.Arrays;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig {

  @Bean
  @ConfigurationProperties(prefix = "app.cors")
  CorsProperties corsProperties() {
    return new CorsProperties();
  }

  @Bean
  WebMvcConfigurer corsConfigurer(CorsProperties corsProperties) {
    return new WebMvcConfigurer() {
      @Override
      public void addCorsMappings(CorsRegistry registry) {
        registry
            .addMapping("/**")
            .allowedOrigins(corsProperties.allowedOrigins().toArray(String[]::new))
            .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
            .allowedHeaders("*")
            .allowCredentials(true);
      }
    };
  }

  public static class CorsProperties {
    private String allowedOrigins = "http://localhost:3000";

    public List<String> allowedOrigins() {
      return Arrays.stream(allowedOrigins.split(","))
          .map(String::trim)
          .filter(origin -> !origin.isBlank())
          .toList();
    }

    public void setAllowedOrigins(String allowedOrigins) {
      this.allowedOrigins = allowedOrigins;
    }
  }
}
