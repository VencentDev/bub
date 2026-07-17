package com.vencentdev.backend.modules.chat.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record ChatReadRequest(@NotNull UUID upToMessageId) {}
