package com.ottnetwork.userservice.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DeviceResponse {

    private UUID id;
    private String deviceId;
    private String deviceName;
    private String deviceType;
    private String platform;
    private LocalDateTime lastActiveAt;
    private String pushToken;
    private LocalDateTime createdAt;
}
