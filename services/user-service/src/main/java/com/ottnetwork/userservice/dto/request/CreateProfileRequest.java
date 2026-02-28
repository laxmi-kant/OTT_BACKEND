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
public class CreateProfileRequest {

    @Size(max = 500)
    private String bio;

    @Size(max = 10)
    private String language;

    @Size(max = 100)
    private String country;

    @Size(max = 50)
    private String timezone;

    @Size(max = 512)
    private String profileImageUrl;
}
