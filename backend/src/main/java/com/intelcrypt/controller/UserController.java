package com.intelcrypt.controller;

import com.intelcrypt.dto.AuthDTO;
import com.intelcrypt.entity.User;
import com.intelcrypt.exception.ResourceNotFoundException;
import com.intelcrypt.repository.UserRepository;
import com.intelcrypt.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * User Controller.
 * 
 * Handles user profile and search operations.
 */
@RestController
@RequestMapping("/api/users")
@Tag(name = "Users", description = "User management endpoints")
@SecurityRequirement(name = "bearerAuth")
public class UserController {
    
    private final UserRepository userRepository;
    
    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
    
    @GetMapping("/me")
    @Operation(summary = "Get current user",
               description = "Get the current authenticated user's profile")
    public ResponseEntity<UserResponse> getCurrentUser(
            @AuthenticationPrincipal UserPrincipal principal) {
        
        User user = principal.getUser();
        return ResponseEntity.ok(UserResponse.fromEntity(user));
    }
    
    @GetMapping("/{userId}")
    @Operation(summary = "Get user by ID",
               description = "Get a user's public profile")
    public ResponseEntity<UserResponse> getUser(@PathVariable UUID userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return ResponseEntity.ok(UserResponse.fromEntity(user));
    }
    
    @PutMapping("/me")
    @Operation(summary = "Update current user",
               description = "Update the current user's profile")
    public ResponseEntity<UserResponse> updateCurrentUser(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody UpdateUserRequest request) {
        
        User user = principal.getUser();
        
        // Note: username change would require validation for uniqueness
        // For now, we don't allow username changes
        
        User savedUser = userRepository.save(user);
        return ResponseEntity.ok(UserResponse.fromEntity(savedUser));
    }
    
    @GetMapping("/search")
    @Operation(summary = "Search users",
               description = "Search for users by username or email. If query is empty, returns all users.")
    public ResponseEntity<List<UserResponse>> searchUsers(
            @RequestParam(defaultValue = "") String q,
            @RequestParam(defaultValue = "50") int limit) {
        
        List<User> users;
        if (q == null || q.trim().isEmpty()) {
            // Return all users when no search query
            users = userRepository.findAll();
        } else {
            users = userRepository.findByUsernameContainingIgnoreCase(q);
        }
        
        List<UserResponse> response = users.stream()
            .limit(limit)
            .map(UserResponse::fromEntity)
            .collect(Collectors.toList());
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * User response matching frontend User model
     */
    public static class UserResponse {
        private String id;
        private String username;
        private String email;
        private String profileImageUrl;
        private List<String> roles;
        private String clearanceLevel;
        private boolean isOnline;
        private String lastSeen;
        private String createdAt;
        
        public static UserResponse fromEntity(User user) {
            UserResponse response = new UserResponse();
            response.id = user.getId().toString();
            response.username = user.getUsername();
            response.email = user.getEmail();
            response.profileImageUrl = null; // Could be added to User entity
            response.roles = user.getRoles().stream()
                .map(Enum::name)
                .collect(Collectors.toList());
            response.clearanceLevel = user.getClearanceLevel().name();
            response.isOnline = false; // Would require real-time tracking
            response.lastSeen = user.getLastLoginAt() != null ? 
                user.getLastLoginAt().toString() : null;
            response.createdAt = user.getCreatedAt() != null ? 
                user.getCreatedAt().toString() : null;
            return response;
        }
        
        // Getters and Setters
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        
        public String getProfileImageUrl() { return profileImageUrl; }
        public void setProfileImageUrl(String profileImageUrl) { this.profileImageUrl = profileImageUrl; }
        
        public List<String> getRoles() { return roles; }
        public void setRoles(List<String> roles) { this.roles = roles; }
        
        public String getClearanceLevel() { return clearanceLevel; }
        public void setClearanceLevel(String clearanceLevel) { this.clearanceLevel = clearanceLevel; }
        
        public boolean isOnline() { return isOnline; }
        public void setOnline(boolean online) { isOnline = online; }
        
        public String getLastSeen() { return lastSeen; }
        public void setLastSeen(String lastSeen) { this.lastSeen = lastSeen; }
        
        public String getCreatedAt() { return createdAt; }
        public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
    }
    
    /**
     * Request to update user profile
     */
    public static class UpdateUserRequest {
        private String username;
        private String profileImageUrl;
        private String clearanceLevel;
        
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        
        public String getProfileImageUrl() { return profileImageUrl; }
        public void setProfileImageUrl(String profileImageUrl) { this.profileImageUrl = profileImageUrl; }
        
        public String getClearanceLevel() { return clearanceLevel; }
        public void setClearanceLevel(String clearanceLevel) { this.clearanceLevel = clearanceLevel; }
    }
}
