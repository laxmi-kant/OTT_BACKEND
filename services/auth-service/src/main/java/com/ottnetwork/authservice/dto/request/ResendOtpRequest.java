package com.ottnetwork.authservice.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ResendOtpRequest {

    @NotBlank(message = "Email is required")
    private String email;

    @NotBlank(message = "Purpose is required (REGISTER or LOGIN)")
    private String purpose;
}
