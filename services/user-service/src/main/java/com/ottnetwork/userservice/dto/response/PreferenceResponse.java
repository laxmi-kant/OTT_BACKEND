package com.ottnetwork.userservice.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PreferenceResponse {

    private UUID id;
    private UUID userId;
    private boolean emailNotifications;
    private boolean pushNotifications;
    private boolean autoplayEnabled;
    private String defaultVideoQuality;
    private boolean subtitlesEnabled;
    private String preferredLanguage;
    private boolean parentalControlEnabled;
    private String maturityRating;
}
