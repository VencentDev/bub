package com.vencentdev.backend.modules.home.service;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class SupabaseMomentStorageServiceTest {

  @Test
  void normalizesSupabaseProjectUrl() {
    assertThat(
            SupabaseMomentStorageService.normalizeSupabaseProjectUrl(
                "https://bwcfulrsyuppkejmiwpr.supabase.co"))
        .isEqualTo("https://bwcfulrsyuppkejmiwpr.supabase.co");
  }

  @Test
  void normalizesSupabaseS3StorageUrlToProjectUrl() {
    assertThat(
            SupabaseMomentStorageService.normalizeSupabaseProjectUrl(
                "https://bwcfulrsyuppkejmiwpr.storage.supabase.co/storage/v1/s3"))
        .isEqualTo("https://bwcfulrsyuppkejmiwpr.supabase.co");
  }
}
