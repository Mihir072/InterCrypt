package com.intelcrypt.crypto;

/**
 * Cipher mode enumeration for AES encryption.
 * 
 * Each mode has specific security characteristics:
 * - GCM: Authenticated encryption, recommended for most use cases
 * - CBC: Requires separate HMAC for integrity, legacy support
 * - CTR: Stream cipher mode, parallelizable
 * - XTS: Disk encryption mode, for storage
 */
public enum CipherMode {
    
    /**
     * Galois/Counter Mode - Authenticated encryption (AEAD)
     * Provides both confidentiality and integrity
     * Recommended for network communications
     */
    GCM("AES/GCM/NoPadding", true, 12, 128),
    
    /**
     * Cipher Block Chaining - Classic block cipher mode
     * Requires PKCS7 padding and separate HMAC for integrity
     */
    CBC("AES/CBC/PKCS5Padding", false, 16, 0),
    
    /**
     * Counter Mode - Stream cipher operation
     * Allows parallel processing, no padding needed
     */
    CTR("AES/CTR/NoPadding", false, 16, 0),
    
    /**
     * XEX-based Tweaked-codebook mode with ciphertext Stealing
     * Designed for disk/storage encryption
     */
    XTS("AES/XTS/NoPadding", false, 16, 0);
    
    private final String transformation;
    private final boolean authenticated;
    private final int ivLength;
    private final int tagLengthBits;
    
    CipherMode(String transformation, boolean authenticated, int ivLength, int tagLengthBits) {
        this.transformation = transformation;
        this.authenticated = authenticated;
        this.ivLength = ivLength;
        this.tagLengthBits = tagLengthBits;
    }
    
    public String getTransformation() {
        return transformation;
    }
    
    /**
     * Whether this mode provides built-in authentication
     */
    public boolean isAuthenticated() {
        return authenticated;
    }
    
    /**
     * Required IV/nonce length in bytes
     */
    public int getIvLength() {
        return ivLength;
    }
    
    /**
     * Authentication tag length for AEAD modes (bits)
     */
    public int getTagLengthBits() {
        return tagLengthBits;
    }
    
    public static CipherMode fromString(String mode) {
        try {
            return valueOf(mode.toUpperCase());
        } catch (IllegalArgumentException e) {
            return GCM; // Default to most secure mode
        }
    }
}
