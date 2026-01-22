package com.intelcrypt.service;

import com.intelcrypt.config.CryptoConfigProperties;
import com.intelcrypt.crypto.AESCryptoService;
import com.intelcrypt.crypto.AsymmetricCryptoService;
import com.intelcrypt.crypto.CipherMode;
import com.intelcrypt.crypto.HybridCryptoService;
import com.intelcrypt.dto.KeyDTO;
import com.intelcrypt.entity.AuditLog;
import com.intelcrypt.entity.EncryptionKey;
import com.intelcrypt.entity.User;
import com.intelcrypt.exception.CryptoException;
import com.intelcrypt.exception.ResourceNotFoundException;
import com.intelcrypt.repository.EncryptionKeyRepository;
import com.intelcrypt.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.KeyPair;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

/**
 * Key Management Service.
 * 
 * SECURITY FEATURES:
 * - Secure key generation using cryptographically secure random
 * - Key encryption at rest (keys are encrypted before storage)
 * - Key rotation with configurable intervals
 * - Audit logging of all key operations
 * - Key versioning for rotation tracking
 */
@Service
public class KeyService {
    
    private static final Logger log = LoggerFactory.getLogger(KeyService.class);
    
    private final EncryptionKeyRepository keyRepository;
    private final UserRepository userRepository;
    private final AESCryptoService aesService;
    private final AsymmetricCryptoService asymmetricService;
    private final HybridCryptoService hybridService;
    private final AuditService auditService;
    private final CryptoConfigProperties config;
    
    public KeyService(EncryptionKeyRepository keyRepository,
                     UserRepository userRepository,
                     AESCryptoService aesService,
                     AsymmetricCryptoService asymmetricService,
                     HybridCryptoService hybridService,
                     AuditService auditService,
                     CryptoConfigProperties config) {
        this.keyRepository = keyRepository;
        this.userRepository = userRepository;
        this.aesService = aesService;
        this.asymmetricService = asymmetricService;
        this.hybridService = hybridService;
        this.auditService = auditService;
        this.config = config;
    }
    
    /**
     * Generate new key pair for a user.
     */
    @Transactional
    public KeyDTO.KeyPairResponse generateUserKeyPair(UUID userId, 
                                                      KeyDTO.GenerateKeyPairRequest request,
                                                      String ipAddress) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User", userId.toString()));
        
        String algorithm = request.getAlgorithm() != null ? request.getAlgorithm() : "RSA";
        int keySize = request.getKeySize() != null ? request.getKeySize() : 
                     config.getCrypto().getRsa().getKeySize();
        
        // Generate new key pair
        var keyPairResult = hybridService.generateUserKeyPair(request.getPassword());
        
        // Update user's keys
        user.setPublicKey(keyPairResult.publicKey());
        user.setEncryptedPrivateKey(keyPairResult.encryptedPrivateKey());
        user.setPrivateKeySalt(keyPairResult.salt());
        userRepository.save(user);
        
        // Calculate expiration
        Instant expiresAt = config.getCrypto().getKeyRotation().isEnabled() ?
            Instant.now().plus(config.getCrypto().getKeyRotation().getIntervalDays(), ChronoUnit.DAYS) :
            null;
        
        // Store key metadata
        EncryptionKey keyEntity = EncryptionKey.builder()
            .user(user)
            .keyType(EncryptionKey.KeyType.ASYMMETRIC_PUBLIC)
            .algorithm(algorithm)
            .keySize(keySize)
            .encryptedKeyMaterial(keyPairResult.publicKey()) // Public key can be stored as-is
            .active(true)
            .version(1)
            .expiresAt(expiresAt)
            .purpose("User E2EE Key Pair")
            .build();
        
        keyEntity = keyRepository.save(keyEntity);
        
        auditService.logCryptoEvent(
            AuditLog.EventType.KEY_GENERATED,
            userId,
            user.getUsername(),
            keyEntity.getId(),
            ipAddress,
            "Generated new " + algorithm + "-" + keySize + " key pair"
        );
        
        log.info("Generated key pair for user: {}", user.getUsername());
        
