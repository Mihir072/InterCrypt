package com.intelcrypt.service;

import com.intelcrypt.config.CryptoConfigProperties;
import com.intelcrypt.crypto.CipherMode;
import com.intelcrypt.crypto.HybridCryptoService;
import com.intelcrypt.dto.MessageDTO;
import com.intelcrypt.entity.AuditLog;
import com.intelcrypt.entity.Message;
import com.intelcrypt.entity.User;
import com.intelcrypt.exception.CryptoException;
import com.intelcrypt.exception.ResourceNotFoundException;
import com.intelcrypt.exception.SecurityPolicyException;
import com.intelcrypt.repository.MessageRepository;
import com.intelcrypt.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.PrivateKey;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

/**
 * Secure Messaging Service.
 * 
 * SECURITY FEATURES:
 * - End-to-end encryption (E2EE)
 * - Hybrid encryption (AES + RSA)
 * - Message expiration (self-destruct)
 * - Classification-based access control
 * - Delivery acknowledgment without content exposure
 * - Audit logging of all message operations
 */
@Service
public class MessageService {
    
    private static final Logger log = LoggerFactory.getLogger(MessageService.class);
    
    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final HybridCryptoService hybridCryptoService;
    private final AuditService auditService;
    private final CryptoConfigProperties config;
    
    public MessageService(MessageRepository messageRepository,
                         UserRepository userRepository,
                         HybridCryptoService hybridCryptoService,
                         AuditService auditService,
                         CryptoConfigProperties config) {
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
        this.hybridCryptoService = hybridCryptoService;
        this.auditService = auditService;
        this.config = config;
    }
    
    /**
     * Send an encrypted message.
     */
    @Transactional
    public MessageDTO.SendResponse sendMessage(UUID senderId, 
                                               MessageDTO.SendRequest request,
                                               String ipAddress) {
        User sender = userRepository.findById(senderId)
            .orElseThrow(() -> new ResourceNotFoundException("Sender", senderId.toString()));
        
        User recipient = userRepository.findByUsername(request.getRecipientUsername())
            .orElseThrow(() -> new ResourceNotFoundException("Recipient", request.getRecipientUsername()));
        
        // Validate recipient has public key
        if (recipient.getPublicKey() == null) {
            throw new CryptoException("Recipient has no encryption key configured");
        }
        
        // Check classification access
        Message.MessageClassification classification = request.getClassification() != null ?
            request.getClassification() : Message.MessageClassification.STANDARD;
        
        validateClearanceLevel(sender, classification);
        validateClearanceLevel(recipient, classification);
        
        String encryptedContent;
        String encryptedKey;
        String algorithm;
        int rounds;
        
        if (request.getPreEncryptedContent() != null) {
            // Client-side E2EE - use pre-encrypted content
            encryptedContent = request.getPreEncryptedContent();
            encryptedKey = request.getPreEncryptedKey();
            algorithm = request.getEncryptionParams() != null ? 
                "AES-" + request.getEncryptionParams().getKeySize() + "-" + 
                request.getEncryptionParams().getMode() : "AES-256-GCM";
            rounds = request.getEncryptionParams() != null ? 
                request.getEncryptionParams().getRounds() : 1;
        } else {
            // Server-side encryption
            CipherMode mode = CipherMode.fromString(config.getCrypto().getAes().getDefaultMode());
            int keySize = config.getCrypto().getAes().getDefaultKeySize();
            rounds = config.getCrypto().getAes().getIterationRounds();
            
            var encryptionResult = hybridCryptoService.encrypt(
                request.getContent(),
                recipient.getPublicKey(),
                mode,
                keySize,
                rounds
            );
            
            encryptedContent = encryptionResult.encryptedContent();
            encryptedKey = encryptionResult.encryptedKey();
            algorithm = "AES-" + keySize + "-" + mode.name();
        }
        
        // Calculate expiration
        Instant expiresAt = null;
        if (request.getExpirationHours() != null && request.getExpirationHours() > 0) {
            expiresAt = Instant.now().plus(request.getExpirationHours(), ChronoUnit.HOURS);
        } else if (config.getMessaging().getDefaultExpirationHours() > 0) {
            expiresAt = Instant.now().plus(config.getMessaging().getDefaultExpirationHours(), ChronoUnit.HOURS);
        }
        
        // Calculate content HMAC for integrity and delivery acknowledgment
        String contentHmac = calculateContentHmac(encryptedContent);
        
        // Create message
        Message message = Message.builder()
            .sender(sender)
            .recipient(recipient)
            .encryptedContent(encryptedContent)
            .encryptedContentKey(encryptedKey)
            .encryptionAlgorithm(algorithm)
            .encryptionRounds(rounds)
            .classification(classification)
            .status(Message.MessageStatus.SENT)
            .expiresAt(expiresAt)
            .contentHmac(contentHmac)
            .build();
        
        message = messageRepository.save(message);
        
        auditService.logMessageEvent(
            AuditLog.EventType.MESSAGE_SENT,
            senderId,
            sender.getUsername(),
            message.getId(),
            ipAddress,
            "Message sent to " + recipient.getUsername() + 
                " [" + classification + "]" +
                (expiresAt != null ? " expires: " + expiresAt : "")
        );
        
        log.info("Message sent: {} -> {} [{}]", 
                sender.getUsername(), recipient.getUsername(), classification);
        
        return MessageDTO.SendResponse.builder()
            .messageId(message.getId().toString())
            .status("SENT")
            .sentAt(message.getCreatedAt())
            .expiresAt(expiresAt)
            .build();
    }
    
