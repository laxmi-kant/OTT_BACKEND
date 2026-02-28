package com.ottnetwork.userservice.service;

import com.ottnetwork.common.dto.PagedResponse;
import com.ottnetwork.common.exception.ResourceNotFoundException;
import com.ottnetwork.userservice.dto.request.UpdateUserRequest;
import com.ottnetwork.userservice.dto.response.UserResponse;
import com.ottnetwork.userservice.event.UserEventProducer;
import com.ottnetwork.userservice.mapper.UserMapper;
import com.ottnetwork.userservice.model.entity.Preference;
import com.ottnetwork.userservice.model.entity.User;
import com.ottnetwork.userservice.repository.PreferenceRepository;
import com.ottnetwork.userservice.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PreferenceRepository preferenceRepository;
    private final UserMapper userMapper;
    private final UserEventProducer userEventProducer;

    @Transactional(readOnly = true)
    public UserResponse getUserById(UUID userId) {
        User user = findUserOrThrow(userId);
        return userMapper.toUserResponse(user);
    }

    @Transactional(readOnly = true)
    public UserResponse getUserByAuthUserId(UUID authUserId) {
        User user = userRepository.findByAuthUserId(authUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "authUserId", authUserId));
        return userMapper.toUserResponse(user);
    }

    @Transactional(readOnly = true)
    public UserResponse getUserByEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        return userMapper.toUserResponse(user);
    }

    @Transactional(readOnly = true)
    public PagedResponse<UserResponse> getAllUsers(Pageable pageable) {
        Page<User> page = userRepository.findByActiveTrue(pageable);
        return toPagedResponse(page);
    }

    @Transactional
    public UserResponse updateUser(UUID userId, UpdateUserRequest request) {
        User user = findUserOrThrow(userId);

        if (request.getFirstName() != null) user.setFirstName(request.getFirstName());
        if (request.getLastName() != null) user.setLastName(request.getLastName());
        if (request.getDisplayName() != null) user.setDisplayName(request.getDisplayName());
        if (request.getAvatarUrl() != null) user.setAvatarUrl(request.getAvatarUrl());
        if (request.getPhone() != null) user.setPhone(request.getPhone());
        if (request.getDateOfBirth() != null) user.setDateOfBirth(request.getDateOfBirth());

        user = userRepository.save(user);

        userEventProducer.publishProfileUpdated(user.getId(), user.getEmail());

        log.info("User updated: userId={}", userId);
        return userMapper.toUserResponse(user);
    }

    @Transactional
    public void deactivateUser(UUID userId) {
        User user = findUserOrThrow(userId);
        user.setActive(false);
        userRepository.save(user);

        userEventProducer.publishUserDeleted(user.getId(), user.getEmail());

        log.info("User deactivated: userId={}", userId);
    }

    @Transactional
    public UserResponse createUserFromRegistration(UUID authUserId, String email, String username, String role) {
        if (userRepository.existsByAuthUserId(authUserId)) {
            log.warn("User already exists for authUserId={}", authUserId);
            return userMapper.toUserResponse(userRepository.findByAuthUserId(authUserId).orElseThrow());
        }

        User user = User.builder()
                .authUserId(authUserId)
                .email(email)
                .username(username)
                .displayName(username)
                .role(role)
                .subscriptionTier("FREE")
                .active(true)
                .build();
        user = userRepository.save(user);

        // Create default preferences
        Preference preference = Preference.builder()
                .user(user)
                .build();
        preferenceRepository.save(preference);

        log.info("User created from registration: userId={}, authUserId={}", user.getId(), authUserId);
        return userMapper.toUserResponse(user);
    }

    private User findUserOrThrow(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));
    }

    private PagedResponse<UserResponse> toPagedResponse(Page<User> page) {
        return PagedResponse.<UserResponse>builder()
                .content(page.getContent().stream().map(userMapper::toUserResponse).toList())
                .page(page.getNumber())
                .size(page.getSize())
                .totalElements(page.getTotalElements())
                .totalPages(page.getTotalPages())
                .last(page.isLast())
                .build();
    }
}
