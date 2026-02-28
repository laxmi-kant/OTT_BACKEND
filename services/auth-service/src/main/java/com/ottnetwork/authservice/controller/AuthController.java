package com.ottnetwork.authservice.controller;

import com.ottnetwork.authservice.dto.request.*;
import com.ottnetwork.authservice.dto.response.AuthResponse;
import com.ottnetwork.authservice.dto.response.OtpResponse;
import com.ottnetwork.authservice.service.AuthService;
import com.ottnetwork.common.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "OTP-based registration, login, and token management")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @Operation(summary = "Register a new user and send OTP")
    public ResponseEntity<ApiResponse<OtpResponse>> register(@Valid @RequestBody RegisterRequest request) {
        OtpResponse response = authService.initiateRegistration(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "Registration initiated. Please verify OTP."));
    }

    @PostMapping("/login")
    @Operation(summary = "Login with email and receive OTP")
    public ResponseEntity<ApiResponse<OtpResponse>> login(@Valid @RequestBody LoginRequest request) {
        OtpResponse response = authService.initiateLogin(request);
        return ResponseEntity.ok(ApiResponse.success(response, "OTP sent. Please verify to login."));
    }

    @PostMapping("/verify-otp")
    @Operation(summary = "Verify OTP and receive JWT tokens")
    public ResponseEntity<ApiResponse<AuthResponse>> verifyOtp(@Valid @RequestBody VerifyOtpRequest request) {
        AuthResponse response = authService.verifyOtpAndAuthenticate(request);
        return ResponseEntity.ok(ApiResponse.success(response, "Authentication successful"));
    }

    @PostMapping("/resend-otp")
    @Operation(summary = "Resend OTP to email")
    public ResponseEntity<ApiResponse<OtpResponse>> resendOtp(@Valid @RequestBody ResendOtpRequest request) {
        OtpResponse response = authService.resendOtp(request);
        return ResponseEntity.ok(ApiResponse.success(response, "OTP resent"));
    }

    @PostMapping("/refresh")
    @Operation(summary = "Refresh access token using refresh token")
    public ResponseEntity<ApiResponse<AuthResponse>> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        AuthResponse response = authService.refreshToken(request);
        return ResponseEntity.ok(ApiResponse.success(response, "Token refreshed"));
    }

    @PostMapping("/logout")
    @Operation(summary = "Logout and invalidate tokens")
    public ResponseEntity<ApiResponse<Void>> logout(@RequestHeader("Authorization") String authHeader) {
        String token = null;
        if (StringUtils.hasText(authHeader) && authHeader.startsWith("Bearer ")) {
            token = authHeader.substring(7);
        }
        authService.logout(token);
        return ResponseEntity.ok(ApiResponse.success(null, "Logged out successfully"));
    }
}
