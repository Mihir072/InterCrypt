package com.intelcrypt.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.intelcrypt.entity.Chat;

/**
 * Repository for Chat entity operations.
 */
@Repository
public interface ChatRepository extends JpaRepository<Chat, UUID> {
    
    /**
     * Find all chats where user is a participant
     */
    @Query("SELECT c FROM Chat c JOIN c.participants p WHERE p.id = :userId AND c.deleted = false ORDER BY c.lastMessageAt DESC NULLS LAST")
    Page<Chat> findByParticipantId(@Param("userId") UUID userId, Pageable pageable);
    
    /**
     * Find all chats where user is a participant (list)
     */
    @Query("SELECT c FROM Chat c JOIN c.participants p WHERE p.id = :userId AND c.deleted = false ORDER BY c.lastMessageAt DESC NULLS LAST")
    List<Chat> findAllByParticipantId(@Param("userId") UUID userId);
    
    /**
     * Find chat by id and check if user is participant
     */
    @Query("SELECT c FROM Chat c JOIN c.participants p WHERE c.id = :chatId AND p.id = :userId AND c.deleted = false")
    Optional<Chat> findByIdAndParticipantId(@Param("chatId") UUID chatId, @Param("userId") UUID userId);
    
    /**
     * Find direct chat between two users
     */
    @Query("SELECT c FROM Chat c JOIN c.participants p1 JOIN c.participants p2 " +
           "WHERE p1.id = :user1Id AND p2.id = :user2Id AND c.type = 'DIRECT' AND c.deleted = false")
    Optional<Chat> findDirectChatBetweenUsers(@Param("user1Id") UUID user1Id, @Param("user2Id") UUID user2Id);
    
    /**
     * Find chats by type
     */
    @Query("SELECT c FROM Chat c JOIN c.participants p WHERE p.id = :userId AND c.type = :type AND c.deleted = false")
    List<Chat> findByParticipantIdAndType(@Param("userId") UUID userId, @Param("type") Chat.ChatType type);
    
    /**
     * Find archived chats for user
     */
    @Query("SELECT c FROM Chat c JOIN c.participants p WHERE p.id = :userId AND c.archived = true AND c.deleted = false")
    List<Chat> findArchivedByParticipantId(@Param("userId") UUID userId);
    
    /**
     * Search chats by name
     */
    @Query("SELECT c FROM Chat c JOIN c.participants p WHERE p.id = :userId AND c.deleted = false AND LOWER(c.name) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<Chat> searchByNameAndParticipantId(@Param("userId") UUID userId, @Param("query") String query);
    
    /**
     * Count unread messages in chat (placeholder - needs message tracking)
     */
    @Query("SELECT COUNT(c) FROM Chat c JOIN c.participants p WHERE p.id = :userId AND c.deleted = false")
    long countByParticipantId(@Param("userId") UUID userId);
}
