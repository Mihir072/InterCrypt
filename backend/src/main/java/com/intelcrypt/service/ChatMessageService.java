package com.intelcrypt.service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.intelcrypt.dto.MessageDTO;
import com.intelcrypt.entity.Chat;
import com.intelcrypt.entity.Message;
import com.intelcrypt.entity.User;
import com.intelcrypt.exception.ResourceNotFoundException;
import com.intelcrypt.exception.UnauthorizedException;
import com.intelcrypt.repository.ChatRepository;
import com.intelcrypt.repository.MessageRepository;
import com.intelcrypt.repository.UserRepository;

/**
 * Service for chat-based messaging operations.
 * Supports the chat→messages structure expected by the frontend.
 */
@Service
@Transactional
public class ChatMessageService {

        private final ChatRepository chatRepository;
        private final MessageRepository messageRepository;
        private final UserRepository userRepository;
        private final ChatService chatService;
        private final SimpMessagingTemplate messagingTemplate;

        public ChatMessageService(
                        ChatRepository chatRepository,
                        MessageRepository messageRepository,
                        UserRepository userRepository,
                        ChatService chatService,
                        SimpMessagingTemplate messagingTemplate) {
                this.chatRepository = chatRepository;
                this.messageRepository = messageRepository;
                this.userRepository = userRepository;
                this.chatService = chatService;
                this.messagingTemplate = messagingTemplate;
        }

        /**
         * Get messages for a chat
         */
        @Transactional(readOnly = true)
        public List<MessageDTO.ChatMessageResponse> getMessages(
                        UUID chatId, UUID userId, int limit, UUID beforeMessageId) {

                // Verify user has access to chat
                Chat chat = chatRepository.findByIdAndParticipantId(chatId, userId)
                                .orElseThrow(() -> new ResourceNotFoundException("Chat not found or access denied"));

                // Get messages for this chat
                List<Message> messages = messageRepository.findByChatIdOrderByCreatedAtAsc(chatId, Instant.now());

                return messages.stream()
                                .limit(limit)
                                .map(msg -> convertToResponse(msg, chatId))
                                .collect(Collectors.toList());
        }

        /**
         * Send a message to a chat
         */
        public MessageDTO.ChatMessageResponse sendMessage(
                        UUID chatId, UUID senderId, MessageDTO.SendChatMessageRequest request, String clientIp) {

                // Verify user has access to chat
                Chat chat = chatRepository.findByIdAndParticipantId(chatId, senderId)
                                .orElseThrow(() -> new ResourceNotFoundException("Chat not found or access denied"));

                User sender = userRepository.findById(senderId)
                                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

                // For direct chats, find the recipient
                User recipient = chat.getParticipants().stream()
                                .filter(p -> !p.getId().equals(senderId))
                                .findFirst()
                                .orElse(sender); // For group chats or self-messages

                // Create the message
                Message message = new Message();
                message.setSender(sender);
                message.setRecipient(recipient);
                message.setChat(chat); // Set the chat reference
                message.setEncryptedContent(
                                request.getContentEncrypted() != null ? request.getContentEncrypted()
                                                : request.getContent());
                message.setEncryptedContentKey(""); // Would be set from encryption params
                message.setStatus(Message.MessageStatus.SENT);

                if (request.getEncryption() != null) {
                        message.setEncryptionAlgorithm(request.getEncryption().getAlgorithm());
                }

                if (request.isSelfDestructing() && request.getExpiresInSeconds() != null) {
                        message.setExpiresAt(Instant.now().plusSeconds(request.getExpiresInSeconds()));
                }

                Message savedMessage = messageRepository.save(message);

                // Update chat's last message
                String preview = request.getContent() != null
                                ? request.getContent().substring(0, Math.min(request.getContent().length(), 100))
                                : "[Encrypted]";
                chatService.updateLastMessage(chatId, preview, senderId);

                MessageDTO.ChatMessageResponse response = convertToResponse(savedMessage, chatId);

                // ─── Real-time push via STOMP ───────────────────────────────────────────
                // convertAndSendToUser routes by the STOMP session's principal name.
                // Our StompChannelInterceptor sets principal =
                // UsernamePasswordAuthenticationToken
                // where getName() returns the username (not the UUID).
                messagingTemplate.convertAndSendToUser(
                                recipient.getUsername(), // must match principal.getName() set in interceptor
                                "/queue/messages",
                                response);
                // ───────────────────────────────────────────────────────────────────────

                return response;
        }

