package com.intelcrypt.crypto;

import com.intelcrypt.exception.CryptoException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.util.Base64;

/**
 * Hybrid Encryption Service combining AES and RSA/ECC.
 * 
 * ENCRYPTION WORKFLOW (E2EE):
 * 
 * 1. Sender generates random AES session key
 * 2. Sender encrypts message with AES session key
 * 3. Sender encrypts AES session key with recipient's public key (RSA/ECC)
 * 4. Both encrypted content and encrypted key are sent to recipient
 * 
 * DECRYPTION WORKFLOW:
 * 
 * 1. Recipient decrypts AES session key using their private key
 * 2. Recipient decrypts message content using AES session key
 * 3. Session key is discarded (forward secrecy)
 * 
 * This hybrid approach provides:
 * - Performance of symmetric encryption for bulk data
 * - Security of asymmetric encryption for key exchange
 * - Forward secrecy (new key per message)
 */
@Component
public class HybridCryptoService {
    
    private static final Logger log = LoggerFactory.getLogger(HybridCryptoService.class);
    
    private AESCryptoService aesCryptoService;
    private AsymmetricCryptoService asymmetricCryptoService;
    
    /**
     * Default constructor for standalone use.
     */
    public HybridCryptoService() {
        this.aesCryptoService = new AESCryptoService();
        this.asymmetricCryptoService = new AsymmetricCryptoService();
    }
    
    /**
     * Spring injection constructor.
     */
    @Autowired
    public HybridCryptoService(AESCryptoService aesCryptoService, 
                                AsymmetricCryptoService asymmetricCryptoService) {
        this.aesCryptoService = aesCryptoService;
        this.asymmetricCryptoService = asymmetricCryptoService;
    }
    
    /**
     * Result of hybrid encryption containing encrypted content and encrypted key.
     */
            public static class HybridEncryptionResult {
        private byte[] encryptedData;     // AES-encrypted message content
        private byte[] encryptedKey;      // RSA-encrypted AES key
        private byte[] iv;                // IV used for AES encryption
        private CipherMode mode;
        private int keySize;
        private int encryptionRounds;
        
        public HybridEncryptionResult() {}
        public HybridEncryptionResult(byte[] encryptedData, byte[] encryptedKey, byte[] iv,
                                     CipherMode mode, int keySize, int encryptionRounds) {
            this.encryptedData = encryptedData;
            this.encryptedKey = encryptedKey;
            this.iv = iv;
            this.mode = mode;
            this.keySize = keySize;
            this.encryptionRounds = encryptionRounds;
        }
        
        public byte[] getEncryptedData() { return encryptedData; }
        public void setEncryptedData(byte[] encryptedData) { this.encryptedData = encryptedData; }
        public byte[] getEncryptedKey() { return encryptedKey; }
        public void setEncryptedKey(byte[] encryptedKey) { this.encryptedKey = encryptedKey; }
        public byte[] getIv() { return iv; }
        public void setIv(byte[] iv) { this.iv = iv; }
        public CipherMode getMode() { return mode; }
        public void setMode(CipherMode mode) { this.mode = mode; }
        public int getKeySize() { return keySize; }
        public void setKeySize(int keySize) { this.keySize = keySize; }
        public int getEncryptionRounds() { return encryptionRounds; }
        public void setEncryptionRounds(int encryptionRounds) { this.encryptionRounds = encryptionRounds; }
        
        public String getEncryptedDataBase64() {
            return Base64.getEncoder().encodeToString(encryptedData);
        }
        
        public String getEncryptedKeyBase64() {
            return Base64.getEncoder().encodeToString(encryptedKey);
        }
        
        public String getIvBase64() {
            return Base64.getEncoder().encodeToString(iv);
        }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private byte[] encryptedData;
            private byte[] encryptedKey;
            private byte[] iv;
            private CipherMode mode;
            private int keySize;
            private int encryptionRounds;
            
