package com.ottnetwork.security;

import com.ottnetwork.common.exception.UnauthorizedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record AuthenticatedUser(UUID id, String email, List<String> roles) {

    @SuppressWarnings("unchecked")
    public static AuthenticatedUser fromSecurityContext() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new UnauthorizedException("User is not authenticated");
        }

        Object principal = authentication.getPrincipal();
        if (principal instanceof Map<?, ?> map) {
            return new AuthenticatedUser(
                    (UUID) map.get("id"),
                    (String) map.get("email"),
                    (List<String>) map.get("roles")
            );
        }

        throw new UnauthorizedException("Invalid authentication principal");
    }
}
