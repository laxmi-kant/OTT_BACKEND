package com.ottnetwork.userservice.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterDeviceRequest {

    @NotBlank
    @Size(max = 255)
    private String deviceId;

    @Size(max = 255)
    private String deviceName;

    @Size(max = 50)
    private String deviceType;

    @Size(max = 50)
    private String platform;

    @Size(max = 512)
    private String pushToken;
}
