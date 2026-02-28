package com.ottnetwork.userservice.model.entity;

import com.ottnetwork.common.model.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "preferences")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Preference extends BaseEntity {

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "email_notifications", nullable = false)
    @Builder.Default
    private boolean emailNotifications = true;

    @Column(name = "push_notifications", nullable = false)
    @Builder.Default
    private boolean pushNotifications = true;

    @Column(name = "autoplay_enabled", nullable = false)
    @Builder.Default
    private boolean autoplayEnabled = true;

    @Column(name = "default_video_quality", nullable = false, length = 20)
    @Builder.Default
    private String defaultVideoQuality = "AUTO";

    @Column(name = "subtitles_enabled", nullable = false)
    @Builder.Default
    private boolean subtitlesEnabled = false;

    @Column(name = "preferred_language", nullable = false, length = 10)
    @Builder.Default
    private String preferredLanguage = "en";

    @Column(name = "parental_control_enabled", nullable = false)
    @Builder.Default
    private boolean parentalControlEnabled = false;

    @Column(name = "parental_control_pin")
    private String parentalControlPin;

    @Column(name = "maturity_rating", nullable = false, length = 10)
    @Builder.Default
    private String maturityRating = "ALL";
}
