package com.ottnetwork.userservice.repository;

import com.ottnetwork.userservice.model.entity.Device;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DeviceRepository extends JpaRepository<Device, UUID> {

    List<Device> findByUserId(UUID userId);

    Optional<Device> findByUserIdAndDeviceId(UUID userId, String deviceId);

    void deleteByUserIdAndDeviceId(UUID userId, String deviceId);
}
