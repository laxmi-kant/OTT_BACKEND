package com.ottnetwork.userservice.model.entity;

import com.ottnetwork.common.model.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Profile extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(length = 500)
    private String bio;

    @Column(length = 10)
    @Builder.Default
    private String language = "en";

    @Column(length = 100)
    private String country;

    @Column(length = 50)
    private String timezone;

    @Column(name = "profile_image_url", length = 512)
    private String profileImageUrl;
}
