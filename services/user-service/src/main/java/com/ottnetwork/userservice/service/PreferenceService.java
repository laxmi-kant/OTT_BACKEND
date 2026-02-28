package com.ottnetwork.userservice.service;

import com.ottnetwork.common.exception.ResourceNotFoundException;
import com.ottnetwork.userservice.dto.request.UpdatePreferenceRequest;
import com.ottnetwork.userservice.dto.response.PreferenceResponse;
import com.ottnetwork.userservice.mapper.UserMapper;
import com.ottnetwork.userservice.model.entity.Preference;
import com.ottnetwork.userservice.model.entity.User;
import com.ottnetwork.userservice.repository.PreferenceRepository;
import com.ottnetwork.userservice.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class PreferenceService {

    private final PreferenceRepository preferenceRepository;
    private final UserRepository userRepository;
    private final UserMapper userMapper;

    @Transactional(readOnly = true)
    public PreferenceResponse getPreferencesByUserId(UUID userId) {
        Preference preference = preferenceRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Preference", "userId", userId));
        return userMapper.toPreferenceResponse(preference);
    }

    @Transactional
    public PreferenceResponse updatePreferences(UUID userId, UpdatePreferenceRequest request) {
        Preference preference = preferenceRepository.findByUserId(userId)
                .orElseGet(() -> {
                    User user = userRepository.findById(userId)
                            .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));
                    return Preference.builder().user(user).build();
                });

        if (request.getEmailNotifications() != null) preference.setEmailNotifications(request.getEmailNotifications());
        if (request.getPushNotifications() != null) preference.setPushNotifications(request.getPushNotifications());
        if (request.getAutoplayEnabled() != null) preference.setAutoplayEnabled(request.getAutoplayEnabled());
        if (request.getDefaultVideoQuality() != null) preference.setDefaultVideoQuality(request.getDefaultVideoQuality());
        if (request.getSubtitlesEnabled() != null) preference.setSubtitlesEnabled(request.getSubtitlesEnabled());
        if (request.getPreferredLanguage() != null) preference.setPreferredLanguage(request.getPreferredLanguage());
        if (request.getParentalControlEnabled() != null) preference.setParentalControlEnabled(request.getParentalControlEnabled());
        if (request.getParentalControlPin() != null) preference.setParentalControlPin(request.getParentalControlPin());
        if (request.getMaturityRating() != null) preference.setMaturityRating(request.getMaturityRating());

        preference = preferenceRepository.save(preference);

        log.info("Preferences updated: userId={}", userId);
        return userMapper.toPreferenceResponse(preference);
    }
}
