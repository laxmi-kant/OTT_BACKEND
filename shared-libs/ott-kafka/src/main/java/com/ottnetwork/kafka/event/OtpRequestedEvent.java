package com.ottnetwork.kafka.event;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OtpRequestedEvent extends BaseEvent {

    private String email;
    private String phone;
    private String otp;
    private String channel;   // EMAIL or SMS
    private String purpose;   // REGISTER or LOGIN
}
