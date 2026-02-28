package com.ottnetwork.authservice.exception;

import lombok.Getter;

@Getter
public class OtpException extends RuntimeException {

    private final OtpErrorType errorType;

    public OtpException(OtpErrorType errorType, String message) {
        super(message);
        this.errorType = errorType;
    }

    public enum OtpErrorType {
        EXPIRED,
        INVALID,
        RATE_LIMITED,
        MAX_ATTEMPTS_EXCEEDED
    }
}
