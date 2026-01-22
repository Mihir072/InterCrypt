package com.intelcrypt.controller;

import com.intelcrypt.dto.AuthDTO;
import com.intelcrypt.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

/**
 * Authentication Controller.
 * 
 * Handles user registration, login, token refresh, and password management.
 */
@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "User authentication and registration endpoints")
public class AuthController {
    
    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    @Operation(summary = "Register a new user",
               description = "Creates a new user account with encryption keys")
    public ResponseEntity<AuthDTO.AuthResponse> register(
            @Valid @RequestBody AuthDTO.RegisterRequest request,
            HttpServletRequest httpRequest) {
        
        AuthDTO.AuthResponse response = authService.register(
            request,
            getClientIp(httpRequest),
            httpRequest.getHeader("User-Agent")
        );
        
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/login")
    @Operation(summary = "User login",
               description = "Authenticate user and receive JWT tokens")
    public ResponseEntity<AuthDTO.AuthResponse> login(
            @Valid @RequestBody AuthDTO.LoginRequest request,
            HttpServletRequest httpRequest) {
        
        AuthDTO.AuthResponse response = authService.login(
            request,
            getClientIp(httpRequest),
            httpRequest.getHeader("User-Agent")
        );
        
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/refresh")
    @Operation(summary = "Refresh access token",
               description = "Exchange refresh token for new access token")
    public ResponseEntity<AuthDTO.AuthResponse> refreshToken(
            @Valid @RequestBody AuthDTO.RefreshTokenRequest request) {
        
        AuthDTO.AuthResponse response = authService.refreshToken(request.getRefreshToken());
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/change-password")
    @Operation(summary = "Change password",
               description = "Change user's password (requires authentication)",
               security = @SecurityRequirement(name = "bearerAuth"))
    public ResponseEntity<Void> changePassword(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody AuthDTO.ChangePasswordRequest request,
            HttpServletRequest httpRequest) {
        
        authService.changePassword(
            userDetails.getUsername(),
            request,
            getClientIp(httpRequest),
            httpRequest.getHeader("User-Agent")
        );
        
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/me")
    @Operation(summary = "Get current user",
               description = "Get information about the currently authenticated user",
               security = @SecurityRequirement(name = "bearerAuth"))
    public ResponseEntity<AuthDTO.UserInfo> getCurrentUser(
            @AuthenticationPrincipal UserDetails userDetails) {
        
        var user = authService.getCurrentUser();
        
        return ResponseEntity.ok(AuthDTO.UserInfo.builder()
            .id(user.getId().toString())
            .username(user.getUsername())
            .email(user.getEmail())
            .roles(user.getRoles().stream().map(Enum::name).toArray(String[]::new))
            .clearanceLevel(user.getClearanceLevel().name())
            .build());
    }
    
    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
