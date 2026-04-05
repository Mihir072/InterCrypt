package com.intelcrypt.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Encrypted message entity.
 * 
 * SECURITY NOTES:
 * - Message content is ALWAYS encrypted (AES-GCM)
 * - Content encryption key is encrypted with recipient's public key
 * - No plaintext is ever stored in the database
 * - Messages support automatic expiration (self-destruct)
 */
@Entity
@Table(name = "messages", indexes = {
    @Index(name = "idx_message_sender", columnList = "sender_id"),
    @Index(name = "idx_message_recipient", columnList = "recipient_id"),
    @Index(name = "idx_message_expires", columnList = "expiresAt")
})
public class Message {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;
    
    /**
     * The chat this message belongs to
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "chat_id")
    private Chat chat;
    
    /**
     * AES-GCM encrypted message content (Base64 encoded)
     * Format: IV || Ciphertext || AuthTag
     */
    @Column(columnDefinition = "TEXT", nullable = false)
    private String encryptedContent;
    
    /**
     * The AES content key, encrypted with recipient's public key (RSA/ECC)
     * Only the recipient can decrypt this with their private key
     */
    @Column(columnDefinition = "TEXT", nullable = false)
    private String encryptedContentKey;
    
    /**
     * Encryption algorithm used for this message
     */
    @Column(length = 30)
    private String encryptionAlgorithm = "AES-256-GCM";
    
    /**
     * Number of encryption rounds applied
     */
    @Column
    private int encryptionRounds = 1;
    
    /**
     * Classification level of this message
     */
    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private MessageClassification classification = MessageClassification.STANDARD;
    
    /**
     * Message status tracking
     */
    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private MessageStatus status = MessageStatus.SENT;
    
    @CreationTimestamp
    @Column(updatable = false)
    private Instant createdAt;
    
    /**
     * When the message should auto-delete (self-destruct)
     */
    @Column
    private Instant expiresAt;
    
    /**
     * When the recipient read the message
     */
    @Column
    private Instant readAt;
    
    /**
     * Soft delete flag - message wiped but record kept for audit
     */
    @Column
    private boolean deleted = false;
    
    /**
     * When the message was securely wiped
     */
    @Column
    private Instant deletedAt;
    
    /**
     * HMAC of the encrypted content for integrity verification
     */
    @Column(length = 128)
    private String contentHmac;
    
    /**
     * Optional metadata (encrypted)
     */
    @Column(columnDefinition = "TEXT")
    private String encryptedMetadata;
    
    @OneToMany(mappedBy = "message", cascade = CascadeType.ALL, orphanRemoval = true)
    private java.util.List<Attachment> attachments = new java.util.ArrayList<>();
    
    public enum MessageClassification {
        STANDARD,
        CONFIDENTIAL,
        SECRET,
        TOP_SECRET
    }
    
    public enum MessageStatus {
        SENT,
        DELIVERED,
        READ,
        EXPIRED,
        DELETED
    }

    public Message() {}

