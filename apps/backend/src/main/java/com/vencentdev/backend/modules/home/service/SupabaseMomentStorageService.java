package com.vencentdev.backend.modules.home.service;

import com.vencentdev.backend.common.exception.StorageException;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.net.URI;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import javax.imageio.ImageIO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.Nullable;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.util.UriComponentsBuilder;

@Service
public class SupabaseMomentStorageService implements MomentStorageService {

  private static final Logger log = LoggerFactory.getLogger(SupabaseMomentStorageService.class);
  private static final int MOMENT_IMAGE_SIZE = 1200;

  private final RestClient restClient;
  private final String supabaseUrl;
  private final String bucket;
  private final String secretKey;

  public SupabaseMomentStorageService(
      @Value("${app.supabase.url:}") String supabaseUrl,
      @Value("${app.supabase.storage.moments-bucket:}") String bucket,
      @Value("${app.supabase.secret-key:}") String secretKey) {
    this.restClient = RestClient.create();
    this.supabaseUrl = normalizeSupabaseProjectUrl(supabaseUrl);
    this.bucket = bucket;
    this.secretKey = secretKey;
  }

  @Override
  public StoredMomentPhoto uploadMoment(
      UUID tetherConnectionId, UUID userId, LocalDate localDate, MultipartFile photo) {
    if (!StringUtils.hasText(supabaseUrl)
        || !StringUtils.hasText(bucket)
        || !StringUtils.hasText(secretKey)) {
      throw new StorageException(
          "Moment storage is not configured. Set SUPABASE_URL, SUPABASE_SECRET_KEY, and SUPABASE_MOMENTS_BUCKET on the backend.");
    }

    String objectPath = objectPath(tetherConnectionId, userId, localDate);
    byte[] squareJpeg = squareJpeg(photo);
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
              .header("x-upsert", "true")
              .contentType(MediaType.IMAGE_JPEG)
              .body(squareJpeg)
              .retrieve()
              .toBodilessEntity();
      log.info(
          "Uploaded moment photo to Supabase Storage bucket={} path={} status={}",
          bucket,
          objectPath,
          response.getStatusCode());
    } catch (RestClientResponseException exception) {
      throw new StorageException(
          "Supabase Storage rejected the upload: HTTP %s %s"
              .formatted(exception.getStatusCode().value(), storageErrorMessage(exception)),
          exception);
    } catch (Exception exception) {
      throw new StorageException("Could not upload moment photo to Supabase Storage", exception);
    }

    return new StoredMomentPhoto(publicUrl(objectPath), objectPath);
  }

  @Override
  public void deleteMoment(String objectPath) {
    if (!StringUtils.hasText(objectPath)) {
      return;
    }
    if (!StringUtils.hasText(supabaseUrl)
        || !StringUtils.hasText(bucket)
        || !StringUtils.hasText(secretKey)) {
      throw new StorageException(
          "Moment storage is not configured. Set SUPABASE_URL, SUPABASE_SECRET_KEY, and SUPABASE_MOMENTS_BUCKET on the backend.");
    }

    URI deleteUri =
        UriComponentsBuilder.fromUriString(supabaseUrl)
            .pathSegment("storage", "v1", "object", bucket)
            .build()
            .toUri();
    try {
      ResponseEntity<String> response =
          restClient
              .method(org.springframework.http.HttpMethod.DELETE)
              .uri(deleteUri)
              .header(HttpHeaders.AUTHORIZATION, "Bearer " + secretKey)
              .header("apikey", secretKey)
              .contentType(MediaType.APPLICATION_JSON)
              .body(Map.of("prefixes", List.of(objectPath)))
              .retrieve()
              .toEntity(String.class);
      log.info(
          "Deleted moment photo from Supabase Storage bucket={} path={} status={}",
          bucket,
          objectPath,
          response.getStatusCode());
    } catch (RestClientResponseException exception) {
      throw new StorageException(
          "Supabase Storage rejected the delete: HTTP %s %s"
              .formatted(exception.getStatusCode().value(), storageErrorMessage(exception)),
          exception);
    } catch (Exception exception) {
      throw new StorageException("Could not delete moment photo from Supabase Storage", exception);
    }
  }

  private byte[] squareJpeg(MultipartFile photo) {
    try {
      BufferedImage source = ImageIO.read(new ByteArrayInputStream(photo.getBytes()));
      if (source == null) {
        throw new StorageException("Moment photo must be a valid image file");
      }

      int cropSize = Math.min(source.getWidth(), source.getHeight());
      int cropX = (source.getWidth() - cropSize) / 2;
      int cropY = (source.getHeight() - cropSize) / 2;
      BufferedImage output =
          new BufferedImage(MOMENT_IMAGE_SIZE, MOMENT_IMAGE_SIZE, BufferedImage.TYPE_INT_RGB);
      Graphics2D graphics = output.createGraphics();
      try {
        graphics.setRenderingHint(
            RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        graphics.setRenderingHint(
            RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        graphics.drawImage(
            source,
            0,
            0,
            MOMENT_IMAGE_SIZE,
            MOMENT_IMAGE_SIZE,
            cropX,
            cropY,
            cropX + cropSize,
            cropY + cropSize,
            null);
      } finally {
        graphics.dispose();
      }

      ByteArrayOutputStream bytes = new ByteArrayOutputStream();
      ImageIO.write(output, "jpg", bytes);
      return bytes.toByteArray();
    } catch (StorageException exception) {
      throw exception;
    } catch (Exception exception) {
      throw new StorageException("Could not prepare moment photo for upload", exception);
    }
  }

  private String objectPath(UUID tetherConnectionId, UUID userId, LocalDate localDate) {
    return "moments/%s/%s/%s/%s.jpg"
        .formatted(tetherConnectionId, userId, localDate, UUID.randomUUID());
  }

  private String publicUrl(String objectPath) {
    return UriComponentsBuilder.fromUriString(supabaseUrl)
        .pathSegment("storage", "v1", "object", "public", bucket)
        .path("/")
        .path(objectPath)
        .build()
        .toUriString();
  }

  static String normalizeSupabaseProjectUrl(@Nullable String value) {
    if (!StringUtils.hasText(value)) {
      return value;
    }
    String trimmed = trimTrailingSlash(value.trim());
    URI uri = URI.create(trimmed);
    String host = uri.getHost();
    if (host != null && host.endsWith(".storage.supabase.co")) {
      String projectRef = host.substring(0, host.length() - ".storage.supabase.co".length());
      return uri.getScheme() + "://" + projectRef + ".supabase.co";
    }
    int storagePathStart = trimmed.indexOf("/storage/v1");
    if (storagePathStart > 0) {
      return trimmed.substring(0, storagePathStart);
    }
    return trimmed;
  }

  private String storageErrorMessage(RestClientResponseException exception) {
    String body = exception.getResponseBodyAsString();
    if (!StringUtils.hasText(body)) {
      return exception.getStatusText();
    }
    return body.length() > 240 ? body.substring(0, 240) : body;
  }

  private static String trimTrailingSlash(String value) {
    if (value == null || !value.endsWith("/")) {
      return value;
    }
    return value.substring(0, value.length() - 1);
  }
}
