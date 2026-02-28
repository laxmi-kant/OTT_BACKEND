package com.ottnetwork.authservice.event;

import com.ottnetwork.kafka.EventPublisher;
import com.ottnetwork.kafka.KafkaTopics;
import com.ottnetwork.kafka.event.BaseEvent;
import com.ottnetwork.kafka.event.OtpRequestedEvent;
import com.ottnetwork.kafka.event.UserRegisteredEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class AuthEventProducer {

    private final EventPublisher eventPublisher;

    public void publishOtpRequested(String email, String phone, String otp, String channel, String purpose) {
        OtpRequestedEvent event = OtpRequestedEvent.builder()
                .email(email)
                .phone(phone)
                .otp(otp)
                .channel(channel)
                .purpose(purpose)
                .build();
        event.setEventType("OTP_REQUESTED");
        event.setSource("auth-service");

        eventPublisher.publish(KafkaTopics.OTP_REQUESTED, email, event);
    }

    public void publishUserRegistered(UUID userId, String email, String username, String role) {
        UserRegisteredEvent event = UserRegisteredEvent.builder()
                .userId(userId)
                .email(email)
                .username(username)
                .role(role)
                .build();
        event.setEventType("USER_REGISTERED");
        event.setSource("auth-service");

        eventPublisher.publish(KafkaTopics.USER_REGISTERED, userId.toString(), event);
    }

    public void publishLogin(UUID userId, String email) {
        BaseEvent event = new BaseEvent() {};
        event.setEventType("USER_LOGIN");
        event.setSource("auth-service");

        eventPublisher.publish(KafkaTopics.AUTH_LOGIN, userId.toString(), event);
    }
}
