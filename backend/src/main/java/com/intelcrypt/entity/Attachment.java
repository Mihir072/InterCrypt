package com.intelcrypt.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Encrypted file attachment entity.
 * 
 * SECURITY NOTES:
 * - File content is encrypted separately from messages
 * - Uses dedicated encryption key for each attachment
 * - Supports large file encryption with chunking
 */
@Entity
@Table(name = "attachments", indexes = {
    @Index(name = "idx_attachment_message", columnList = "message_id")
})
public class Attachment {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "message_id", nullable = false)
    private Message message;
    
    /**
     * Encrypted original filename
     */
    @Column(length = 500)
    private String encryptedFilename;
    
    /**
     * MIME type (may be obfuscated for security)
     */
    @Column(length = 100)
    private String mimeType;
    
    /**
     * Size of encrypted content in bytes
     */
    @Column
    private long encryptedSize;
    
    /**
     * Original file size before encryption
     */
    @Column
    private long originalSize;
    
    /**
     * Encrypted file content (Base64)
     * For large files, this is stored in chunks
     */
    @Column(columnDefinition = "TEXT")
    private String encryptedContent;
    
    /**
     * Path to encrypted file on disk (for large files)
     */
    @Column(length = 500)
    private String encryptedFilePath;
    
    /**
     * Encrypted attachment key (encrypted with message key)
     */
    @Column(columnDefinition = "TEXT")
    private String encryptedKey;
    
    /**
     * SHA-256 hash of original file for integrity
     */
    @Column(length = 64)
    private String originalFileHash;
    
    @CreationTimestamp
    @Column(updatable = false)
    private Instant createdAt;
    
    @Column
    private boolean deleted = false;
    
    /**
     * Flag indicating if the attachment contains steganographic data
     */
    @Column
    private boolean hasHiddenData = false;

    public Attachment() {}

    public Attachment(UUID id, Message message, String encryptedFilename, String mimeType,
                      long encryptedSize, long originalSize, String encryptedContent,
                      String encryptedFilePath, String encryptedKey, String originalFileHash,
                      Instant createdAt, boolean deleted) {
        this.id = id;
        this.message = message;
        this.encryptedFilename = encryptedFilename;
        this.mimeType = mimeType;
        this.encryptedSize = encryptedSize;
        this.originalSize = originalSize;
        this.encryptedContent = encryptedContent;
        this.encryptedFilePath = encryptedFilePath;
        this.encryptedKey = encryptedKey;
        this.originalFileHash = originalFileHash;
        this.createdAt = createdAt;
        this.deleted = deleted;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public Message getMessage() {
        return message;
    }

    public void setMessage(Message message) {
        this.message = message;
    }

    public String getEncryptedFilename() {
        return encryptedFilename;
    }

    public void setEncryptedFilename(String encryptedFilename) {
        this.encryptedFilename = encryptedFilename;
    }

    public String getMimeType() {
        return mimeType;
    }

    public void setMimeType(String mimeType) {
        this.mimeType = mimeType;
    }

    public long getEncryptedSize() {
        return encryptedSize;
    }

    public void setEncryptedSize(long encryptedSize) {
        this.encryptedSize = encryptedSize;
    }

    public long getOriginalSize() {
        return originalSize;
    }

    public void setOriginalSize(long originalSize) {
        this.originalSize = originalSize;
    }

    public String getEncryptedContent() {
        return encryptedContent;
    }

    public void setEncryptedContent(String encryptedContent) {
        this.encryptedContent = encryptedContent;
    }

    public String getEncryptedFilePath() {
        return encryptedFilePath;
    }

    public void setEncryptedFilePath(String encryptedFilePath) {
        this.encryptedFilePath = encryptedFilePath;
    }

    public String getEncryptedKey() {
        return encryptedKey;
    }

    public void setEncryptedKey(String encryptedKey) {
        this.encryptedKey = encryptedKey;
    }

    public String getOriginalFileHash() {
        return originalFileHash;
    }

    public void setOriginalFileHash(String originalFileHash) {
        this.originalFileHash = originalFileHash;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public boolean isDeleted() {
        return deleted;
    }

    public void setDeleted(boolean deleted) {
        this.deleted = deleted;
    }

    public boolean isHasHiddenData() {
        return hasHiddenData;
    }

    public void setHasHiddenData(boolean hasHiddenData) {
        this.hasHiddenData = hasHiddenData;
    }

    @Override
    public String toString() {
        return "Attachment{" +
                "id=" + id +
                ", mimeType='" + mimeType + '\'' +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Attachment that = (Attachment) o;
        return Objects.equals(id, that.id);
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
        private Message message;
        private String encryptedFilename;
        private String mimeType;
        private long encryptedSize;
        private long originalSize;
        private String encryptedContent;
        private String encryptedFilePath;
        private String encryptedKey;
        private String originalFileHash;
        private Instant createdAt;
        private boolean deleted = false;

        public Builder id(UUID id) {
            this.id = id;
            return this;
        }

        public Builder message(Message message) {
            this.message = message;
            return this;
        }

        public Builder encryptedFilename(String encryptedFilename) {
            this.encryptedFilename = encryptedFilename;
            return this;
        }

        public Builder mimeType(String mimeType) {
            this.mimeType = mimeType;
            return this;
        }

        public Builder encryptedSize(long encryptedSize) {
            this.encryptedSize = encryptedSize;
            return this;
        }

        public Builder originalSize(long originalSize) {
            this.originalSize = originalSize;
            return this;
        }

        public Builder encryptedContent(String encryptedContent) {
            this.encryptedContent = encryptedContent;
            return this;
        }

        public Builder encryptedFilePath(String encryptedFilePath) {
            this.encryptedFilePath = encryptedFilePath;
            return this;
        }

        public Builder encryptedKey(String encryptedKey) {
            this.encryptedKey = encryptedKey;
            return this;
        }

        public Builder originalFileHash(String originalFileHash) {
            this.originalFileHash = originalFileHash;
            return this;
        }

        public Builder createdAt(Instant createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public Builder deleted(boolean deleted) {
            this.deleted = deleted;
            return this;
        }

        public Attachment build() {
            return new Attachment(id, message, encryptedFilename, mimeType, encryptedSize,
                    originalSize, encryptedContent, encryptedFilePath, encryptedKey,
                    originalFileHash, createdAt, deleted);
        }
    }
}
