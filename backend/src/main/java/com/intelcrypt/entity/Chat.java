package com.intelcrypt.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * Chat/Conversation entity representing a chat room or direct message.
 * 
 * SECURITY NOTES:
 * - Chats have classification levels that restrict access
 * - Only users with appropriate clearance can access classified chats
 * - Chat encryption settings determine message encryption strength
 */
@Entity
@Table(name = "chats", indexes = {
    @Index(name = "idx_chat_created_by", columnList = "created_by_id"),
    @Index(name = "idx_chat_type", columnList = "chat_type"),
    @Index(name = "idx_chat_classification", columnList = "classification_level")
})
public class Chat {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    
    @Column(nullable = false, length = 100)
    private String name;
    
    @Column(length = 500)
    private String description;
    
    @Column(length = 500)
    private String avatarUrl;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "chat_type", nullable = false, length = 20)
    private ChatType type = ChatType.DIRECT;
    
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "chat_participants",
        joinColumns = @JoinColumn(name = "chat_id"),
        inverseJoinColumns = @JoinColumn(name = "user_id")
    )
    private Set<User> participants = new HashSet<>();
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_id", nullable = false)
    private User createdBy;
    
    @CreationTimestamp
    @Column(updatable = false)
    private Instant createdAt;
    
    @UpdateTimestamp
    private Instant updatedAt;
    
    @Column
    private Instant lastMessageAt;
    
    @Column(length = 255)
    private String lastMessagePreview;
    
    @Column
    private UUID lastMessageSenderId;
    
    @Column(nullable = false)
    private boolean archived = false;
    
    @Column(nullable = false)
    private boolean deleted = false;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "classification_level", length = 20)
    private ClassificationLevel classificationLevel = ClassificationLevel.UNCLASSIFIED;
    
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "chat_allowed_roles", joinColumns = @JoinColumn(name = "chat_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "role")
    private Set<User.Role> allowedRoles = new HashSet<>();
    
    // Encryption settings
    @Column(length = 30)
    private String encryptionAlgorithm = "AES-256-GCM";
    
    @Column
    private UUID encryptionKeyId;
    
    @Column(length = 20)
    private String encryptionLevel = "HIGH";
    
    @Column
    private boolean isE2E = true;
    
    public enum ChatType {
        DIRECT,
        GROUP,
        CHANNEL,
        BROADCAST
    }
    
    public enum ClassificationLevel {
        UNCLASSIFIED,
        CONFIDENTIAL,
        SECRET,
        TOP_SECRET
    }
    
    public Chat() {}
    
    public Chat(String name, ChatType type, User createdBy) {
        this.name = name;
        this.type = type;
        this.createdBy = createdBy;
        this.participants.add(createdBy);
    }
    
    // Getters and Setters
    
    public UUID getId() {
        return id;
    }
    
    public void setId(UUID id) {
        this.id = id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public String getAvatarUrl() {
        return avatarUrl;
    }
    
    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }
    
    public ChatType getType() {
        return type;
    }
    
    public void setType(ChatType type) {
        this.type = type;
    }
    
    public Set<User> getParticipants() {
        return participants;
    }
    
    public void setParticipants(Set<User> participants) {
        this.participants = participants;
    }
    
    public void addParticipant(User user) {
        this.participants.add(user);
    }
    
    public void removeParticipant(User user) {
        this.participants.remove(user);
    }
    
    public User getCreatedBy() {
        return createdBy;
    }
    
    public void setCreatedBy(User createdBy) {
        this.createdBy = createdBy;
    }
    
    public Instant getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
    
    public Instant getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    public Instant getLastMessageAt() {
        return lastMessageAt;
    }
    
    public void setLastMessageAt(Instant lastMessageAt) {
        this.lastMessageAt = lastMessageAt;
    }
    
    public String getLastMessagePreview() {
        return lastMessagePreview;
    }
    
    public void setLastMessagePreview(String lastMessagePreview) {
        this.lastMessagePreview = lastMessagePreview;
    }
    
    public UUID getLastMessageSenderId() {
        return lastMessageSenderId;
    }
    
    public void setLastMessageSenderId(UUID lastMessageSenderId) {
        this.lastMessageSenderId = lastMessageSenderId;
    }
    
    public boolean isArchived() {
        return archived;
    }
    
    public void setArchived(boolean archived) {
        this.archived = archived;
    }
    
    public boolean isDeleted() {
        return deleted;
    }
    
    public void setDeleted(boolean deleted) {
        this.deleted = deleted;
    }
    
    public ClassificationLevel getClassificationLevel() {
        return classificationLevel;
    }
    
    public void setClassificationLevel(ClassificationLevel classificationLevel) {
        this.classificationLevel = classificationLevel;
    }
    
    public Set<User.Role> getAllowedRoles() {
        return allowedRoles;
    }
    
    public void setAllowedRoles(Set<User.Role> allowedRoles) {
        this.allowedRoles = allowedRoles;
    }
    
    public String getEncryptionAlgorithm() {
        return encryptionAlgorithm;
    }
    
    public void setEncryptionAlgorithm(String encryptionAlgorithm) {
        this.encryptionAlgorithm = encryptionAlgorithm;
    }
    
    public UUID getEncryptionKeyId() {
        return encryptionKeyId;
    }
    
    public void setEncryptionKeyId(UUID encryptionKeyId) {
        this.encryptionKeyId = encryptionKeyId;
    }
    
    public String getEncryptionLevel() {
        return encryptionLevel;
    }
    
    public void setEncryptionLevel(String encryptionLevel) {
        this.encryptionLevel = encryptionLevel;
    }
    
    public boolean isE2E() {
        return isE2E;
    }
    
    public void setE2E(boolean e2E) {
        isE2E = e2E;
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Chat chat = (Chat) o;
        return Objects.equals(id, chat.id);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
    
    @Override
    public String toString() {
        return "Chat{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", type=" + type +
                ", classificationLevel=" + classificationLevel +
                '}';
    }
}
