package com.intelcrypt.dto;

import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.Objects;

/**
 * Key management DTOs.
 */
public class KeyDTO {
    
    /**
     * Request to generate new key pair.
     */
    public static class GenerateKeyPairRequest {
        @NotNull(message = "Password is required")
        private String password;
        private String algorithm;
        private Integer keySize;
        
        public GenerateKeyPairRequest() {}
        public GenerateKeyPairRequest(String password, String algorithm, Integer keySize) {
            this.password = password;
            this.algorithm = algorithm;
            this.keySize = keySize;
        }
        
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
        public String getAlgorithm() { return algorithm; }
        public void setAlgorithm(String algorithm) { this.algorithm = algorithm; }
        public Integer getKeySize() { return keySize; }
        public void setKeySize(Integer keySize) { this.keySize = keySize; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String password;
            private String algorithm;
            private Integer keySize;
            public Builder password(String password) { this.password = password; return this; }
            public Builder algorithm(String algorithm) { this.algorithm = algorithm; return this; }
            public Builder keySize(Integer keySize) { this.keySize = keySize; return this; }
            public GenerateKeyPairRequest build() { return new GenerateKeyPairRequest(password, algorithm, keySize); }
        }
    }
    
    /**
     * Key pair generation response.
     */
    public static class KeyPairResponse {
        private String keyId;
        private String publicKey;
        private String algorithm;
        private int keySize;
        private Instant createdAt;
        private Instant expiresAt;
        
        public KeyPairResponse() {}
        public KeyPairResponse(String keyId, String publicKey, String algorithm, int keySize, Instant createdAt, Instant expiresAt) {
            this.keyId = keyId;
            this.publicKey = publicKey;
            this.algorithm = algorithm;
            this.keySize = keySize;
            this.createdAt = createdAt;
            this.expiresAt = expiresAt;
        }
        
