package com.ottnetwork.kafka.event;

import lombok.*;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserRegisteredEvent extends BaseEvent {

    private UUID userId;
    private String email;
    private String username;
    private String role;
}
