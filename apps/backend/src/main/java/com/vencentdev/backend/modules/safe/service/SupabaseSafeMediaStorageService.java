package com.vencentdev.backend.modules.safe.service;

import com.vencentdev.backend.common.exception.StorageException;
import com.vencentdev.backend.modules.home.service.SupabaseMomentStorageService;
import java.net.URI;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.util.UriComponentsBuilder;

@Service
public class SupabaseSafeMediaStorageService implements SafeMediaStorageService {

  private static final Logger log = LoggerFactory.getLogger(SupabaseSafeMediaStorageService.class);

  private final RestClient restClient;
  private final String supabaseUrl;
  private final String bucket;
  private final String secretKey;

  public SupabaseSafeMediaStorageService(
      @Value("${app.supabase.url:}") String supabaseUrl,
      @Value("${app.supabase.storage.safe-bucket:}") String bucket,
      @Value("${app.supabase.secret-key:}") String secretKey) {
    this.restClient = RestClient.create();
    this.supabaseUrl = SupabaseMomentStorageService.normalizeSupabaseProjectUrl(supabaseUrl);
    this.bucket = bucket;
    this.secretKey = secretKey;
  }

  @Override
  public StoredSafeMedia uploadSafeMedia(
      UUID connectionId, UUID uploaderUserId, MultipartFile file) {
    requireConfigured();
    String contentType =
        StringUtils.hasText(file.getContentType())
            ? file.getContentType()
            : MediaType.APPLICATION_OCTET_STREAM_VALUE;
    String objectPath = objectPath(connectionId, uploaderUserId, file.getOriginalFilename());
    URI uploadUri =
        UriComponentsBuilder.fromUriString(supabaseUrl)
            .pathSegment("storage", "v1", "object", bucket)
            .path("/")
            .path(objectPath)
            .build()
            .toUri();

    try {
      ResponseEntity<Void> response =
          restClient
              .post()
              .uri(uploadUri)
              .header(HttpHeaders.AUTHORIZATION, "Bearer " + secretKey)
              .header("apikey", secretKey)
              .header("x-upsert", "false")
              .contentType(MediaType.parseMediaType(contentType))
              .body(file.getBytes())
              .retrieve()
              .toBodilessEntity();
      log.info(
          "Uploaded Safe media to Supabase Storage bucket={} path={} status={}",
          bucket,
          objectPath,
          response.getStatusCode());
    } catch (RestClientResponseException exception) {
      throw new StorageException(
          "Supabase Storage rejected the Safe media upload: HTTP %s %s"
              .formatted(exception.getStatusCode().value(), storageErrorMessage(exception)),
          exception);
    } catch (Exception exception) {
      throw new StorageException("Could not upload Safe media to Supabase Storage", exception);
    }

    return new StoredSafeMedia(publicUrl(objectPath), objectPath, contentType, file.getSize());
  }

  @Override
  public void deleteSafeMedia(String storageObjectPath) {
    requireConfigured();
    if (!StringUtils.hasText(storageObjectPath)) {
      return;
    }
    URI deleteUri =
        UriComponentsBuilder.fromUriString(supabaseUrl)
            .pathSegment("storage", "v1", "object", bucket)
            .path("/")
            .path(storageObjectPath)
            .build()
            .toUri();
    try {
      restClient
          .delete()
          .uri(deleteUri)
          .header(HttpHeaders.AUTHORIZATION, "Bearer " + secretKey)
          .header("apikey", secretKey)
          .retrieve()
          .toBodilessEntity();
    } catch (RestClientResponseException exception) {
      throw new StorageException(
          "Supabase Storage rejected the Safe media delete: HTTP %s %s"
              .formatted(exception.getStatusCode().value(), storageErrorMessage(exception)),
          exception);
    } catch (Exception exception) {
      throw new StorageException("Could not delete Safe media from Supabase Storage", exception);
    }
  }

  private void requireConfigured() {
    if (!StringUtils.hasText(supabaseUrl)
        || !StringUtils.hasText(bucket)
        || !StringUtils.hasText(secretKey)) {
      throw new StorageException(
          "Safe media storage is not configured. Set SUPABASE_URL, SUPABASE_SECRET_KEY, and SUPABASE_SAFE_BUCKET on the backend.");
    }
  }

  private String objectPath(UUID connectionId, UUID uploaderUserId, String originalFilename) {
    String extension = extension(originalFilename);
    return "safe/%s/%s/%s%s".formatted(connectionId, uploaderUserId, UUID.randomUUID(), extension);
  }

  private String extension(String filename) {
    if (!StringUtils.hasText(filename)) {
      return "";
    }
    String clean = filename.trim();
    int dot = clean.lastIndexOf('.');
    if (dot < 0 || dot == clean.length() - 1) {
      return "";
    }
    return clean.substring(dot).replaceAll("[^A-Za-z0-9.]", "");
  }

  private String publicUrl(String objectPath) {
    return UriComponentsBuilder.fromUriString(supabaseUrl)
        .pathSegment("storage", "v1", "object", "public", bucket)
        .path("/")
        .path(objectPath)
        .build()
        .toUriString();
  }

  private String storageErrorMessage(RestClientResponseException exception) {
    String body = exception.getResponseBodyAsString();
    if (!StringUtils.hasText(body)) {
      return exception.getStatusText();
    }
    return body.length() > 240 ? body.substring(0, 240) : body;
  }
}
