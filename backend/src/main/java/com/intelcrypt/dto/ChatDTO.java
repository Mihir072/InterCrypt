package com.intelcrypt.dto;

import com.intelcrypt.entity.Chat;
import com.intelcrypt.entity.User;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Chat DTOs for API requests and responses.
 */
public class ChatDTO {
    
    /**
     * Request to create a new chat
     */
    public static class CreateChatRequest {
        @NotBlank(message = "Chat name is required")
        @Size(min = 1, max = 100, message = "Chat name must be between 1 and 100 characters")
        private String name;
        
        private String description;
        
        @NotNull(message = "Chat type is required")
        private String type;
        
        private List<String> participantIds;
        
        private String classificationLevel;
        
        public CreateChatRequest() {}
        
        public CreateChatRequest(String name, String description, String type, List<String> participantIds, String classificationLevel) {
            this.name = name;
            this.description = description;
            this.type = type;
            this.participantIds = participantIds;
            this.classificationLevel = classificationLevel;
        }
        
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        
        public String getType() { return type; }
        public void setType(String type) { this.type = type; }
        
        public List<String> getParticipantIds() { return participantIds; }
        public void setParticipantIds(List<String> participantIds) { this.participantIds = participantIds; }
        
        public String getClassificationLevel() { return classificationLevel; }
        public void setClassificationLevel(String classificationLevel) { this.classificationLevel = classificationLevel; }
        
        public static Builder builder() { return new Builder(); }
        
        public static class Builder {
            private String name;
            private String description;
            private String type;
            private List<String> participantIds;
            private String classificationLevel;
            
            public Builder name(String name) { this.name = name; return this; }
            public Builder description(String description) { this.description = description; return this; }
            public Builder type(String type) { this.type = type; return this; }
            public Builder participantIds(List<String> participantIds) { this.participantIds = participantIds; return this; }
            public Builder classificationLevel(String classificationLevel) { this.classificationLevel = classificationLevel; return this; }
            
            public CreateChatRequest build() {
                return new CreateChatRequest(name, description, type, participantIds, classificationLevel);
            }
        }
    }
    
    /**
     * Request to update a chat
     */
    public static class UpdateChatRequest {
        private String name;
        private String description;
        private String avatarUrl;
        private Boolean archived;
        private Boolean muted;
        
        public UpdateChatRequest() {}
        
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        
        public String getAvatarUrl() { return avatarUrl; }
        public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
        
        public Boolean getArchived() { return archived; }
        public void setArchived(Boolean archived) { this.archived = archived; }
        
        public Boolean getMuted() { return muted; }
        public void setMuted(Boolean muted) { this.muted = muted; }
    }
    
    /**
     * Chat response DTO matching frontend Chat model
     */
    public static class ChatResponse {
        private String id;
        private String name;
        private String description;
        private String avatarUrl;
        private String type;
        private List<ParticipantInfo> participants;
        private ParticipantInfo createdBy;
        private String createdAt;
        private String lastMessageAt;
        private String lastMessagePreview;
        private String lastMessageSenderId;
        private int unreadCount;
        private boolean isArchived;
        private boolean isMuted;
        private String classificationLevel;
        private List<String> allowedRoles;
        private EncryptionInfo encryption;
        
        public ChatResponse() {}
        
        // Factory method to create from entity (for non-user-specific contexts)
        public static ChatResponse fromEntity(Chat chat, int unreadCount, boolean isMuted) {
            return fromEntity(chat, null, unreadCount, isMuted);
        }
        
        // Factory method to create from entity with current user context
        // For DIRECT chats, shows the OTHER participant's name instead of chat name
        public static ChatResponse fromEntity(Chat chat, User currentUser, int unreadCount, boolean isMuted) {
            ChatResponse response = new ChatResponse();
            response.id = chat.getId().toString();
            
            // For direct chats, show the OTHER participant's name
            if (chat.getType() == Chat.ChatType.DIRECT && currentUser != null) {
                User otherUser = chat.getParticipants().stream()
                    .filter(p -> !p.getId().equals(currentUser.getId()))
                    .findFirst()
                    .orElse(null);
                response.name = otherUser != null ? otherUser.getUsername() : chat.getName();
                response.avatarUrl = null; // Could use otherUser's avatar
            } else {
                response.name = chat.getName();
                response.avatarUrl = chat.getAvatarUrl();
            }
            
            response.description = chat.getDescription();
            response.type = chat.getType().name();
            response.participants = chat.getParticipants().stream()
                .map(ParticipantInfo::fromUser)
                .collect(Collectors.toList());
            response.createdBy = ParticipantInfo.fromUser(chat.getCreatedBy());
            response.createdAt = chat.getCreatedAt() != null ? chat.getCreatedAt().toString() : null;
            response.lastMessageAt = chat.getLastMessageAt() != null ? chat.getLastMessageAt().toString() : Instant.now().toString();
            response.lastMessagePreview = chat.getLastMessagePreview();
            response.lastMessageSenderId = chat.getLastMessageSenderId() != null ? chat.getLastMessageSenderId().toString() : null;
            response.unreadCount = unreadCount;
            response.isArchived = chat.isArchived();
            response.isMuted = isMuted;
            response.classificationLevel = chat.getClassificationLevel().name();
            response.allowedRoles = chat.getAllowedRoles().stream()
                .map(Enum::name)
                .collect(Collectors.toList());
            response.encryption = new EncryptionInfo(
                chat.getEncryptionAlgorithm(),
                chat.getEncryptionKeyId() != null ? chat.getEncryptionKeyId().toString() : null,
                chat.getEncryptionLevel(),
                chat.isE2E(),
                chat.getCreatedAt() != null ? chat.getCreatedAt().toString() : null
            );
            return response;
        }
        