    public Message(UUID id, User sender, User recipient, String encryptedContent,
                   String encryptedContentKey, String encryptionAlgorithm, int encryptionRounds,
                   MessageClassification classification, MessageStatus status, Instant createdAt,
                   Instant expiresAt, Instant readAt, boolean deleted, Instant deletedAt,
                   String contentHmac, String encryptedMetadata) {
        this.id = id;
        this.sender = sender;
        this.recipient = recipient;
        this.encryptedContent = encryptedContent;
        this.encryptedContentKey = encryptedContentKey;
        this.encryptionAlgorithm = encryptionAlgorithm;
        this.encryptionRounds = encryptionRounds;
        this.classification = classification;
        this.status = status;
        this.createdAt = createdAt;
        this.expiresAt = expiresAt;
        this.readAt = readAt;
        this.deleted = deleted;
        this.deletedAt = deletedAt;
        this.contentHmac = contentHmac;
        this.encryptedMetadata = encryptedMetadata;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public User getSender() {
        return sender;
    }

    public void setSender(User sender) {
        this.sender = sender;
    }

    public User getRecipient() {
        return recipient;
    }

    public void setRecipient(User recipient) {
        this.recipient = recipient;
    }

    public Chat getChat() {
        return chat;
    }

    public void setChat(Chat chat) {
        this.chat = chat;
    }

    public String getEncryptedContent() {
        return encryptedContent;
    }

    public void setEncryptedContent(String encryptedContent) {
        this.encryptedContent = encryptedContent;
    }

    public String getEncryptedContentKey() {
        return encryptedContentKey;
    }

    public void setEncryptedContentKey(String encryptedContentKey) {
        this.encryptedContentKey = encryptedContentKey;
    }

    public String getEncryptionAlgorithm() {
        return encryptionAlgorithm;
    }

    public void setEncryptionAlgorithm(String encryptionAlgorithm) {
        this.encryptionAlgorithm = encryptionAlgorithm;
    }

    public int getEncryptionRounds() {
        return encryptionRounds;
    }

    public void setEncryptionRounds(int encryptionRounds) {
        this.encryptionRounds = encryptionRounds;
    }

    public MessageClassification getClassification() {
        return classification;
    }

    public void setClassification(MessageClassification classification) {
        this.classification = classification;
    }

    public MessageStatus getStatus() {
        return status;
    }

    public void setStatus(MessageStatus status) {
        this.status = status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(Instant expiresAt) {
        this.expiresAt = expiresAt;
    }

    public Instant getReadAt() {
        return readAt;
    }

    public void setReadAt(Instant readAt) {
        this.readAt = readAt;
    }

    public boolean isDeleted() {
        return deleted;
    }

    public void setDeleted(boolean deleted) {
        this.deleted = deleted;
    }

    public Instant getDeletedAt() {
        return deletedAt;
    }

    public void setDeletedAt(Instant deletedAt) {
        this.deletedAt = deletedAt;
    }

    public String getContentHmac() {
        return contentHmac;
    }

    public void setContentHmac(String contentHmac) {
        this.contentHmac = contentHmac;
    }

    public String getEncryptedMetadata() {
        return encryptedMetadata;
    }

    public void setEncryptedMetadata(String encryptedMetadata) {
        this.encryptedMetadata = encryptedMetadata;
    }

    public java.util.List<Attachment> getAttachments() {
        return attachments;
    }

    public void setAttachments(java.util.List<Attachment> attachments) {
        this.attachments = attachments;
    }
    
    /**
     * Check if message has expired
     */
    public boolean isExpired() {
        return expiresAt != null && Instant.now().isAfter(expiresAt);
    }
    
    /**
     * Mark message as read
     */
    public void markAsRead() {
        this.status = MessageStatus.READ;
        this.readAt = Instant.now();
    }
    
    /**
     * Soft delete with secure wipe
     */
    public void secureDelete() {
        this.deleted = true;
        this.deletedAt = Instant.now();
        this.status = MessageStatus.DELETED;
        this.encryptedContent = null;
        this.encryptedContentKey = null;
    }

    @Override
    public String toString() {
        return "Message{" +
                "id=" + id +
                ", encryptionAlgorithm='" + encryptionAlgorithm + '\'' +
                ", encryptionRounds=" + encryptionRounds +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Message message = (Message) o;
        return Objects.equals(id, message.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }

    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private UUID id;
        private User sender;
        private User recipient;
        private String encryptedContent;
        private String encryptedContentKey;
        private String encryptionAlgorithm = "AES-256-GCM";
        private int encryptionRounds = 1;
        private MessageClassification classification = MessageClassification.STANDARD;
        private MessageStatus status = MessageStatus.SENT;
        private Instant createdAt;
        private Instant expiresAt;
        private Instant readAt;
        private boolean deleted = false;
        private Instant deletedAt;
        private String contentHmac;
        private String encryptedMetadata;

        public Builder id(UUID id) {
            this.id = id;
            return this;
        }

        public Builder sender(User sender) {
            this.sender = sender;
            return this;
        }

        public Builder recipient(User recipient) {
            this.recipient = recipient;
            return this;
        }

        public Builder encryptedContent(String encryptedContent) {
            this.encryptedContent = encryptedContent;
            return this;
        }

        public Builder encryptedContentKey(String encryptedContentKey) {
            this.encryptedContentKey = encryptedContentKey;
            return this;
        }

        public Builder encryptionAlgorithm(String encryptionAlgorithm) {
            this.encryptionAlgorithm = encryptionAlgorithm;
            return this;
        }

        public Builder encryptionRounds(int encryptionRounds) {
            this.encryptionRounds = encryptionRounds;
            return this;
        }

        public Builder classification(MessageClassification classification) {
            this.classification = classification;
            return this;
        }

        public Builder status(MessageStatus status) {
            this.status = status;
            return this;
        }

        public Builder createdAt(Instant createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public Builder expiresAt(Instant expiresAt) {
            this.expiresAt = expiresAt;
            return this;
        }

        public Builder readAt(Instant readAt) {
            this.readAt = readAt;
            return this;
        }

        public Builder deleted(boolean deleted) {
            this.deleted = deleted;
            return this;
        }

        public Builder deletedAt(Instant deletedAt) {
            this.deletedAt = deletedAt;
            return this;
        }

        public Builder contentHmac(String contentHmac) {
            this.contentHmac = contentHmac;
            return this;
        }

        public Builder encryptedMetadata(String encryptedMetadata) {
            this.encryptedMetadata = encryptedMetadata;
            return this;
        }

        public Message build() {
            return new Message(id, sender, recipient, encryptedContent, encryptedContentKey,
                    encryptionAlgorithm, encryptionRounds, classification, status, createdAt,
                    expiresAt, readAt, deleted, deletedAt, contentHmac, encryptedMetadata);
        }
    }
}
