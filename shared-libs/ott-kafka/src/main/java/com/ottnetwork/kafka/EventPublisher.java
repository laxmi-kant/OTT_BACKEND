package com.ottnetwork.kafka;

import com.ottnetwork.kafka.event.BaseEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Component;

import java.util.concurrent.CompletableFuture;

@Slf4j
@Component
@RequiredArgsConstructor
public class EventPublisher {

    private final KafkaTemplate<String, Object> kafkaTemplate;

    public void publish(String topic, String key, BaseEvent event) {
        event.initDefaults();
        kafkaTemplate.send(topic, key, event)
                .whenComplete((result, ex) -> {
                    if (ex != null) {
                        log.error("Failed to publish event to topic={}, key={}: {}",
                                topic, key, ex.getMessage());
                    } else {
                        log.info("Published event to topic={}, key={}, offset={}",
                                topic, key, result.getRecordMetadata().offset());
                    }
                });
    }

    public CompletableFuture<SendResult<String, Object>> publishAsync(String topic, String key, BaseEvent event) {
        event.initDefaults();
        return kafkaTemplate.send(topic, key, event);
    }
}
