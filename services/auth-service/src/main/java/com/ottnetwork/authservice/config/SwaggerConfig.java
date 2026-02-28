package com.ottnetwork.authservice.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI authServiceOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("OTT Auth Service API")
                        .description("OTP-based authentication, JWT token management, and OAuth2 provider linkage")
                        .version("1.0.0"));
    }
}
