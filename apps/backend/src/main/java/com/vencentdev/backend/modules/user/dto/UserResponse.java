package com.vencentdev.backend.modules.user.dto;

import com.vencentdev.backend.modules.user.enums.KycStatus;
import com.vencentdev.backend.modules.user.enums.Role;
import com.vencentdev.backend.modules.user.enums.ThemeMode;
import com.vencentdev.backend.modules.user.enums.UserType;
import java.time.Instant;
import java.util.UUID;

public record UserResponse(
    UUID id,
    String email,
    String displayName,
    Role role,
    UserType userType,
    KycStatus kycStatus,
    ThemeMode themeMode,
    String language,
    Instant createdAt,
    Instant updatedAt) {}
