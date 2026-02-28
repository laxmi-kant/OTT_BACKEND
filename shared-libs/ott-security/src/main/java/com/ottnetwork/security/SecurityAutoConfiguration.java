package com.ottnetwork.security;

import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Import;

@AutoConfiguration
@ConditionalOnProperty(name = "ott.security.enabled", havingValue = "true", matchIfMissing = true)
@Import(SecurityConfig.class)
@ComponentScan(basePackages = "com.ottnetwork.security")
public class SecurityAutoConfiguration {
}
