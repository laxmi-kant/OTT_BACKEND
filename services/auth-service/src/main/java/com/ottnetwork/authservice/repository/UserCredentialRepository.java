package com.ottnetwork.authservice.repository;

import com.ottnetwork.authservice.model.entity.UserCredential;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserCredentialRepository extends JpaRepository<UserCredential, UUID> {

    Optional<UserCredential> findByEmail(String email);

    Optional<UserCredential> findByUsername(String username);

    boolean existsByEmail(String email);

    boolean existsByUsername(String username);
}