        // Getters and Setters
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        
        public String getAvatarUrl() { return avatarUrl; }
        public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
        
        public String getType() { return type; }
        public void setType(String type) { this.type = type; }
        
        public List<ParticipantInfo> getParticipants() { return participants; }
        public void setParticipants(List<ParticipantInfo> participants) { this.participants = participants; }
        
        public ParticipantInfo getCreatedBy() { return createdBy; }
        public void setCreatedBy(ParticipantInfo createdBy) { this.createdBy = createdBy; }
        
        public String getCreatedAt() { return createdAt; }
        public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
        
        public String getLastMessageAt() { return lastMessageAt; }
        public void setLastMessageAt(String lastMessageAt) { this.lastMessageAt = lastMessageAt; }
        
        public String getLastMessagePreview() { return lastMessagePreview; }
        public void setLastMessagePreview(String lastMessagePreview) { this.lastMessagePreview = lastMessagePreview; }
        
        public String getLastMessageSenderId() { return lastMessageSenderId; }
        public void setLastMessageSenderId(String lastMessageSenderId) { this.lastMessageSenderId = lastMessageSenderId; }
        
        public int getUnreadCount() { return unreadCount; }
        public void setUnreadCount(int unreadCount) { this.unreadCount = unreadCount; }
        
        public boolean isArchived() { return isArchived; }
        public void setArchived(boolean archived) { isArchived = archived; }
        
        public boolean isMuted() { return isMuted; }
        public void setMuted(boolean muted) { isMuted = muted; }
        
        public String getClassificationLevel() { return classificationLevel; }
        public void setClassificationLevel(String classificationLevel) { this.classificationLevel = classificationLevel; }
        
        public List<String> getAllowedRoles() { return allowedRoles; }
        public void setAllowedRoles(List<String> allowedRoles) { this.allowedRoles = allowedRoles; }
        
        public EncryptionInfo getEncryption() { return encryption; }
        public void setEncryption(EncryptionInfo encryption) { this.encryption = encryption; }
    }
    
    /**
     * Participant info for chat responses
     */
    public static class ParticipantInfo {
        private String id;
        private String username;
        private String email;
        private String profileImageUrl;
        private List<String> roles;
        private String clearanceLevel;
        private boolean isOnline;
        private String lastSeen;
        private String createdAt;
        
        public ParticipantInfo() {}
        
        public static ParticipantInfo fromUser(User user) {
            ParticipantInfo info = new ParticipantInfo();
            info.id = user.getId().toString();
            info.username = user.getUsername();
            info.email = user.getEmail();
            info.profileImageUrl = null; // Not stored in User entity currently
            info.roles = user.getRoles().stream().map(Enum::name).collect(Collectors.toList());
            info.clearanceLevel = user.getClearanceLevel().name();
            info.isOnline = false; // Would need real-time tracking
            info.lastSeen = user.getLastLoginAt() != null ? user.getLastLoginAt().toString() : null;
            info.createdAt = user.getCreatedAt() != null ? user.getCreatedAt().toString() : null;
            return info;
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
     * Encryption info for chat responses
     */
    public static class EncryptionInfo {
        private String algorithm;
        private String keyId;
        private String encryptionLevel;
        private boolean isE2E;
        private String keyCreatedAt;
        
        public EncryptionInfo() {}
        
        public EncryptionInfo(String algorithm, String keyId, String encryptionLevel, boolean isE2E, String keyCreatedAt) {
            this.algorithm = algorithm;
            this.keyId = keyId;
            this.encryptionLevel = encryptionLevel;
            this.isE2E = isE2E;
            this.keyCreatedAt = keyCreatedAt;
        }
        
        public String getAlgorithm() { return algorithm; }
        public void setAlgorithm(String algorithm) { this.algorithm = algorithm; }
        
        public String getKeyId() { return keyId; }
        public void setKeyId(String keyId) { this.keyId = keyId; }
        
        public String getEncryptionLevel() { return encryptionLevel; }
        public void setEncryptionLevel(String encryptionLevel) { this.encryptionLevel = encryptionLevel; }
        
        public boolean isE2E() { return isE2E; }
        public void setE2E(boolean e2E) { isE2E = e2E; }
        
        public String getKeyCreatedAt() { return keyCreatedAt; }
        public void setKeyCreatedAt(String keyCreatedAt) { this.keyCreatedAt = keyCreatedAt; }
    }
}
