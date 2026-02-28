package com.ottnetwork.userservice.service;

import com.ottnetwork.common.exception.ResourceNotFoundException;
import com.ottnetwork.userservice.dto.request.RegisterDeviceRequest;
import com.ottnetwork.userservice.dto.response.DeviceResponse;
import com.ottnetwork.userservice.mapper.UserMapper;
import com.ottnetwork.userservice.model.entity.Device;
import com.ottnetwork.userservice.model.entity.User;
import com.ottnetwork.userservice.repository.DeviceRepository;
import com.ottnetwork.userservice.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class DeviceService {

    private final DeviceRepository deviceRepository;
    private final UserRepository userRepository;
    private final UserMapper userMapper;

    @Transactional(readOnly = true)
    public List<DeviceResponse> getDevicesByUserId(UUID userId) {
        return deviceRepository.findByUserId(userId)
                .stream()
                .map(userMapper::toDeviceResponse)
                .toList();
    }

    @Transactional
    public DeviceResponse registerDevice(UUID userId, RegisterDeviceRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        // Upsert: update if device already exists for this user
        Device device = deviceRepository.findByUserIdAndDeviceId(userId, request.getDeviceId())
                .orElseGet(() -> {
                    Device newDevice = userMapper.toDevice(request);
                    newDevice.setUser(user);
                    return newDevice;
                });

        device.setDeviceName(request.getDeviceName());
        device.setDeviceType(request.getDeviceType());
        device.setPlatform(request.getPlatform());
        device.setPushToken(request.getPushToken());
        device.setLastActiveAt(LocalDateTime.now());

        device = deviceRepository.save(device);

        log.info("Device registered: deviceId={}, userId={}", request.getDeviceId(), userId);
        return userMapper.toDeviceResponse(device);
    }

    @Transactional
    public void removeDevice(UUID userId, String deviceId) {
        Device device = deviceRepository.findByUserIdAndDeviceId(userId, deviceId)
                .orElseThrow(() -> new ResourceNotFoundException("Device", "deviceId", deviceId));
        deviceRepository.delete(device);
        log.info("Device removed: deviceId={}, userId={}", deviceId, userId);
    }
}
