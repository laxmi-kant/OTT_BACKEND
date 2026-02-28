package com.ottnetwork.authservice.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OtpResponse {

    private String message;
    private int otpExpiresInSeconds;
    private int retryAfterSeconds;
}
