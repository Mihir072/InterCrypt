package com.intelcrypt.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * OpenAPI Configuration.
 * 
 * Configures Swagger UI and OpenAPI documentation for the IntelCrypt API.
 */
@Configuration
public class OpenApiConfig {
    
    @Bean
    public OpenAPI intelCryptOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("IntelCrypt API")
                .description("""
                    # IntelCrypt - Extended AES-Based Secure Messaging & Data Vault Platform
                    
                    ## Overview
                    IntelCrypt provides military-grade end-to-end encrypted messaging with:
                    - **Extended AES Encryption**: 128/192/256-bit keys with GCM/CBC/CTR/XTS modes
                    - **Hybrid Encryption**: AES for content, RSA/ECC for key exchange
                    - **Multi-Round Encryption**: Iterative encryption layers for defense in depth
                    - **Zero-Knowledge Architecture**: Private keys never leave client devices
                    
                    ## Security Features
                    - JWT-based authentication with role-based access control
                    - Argon2id password hashing
                    - Rate limiting and intrusion detection
                    - Tamper-resistant audit logging with HMAC chain
                    - Message expiration and secure deletion
                    
                    ## Classification Levels
                    - `UNCLASSIFIED`: Standard messages
                    - `CONFIDENTIAL`: Business sensitive
                    - `SECRET`: Highly restricted access
                    - `TOP_SECRET`: Maximum security clearance required
                    """)
                .version("1.0.0")
                .contact(new Contact()
                    .name("IntelCrypt Security Team")
                    .email("security@intelcrypt.local"))
                .license(new License()
                    .name("Proprietary")
                    .url("https://intelcrypt.local/license")))
            .servers(List.of(
                new Server()
                    .url("http://localhost:8080")
                    .description("Development Server"),
                new Server()
                    .url("https://api.intelcrypt.local")
                    .description("Production Server")))
            .components(new Components()
                .addSecuritySchemes("bearerAuth", new SecurityScheme()
                    .type(SecurityScheme.Type.HTTP)
                    .scheme("bearer")
                    .bearerFormat("JWT")
                    .description("Enter your JWT access token")))
            .addSecurityItem(new SecurityRequirement()
                .addList("bearerAuth"));
    }
}
