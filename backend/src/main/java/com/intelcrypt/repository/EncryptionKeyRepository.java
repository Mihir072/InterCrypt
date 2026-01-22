package com.intelcrypt.repository;

import com.intelcrypt.entity.EncryptionKey;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface EncryptionKeyRepository extends JpaRepository<EncryptionKey, UUID> {
    
    /**
     * Find active key by user and type.
     */
    @Query("SELECT k FROM EncryptionKey k WHERE k.user.id = :userId " +
           "AND k.keyType = :keyType AND k.active = true")
    Optional<EncryptionKey> findActiveKey(@Param("userId") UUID userId, 
                                          @Param("keyType") EncryptionKey.KeyType keyType);
    
    /**
     * Find all keys for a user.
     */
    List<EncryptionKey> findByUserId(UUID userId);
    
    /**
     * Find keys due for rotation.
     */
    @Query("SELECT k FROM EncryptionKey k WHERE k.active = true " +
           "AND k.expiresAt IS NOT NULL AND k.expiresAt < :now")
    List<EncryptionKey> findKeysNeedingRotation(@Param("now") Instant now);
    
    /**
     * Find system master key.
     */
    @Query("SELECT k FROM EncryptionKey k WHERE k.keyType = 'MASTER' " +
           "AND k.active = true AND k.user IS NULL")
    Optional<EncryptionKey> findActiveMasterKey();
    
    /**
     * Deactivate all keys for user of specific type.
     */
    @Query("UPDATE EncryptionKey k SET k.active = false, k.rotatedAt = :now " +
           "WHERE k.user.id = :userId AND k.keyType = :keyType AND k.active = true")
    int deactivateUserKeys(@Param("userId") UUID userId, 
                           @Param("keyType") EncryptionKey.KeyType keyType,
                           @Param("now") Instant now);
}
