package com.ottnetwork.common.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum SubscriptionTier {

    FREE(0),
    BASIC(1),
    STANDARD(2),
    PREMIUM(3);

    private final int level;
}
