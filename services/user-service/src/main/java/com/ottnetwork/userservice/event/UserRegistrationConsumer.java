package com.ottnetwork.userservice.event;

import com.ottnetwork.kafka.KafkaTopics;
import com.ottnetwork.kafka.event.UserRegisteredEvent;
import com.ottnetwork.userservice.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class UserRegistrationConsumer {

    private final UserService userService;

    @KafkaListener(
            topics = KafkaTopics.USER_REGISTERED,
            groupId = "user-service-group",
            containerFactory = "kafkaListenerContainerFactory"
    )
    public void handleUserRegistered(UserRegisteredEvent event) {
        log.info("Received UserRegisteredEvent: userId={}, email={}", event.getUserId(), event.getEmail());

        try {
            userService.createUserFromRegistration(
                    event.getUserId(),
                    event.getEmail(),
                    event.getUsername(),
                    event.getRole()
            );
            log.info("User record created from registration event: authUserId={}", event.getUserId());
        } catch (Exception e) {
            log.error("Failed to process UserRegisteredEvent: userId={}", event.getUserId(), e);
            throw e;
        }
    }
}
