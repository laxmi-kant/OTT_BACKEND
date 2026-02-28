package com.ottnetwork.common.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum UserRole {

    ADMIN("Admin"),
    CONTENT_MANAGER("Content Manager"),
    CONTENT_CREATOR("Content Creator"),
    SUBSCRIBER("Subscriber"),
    GUEST("Guest");

    private final String displayName;
}
