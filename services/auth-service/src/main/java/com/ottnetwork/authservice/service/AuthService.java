package com.ottnetwork.authservice.service;

import com.ottnetwork.authservice.dto.request.*;
import com.ottnetwork.authservice.dto.response.AuthResponse;
import com.ottnetwork.authservice.dto.response.OtpResponse;
import com.ottnetwork.authservice.event.AuthEventProducer;
import com.ottnetwork.authservice.exception.AuthenticationException;
import com.ottnetwork.authservice.model.entity.RefreshToken;
import com.ottnetwork.authservice.model.entity.UserCredential;
import com.ottnetwork.authservice.repository.RefreshTokenRepository;
import com.ottnetwork.authservice.repository.UserCredentialRepository;
import com.ottnetwork.common.exception.DuplicateResourceException;
import com.ottnetwork.common.exception.ResourceNotFoundException;
import com.ottnetwork.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Date;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserCredentialRepository userCredentialRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final OtpService otpService;
    private final TokenBlacklistService tokenBlacklistService;
    private final JwtTokenProvider jwtTokenProvider;
    private final AuthEventProducer authEventProducer;

    @Transactional
    public OtpResponse initiateRegistration(RegisterRequest request) {
        if (userCredentialRepository.existsByEmail(request.getEmail())) {
            throw new DuplicateResourceException("User", "email", request.getEmail());
        }
        if (userCredentialRepository.existsByUsername(request.getUsername())) {
            throw new DuplicateResourceException("User", "username", request.getUsername());
        }

        // Create unverified user credential
        UserCredential user = UserCredential.builder()
                .email(request.getEmail())
                .username(request.getUsername())
                .role("SUBSCRIBER")
                .enabled(true)
                .emailVerified(false)
                .build();
        userCredentialRepository.save(user);

        // Generate and send OTP
        otpService.generateAndSendOtp(request.getEmail(), "REGISTER");

        return OtpResponse.builder()
                .message("OTP sent to " + request.getEmail())
                .otpExpiresInSeconds(otpService.getOtpTtlSeconds())
                .retryAfterSeconds(otpService.getOtpTtlSeconds())
                .build();
    }

    public OtpResponse initiateLogin(LoginRequest request) {
        UserCredential user = userCredentialRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", request.getEmail()));

        if (!user.isEnabled()) {
            throw new AuthenticationException("Account is disabled");
        }

        // Generate and send OTP
        otpService.generateAndSendOtp(request.getEmail(), "LOGIN");

        return OtpResponse.builder()
                .message("OTP sent to " + request.getEmail())
                .otpExpiresInSeconds(otpService.getOtpTtlSeconds())
                .retryAfterSeconds(otpService.getOtpTtlSeconds())
                .build();
    }

    @Transactional
    public AuthResponse verifyOtpAndAuthenticate(VerifyOtpRequest request) {
        // Verify OTP
        otpService.verifyOtp(request.getEmail(), request.getOtp());

        // Find user
        UserCredential user = userCredentialRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", request.getEmail()));

        // Mark email as verified if this is a registration verification
        boolean isNewRegistration = !user.isEmailVerified();
        if (isNewRegistration) {
            user.setEmailVerified(true);
        }

        // Update last login
        user.setLastLoginAt(LocalDateTime.now());
        userCredentialRepository.save(user);

        // Generate tokens
        AuthResponse authResponse = generateAuthResponse(user);

        // Publish events
        if (isNewRegistration) {
            authEventProducer.publishUserRegistered(
                    user.getId(), user.getEmail(), user.getUsername(), user.getRole());
        }
        authEventProducer.publishLogin(user.getId(), user.getEmail());

        log.info("User authenticated: userId={}, isNewRegistration={}", user.getId(), isNewRegistration);
        return authResponse;
    }

    public OtpResponse resendOtp(ResendOtpRequest request) {
        UserCredential user = userCredentialRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", request.getEmail()));

        if (!user.isEnabled()) {
            throw new AuthenticationException("Account is disabled");
        }

        otpService.generateAndSendOtp(request.getEmail(), request.getPurpose());

        return OtpResponse.builder()
                .message("OTP resent to " + request.getEmail())
                .otpExpiresInSeconds(otpService.getOtpTtlSeconds())
                .retryAfterSeconds(otpService.getOtpTtlSeconds())
                .build();
    }

    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        RefreshToken storedToken = refreshTokenRepository.findByToken(request.getRefreshToken())
                .orElseThrow(() -> new AuthenticationException("Invalid refresh token"));

        if (storedToken.isRevoked()) {
            throw new AuthenticationException("Refresh token has been revoked");
        }

        if (storedToken.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new AuthenticationException("Refresh token has expired");
        }

        // Revoke old refresh token
        storedToken.setRevoked(true);
        refreshTokenRepository.save(storedToken);

        // Find user and issue new tokens
        UserCredential user = userCredentialRepository.findById(storedToken.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", storedToken.getUserId()));

        return generateAuthResponse(user);
    }

    @Transactional
    public void logout(String accessToken) {
        if (accessToken != null && jwtTokenProvider.validateToken(accessToken)) {
            // Blacklist access token
            Date expiration = jwtTokenProvider.getExpirationFromToken(accessToken);
            long ttl = expiration.getTime() - System.currentTimeMillis();
            if (ttl > 0) {
                tokenBlacklistService.blacklistToken(accessToken, ttl);
            }

            // Revoke all refresh tokens for this user
            var userId = jwtTokenProvider.getUserIdFromToken(accessToken);
            refreshTokenRepository.revokeAllByUserId(userId);

            log.info("User logged out: userId={}", userId);
        }
    }

    private AuthResponse generateAuthResponse(UserCredential user) {
        String accessToken = jwtTokenProvider.generateAccessToken(
                user.getId(), user.getEmail(), List.of(user.getRole()));
        String refreshTokenStr = jwtTokenProvider.generateRefreshToken(user.getId());

        // Persist refresh token
        RefreshToken refreshToken = RefreshToken.builder()
                .userId(user.getId())
                .token(refreshTokenStr)
                .expiresAt(LocalDateTime.now().plusDays(7))
                .revoked(false)
                .build();
        refreshTokenRepository.save(refreshToken);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshTokenStr)
                .tokenType("Bearer")
                .expiresIn(jwtTokenProvider.getAccessTokenExpirationMs() / 1000)
                .userId(user.getId())
                .email(user.getEmail())
                .role(user.getRole())
                .build();
    }
}
