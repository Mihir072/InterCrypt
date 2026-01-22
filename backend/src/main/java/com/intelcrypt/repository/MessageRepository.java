package com.intelcrypt.repository;

import com.intelcrypt.entity.Message;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MessageRepository extends JpaRepository<Message, UUID> {
    
    /**
     * Find messages received by a user (inbox).
     */
    @Query("SELECT m FROM Message m WHERE m.recipient.id = :userId " +
           "AND m.deleted = false AND (m.expiresAt IS NULL OR m.expiresAt > :now) " +
           "ORDER BY m.createdAt DESC")
    Page<Message> findInbox(@Param("userId") UUID userId, 
                            @Param("now") Instant now,
                            Pageable pageable);
    
    /**
     * Find messages sent by a user.
     */
    @Query("SELECT m FROM Message m WHERE m.sender.id = :userId " +
           "AND m.deleted = false ORDER BY m.createdAt DESC")
    Page<Message> findSent(@Param("userId") UUID userId, Pageable pageable);
    
    /**
     * Find a specific message if user is sender or recipient.
     */
    @Query("SELECT m FROM Message m WHERE m.id = :messageId " +
           "AND (m.sender.id = :userId OR m.recipient.id = :userId) " +
           "AND m.deleted = false")
    Optional<Message> findByIdAndUser(@Param("messageId") UUID messageId, 
                                      @Param("userId") UUID userId);
    
    /**
     * Find expired messages for cleanup.
     */
    @Query("SELECT m FROM Message m WHERE m.expiresAt IS NOT NULL " +
           "AND m.expiresAt < :now AND m.deleted = false")
    List<Message> findExpiredMessages(@Param("now") Instant now);
    
    /**
     * Count unread messages for user.
     */
    @Query("SELECT COUNT(m) FROM Message m WHERE m.recipient.id = :userId " +
           "AND m.status = 'SENT' AND m.deleted = false " +
           "AND (m.expiresAt IS NULL OR m.expiresAt > :now)")
    long countUnread(@Param("userId") UUID userId, @Param("now") Instant now);
    
    /**
     * Soft delete expired messages.
     */
    @Modifying
    @Query("UPDATE Message m SET m.deleted = true, m.deletedAt = :now, " +
           "m.status = 'EXPIRED', m.encryptedContent = null, m.encryptedContentKey = null " +
           "WHERE m.expiresAt < :now AND m.deleted = false")
    int deleteExpiredMessages(@Param("now") Instant now);
    
    /**
     * Secure wipe - permanent deletion after retention period.
     */
    @Modifying
    @Query("DELETE FROM Message m WHERE m.deleted = true AND m.deletedAt < :cutoff")
    int permanentlyDeleteOldMessages(@Param("cutoff") Instant cutoff);
    
    /**
     * Find messages sent by user, ordered by creation date descending
     */
    @Query("SELECT m FROM Message m WHERE m.sender.id = :senderId AND m.deleted = false ORDER BY m.createdAt DESC")
    List<Message> findBySenderIdOrderByCreatedAtDesc(@Param("senderId") UUID senderId);
    
    /**
     * Find unread messages for recipient
     */
    @Query("SELECT m FROM Message m WHERE m.recipient.id = :recipientId AND m.readAt IS NULL AND m.deleted = false")
    List<Message> findByRecipientIdAndReadAtIsNull(@Param("recipientId") UUID recipientId);
    
    /**
     * Find messages for a chat, ordered by creation date ascending (oldest first)
     */
    @Query("SELECT m FROM Message m WHERE m.chat.id = :chatId AND m.deleted = false " +
           "AND (m.expiresAt IS NULL OR m.expiresAt > :now) ORDER BY m.createdAt ASC")
    List<Message> findByChatIdOrderByCreatedAtAsc(@Param("chatId") UUID chatId, @Param("now") Instant now);
    
    /**
     * Find messages for a chat with pagination (oldest first)
     */
    @Query("SELECT m FROM Message m WHERE m.chat.id = :chatId AND m.deleted = false " +
           "AND (m.expiresAt IS NULL OR m.expiresAt > :now) ORDER BY m.createdAt ASC")
    Page<Message> findByChatId(@Param("chatId") UUID chatId, @Param("now") Instant now, Pageable pageable);
}
