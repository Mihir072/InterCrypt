package com.intelcrypt.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Cryptographic key storage entity.
 * 
 * SECURITY NOTES:
 * - Stores encrypted key material (never plaintext keys)
 * - Supports key rotation with version tracking
 * - Master keys are encrypted with hardware security module (HSM) in production
 */
@Entity
@Table(name = "encryption_keys", indexes = {
    @Index(name = "idx_key_user", columnList = "user_id"),
    @Index(name = "idx_key_type", columnList = "keyType"),
    @Index(name = "idx_key_active", columnList = "active")
})
public class EncryptionKey {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;
    
    /**
     * Type of cryptographic key
     */
    @Enumerated(EnumType.STRING)
    @Column(length = 20, nullable = false)
    private KeyType keyType;
    
    /**
     * Key algorithm (AES, RSA, ECC)
     */
    @Column(length = 20, nullable = false)
    private String algorithm;
    
    /**
     * Key size in bits
     */
    @Column(nullable = false)
    private int keySize;
    
    /**
     * Encrypted key material (never store plaintext!)
     */
    @Column(columnDefinition = "TEXT", nullable = false)
    private String encryptedKeyMaterial;
    
    /**
     * ID of the key used to encrypt this key (key hierarchy)
     */
    @Column
    private UUID encryptingKeyId;
    
    /**
     * Key version for rotation tracking
     */
    @Column(nullable = false)
    private int version;
    
    /**
     * Whether this key is currently active
     */
    @Column(nullable = false)
    private boolean active;
    
    @CreationTimestamp
    @Column(updatable = false)
    private Instant createdAt;
    
    /**
     * When this key expires (for automatic rotation)
     */
    @Column
    private Instant expiresAt;
    
    /**
     * When this key was rotated/replaced
     */
    @Column
    private Instant rotatedAt;
    
    /**
     * Purpose/usage description for audit
     */
    @Column(length = 200)
    private String purpose;
    
    /**
     * Checksum of key material for integrity
     */
    @Column(length = 64)
    private String keyChecksum;
    
    // Constructors
    public EncryptionKey() {
        this.version = 1;
        this.active = true;
    }
    
    public EncryptionKey(UUID id, User user, KeyType keyType, String algorithm,
                        int keySize, String encryptedKeyMaterial, UUID encryptingKeyId,
                        int version, boolean active, Instant createdAt, Instant expiresAt,
                        Instant rotatedAt, String purpose, String keyChecksum) {
        this.id = id;
        this.user = user;
        this.keyType = keyType;
        this.algorithm = algorithm;
        this.keySize = keySize;
        this.encryptedKeyMaterial = encryptedKeyMaterial;
        this.encryptingKeyId = encryptingKeyId;
        this.version = version;
        this.active = active;
        this.createdAt = createdAt;
        this.expiresAt = expiresAt;
        this.rotatedAt = rotatedAt;
        this.purpose = purpose;
        this.keyChecksum = keyChecksum;
    }
    
    // Getters and Setters
    public UUID getId() {
        return id;
    }
    
    public void setId(UUID id) {
        this.id = id;
    }
    
    public User getUser() {
        return user;
    }
    
    public void setUser(User user) {
        this.user = user;
    }
    
    public KeyType getKeyType() {
        return keyType;
    }
    
    public void setKeyType(KeyType keyType) {
        this.keyType = keyType;
    }
    
    public String getAlgorithm() {
        return algorithm;
    }
    
    public void setAlgorithm(String algorithm) {
        this.algorithm = algorithm;
    }
    
    public int getKeySize() {
        return keySize;
    }
    
    public void setKeySize(int keySize) {
        this.keySize = keySize;
    }
    
    public String getEncryptedKeyMaterial() {
        return encryptedKeyMaterial;
    }
    
    public void setEncryptedKeyMaterial(String encryptedKeyMaterial) {
        this.encryptedKeyMaterial = encryptedKeyMaterial;
    }
    
