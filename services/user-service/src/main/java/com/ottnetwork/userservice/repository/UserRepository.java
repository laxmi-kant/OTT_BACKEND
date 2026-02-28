package com.ottnetwork.userservice.repository;

import com.ottnetwork.userservice.model.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByAuthUserId(UUID authUserId);

    Optional<User> findByEmail(String email);

    Optional<User> findByUsername(String username);

    boolean existsByEmail(String email);

    boolean existsByUsername(String username);

    boolean existsByAuthUserId(UUID authUserId);

    Page<User> findByActiveTrue(Pageable pageable);

    Page<User> findByRole(String role, Pageable pageable);

    Page<User> findBySubscriptionTier(String subscriptionTier, Pageable pageable);
}
