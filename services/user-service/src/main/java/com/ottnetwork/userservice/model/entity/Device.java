package com.ottnetwork.userservice.model.entity;

import com.ottnetwork.common.model.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "devices", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "device_id"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Device extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "device_id", nullable = false)
    private String deviceId;

    @Column(name = "device_name")
    private String deviceName;

    @Column(name = "device_type", length = 50)
    private String deviceType;

    @Column(length = 50)
    private String platform;

    @Column(name = "last_active_at")
    private LocalDateTime lastActiveAt;

    @Column(name = "push_token", length = 512)
    private String pushToken;
}