    public UUID getEncryptingKeyId() {
        return encryptingKeyId;
    }
    
    public void setEncryptingKeyId(UUID encryptingKeyId) {
        this.encryptingKeyId = encryptingKeyId;
    }
    
    public int getVersion() {
        return version;
    }
    
    public void setVersion(int version) {
        this.version = version;
    }
    
    public boolean isActive() {
        return active;
    }
    
    public void setActive(boolean active) {
        this.active = active;
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
    
    public Instant getRotatedAt() {
        return rotatedAt;
    }
    
    public void setRotatedAt(Instant rotatedAt) {
        this.rotatedAt = rotatedAt;
    }
    
    public String getPurpose() {
        return purpose;
    }
    
    public void setPurpose(String purpose) {
        this.purpose = purpose;
    }
    
    public String getKeyChecksum() {
        return keyChecksum;
    }
    
    public void setKeyChecksum(String keyChecksum) {
        this.keyChecksum = keyChecksum;
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        EncryptionKey that = (EncryptionKey) o;
        return Objects.equals(id, that.id);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
    
    @Override
    public String toString() {
        return "EncryptionKey{" +
                "id=" + id +
                ", keyType=" + keyType +
                ", algorithm='" + algorithm + '\'' +
                ", keySize=" + keySize +
                ", version=" + version +
                ", active=" + active +
                ", createdAt=" + createdAt +
                '}';
    }
    
    /**
     * Check if key has expired
     */
    public boolean isExpired() {
        return expiresAt != null && Instant.now().isAfter(expiresAt);
    }
    
    // Builder
    public static Builder builder() {
        return new Builder();
    }
    
    public static class Builder {
        private UUID id;
        private User user;
        private KeyType keyType;
        private String algorithm;
        private int keySize;
        private String encryptedKeyMaterial;
        private UUID encryptingKeyId;
        private int version = 1;
        private boolean active = true;
        private Instant createdAt;
        private Instant expiresAt;
        private Instant rotatedAt;
        private String purpose;
        private String keyChecksum;
        
        public Builder id(UUID id) {
            this.id = id;
            return this;
        }
        
        public Builder user(User user) {
            this.user = user;
            return this;
        }
        
        public Builder keyType(KeyType keyType) {
            this.keyType = keyType;
            return this;
        }
        
        public Builder algorithm(String algorithm) {
            this.algorithm = algorithm;
            return this;
        }
        
        public Builder keySize(int keySize) {
            this.keySize = keySize;
            return this;
        }
        
        public Builder encryptedKeyMaterial(String encryptedKeyMaterial) {
            this.encryptedKeyMaterial = encryptedKeyMaterial;
            return this;
        }
        
        public Builder encryptingKeyId(UUID encryptingKeyId) {
            this.encryptingKeyId = encryptingKeyId;
            return this;
        }
        
        public Builder version(int version) {
            this.version = version;
            return this;
        }
        
        public Builder active(boolean active) {
            this.active = active;
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
        
        public Builder rotatedAt(Instant rotatedAt) {
            this.rotatedAt = rotatedAt;
            return this;
        }
        
        public Builder purpose(String purpose) {
            this.purpose = purpose;
            return this;
        }
        
        public Builder keyChecksum(String keyChecksum) {
            this.keyChecksum = keyChecksum;
            return this;
        }
        
        public EncryptionKey build() {
            return new EncryptionKey(id, user, keyType, algorithm, keySize,
                                   encryptedKeyMaterial, encryptingKeyId, version, active,
                                   createdAt, expiresAt, rotatedAt, purpose, keyChecksum);
        }
    }
    
    public enum KeyType {
        MASTER,      // System master key (HSM protected in production)
        USER_KEK,    // User's key encryption key
        SESSION,     // Ephemeral session key
        MESSAGE,     // Per-message content key
        ASYMMETRIC_PUBLIC,  // RSA/ECC public key
        ASYMMETRIC_PRIVATE  // RSA/ECC private key (encrypted)
    }
}
