package com.ottnetwork.userservice.event;

import com.ottnetwork.kafka.EventPublisher;
import com.ottnetwork.kafka.KafkaTopics;
import com.ottnetwork.kafka.event.BaseEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class UserEventProducer {

    private final EventPublisher eventPublisher;

    public void publishProfileUpdated(UUID userId, String email) {
        BaseEvent event = new BaseEvent() {};
        event.setEventType("USER_PROFILE_UPDATED");
        event.setSource("user-service");

        eventPublisher.publish(KafkaTopics.USER_PROFILE_UPDATED, userId.toString(), event);
    }

    public void publishUserDeleted(UUID userId, String email) {
        BaseEvent event = new BaseEvent() {};
        event.setEventType("USER_DELETED");
        event.setSource("user-service");

        eventPublisher.publish(KafkaTopics.USER_DELETED, userId.toString(), event);
    }
}
