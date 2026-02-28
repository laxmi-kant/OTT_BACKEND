package com.ottnetwork.authservice.service;

import com.ottnetwork.authservice.exception.OtpException;
import com.ottnetwork.authservice.exception.OtpException.OtpErrorType;
import com.ottnetwork.authservice.event.AuthEventProducer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class OtpService {

    private static final String OTP_PREFIX = "otp:";
    private static final String OTP_ATTEMPTS_PREFIX = "otp_attempts:";
    private static final String OTP_RATE_PREFIX = "otp_rate:";
    private static final SecureRandom RANDOM = new SecureRandom();

    private final RedisTemplate<String, String> redisTemplate;
    private final PasswordEncoder passwordEncoder;
    private final AuthEventProducer authEventProducer;

    @Value("${otp.length:6}")
    private int otpLength;

    @Value("${otp.ttl-seconds:300}")
    private int otpTtlSeconds;

    @Value("${otp.max-requests-per-window:3}")
    private int maxRequestsPerWindow;

    @Value("${otp.max-verify-attempts:5}")
    private int maxVerifyAttempts;

    @Value("${otp.rate-limit-window-seconds:900}")
    private int rateLimitWindowSeconds;

    public void generateAndSendOtp(String email, String purpose) {
        checkRateLimit(email);

        String otp = generateOtp();
        String hashedOtp = passwordEncoder.encode(otp);

        // Store hashed OTP in Redis with TTL
        String otpKey = OTP_PREFIX + email;
        redisTemplate.opsForValue().set(otpKey, hashedOtp, otpTtlSeconds, TimeUnit.SECONDS);

        // Reset attempt counter
        String attemptsKey = OTP_ATTEMPTS_PREFIX + email;
        redisTemplate.delete(attemptsKey);

        // Increment rate limit counter
        String rateKey = OTP_RATE_PREFIX + email;
        redisTemplate.opsForValue().increment(rateKey);
        redisTemplate.expire(rateKey, rateLimitWindowSeconds, TimeUnit.SECONDS);

        // Publish event for notification-service to deliver the OTP
        String channel = email.contains("@") ? "EMAIL" : "SMS";
        authEventProducer.publishOtpRequested(email, null, otp, channel, purpose);

        log.info("OTP generated and event published for email={}, purpose={}", email, purpose);
    }

    public boolean verifyOtp(String email, String otp) {
        String otpKey = OTP_PREFIX + email;
        String attemptsKey = OTP_ATTEMPTS_PREFIX + email;

        // Check if OTP exists (not expired)
        String storedHash = redisTemplate.opsForValue().get(otpKey);
        if (storedHash == null) {
            throw new OtpException(OtpErrorType.EXPIRED, "OTP has expired or was not requested");
        }

        // Check attempt count
        String attemptsStr = redisTemplate.opsForValue().get(attemptsKey);
        int attempts = attemptsStr != null ? Integer.parseInt(attemptsStr) : 0;
        if (attempts >= maxVerifyAttempts) {
            redisTemplate.delete(otpKey);
            redisTemplate.delete(attemptsKey);
            throw new OtpException(OtpErrorType.MAX_ATTEMPTS_EXCEEDED,
                    "Maximum OTP verification attempts exceeded. Please request a new OTP.");
        }

        // Increment attempts
        redisTemplate.opsForValue().increment(attemptsKey);
        redisTemplate.expire(attemptsKey, otpTtlSeconds, TimeUnit.SECONDS);

        // Verify OTP
        if (!passwordEncoder.matches(otp, storedHash)) {
            int remaining = maxVerifyAttempts - attempts - 1;
            throw new OtpException(OtpErrorType.INVALID,
                    String.format("Invalid OTP. %d attempt(s) remaining.", remaining));
        }

        // OTP is valid — clean up
        redisTemplate.delete(otpKey);
        redisTemplate.delete(attemptsKey);

        return true;
    }

    public int getOtpTtlSeconds() {
        return otpTtlSeconds;
    }

    private void checkRateLimit(String email) {
        String rateKey = OTP_RATE_PREFIX + email;
        String countStr = redisTemplate.opsForValue().get(rateKey);
        int count = countStr != null ? Integer.parseInt(countStr) : 0;

        if (count >= maxRequestsPerWindow) {
            Long ttl = redisTemplate.getExpire(rateKey, TimeUnit.SECONDS);
            throw new OtpException(OtpErrorType.RATE_LIMITED,
                    String.format("Too many OTP requests. Try again in %d seconds.",
                            ttl != null ? ttl : rateLimitWindowSeconds));
        }
    }

    private String generateOtp() {
        int bound = (int) Math.pow(10, otpLength);
        int otp = RANDOM.nextInt(bound);
        return String.format("%0" + otpLength + "d", otp);
    }
}
