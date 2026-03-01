package com.ottnetwork.authservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = {
        "com.ottnetwork.authservice",
        "com.ottnetwork.common",
        "com.ottnetwork.security",
        "com.ottnetwork.kafka"
})
public class AuthServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(AuthServiceApplication.class, args);
    }
}
