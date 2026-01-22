package com.intelcrypt.controller;

import com.intelcrypt.dto.KeyDTO;
import com.intelcrypt.security.UserPrincipal;
import com.intelcrypt.service.KeyService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Key Management Controller.
 * 
 * Handles cryptographic key generation, rotation, and retrieval.
 */
@RestController
@RequestMapping("/api/keys")
@Tag(name = "Key Management", description = "Cryptographic key management endpoints")
@SecurityRequirement(name = "bearerAuth")
public class KeyController {
    
    private final KeyService keyService;

    public KeyController(KeyService keyService) {
        this.keyService = keyService;
    }
    
    @PostMapping("/generate")
    @Operation(summary = "Generate new key pair",
               description = "Generate a new RSA/ECC key pair for the authenticated user")
    public ResponseEntity<KeyDTO.KeyPairResponse> generateKeyPair(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody KeyDTO.GenerateKeyPairRequest request,
            HttpServletRequest httpRequest) {
        
        KeyDTO.KeyPairResponse response = keyService.generateUserKeyPair(
            principal.getUser().getId(),
            request,
            getClientIp(httpRequest)
        );
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/public/{username}")
    @Operation(summary = "Get user's public key",
               description = "Retrieve a user's public key for message encryption")
    public ResponseEntity<KeyDTO.PublicKeyResponse> getPublicKey(
            @PathVariable String username) {
        
        KeyDTO.PublicKeyResponse response = keyService.getUserPublicKey(username);
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/rotate")
    @Operation(summary = "Rotate key pair",
               description = "Generate new key pair and deprecate old keys")
    public ResponseEntity<KeyDTO.KeyPairResponse> rotateKeys(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody KeyDTO.RotateKeyRequest request,
            HttpServletRequest httpRequest) {
        
        KeyDTO.KeyPairResponse response = keyService.rotateUserKeys(
            principal.getUser().getId(),
            request,
            getClientIp(httpRequest)
        );
        
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/session")
    @Operation(summary = "Generate AES session key",
               description = "Generate a new AES session key for symmetric encryption")
    public ResponseEntity<KeyDTO.AESKeyResponse> generateSessionKey(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody KeyDTO.GenerateAESKeyRequest request,
            HttpServletRequest httpRequest) {
        
        KeyDTO.AESKeyResponse response = keyService.generateAESKey(
            principal.getUser().getId(),
            request,
            getClientIp(httpRequest)
        );
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/list")
    @Operation(summary = "List user's keys",
               description = "Get metadata for all keys owned by the authenticated user")
    public ResponseEntity<List<KeyDTO.KeyInfo>> listKeys(
            @AuthenticationPrincipal UserPrincipal principal) {
        
        List<KeyDTO.KeyInfo> keys = keyService.listUserKeys(principal.getUser().getId());
        return ResponseEntity.ok(keys);
    }
    
    // Admin endpoints
    
    @GetMapping("/admin/user/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Admin: Get user's key info",
               description = "Admin endpoint to view user's key metadata")
    public ResponseEntity<List<KeyDTO.KeyInfo>> getKeysByUserId(
            @PathVariable String userId) {
        
        List<KeyDTO.KeyInfo> keys = keyService.listUserKeys(
            java.util.UUID.fromString(userId));
        return ResponseEntity.ok(keys);
    }
    
    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
