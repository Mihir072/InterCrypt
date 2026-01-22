package com.intelcrypt.repository;

import com.intelcrypt.entity.Attachment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AttachmentRepository extends JpaRepository<Attachment, UUID> {
    
    List<Attachment> findByMessageId(UUID messageId);
    
    @Modifying
    @Query("UPDATE Attachment a SET a.deleted = true, a.encryptedContent = null " +
           "WHERE a.message.id = :messageId")
    int softDeleteByMessageId(@Param("messageId") UUID messageId);
    
    @Query("SELECT SUM(a.encryptedSize) FROM Attachment a WHERE a.message.sender.id = :userId " +
           "AND a.deleted = false")
    Long getTotalStorageUsed(@Param("userId") UUID userId);
}
