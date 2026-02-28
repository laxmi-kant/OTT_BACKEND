package com.ottnetwork.userservice.dto.request;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdatePreferenceRequest {

    private Boolean emailNotifications;
    private Boolean pushNotifications;
    private Boolean autoplayEnabled;

    @Size(max = 20)
    private String defaultVideoQuality;

    private Boolean subtitlesEnabled;

    @Size(max = 10)
    private String preferredLanguage;

    private Boolean parentalControlEnabled;

    @Size(max = 255)
    private String parentalControlPin;

    @Size(max = 10)
    private String maturityRating;
}
