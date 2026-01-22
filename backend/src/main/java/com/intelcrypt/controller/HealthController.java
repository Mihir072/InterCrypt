package com.intelcrypt.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

/**
 * Health Check Controller.
 * 
 * Provides health and status endpoints for monitoring.
 */
@RestController
@RequestMapping("/api")
@Tag(name = "Health", description = "Application health and status endpoints")
public class HealthController {
    
    @GetMapping("/health")
    @Operation(summary = "Health check",
               description = "Check if the application is running")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "timestamp", Instant.now().toString(),
            "service", "IntelCrypt",
            "version", "1.0.0"
        ));
    }
    
    @GetMapping("/info")
    @Operation(summary = "Application info",
               description = "Get application information")
    public ResponseEntity<Map<String, Object>> info() {
        return ResponseEntity.ok(Map.of(
            "name", "IntelCrypt",
            "description", "Extended AES-Based Secure Messaging & Data Vault Platform",
            "version", "1.0.0",
            "security", Map.of(
                "encryption", "AES-256-GCM",
                "keyExchange", "RSA-4096",
                "hashing", "Argon2id"
            )
        ));
    }
}
