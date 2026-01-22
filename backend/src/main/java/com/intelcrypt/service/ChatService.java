package com.intelcrypt.service;

import com.intelcrypt.dto.ChatDTO;
import com.intelcrypt.entity.Chat;
import com.intelcrypt.entity.User;
import com.intelcrypt.exception.ResourceNotFoundException;
import com.intelcrypt.exception.UnauthorizedException;
import com.intelcrypt.repository.ChatRepository;
import com.intelcrypt.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Service for Chat operations.
 */
@Service
@Transactional
public class ChatService {
    
    private final ChatRepository chatRepository;
    private final UserRepository userRepository;
    
    public ChatService(ChatRepository chatRepository, UserRepository userRepository) {
        this.chatRepository = chatRepository;
        this.userRepository = userRepository;
    }
    
    /**
     * Get current authenticated user
     */
    private User getCurrentUser() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByUsername(username)
            .orElseThrow(() -> new UnauthorizedException("User not authenticated"));
    }
    
    /**
     * Get all chats for current user
     */
    @Transactional(readOnly = true)
    public List<ChatDTO.ChatResponse> getChatsForCurrentUser() {
        User currentUser = getCurrentUser();
        List<Chat> chats = chatRepository.findAllByParticipantId(currentUser.getId());
        return chats.stream()
            .map(chat -> ChatDTO.ChatResponse.fromEntity(chat, currentUser, 0, false))
            .collect(Collectors.toList());
    }
    
    /**
     * Get paginated chats for current user
     */
    @Transactional(readOnly = true)
    public Page<ChatDTO.ChatResponse> getChatsForCurrentUser(Pageable pageable) {
        User currentUser = getCurrentUser();
        return chatRepository.findByParticipantId(currentUser.getId(), pageable)
            .map(chat -> ChatDTO.ChatResponse.fromEntity(chat, currentUser, 0, false));
    }
    
    /**
     * Get chat by ID
     */
    @Transactional(readOnly = true)
    public ChatDTO.ChatResponse getChatById(UUID chatId) {
        User currentUser = getCurrentUser();
        Chat chat = chatRepository.findByIdAndParticipantId(chatId, currentUser.getId())
            .orElseThrow(() -> new ResourceNotFoundException("Chat not found or access denied"));
        return ChatDTO.ChatResponse.fromEntity(chat, 0, false);
    }
    
    /**
     * Create a new chat
     */
    public ChatDTO.ChatResponse createChat(ChatDTO.CreateChatRequest request) {
        User currentUser = getCurrentUser();
        
        Chat.ChatType chatType = Chat.ChatType.valueOf(request.getType().toUpperCase());
        
        Chat chat = new Chat(request.getName(), chatType, currentUser);
        chat.setDescription(request.getDescription());
        
        if (request.getClassificationLevel() != null) {
            chat.setClassificationLevel(Chat.ClassificationLevel.valueOf(request.getClassificationLevel().toUpperCase()));
        }
        
        // Add participants
        if (request.getParticipantIds() != null) {
            for (String participantId : request.getParticipantIds()) {
                UUID userId = UUID.fromString(participantId);
                userRepository.findById(userId).ifPresent(chat::addParticipant);
            }
        }
        
        chat.setLastMessageAt(Instant.now());
        
        Chat savedChat = chatRepository.save(chat);
        return ChatDTO.ChatResponse.fromEntity(savedChat, 0, false);
    }
    
    /**
     * Create or get direct chat between two users
     */
    public ChatDTO.ChatResponse getOrCreateDirectChat(UUID otherUserId) {
        User currentUser = getCurrentUser();
        
        // Check if direct chat already exists
        return chatRepository.findDirectChatBetweenUsers(currentUser.getId(), otherUserId)
            .map(chat -> ChatDTO.ChatResponse.fromEntity(chat, 0, false))
            .orElseGet(() -> {
                // Create new direct chat
                User otherUser = userRepository.findById(otherUserId)
                    .orElseThrow(() -> new ResourceNotFoundException("User not found"));
                
                Chat chat = new Chat(otherUser.getUsername(), Chat.ChatType.DIRECT, currentUser);
                chat.addParticipant(otherUser);
                chat.setLastMessageAt(Instant.now());
                
                Chat savedChat = chatRepository.save(chat);
                return ChatDTO.ChatResponse.fromEntity(savedChat, 0, false);
            });
    }
    
    /**
     * Update chat
     */
    public ChatDTO.ChatResponse updateChat(UUID chatId, ChatDTO.UpdateChatRequest request) {
        User currentUser = getCurrentUser();
        Chat chat = chatRepository.findByIdAndParticipantId(chatId, currentUser.getId())
            .orElseThrow(() -> new ResourceNotFoundException("Chat not found or access denied"));
        
        if (request.getName() != null) {
            chat.setName(request.getName());
        }
        if (request.getDescription() != null) {
            chat.setDescription(request.getDescription());
        }
        if (request.getAvatarUrl() != null) {
            chat.setAvatarUrl(request.getAvatarUrl());
        }
        if (request.getArchived() != null) {
            chat.setArchived(request.getArchived());
        }
        
        Chat savedChat = chatRepository.save(chat);
        return ChatDTO.ChatResponse.fromEntity(savedChat, 0, request.getMuted() != null && request.getMuted());
    }
    
    /**
     * Add participant to chat
     */
    public ChatDTO.ChatResponse addParticipant(UUID chatId, UUID userId) {
        User currentUser = getCurrentUser();
        Chat chat = chatRepository.findByIdAndParticipantId(chatId, currentUser.getId())
            .orElseThrow(() -> new ResourceNotFoundException("Chat not found or access denied"));
        
        // Verify creator can add participants
        if (!chat.getCreatedBy().getId().equals(currentUser.getId()) && chat.getType() != Chat.ChatType.GROUP) {
            throw new UnauthorizedException("Only chat creator can add participants");
        }
        
        User newParticipant = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        chat.addParticipant(newParticipant);
        Chat savedChat = chatRepository.save(chat);
        return ChatDTO.ChatResponse.fromEntity(savedChat, 0, false);
    }
    
    /**
     * Remove participant from chat
     */
    public ChatDTO.ChatResponse removeParticipant(UUID chatId, UUID userId) {
        User currentUser = getCurrentUser();
        Chat chat = chatRepository.findByIdAndParticipantId(chatId, currentUser.getId())
            .orElseThrow(() -> new ResourceNotFoundException("Chat not found or access denied"));
        
        // Check permission
        if (!chat.getCreatedBy().getId().equals(currentUser.getId()) && !currentUser.getId().equals(userId)) {
            throw new UnauthorizedException("Cannot remove this participant");
        }
        
        User participantToRemove = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        
        chat.removeParticipant(participantToRemove);
        Chat savedChat = chatRepository.save(chat);
        return ChatDTO.ChatResponse.fromEntity(savedChat, 0, false);
    }
    
    /**
     * Leave chat
     */
    public void leaveChat(UUID chatId) {
        User currentUser = getCurrentUser();
        Chat chat = chatRepository.findByIdAndParticipantId(chatId, currentUser.getId())
            .orElseThrow(() -> new ResourceNotFoundException("Chat not found or access denied"));
        
        chat.removeParticipant(currentUser);
        chatRepository.save(chat);
    }
    
    /**
     * Delete chat (soft delete)
     */
    public void deleteChat(UUID chatId) {
        User currentUser = getCurrentUser();
        Chat chat = chatRepository.findByIdAndParticipantId(chatId, currentUser.getId())
            .orElseThrow(() -> new ResourceNotFoundException("Chat not found or access denied"));
        
        // Only creator can delete
        if (!chat.getCreatedBy().getId().equals(currentUser.getId())) {
            throw new UnauthorizedException("Only chat creator can delete the chat");
        }
        
        chat.setDeleted(true);
        chatRepository.save(chat);
    }
    
    /**
     * Search chats
     */
    @Transactional(readOnly = true)
    public List<ChatDTO.ChatResponse> searchChats(String query) {
        User currentUser = getCurrentUser();
        return chatRepository.searchByNameAndParticipantId(currentUser.getId(), query).stream()
            .map(chat -> ChatDTO.ChatResponse.fromEntity(chat, 0, false))
            .collect(Collectors.toList());
    }
    
    /**
     * Update last message info
     */
    public void updateLastMessage(UUID chatId, String preview, UUID senderId) {
        chatRepository.findById(chatId).ifPresent(chat -> {
            chat.setLastMessageAt(Instant.now());
            chat.setLastMessagePreview(preview);
            chat.setLastMessageSenderId(senderId);
            chatRepository.save(chat);
        });
    }
}