        public String getKeyId() { return keyId; }
        public void setKeyId(String keyId) { this.keyId = keyId; }
        public String getPublicKey() { return publicKey; }
        public void setPublicKey(String publicKey) { this.publicKey = publicKey; }
        public String getAlgorithm() { return algorithm; }
        public void setAlgorithm(String algorithm) { this.algorithm = algorithm; }
        public int getKeySize() { return keySize; }
        public void setKeySize(int keySize) { this.keySize = keySize; }
        public Instant getCreatedAt() { return createdAt; }
        public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
        public Instant getExpiresAt() { return expiresAt; }
        public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String keyId;
            private String publicKey;
            private String algorithm;
            private int keySize;
            private Instant createdAt;
            private Instant expiresAt;
            public Builder keyId(String keyId) { this.keyId = keyId; return this; }
            public Builder publicKey(String publicKey) { this.publicKey = publicKey; return this; }
            public Builder algorithm(String algorithm) { this.algorithm = algorithm; return this; }
            public Builder keySize(int keySize) { this.keySize = keySize; return this; }
            public Builder createdAt(Instant createdAt) { this.createdAt = createdAt; return this; }
            public Builder expiresAt(Instant expiresAt) { this.expiresAt = expiresAt; return this; }
            public KeyPairResponse build() { return new KeyPairResponse(keyId, publicKey, algorithm, keySize, createdAt, expiresAt); }
        }
    }
    
    /**
     * Public key response (for message encryption).
     */
    public static class PublicKeyResponse {
        private String username;
        private String publicKey;
        private String algorithm;
        private int keySize;
        
        public PublicKeyResponse() {}
        public PublicKeyResponse(String username, String publicKey, String algorithm, int keySize) {
            this.username = username;
            this.publicKey = publicKey;
            this.algorithm = algorithm;
            this.keySize = keySize;
        }
        
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        public String getPublicKey() { return publicKey; }
        public void setPublicKey(String publicKey) { this.publicKey = publicKey; }
        public String getAlgorithm() { return algorithm; }
        public void setAlgorithm(String algorithm) { this.algorithm = algorithm; }
        public int getKeySize() { return keySize; }
        public void setKeySize(int keySize) { this.keySize = keySize; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String username;
            private String publicKey;
            private String algorithm;
            private int keySize;
            public Builder username(String username) { this.username = username; return this; }
            public Builder publicKey(String publicKey) { this.publicKey = publicKey; return this; }
            public Builder algorithm(String algorithm) { this.algorithm = algorithm; return this; }
            public Builder keySize(int keySize) { this.keySize = keySize; return this; }
            public PublicKeyResponse build() { return new PublicKeyResponse(username, publicKey, algorithm, keySize); }
        }
    }
    
    /**
     * Request to rotate keys.
     */
    public static class RotateKeyRequest {
        @NotNull(message = "Password is required")
        private String password;
        private String reason;
        
        public RotateKeyRequest() {}
        public RotateKeyRequest(String password, String reason) {
            this.password = password;
            this.reason = reason;
        }
        
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
        public String getReason() { return reason; }
        public void setReason(String reason) { this.reason = reason; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String password;
            private String reason;
            public Builder password(String password) { this.password = password; return this; }
            public Builder reason(String reason) { this.reason = reason; return this; }
            public RotateKeyRequest build() { return new RotateKeyRequest(password, reason); }
        }
    }
    
    /**
     * AES key generation request (for session keys).
     */
    public static class GenerateAESKeyRequest {
        private Integer keySize;
        private String purpose;
        
        public GenerateAESKeyRequest() {}
        public GenerateAESKeyRequest(Integer keySize, String purpose) {
            this.keySize = keySize;
            this.purpose = purpose;
        }
        
        public Integer getKeySize() { return keySize; }
        public void setKeySize(Integer keySize) { this.keySize = keySize; }
        public String getPurpose() { return purpose; }
        public void setPurpose(String purpose) { this.purpose = purpose; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private Integer keySize;
            private String purpose;
            public Builder keySize(Integer keySize) { this.keySize = keySize; return this; }
            public Builder purpose(String purpose) { this.purpose = purpose; return this; }
            public GenerateAESKeyRequest build() { return new GenerateAESKeyRequest(keySize, purpose); }
        }
    }
    
    /**
     * AES key response.
     */
    public static class AESKeyResponse {
        private String keyId;
        private String key;
        private int keySize;
        private Instant createdAt;
        
        public AESKeyResponse() {}
        public AESKeyResponse(String keyId, String key, int keySize, Instant createdAt) {
            this.keyId = keyId;
            this.key = key;
            this.keySize = keySize;
            this.createdAt = createdAt;
        }
        
        public String getKeyId() { return keyId; }
        public void setKeyId(String keyId) { this.keyId = keyId; }
        public String getKey() { return key; }
        public void setKey(String key) { this.key = key; }
        public int getKeySize() { return keySize; }
        public void setKeySize(int keySize) { this.keySize = keySize; }
        public Instant getCreatedAt() { return createdAt; }
        public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String keyId;
            private String key;
            private int keySize;
            private Instant createdAt;
            public Builder keyId(String keyId) { this.keyId = keyId; return this; }
            public Builder key(String key) { this.key = key; return this; }
            public Builder keySize(int keySize) { this.keySize = keySize; return this; }
            public Builder createdAt(Instant createdAt) { this.createdAt = createdAt; return this; }
            public AESKeyResponse build() { return new AESKeyResponse(keyId, key, keySize, createdAt); }
        }
    }
    
    /**
     * Key info (without sensitive data).
     */
    public static class KeyInfo {
        private String id;
        private String keyType;
        private String algorithm;
        private int keySize;
        private int version;
        private boolean active;
        private Instant createdAt;
        private Instant expiresAt;
        private String purpose;
        
        public KeyInfo() {}
        public KeyInfo(String id, String keyType, String algorithm, int keySize, int version,
                      boolean active, Instant createdAt, Instant expiresAt, String purpose) {
            this.id = id;
            this.keyType = keyType;
            this.algorithm = algorithm;
            this.keySize = keySize;
            this.version = version;
            this.active = active;
            this.createdAt = createdAt;
            this.expiresAt = expiresAt;
            this.purpose = purpose;
        }
        
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getKeyType() { return keyType; }
        public void setKeyType(String keyType) { this.keyType = keyType; }
        public String getAlgorithm() { return algorithm; }
        public void setAlgorithm(String algorithm) { this.algorithm = algorithm; }
        public int getKeySize() { return keySize; }
        public void setKeySize(int keySize) { this.keySize = keySize; }
        public int getVersion() { return version; }
        public void setVersion(int version) { this.version = version; }
        public boolean isActive() { return active; }
        public void setActive(boolean active) { this.active = active; }
        public Instant getCreatedAt() { return createdAt; }
        public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
        public Instant getExpiresAt() { return expiresAt; }
        public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
        public String getPurpose() { return purpose; }
        public void setPurpose(String purpose) { this.purpose = purpose; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String id;
            private String keyType;
            private String algorithm;
            private int keySize;
            private int version;
            private boolean active;
            private Instant createdAt;
            private Instant expiresAt;
            private String purpose;
            public Builder id(String id) { this.id = id; return this; }
            public Builder keyType(String keyType) { this.keyType = keyType; return this; }
            public Builder algorithm(String algorithm) { this.algorithm = algorithm; return this; }
            public Builder keySize(int keySize) { this.keySize = keySize; return this; }
            public Builder version(int version) { this.version = version; return this; }
            public Builder active(boolean active) { this.active = active; return this; }
            public Builder createdAt(Instant createdAt) { this.createdAt = createdAt; return this; }
            public Builder expiresAt(Instant expiresAt) { this.expiresAt = expiresAt; return this; }
            public Builder purpose(String purpose) { this.purpose = purpose; return this; }
            public KeyInfo build() { 
                return new KeyInfo(id, keyType, algorithm, keySize, version, active, createdAt, expiresAt, purpose); 
            }
        }
    }
}