    /**
     * Get user's inbox (received messages).
     */
    public MessageDTO.MessageListResponse getInbox(UUID userId, int page, int size) {
        Page<Message> messages = messageRepository.findInbox(
            userId, Instant.now(), PageRequest.of(page, size));
        
        return buildMessageListResponse(messages, page, size);
    }
    
    /**
     * Get user's sent messages.
     */
    public MessageDTO.MessageListResponse getSentMessages(UUID userId, int page, int size) {
        Page<Message> messages = messageRepository.findSent(userId, PageRequest.of(page, size));
        return buildMessageListResponse(messages, page, size);
    }
    
    /**
     * Get message details (encrypted).
     */
    public MessageDTO.MessageDetail getMessage(UUID userId, UUID messageId, String ipAddress) {
        Message message = messageRepository.findByIdAndUser(messageId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Message", messageId.toString()));
        
        // Check expiration
        if (message.isExpired()) {
            message.setStatus(Message.MessageStatus.EXPIRED);
            messageRepository.save(message);
            throw new SecurityPolicyException("Message has expired");
        }
        
        // Mark as delivered if recipient
        if (message.getRecipient().getId().equals(userId) && 
            message.getStatus() == Message.MessageStatus.SENT) {
            message.setStatus(Message.MessageStatus.DELIVERED);
            messageRepository.save(message);
            
            auditService.logMessageEvent(
                AuditLog.EventType.MESSAGE_RECEIVED,
                userId,
                message.getRecipient().getUsername(),
                messageId,
                ipAddress,
                "Message delivered"
            );
        }
        
        return buildMessageDetail(message);
    }
    
    /**
     * Decrypt a message using user's private key.
     */
    @Transactional
    public MessageDTO.DecryptedMessage decryptMessage(UUID userId, 
                                                      MessageDTO.DecryptRequest request,
                                                      String ipAddress) {
        UUID messageId = UUID.fromString(request.getMessageId());
        
        Message message = messageRepository.findByIdAndUser(messageId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Message", request.getMessageId()));
        
        // Only recipient can decrypt
        if (!message.getRecipient().getId().equals(userId)) {
            auditService.logSecurityEvent(
                AuditLog.EventType.SUSPICIOUS_ACTIVITY,
                userId,
                ipAddress,
                null,
                "Attempted to decrypt message not addressed to user"
            );
            throw new SecurityPolicyException("Cannot decrypt message not addressed to you");
        }
        
        // Check expiration
        if (message.isExpired()) {
            throw new SecurityPolicyException("Message has expired");
        }
        
        User recipient = message.getRecipient();
        
        // Recover private key using password
        PrivateKey privateKey = hybridCryptoService.recoverPrivateKey(
            recipient.getEncryptedPrivateKey(),
            request.getPassword(),
            recipient.getPrivateKeySalt()
        );
        
        // Parse encryption mode
        String[] algParts = message.getEncryptionAlgorithm().split("-");
        CipherMode mode = algParts.length > 2 ? CipherMode.fromString(algParts[2]) : CipherMode.GCM;
        
        // Decrypt message
        String decryptedContent = hybridCryptoService.decrypt(
            message.getEncryptedContent(),
            message.getEncryptedContentKey(),
            privateKey,
            mode,
            message.getEncryptionRounds()
        );
        
        // Mark as read
        message.markAsRead();
        messageRepository.save(message);
        
        auditService.logMessageEvent(
            AuditLog.EventType.MESSAGE_READ,
            userId,
            recipient.getUsername(),
            messageId,
            ipAddress,
            "Message decrypted and read"
        );
        
        auditService.logCryptoEvent(
            AuditLog.EventType.DECRYPTION_PERFORMED,
            userId,
            recipient.getUsername(),
            null,
            ipAddress,
            "Decrypted message: " + messageId
        );
        
        return MessageDTO.DecryptedMessage.builder()
            .id(message.getId().toString())
            .senderUsername(message.getSender().getUsername())
            .content(decryptedContent)
            .classification(message.getClassification().name())
            .createdAt(message.getCreatedAt())
            .build();
    }
    
    /**
     * Get delivery acknowledgment (proves delivery without exposing content).
     */
    public MessageDTO.DeliveryAck getDeliveryAcknowledgment(UUID userId, UUID messageId) {
        Message message = messageRepository.findByIdAndUser(messageId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Message", messageId.toString()));
        
        return MessageDTO.DeliveryAck.builder()
            .messageId(message.getId().toString())
            .status(message.getStatus().name())
            .deliveredAt(message.getReadAt())
            .contentHash(message.getContentHmac())
            .build();
    }
    
    /**
     * Delete a message (soft delete with secure wipe).
     */
    @Transactional
    public void deleteMessage(UUID userId, UUID messageId, String ipAddress) {
        Message message = messageRepository.findByIdAndUser(messageId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Message", messageId.toString()));
        
        message.secureDelete();
        messageRepository.save(message);
        
        auditService.logMessageEvent(
            AuditLog.EventType.MESSAGE_DELETED,
            userId,
            null,
            messageId,
            ipAddress,
            "Message securely deleted"
        );
        
        log.info("Message deleted: {}", messageId);
    }
    
    /**
     * Count unread messages.
     */
    public long countUnread(UUID userId) {
        return messageRepository.countUnread(userId, Instant.now());
    }
    
    /**
     * Scheduled task: Clean up expired messages.
     */
    @Scheduled(fixedRate = 300000) // Every 5 minutes
    @Transactional
    public void cleanupExpiredMessages() {
        int deleted = messageRepository.deleteExpiredMessages(Instant.now());
        if (deleted > 0) {
            log.info("Cleaned up {} expired messages", deleted);
        }
    }
    
    /**
     * Scheduled task: Permanently delete old soft-deleted messages.
     */
    @Scheduled(cron = "0 0 2 * * *") // Every day at 2 AM
    @Transactional
    public void permanentlyDeleteOldMessages() {
        // Delete messages soft-deleted more than 30 days ago
        Instant cutoff = Instant.now().minus(30, ChronoUnit.DAYS);
        int deleted = messageRepository.permanentlyDeleteOldMessages(cutoff);
        if (deleted > 0) {
            log.info("Permanently deleted {} old messages", deleted);
        }
    }
    
    /**
     * Validate user has required clearance level.
     */
    private void validateClearanceLevel(User user, Message.MessageClassification classification) {
        User.ClearanceLevel required = switch (classification) {
            case STANDARD -> User.ClearanceLevel.STANDARD;
            case CONFIDENTIAL -> User.ClearanceLevel.CONFIDENTIAL;
            case SECRET -> User.ClearanceLevel.SECRET;
            case TOP_SECRET -> User.ClearanceLevel.TOP_SECRET;
        };
        
        if (user.getClearanceLevel().ordinal() < required.ordinal()) {
            throw new SecurityPolicyException(
                "Insufficient clearance level for " + classification + " messages");
        }
    }
    
    /**
     * Calculate HMAC of encrypted content for integrity verification.
     */
    private String calculateContentHmac(String content) {
        try {
            Mac hmac = Mac.getInstance("HmacSHA256");
            byte[] key = "IntelCrypt-Content-HMAC".getBytes(StandardCharsets.UTF_8);
            hmac.init(new SecretKeySpec(key, "HmacSHA256"));
            byte[] hash = hmac.doFinal(content.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hash);
        } catch (Exception e) {
            log.error("Failed to calculate content HMAC", e);
            return null;
        }
    }
    
    /**
     * Build message list response.
     */
    private MessageDTO.MessageListResponse buildMessageListResponse(Page<Message> messages, 
                                                                     int page, int size) {
        List<MessageDTO.MessageSummary> summaries = messages.getContent().stream()
            .map(this::buildMessageSummary)
            .toList();
        
        return MessageDTO.MessageListResponse.builder()
            .messages(summaries)
            .page(page)
            .size(size)
            .totalElements(messages.getTotalElements())
            .totalPages(messages.getTotalPages())
            .build();
    }
    
    /**
     * Build message summary.
     */
    private MessageDTO.MessageSummary buildMessageSummary(Message message) {
        return MessageDTO.MessageSummary.builder()
            .id(message.getId().toString())
            .senderUsername(message.getSender().getUsername())
            .recipientUsername(message.getRecipient().getUsername())
            .classification(message.getClassification().name())
            .status(message.getStatus().name())
            .createdAt(message.getCreatedAt())
            .expiresAt(message.getExpiresAt())
            .hasAttachments(false) // TODO: implement attachments
            .build();
    }
    
    /**
     * Build message detail.
     */
    private MessageDTO.MessageDetail buildMessageDetail(Message message) {
        return MessageDTO.MessageDetail.builder()
            .id(message.getId().toString())
            .senderUsername(message.getSender().getUsername())
            .recipientUsername(message.getRecipient().getUsername())
            .encryptedContent(message.getEncryptedContent())
            .encryptedContentKey(message.getEncryptedContentKey())
            .encryptionAlgorithm(message.getEncryptionAlgorithm())
            .encryptionRounds(message.getEncryptionRounds())
            .classification(message.getClassification().name())
            .status(message.getStatus().name())
            .createdAt(message.getCreatedAt())
            .readAt(message.getReadAt())
            .expiresAt(message.getExpiresAt())
            .attachments(List.of())
            .build();
    }
}