        /**
         * Mark a message as read
         */
        public void markMessageAsRead(UUID chatId, UUID messageId, UUID userId) {
                // Verify access
                chatRepository.findByIdAndParticipantId(chatId, userId)
                                .orElseThrow(() -> new ResourceNotFoundException("Chat not found or access denied"));

                messageRepository.findById(messageId).ifPresent(message -> {
                        if (message.getRecipient().getId().equals(userId)) {
                                message.setReadAt(Instant.now());
                                message.setStatus(Message.MessageStatus.READ);
                                messageRepository.save(message);
                        }
                });
        }

        /**
         * Mark all messages as read
         */
        public void markAllMessagesAsRead(UUID chatId, UUID userId) {
                // Verify access
                chatRepository.findByIdAndParticipantId(chatId, userId)
                                .orElseThrow(() -> new ResourceNotFoundException("Chat not found or access denied"));

                // Mark all unread messages as read
                List<Message> unreadMessages = messageRepository.findByRecipientIdAndReadAtIsNull(userId);
                Instant now = Instant.now();

                unreadMessages.forEach(message -> {
                        message.setReadAt(now);
                        message.setStatus(Message.MessageStatus.READ);
                });

                messageRepository.saveAll(unreadMessages);
        }

        /**
         * Delete a message
         */
        public void deleteMessage(UUID chatId, UUID messageId, UUID userId, String clientIp) {
                // Verify access
                chatRepository.findByIdAndParticipantId(chatId, userId)
                                .orElseThrow(() -> new ResourceNotFoundException("Chat not found or access denied"));

                Message message = messageRepository.findById(messageId)
                                .orElseThrow(() -> new ResourceNotFoundException("Message not found"));

                // Only sender can delete their message
                if (!message.getSender().getId().equals(userId)) {
                        throw new UnauthorizedException("Cannot delete this message");
                }

                message.setDeleted(true);
                message.setDeletedAt(Instant.now());
                messageRepository.save(message);
        }

        /**
         * Search messages in a chat
         */
        @Transactional(readOnly = true)
        public List<MessageDTO.ChatMessageResponse> searchMessages(UUID chatId, UUID userId, String query) {
                // Verify access
                chatRepository.findByIdAndParticipantId(chatId, userId)
                                .orElseThrow(() -> new ResourceNotFoundException("Chat not found or access denied"));

                // Search is limited since content is encrypted
                // In a real implementation, you'd search through metadata or have a search
                // index
                return new ArrayList<>();
        }

        /**
         * Convert Message entity to ChatMessageResponse DTO
         */
        private MessageDTO.ChatMessageResponse convertToResponse(Message message, UUID chatId) {
                MessageDTO.EncryptionParams encryption = MessageDTO.EncryptionParams.builder()
                                .algorithm(message.getEncryptionAlgorithm())
                                .encryptionLevel(message.getClassification().name())
                                .build();

                return MessageDTO.ChatMessageResponse.builder()
                                .id(message.getId().toString())
                                .chatId(chatId.toString())
                                .senderId(message.getSender().getId().toString())
                                .senderUsername(message.getSender().getUsername())
                                .content("[Encrypted]")
                                .contentEncrypted(message.getEncryptedContent())
                                .encryption(encryption)
                                .status(message.getStatus().name())
                                .sentAt(message.getCreatedAt() != null ? message.getCreatedAt().toString() : null)
                                .deliveredAt(null) // Would track separately
                                .readAt(message.getReadAt() != null ? message.getReadAt().toString() : null)
                                .expiresAt(message.getExpiresAt() != null ? message.getExpiresAt().toString() : null)
                                .attachments(new ArrayList<>())
                                .isEdited(false)
                                .isSelfDestructing(message.getExpiresAt() != null)
                                .build();
        }
}