            public Builder encryptedData(byte[] encryptedData) { this.encryptedData = encryptedData; return this; }
            public Builder encryptedKey(byte[] encryptedKey) { this.encryptedKey = encryptedKey; return this; }
            public Builder iv(byte[] iv) { this.iv = iv; return this; }
            public Builder mode(CipherMode mode) { this.mode = mode; return this; }
            public Builder keySize(int keySize) { this.keySize = keySize; return this; }
            public Builder encryptionRounds(int encryptionRounds) { this.encryptionRounds = encryptionRounds; return this; }
            public HybridEncryptionResult build() {
                return new HybridEncryptionResult(encryptedData, encryptedKey, iv, mode, keySize, encryptionRounds);
            }
        }
    }
    
    /**
     * Encrypt bytes for a recipient using hybrid encryption.
     */
    public HybridEncryptionResult encryptHybrid(byte[] plaintext, PublicKey recipientPublicKey,
                                                 CipherMode mode, int keySize) {
        return encryptHybridMultiRound(plaintext, recipientPublicKey, mode, keySize, 1);
    }
    
    /**
     * Encrypt with multi-round AES.
     */
    public HybridEncryptionResult encryptHybridMultiRound(byte[] plaintext, PublicKey recipientPublicKey,
                                                          CipherMode mode, int keySize, int rounds) {
        try {
            // Step 1: Generate random AES session key
            byte[] sessionKey = aesCryptoService.generateKey(keySize);
            
            // Step 2: Encrypt message with AES session key
            EncryptionResult aesResult = rounds > 1 
                ? aesCryptoService.encryptMultiRound(plaintext, sessionKey, mode, rounds)
                : aesCryptoService.encrypt(plaintext, sessionKey, mode);
            
            // Step 3: Encrypt session key with recipient's public key
            byte[] encryptedKey = asymmetricCryptoService.encryptWithPublicKey(sessionKey, recipientPublicKey);
            
            // Clear session key from memory
            java.util.Arrays.fill(sessionKey, (byte) 0);
            
            log.debug("Hybrid encryption completed: mode={}, keySize={}, rounds={}", 
                     mode, keySize, rounds);
            
            return HybridEncryptionResult.builder()
                .encryptedData(aesResult.getCiphertext())
                .encryptedKey(encryptedKey)
                .iv(aesResult.getIv())
                .mode(mode)
                .keySize(keySize)
                .encryptionRounds(rounds)
                .build();
            
        } catch (Exception e) {
            throw new CryptoException("Hybrid encryption failed", e);
        }
    }
    
    /**
     * Decrypt using hybrid decryption.
     */
    public byte[] decryptHybrid(HybridEncryptionResult encrypted, PrivateKey recipientPrivateKey) {
        return decryptHybridMultiRound(encrypted, recipientPrivateKey, 1);
    }
    
    /**
     * Decrypt multi-round hybrid encryption.
     */
    public byte[] decryptHybridMultiRound(HybridEncryptionResult encrypted, PrivateKey recipientPrivateKey, int rounds) {
        try {
            // Step 1: Decrypt AES session key with private key
            byte[] sessionKey = asymmetricCryptoService.decryptWithPrivateKey(
                encrypted.getEncryptedKey(), recipientPrivateKey);
            
            // Reconstruct encryption result
            EncryptionResult aesResult = EncryptionResult.builder()
                .ciphertext(encrypted.getEncryptedData())
                .iv(encrypted.getIv())
                .mode(encrypted.getMode())
                .keySize(encrypted.getKeySize())
                .encryptionRounds(rounds)
                .build();
            
            // Step 2: Decrypt message with AES session key
            byte[] plaintext = rounds > 1
                ? aesCryptoService.decryptMultiRound(aesResult, sessionKey, encrypted.getMode(), rounds)
                : aesCryptoService.decrypt(aesResult, sessionKey, encrypted.getMode());
            
            // Clear session key from memory
            java.util.Arrays.fill(sessionKey, (byte) 0);
            
            log.debug("Hybrid decryption completed successfully");
            
            return plaintext;
            
        } catch (Exception e) {
            throw new CryptoException("Hybrid decryption failed", e);
        }
    }
    
    // ============= String-based API for Service Layer =============
    
    /**
     * Result of string-based hybrid encryption.
     */
    public record StringEncryptionResult(
        String encryptedContent,  // Base64-encoded encrypted content
        String encryptedKey,      // Base64-encoded encrypted key
        CipherMode mode,
        int keySize,
        int rounds
    ) {}
    
    /**
     * Encrypt a message for a recipient using hybrid encryption (String API).
     */
    public StringEncryptionResult encrypt(String plaintext, String recipientPublicKey,
                                           CipherMode mode, int keySize, int rounds) {
        try {
            PublicKey publicKey = asymmetricCryptoService.decodePublicKey(recipientPublicKey, "RSA");
            HybridEncryptionResult result = encryptHybridMultiRound(
                plaintext.getBytes(java.nio.charset.StandardCharsets.UTF_8),
                publicKey,
                mode,
                keySize,
                rounds
            );
            
            // Combine IV and encrypted data for storage
            String combined = result.getIvBase64() + ":" + result.getEncryptedDataBase64();
            
            return new StringEncryptionResult(
                combined,
                result.getEncryptedKeyBase64(),
                mode,
                keySize,
                rounds
            );
        } catch (Exception e) {
            throw new CryptoException("Hybrid encryption failed", e);
        }
    }
    
    /**
     * Decrypt a message using hybrid decryption (String API).
     */
    public String decrypt(String encryptedContent, String encryptedKey,
                         PrivateKey recipientPrivateKey, CipherMode mode, int rounds) {
        try {
            // Parse combined format (IV:Ciphertext)
            String[] parts = encryptedContent.split(":");
            byte[] iv = Base64.getDecoder().decode(parts[0]);
            byte[] ciphertext = Base64.getDecoder().decode(parts[1]);
            byte[] encKeyBytes = Base64.getDecoder().decode(encryptedKey);
            
            HybridEncryptionResult encrypted = HybridEncryptionResult.builder()
                .encryptedData(ciphertext)
                .encryptedKey(encKeyBytes)
                .iv(iv)
                .mode(mode)
                .keySize(256)
                .encryptionRounds(rounds)
                .build();
            
            byte[] plaintext = decryptHybridMultiRound(encrypted, recipientPrivateKey, rounds);
            return new String(plaintext, java.nio.charset.StandardCharsets.UTF_8);
            
        } catch (Exception e) {
            throw new CryptoException("Hybrid decryption failed", e);
        }
    }
    
    /**
     * Generate a new key pair for a user.
     * Returns public key (shareable) and encrypted private key (for storage).
     */
    public record UserKeyPair(
        String publicKey,           // PEM-encoded public key
        String encryptedPrivateKey, // Encrypted with user's password
        String salt                 // Salt used for password-based encryption
    ) {}
    
    /**
     * Generate user key pair with encrypted private key.
     * 
     * @param password User's password for private key encryption
     * @return UserKeyPair with public key and encrypted private key
     */
    public UserKeyPair generateUserKeyPair(String password) {
        try {
            // Generate RSA key pair
            KeyPair keyPair = asymmetricCryptoService.generateRSAKeyPair();
            
            // Encode public key
            String publicKeyPem = asymmetricCryptoService.encodePublicKey(keyPair.getPublic());
            
            // Generate salt and encrypt private key
            byte[] salt = asymmetricCryptoService.generateSalt();
            String saltBase64 = Base64.getEncoder().encodeToString(salt);
            String encryptedPrivateKey = asymmetricCryptoService.encryptPrivateKey(
                keyPair.getPrivate(), password, salt);
            
            log.info("Generated new user key pair");
            
            return new UserKeyPair(publicKeyPem, encryptedPrivateKey, saltBase64);
            
        } catch (Exception e) {
            throw new CryptoException("Failed to generate user key pair", e);
        }
    }
    
    /**
     * Recover user's private key using their password.
     */
    public PrivateKey recoverPrivateKey(String encryptedPrivateKey, String password, String saltBase64) {
        byte[] salt = Base64.getDecoder().decode(saltBase64);
        return asymmetricCryptoService.decryptPrivateKey(encryptedPrivateKey, password, salt, "RSA");
    }
}
