package com.ottnetwork.userservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = {
        "com.ottnetwork.userservice",
        "com.ottnetwork.common",
        "com.ottnetwork.security",
        "com.ottnetwork.kafka"
})
public class UserServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(UserServiceApplication.class, args);
    }
}
