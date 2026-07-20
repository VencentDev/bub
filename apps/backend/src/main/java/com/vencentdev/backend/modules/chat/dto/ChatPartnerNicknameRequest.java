package com.vencentdev.backend.modules.chat.dto;

import jakarta.validation.constraints.Size;

public record ChatPartnerNicknameRequest(@Size(max = 80) String nickname) {}
