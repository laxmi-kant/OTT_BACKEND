package com.ottnetwork.authservice.repository;

import com.ottnetwork.authservice.model.entity.OAuthProvider;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OAuthProviderRepository extends JpaRepository<OAuthProvider, UUID> {

    Optional<OAuthProvider> findByProviderAndProviderUserId(String provider, String providerUserId);

    List<OAuthProvider> findByUserId(UUID userId);
}