        return KeyDTO.KeyPairResponse.builder()
            .keyId(keyEntity.getId().toString())
            .publicKey(keyPairResult.publicKey())
            .algorithm(algorithm)
            .keySize(keySize)
            .createdAt(keyEntity.getCreatedAt())
            .expiresAt(expiresAt)
            .build();
    }
    
    /**
     * Get user's public key (for sending encrypted messages).
     */
    public KeyDTO.PublicKeyResponse getUserPublicKey(String username) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new ResourceNotFoundException("User", username));
        
        if (user.getPublicKey() == null || user.getPublicKey().isEmpty()) {
            throw new CryptoException("User has no public key configured");
        }
        
        return KeyDTO.PublicKeyResponse.builder()
            .username(username)
            .publicKey(user.getPublicKey())
            .algorithm("RSA")
            .keySize(config.getCrypto().getRsa().getKeySize())
            .build();
    }
    
    /**
     * Generate AES session key.
     */
    public KeyDTO.AESKeyResponse generateAESKey(UUID userId, 
                                                KeyDTO.GenerateAESKeyRequest request,
                                                String ipAddress) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User", userId.toString()));
        
        int keySize = request.getKeySize() != null ? request.getKeySize() :
                     config.getCrypto().getAes().getDefaultKeySize();
        
        byte[] keyBytes = aesService.generateKey(keySize);
        String key = Base64.getEncoder().encodeToString(keyBytes);
        
        // Store encrypted key
        byte[] encryptedKeyBytes = asymmetricService.encryptWithPublicKey(
            keyBytes,
            asymmetricService.decodePublicKey(user.getPublicKey(), "RSA")
        );
        String encryptedKey = Base64.getEncoder().encodeToString(encryptedKeyBytes);
        
        EncryptionKey keyEntity = EncryptionKey.builder()
            .user(user)
            .keyType(EncryptionKey.KeyType.SESSION)
            .algorithm("AES")
            .keySize(keySize)
            .encryptedKeyMaterial(encryptedKey)
            .active(true)
            .version(1)
            .purpose(request.getPurpose())
            .build();
        
        keyEntity = keyRepository.save(keyEntity);
        
        auditService.logCryptoEvent(
            AuditLog.EventType.KEY_GENERATED,
            userId,
            user.getUsername(),
            keyEntity.getId(),
            ipAddress,
            "Generated AES-" + keySize + " session key"
        );
        
        // WARNING: Key is only returned ONCE. User must store it securely.
        return KeyDTO.AESKeyResponse.builder()
            .keyId(keyEntity.getId().toString())
            .key(key) // Plaintext key - only returned this once!
            .keySize(keySize)
            .createdAt(keyEntity.getCreatedAt())
            .build();
    }
    
    /**
     * Rotate user's key pair.
     */
    @Transactional
    public KeyDTO.KeyPairResponse rotateUserKeys(UUID userId, 
                                                 KeyDTO.RotateKeyRequest request,
                                                 String ipAddress) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User", userId.toString()));
        
        // Get current key version
        int currentVersion = keyRepository.findActiveKey(userId, EncryptionKey.KeyType.ASYMMETRIC_PUBLIC)
            .map(EncryptionKey::getVersion)
            .orElse(0);
        
        // Deactivate old keys (but keep for potential decryption of old messages)
        keyRepository.deactivateUserKeys(userId, EncryptionKey.KeyType.ASYMMETRIC_PUBLIC, Instant.now());
        keyRepository.deactivateUserKeys(userId, EncryptionKey.KeyType.ASYMMETRIC_PRIVATE, Instant.now());
        
        // Generate new key pair
        var keyPairResult = hybridService.generateUserKeyPair(request.getPassword());
        
        // Update user
        user.setPublicKey(keyPairResult.publicKey());
        user.setEncryptedPrivateKey(keyPairResult.encryptedPrivateKey());
        user.setPrivateKeySalt(keyPairResult.salt());
        userRepository.save(user);
        
        Instant expiresAt = config.getCrypto().getKeyRotation().isEnabled() ?
            Instant.now().plus(config.getCrypto().getKeyRotation().getIntervalDays(), ChronoUnit.DAYS) :
            null;
        
        // Store new key metadata
        EncryptionKey keyEntity = EncryptionKey.builder()
            .user(user)
            .keyType(EncryptionKey.KeyType.ASYMMETRIC_PUBLIC)
            .algorithm("RSA")
            .keySize(config.getCrypto().getRsa().getKeySize())
            .encryptedKeyMaterial(keyPairResult.publicKey())
            .active(true)
            .version(currentVersion + 1)
            .expiresAt(expiresAt)
            .purpose("Key rotation" + (request.getReason() != null ? ": " + request.getReason() : ""))
            .build();
        
        keyEntity = keyRepository.save(keyEntity);
        
        auditService.logCryptoEvent(
            AuditLog.EventType.KEY_ROTATED,
            userId,
            user.getUsername(),
            keyEntity.getId(),
            ipAddress,
            "Rotated to version " + (currentVersion + 1) + 
                (request.getReason() != null ? " - Reason: " + request.getReason() : "")
        );
        
        log.info("Key rotation completed for user: {}, new version: {}", 
                user.getUsername(), currentVersion + 1);
        
        return KeyDTO.KeyPairResponse.builder()
            .keyId(keyEntity.getId().toString())
            .publicKey(keyPairResult.publicKey())
            .algorithm("RSA")
            .keySize(config.getCrypto().getRsa().getKeySize())
            .createdAt(keyEntity.getCreatedAt())
            .expiresAt(expiresAt)
            .build();
    }
    
    /**
     * List user's keys (metadata only).
     */
    public List<KeyDTO.KeyInfo> listUserKeys(UUID userId) {
        return keyRepository.findByUserId(userId).stream()
            .map(key -> KeyDTO.KeyInfo.builder()
                .id(key.getId().toString())
                .keyType(key.getKeyType().name())
                .algorithm(key.getAlgorithm())
                .keySize(key.getKeySize())
                .version(key.getVersion())
                .active(key.isActive())
                .createdAt(key.getCreatedAt())
                .expiresAt(key.getExpiresAt())
                .purpose(key.getPurpose())
                .build())
            .toList();
    }
    
    /**
     * Scheduled task: Check and alert for keys needing rotation.
     */
    @Scheduled(cron = "0 0 * * * *") // Every hour
    @Transactional
    public void checkKeyRotation() {
        if (!config.getCrypto().getKeyRotation().isEnabled()) {
            return;
        }
        
        List<EncryptionKey> keysNeedingRotation = keyRepository.findKeysNeedingRotation(Instant.now());
        
        for (EncryptionKey key : keysNeedingRotation) {
            log.warn("Key rotation needed: keyId={}, userId={}, expires={}",
                    key.getId(), key.getUser().getId(), key.getExpiresAt());
            
            auditService.logSecurityEvent(
                AuditLog.EventType.KEY_ROTATED,
                key.getUser().getId(),
                "SYSTEM",
                null,
                "Key rotation required for key: " + key.getId()
            );
        }
    }
}
