package com.intelcrypt.crypto;

import java.util.Base64;
import java.util.Objects;

/**
 * Immutable result of an encryption operation.
 * Contains all data needed for decryption and verification.
 * Supports both byte[] and Base64 string representations.
 */
public class EncryptionResult {
    
    /**
     * Raw ciphertext bytes
     */
    private byte[] ciphertext;
    
    /**
     * Raw initialization vector bytes
     */
    private byte[] iv;
    
    /**
     * Raw authentication tag bytes (for AEAD modes)
     */
    private byte[] authTag;
    
    /**
     * Cipher mode used for encryption
     */
    private CipherMode mode;
    
    /**
     * AES key size in bits
     */
    private int keySize;
    
    /**
     * Number of encryption rounds applied
     */
    private int encryptionRounds;
    
    /**
     * HMAC for non-authenticated modes (optional)
     */
    private String hmac;
    
    // Constructors
    public EncryptionResult() {
    }
    
    public EncryptionResult(byte[] ciphertext, byte[] iv, byte[] authTag,
                           CipherMode mode, int keySize, int encryptionRounds, String hmac) {
        this.ciphertext = ciphertext;
        this.iv = iv;
        this.authTag = authTag;
        this.mode = mode;
        this.keySize = keySize;
        this.encryptionRounds = encryptionRounds;
        this.hmac = hmac;
    }
    
    // Getters
    public byte[] getCiphertext() {
        return ciphertext;
    }
    
    public void setCiphertext(byte[] ciphertext) {
        this.ciphertext = ciphertext;
    }
    
    public byte[] getIv() {
        return iv;
    }
    
    public void setIv(byte[] iv) {
        this.iv = iv;
    }
    
    public byte[] getAuthTag() {
        return authTag;
    }
    
    public void setAuthTag(byte[] authTag) {
        this.authTag = authTag;
    }
    
    public CipherMode getMode() {
        return mode;
    }
    
    public void setMode(CipherMode mode) {
        this.mode = mode;
    }
    
    public int getKeySize() {
        return keySize;
    }
    
    public void setKeySize(int keySize) {
        this.keySize = keySize;
    }
    
    public int getEncryptionRounds() {
        return encryptionRounds;
    }
    
    public void setEncryptionRounds(int encryptionRounds) {
        this.encryptionRounds = encryptionRounds;
    }
    
    public String getHmac() {
        return hmac;
    }
    
    public void setHmac(String hmac) {
        this.hmac = hmac;
    }
    
    /**
     * Get Base64-encoded ciphertext
     */
    public String getCiphertextBase64() {
        return ciphertext != null ? Base64.getEncoder().encodeToString(ciphertext) : null;
    }
    
    /**
     * Get Base64-encoded IV
     */
    public String getIvBase64() {
        return iv != null ? Base64.getEncoder().encodeToString(iv) : null;
    }
    
    /**
     * Get Base64-encoded auth tag
     */
    public String getAuthTagBase64() {
        return authTag != null ? Base64.getEncoder().encodeToString(authTag) : null;
    }
    
    /**
     * Combine IV, ciphertext, and tag into single Base64 string for storage
     * Format: IV || Ciphertext || AuthTag (if applicable)
     */
    public String getCombined() {
        String ivB64 = getIvBase64();
        String ctB64 = getCiphertextBase64();
        String tagB64 = getAuthTagBase64();
        
        if (tagB64 != null) {
            return ivB64 + ":" + ctB64 + ":" + tagB64;
        }
        return ivB64 + ":" + ctB64;
    }
    
    /**
     * Parse combined format back to components
     */
    public static EncryptionResult fromCombined(String combined, CipherMode mode, int keySize, int rounds) {
        String[] parts = combined.split(":");
        EncryptionResultBuilder builder = EncryptionResult.builder()
            .iv(Base64.getDecoder().decode(parts[0]))
            .ciphertext(Base64.getDecoder().decode(parts[1]))
            .mode(mode)
            .keySize(keySize)
            .encryptionRounds(rounds);
            
        if (parts.length > 2) {
            builder.authTag(Base64.getDecoder().decode(parts[2]));
        }
        
        return builder.build();
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        EncryptionResult that = (EncryptionResult) o;
        return keySize == that.keySize &&
               encryptionRounds == that.encryptionRounds &&
               java.util.Arrays.equals(ciphertext, that.ciphertext) &&
               java.util.Arrays.equals(iv, that.iv) &&
               java.util.Arrays.equals(authTag, that.authTag) &&
               mode == that.mode &&
               Objects.equals(hmac, that.hmac);
    }
    
    @Override
    public int hashCode() {
        int result = Objects.hash(mode, keySize, encryptionRounds, hmac);
        result = 31 * result + java.util.Arrays.hashCode(ciphertext);
        result = 31 * result + java.util.Arrays.hashCode(iv);
        result = 31 * result + java.util.Arrays.hashCode(authTag);
        return result;
    }
    
    @Override
    public String toString() {
        return "EncryptionResult{" +
                "mode=" + mode +
                ", keySize=" + keySize +
                ", encryptionRounds=" + encryptionRounds +
                ", ciphertextLength=" + (ciphertext != null ? ciphertext.length : 0) +
                ", ivLength=" + (iv != null ? iv.length : 0) +
                '}';
    }
    
    // Builder
    public static EncryptionResultBuilder builder() {
        return new EncryptionResultBuilder();
    }
    
    public static class EncryptionResultBuilder {
        private byte[] ciphertext;
        private byte[] iv;
        private byte[] authTag;
        private CipherMode mode;
        private int keySize;
        private int encryptionRounds;
        private String hmac;
        
        public EncryptionResultBuilder ciphertext(byte[] ciphertext) {
            this.ciphertext = ciphertext;
            return this;
        }
        
        public EncryptionResultBuilder iv(byte[] iv) {
            this.iv = iv;
            return this;
        }
        
        public EncryptionResultBuilder authTag(byte[] authTag) {
            this.authTag = authTag;
            return this;
        }
        
        public EncryptionResultBuilder mode(CipherMode mode) {
            this.mode = mode;
            return this;
        }
        
        public EncryptionResultBuilder keySize(int keySize) {
            this.keySize = keySize;
            return this;
        }
        
        public EncryptionResultBuilder encryptionRounds(int encryptionRounds) {
            this.encryptionRounds = encryptionRounds;
            return this;
        }
        
        public EncryptionResultBuilder hmac(String hmac) {
            this.hmac = hmac;
            return this;
        }
        
        public EncryptionResult build() {
            return new EncryptionResult(ciphertext, iv, authTag, mode, keySize, encryptionRounds, hmac);
        }
    }
}
