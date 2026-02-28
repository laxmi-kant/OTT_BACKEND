package com.ottnetwork.userservice.service;

import com.ottnetwork.common.exception.ResourceNotFoundException;
import com.ottnetwork.userservice.dto.request.CreateProfileRequest;
import com.ottnetwork.userservice.dto.request.UpdateProfileRequest;
import com.ottnetwork.userservice.dto.response.ProfileResponse;
import com.ottnetwork.userservice.mapper.UserMapper;
import com.ottnetwork.userservice.model.entity.Profile;
import com.ottnetwork.userservice.model.entity.User;
import com.ottnetwork.userservice.repository.ProfileRepository;
import com.ottnetwork.userservice.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class ProfileService {

    private final ProfileRepository profileRepository;
    private final UserRepository userRepository;
    private final UserMapper userMapper;

    @Transactional(readOnly = true)
    public List<ProfileResponse> getProfilesByUserId(UUID userId) {
        return profileRepository.findByUserId(userId)
                .stream()
                .map(userMapper::toProfileResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public ProfileResponse getProfileById(UUID profileId) {
        Profile profile = profileRepository.findById(profileId)
                .orElseThrow(() -> new ResourceNotFoundException("Profile", "id", profileId));
        return userMapper.toProfileResponse(profile);
    }

    @Transactional
    public ProfileResponse createProfile(UUID userId, CreateProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        Profile profile = userMapper.toProfile(request);
        profile.setUser(user);

        profile = profileRepository.save(profile);

        log.info("Profile created: profileId={}, userId={}", profile.getId(), userId);
        return userMapper.toProfileResponse(profile);
    }

    @Transactional
    public ProfileResponse updateProfile(UUID profileId, UpdateProfileRequest request) {
        Profile profile = profileRepository.findById(profileId)
                .orElseThrow(() -> new ResourceNotFoundException("Profile", "id", profileId));

        if (request.getBio() != null) profile.setBio(request.getBio());
        if (request.getLanguage() != null) profile.setLanguage(request.getLanguage());
        if (request.getCountry() != null) profile.setCountry(request.getCountry());
        if (request.getTimezone() != null) profile.setTimezone(request.getTimezone());
        if (request.getProfileImageUrl() != null) profile.setProfileImageUrl(request.getProfileImageUrl());

        profile = profileRepository.save(profile);

        log.info("Profile updated: profileId={}", profileId);
        return userMapper.toProfileResponse(profile);
    }

    @Transactional
    public void deleteProfile(UUID profileId) {
        if (!profileRepository.existsById(profileId)) {
            throw new ResourceNotFoundException("Profile", "id", profileId);
        }
        profileRepository.deleteById(profileId);
        log.info("Profile deleted: profileId={}", profileId);
    }
}
