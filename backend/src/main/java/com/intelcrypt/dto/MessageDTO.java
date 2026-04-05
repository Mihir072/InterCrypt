package com.intelcrypt.dto;

import com.intelcrypt.entity.Message;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.util.List;
import java.util.Objects;

/**
 * Message request/response DTOs.
 */
public class MessageDTO {
    
    /**
     * Request to send an encrypted message.
     */
    public static class SendRequest {
        @NotBlank(message = "Recipient username is required")
        private String recipientUsername;
        
        @NotBlank(message = "Message content is required")
        private String content;
        
        /**
         * Message classification level
         */
        private Message.MessageClassification classification;
        
        /**
         * Hours until message auto-deletes (null = never)
         */
        private Integer expirationHours;
        
        /**
         * Optional: Pre-encrypted content (client-side E2EE)
         */
        private String preEncryptedContent;
        
        /**
         * Optional: Pre-encrypted content key (for client-side E2EE)
         */
        private String preEncryptedKey;
        
        /**
         * Encryption parameters (if using pre-encrypted)
         */
        private EncryptionParams encryptionParams;
        
        public SendRequest() {}
        public SendRequest(String recipientUsername, String content, Message.MessageClassification classification,
                          Integer expirationHours, String preEncryptedContent, String preEncryptedKey,
                          EncryptionParams encryptionParams) {
            this.recipientUsername = recipientUsername;
            this.content = content;
            this.classification = classification;
            this.expirationHours = expirationHours;
            this.preEncryptedContent = preEncryptedContent;
            this.preEncryptedKey = preEncryptedKey;
            this.encryptionParams = encryptionParams;
        }
        
        public String getRecipientUsername() { return recipientUsername; }
        public void setRecipientUsername(String recipientUsername) { this.recipientUsername = recipientUsername; }
        public String getContent() { return content; }
        public void setContent(String content) { this.content = content; }
        public Message.MessageClassification getClassification() { return classification; }
        public void setClassification(Message.MessageClassification classification) { this.classification = classification; }
        public Integer getExpirationHours() { return expirationHours; }
        public void setExpirationHours(Integer expirationHours) { this.expirationHours = expirationHours; }
        public String getPreEncryptedContent() { return preEncryptedContent; }
        public void setPreEncryptedContent(String preEncryptedContent) { this.preEncryptedContent = preEncryptedContent; }
        public String getPreEncryptedKey() { return preEncryptedKey; }
        public void setPreEncryptedKey(String preEncryptedKey) { this.preEncryptedKey = preEncryptedKey; }
        public EncryptionParams getEncryptionParams() { return encryptionParams; }
        public void setEncryptionParams(EncryptionParams encryptionParams) { this.encryptionParams = encryptionParams; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String recipientUsername;
            private String content;
            private Message.MessageClassification classification;
            private Integer expirationHours;
            private String preEncryptedContent;
            private String preEncryptedKey;
            private EncryptionParams encryptionParams;
            
            public Builder recipientUsername(String recipientUsername) { this.recipientUsername = recipientUsername; return this; }
            public Builder content(String content) { this.content = content; return this; }
            public Builder classification(Message.MessageClassification classification) { this.classification = classification; return this; }
            public Builder expirationHours(Integer expirationHours) { this.expirationHours = expirationHours; return this; }
            public Builder preEncryptedContent(String preEncryptedContent) { this.preEncryptedContent = preEncryptedContent; return this; }
            public Builder preEncryptedKey(String preEncryptedKey) { this.preEncryptedKey = preEncryptedKey; return this; }
            public Builder encryptionParams(EncryptionParams encryptionParams) { this.encryptionParams = encryptionParams; return this; }
            public SendRequest build() {
                return new SendRequest(recipientUsername, content, classification, expirationHours,
                        preEncryptedContent, preEncryptedKey, encryptionParams);
            }
        }
    }
    
    /**
     * Encryption parameters.
     */
    public static class EncryptionParams {
        private String algorithm; // AES-256-GCM, etc.
        private String mode;      // GCM, CBC, CTR, XTS
        private int keySize;      // 128, 192, 256
        private int rounds;       // Number of encryption rounds
        private String keyId;     // Key identifier
        private String encryptionLevel; // Classification level
        private boolean isE2E;    // End-to-end encrypted
        
        public EncryptionParams() {}
        public EncryptionParams(String algorithm, String mode, int keySize, int rounds, 
                               String keyId, String encryptionLevel, boolean isE2E) {
            this.algorithm = algorithm;
            this.mode = mode;
            this.keySize = keySize;
            this.rounds = rounds;
            this.keyId = keyId;
            this.encryptionLevel = encryptionLevel;
            this.isE2E = isE2E;
        }
        
        public String getAlgorithm() { return algorithm; }
        public void setAlgorithm(String algorithm) { this.algorithm = algorithm; }
        public String getMode() { return mode; }
        public void setMode(String mode) { this.mode = mode; }
        public int getKeySize() { return keySize; }
        public void setKeySize(int keySize) { this.keySize = keySize; }
        public int getRounds() { return rounds; }
        public void setRounds(int rounds) { this.rounds = rounds; }
        public String getKeyId() { return keyId; }
        public void setKeyId(String keyId) { this.keyId = keyId; }
        public String getEncryptionLevel() { return encryptionLevel; }
        public void setEncryptionLevel(String encryptionLevel) { this.encryptionLevel = encryptionLevel; }
        public boolean isE2E() { return isE2E; }
        public void setE2E(boolean isE2E) { this.isE2E = isE2E; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String algorithm;
            private String mode;
            private int keySize;
            private int rounds;
            private String keyId;
            private String encryptionLevel;
            private boolean isE2E;
            
            public Builder algorithm(String algorithm) { this.algorithm = algorithm; return this; }
            public Builder mode(String mode) { this.mode = mode; return this; }
            public Builder keySize(int keySize) { this.keySize = keySize; return this; }
            public Builder rounds(int rounds) { this.rounds = rounds; return this; }
            public Builder keyId(String keyId) { this.keyId = keyId; return this; }
            public Builder encryptionLevel(String encryptionLevel) { this.encryptionLevel = encryptionLevel; return this; }
            public Builder isE2E(boolean isE2E) { this.isE2E = isE2E; return this; }
            public EncryptionParams build() {
                return new EncryptionParams(algorithm, mode, keySize, rounds, keyId, encryptionLevel, isE2E);
            }
        }
    }
    
    /**
     * Request to send a message to a chat (used by ChatMessageService).
     */
    public static class SendChatMessageRequest {
        private String content;
        private String contentEncrypted;
        private EncryptionParams encryption;
        private boolean selfDestructing;
        private Integer expiresInSeconds;
        private List<AttachmentData> attachments;
        
        public SendChatMessageRequest() {}
        
        public String getContent() { return content; }
        public void setContent(String content) { this.content = content; }
        public String getContentEncrypted() { return contentEncrypted; }
        public void setContentEncrypted(String contentEncrypted) { this.contentEncrypted = contentEncrypted; }
        public EncryptionParams getEncryption() { return encryption; }
        public void setEncryption(EncryptionParams encryption) { this.encryption = encryption; }
        public boolean isSelfDestructing() { return selfDestructing; }
        public void setSelfDestructing(boolean selfDestructing) { this.selfDestructing = selfDestructing; }
        public Integer getExpiresInSeconds() { return expiresInSeconds; }
        public void setExpiresInSeconds(Integer expiresInSeconds) { this.expiresInSeconds = expiresInSeconds; }
        public List<AttachmentData> getAttachments() { return attachments; }
        public void setAttachments(List<AttachmentData> attachments) { this.attachments = attachments; }
    }
    
    /**
     * Attachment data for messages.
     */
    public static class AttachmentData {
        private String id;
        private String filename;
        private String mimeType;
        private long size;
        private String url;
        private boolean hasHiddenData;
        
        public AttachmentData() {}
        
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getFilename() { return filename; }
        public void setFilename(String filename) { this.filename = filename; }
        public String getMimeType() { return mimeType; }
        public void setMimeType(String mimeType) { this.mimeType = mimeType; }
        public long getSize() { return size; }
        public void setSize(long size) { this.size = size; }
        public String getUrl() { return url; }
        public void setUrl(String url) { this.url = url; }
        public boolean isHasHiddenData() { return hasHiddenData; }
        public void setHasHiddenData(boolean hasHiddenData) { this.hasHiddenData = hasHiddenData; }
    }
    
    /**
     * Response for a chat message.
     */
    public static class ChatMessageResponse {
        private String id;
        private String chatId;
        private String senderId;
        private String senderUsername;
        private String content;
        private String contentEncrypted;
        private EncryptionParams encryption;
        private String status;
        private String sentAt;
        private String deliveredAt;
        private String readAt;
        private String expiresAt;
        private List<AttachmentData> attachments;
        private boolean isEdited;
        private boolean isSelfDestructing;
        
        public ChatMessageResponse() {}
        
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getChatId() { return chatId; }
        public void setChatId(String chatId) { this.chatId = chatId; }
        public String getSenderId() { return senderId; }
        public void setSenderId(String senderId) { this.senderId = senderId; }
        public String getSenderUsername() { return senderUsername; }
        public void setSenderUsername(String senderUsername) { this.senderUsername = senderUsername; }
        public String getContent() { return content; }
        public void setContent(String content) { this.content = content; }
        public String getContentEncrypted() { return contentEncrypted; }
        public void setContentEncrypted(String contentEncrypted) { this.contentEncrypted = contentEncrypted; }
        public EncryptionParams getEncryption() { return encryption; }
        public void setEncryption(EncryptionParams encryption) { this.encryption = encryption; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public String getSentAt() { return sentAt; }
        public void setSentAt(String sentAt) { this.sentAt = sentAt; }
        public String getDeliveredAt() { return deliveredAt; }
        public void setDeliveredAt(String deliveredAt) { this.deliveredAt = deliveredAt; }
        public String getReadAt() { return readAt; }
        public void setReadAt(String readAt) { this.readAt = readAt; }
        public String getExpiresAt() { return expiresAt; }
        public void setExpiresAt(String expiresAt) { this.expiresAt = expiresAt; }
        public List<AttachmentData> getAttachments() { return attachments; }
        public void setAttachments(List<AttachmentData> attachments) { this.attachments = attachments; }
        public boolean isEdited() { return isEdited; }
        public void setEdited(boolean isEdited) { this.isEdited = isEdited; }
        public boolean isSelfDestructing() { return isSelfDestructing; }
        public void setSelfDestructing(boolean isSelfDestructing) { this.isSelfDestructing = isSelfDestructing; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String id;
            private String chatId;
            private String senderId;
            private String senderUsername;
            private String content;
            private String contentEncrypted;
            private EncryptionParams encryption;
            private String status;
            private String sentAt;
            private String deliveredAt;
            private String readAt;
            private String expiresAt;
            private List<AttachmentData> attachments;
            private boolean isEdited;
            private boolean isSelfDestructing;
            
            public Builder id(String id) { this.id = id; return this; }
            public Builder chatId(String chatId) { this.chatId = chatId; return this; }
            public Builder senderId(String senderId) { this.senderId = senderId; return this; }
            public Builder senderUsername(String senderUsername) { this.senderUsername = senderUsername; return this; }
            public Builder content(String content) { this.content = content; return this; }
            public Builder contentEncrypted(String contentEncrypted) { this.contentEncrypted = contentEncrypted; return this; }
            public Builder encryption(EncryptionParams encryption) { this.encryption = encryption; return this; }
            public Builder status(String status) { this.status = status; return this; }
            public Builder sentAt(String sentAt) { this.sentAt = sentAt; return this; }
            public Builder deliveredAt(String deliveredAt) { this.deliveredAt = deliveredAt; return this; }
            public Builder readAt(String readAt) { this.readAt = readAt; return this; }
            public Builder expiresAt(String expiresAt) { this.expiresAt = expiresAt; return this; }
            public Builder attachments(List<AttachmentData> attachments) { this.attachments = attachments; return this; }
            public Builder isEdited(boolean isEdited) { this.isEdited = isEdited; return this; }
            public Builder isSelfDestructing(boolean isSelfDestructing) { this.isSelfDestructing = isSelfDestructing; return this; }
            
            public ChatMessageResponse build() {
                ChatMessageResponse response = new ChatMessageResponse();
                response.id = this.id;
                response.chatId = this.chatId;
                response.senderId = this.senderId;
                response.senderUsername = this.senderUsername;
                response.content = this.content;
                response.contentEncrypted = this.contentEncrypted;
                response.encryption = this.encryption;
                response.status = this.status;
                response.sentAt = this.sentAt;
                response.deliveredAt = this.deliveredAt;
                response.readAt = this.readAt;
                response.expiresAt = this.expiresAt;
                response.attachments = this.attachments;
                response.isEdited = this.isEdited;
                response.isSelfDestructing = this.isSelfDestructing;
                return response;
            }
        }
    }
    
    /**
     * Response after sending a message.
     */
    public static class SendResponse {
        private String messageId;
        private String status;
        private Instant sentAt;
        private Instant expiresAt;
        
        public SendResponse() {}
        public SendResponse(String messageId, String status, Instant sentAt, Instant expiresAt) {
            this.messageId = messageId;
            this.status = status;
            this.sentAt = sentAt;
            this.expiresAt = expiresAt;
        }
        
        public String getMessageId() { return messageId; }
        public void setMessageId(String messageId) { this.messageId = messageId; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public Instant getSentAt() { return sentAt; }
        public void setSentAt(Instant sentAt) { this.sentAt = sentAt; }
        public Instant getExpiresAt() { return expiresAt; }
        public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String messageId;
            private String status;
            private Instant sentAt;
            private Instant expiresAt;
            
            public Builder messageId(String messageId) { this.messageId = messageId; return this; }
            public Builder status(String status) { this.status = status; return this; }
            public Builder sentAt(Instant sentAt) { this.sentAt = sentAt; return this; }
            public Builder expiresAt(Instant expiresAt) { this.expiresAt = expiresAt; return this; }
            public SendResponse build() { return new SendResponse(messageId, status, sentAt, expiresAt); }
        }
    }
    
    /**
     * Message summary for inbox/sent listings.
     */
    public static class MessageSummary {
        private String id;
        private String senderUsername;
        private String recipientUsername;
        private String classification;
        private String status;
        private Instant createdAt;
        private Instant expiresAt;
        private boolean hasAttachments;
        
        public MessageSummary() {}
        public MessageSummary(String id, String senderUsername, String recipientUsername, String classification,
                             String status, Instant createdAt, Instant expiresAt, boolean hasAttachments) {
            this.id = id;
            this.senderUsername = senderUsername;
            this.recipientUsername = recipientUsername;
            this.classification = classification;
            this.status = status;
            this.createdAt = createdAt;
            this.expiresAt = expiresAt;
            this.hasAttachments = hasAttachments;
        }
        
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getSenderUsername() { return senderUsername; }
        public void setSenderUsername(String senderUsername) { this.senderUsername = senderUsername; }
        public String getRecipientUsername() { return recipientUsername; }
        public void setRecipientUsername(String recipientUsername) { this.recipientUsername = recipientUsername; }
        public String getClassification() { return classification; }
        public void setClassification(String classification) { this.classification = classification; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public Instant getCreatedAt() { return createdAt; }
        public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
        public Instant getExpiresAt() { return expiresAt; }
        public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
        public boolean isHasAttachments() { return hasAttachments; }
        public void setHasAttachments(boolean hasAttachments) { this.hasAttachments = hasAttachments; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String id;
            private String senderUsername;
            private String recipientUsername;
            private String classification;
            private String status;
            private Instant createdAt;
            private Instant expiresAt;
            private boolean hasAttachments;
            
            public Builder id(String id) { this.id = id; return this; }
            public Builder senderUsername(String senderUsername) { this.senderUsername = senderUsername; return this; }
            public Builder recipientUsername(String recipientUsername) { this.recipientUsername = recipientUsername; return this; }
            public Builder classification(String classification) { this.classification = classification; return this; }
            public Builder status(String status) { this.status = status; return this; }
            public Builder createdAt(Instant createdAt) { this.createdAt = createdAt; return this; }
            public Builder expiresAt(Instant expiresAt) { this.expiresAt = expiresAt; return this; }
            public Builder hasAttachments(boolean hasAttachments) { this.hasAttachments = hasAttachments; return this; }
            public MessageSummary build() {
                return new MessageSummary(id, senderUsername, recipientUsername, classification, status,
                        createdAt, expiresAt, hasAttachments);
            }
        }
    }
    
    /**
     * Full message details (for decryption).
     */
    public static class MessageDetail {
        private String id;
        private String senderUsername;
        private String recipientUsername;
        private String encryptedContent;
        private String encryptedContentKey;
        private String encryptionAlgorithm;
        private int encryptionRounds;
        private String classification;
        private String status;
        private Instant createdAt;
        private Instant readAt;
        private Instant expiresAt;
        private List<AttachmentSummary> attachments;
        
        public MessageDetail() {}
        public MessageDetail(String id, String senderUsername, String recipientUsername, String encryptedContent,
                            String encryptedContentKey, String encryptionAlgorithm, int encryptionRounds,
                            String classification, String status, Instant createdAt, Instant readAt,
                            Instant expiresAt, List<AttachmentSummary> attachments) {
            this.id = id;
            this.senderUsername = senderUsername;
            this.recipientUsername = recipientUsername;
            this.encryptedContent = encryptedContent;
            this.encryptedContentKey = encryptedContentKey;
            this.encryptionAlgorithm = encryptionAlgorithm;
            this.encryptionRounds = encryptionRounds;
            this.classification = classification;
            this.status = status;
            this.createdAt = createdAt;
            this.readAt = readAt;
            this.expiresAt = expiresAt;
            this.attachments = attachments;
        }
        
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getSenderUsername() { return senderUsername; }
        public void setSenderUsername(String senderUsername) { this.senderUsername = senderUsername; }
        public String getRecipientUsername() { return recipientUsername; }
        public void setRecipientUsername(String recipientUsername) { this.recipientUsername = recipientUsername; }
        public String getEncryptedContent() { return encryptedContent; }
        public void setEncryptedContent(String encryptedContent) { this.encryptedContent = encryptedContent; }
        public String getEncryptedContentKey() { return encryptedContentKey; }
        public void setEncryptedContentKey(String encryptedContentKey) { this.encryptedContentKey = encryptedContentKey; }
        public String getEncryptionAlgorithm() { return encryptionAlgorithm; }
        public void setEncryptionAlgorithm(String encryptionAlgorithm) { this.encryptionAlgorithm = encryptionAlgorithm; }
        public int getEncryptionRounds() { return encryptionRounds; }
        public void setEncryptionRounds(int encryptionRounds) { this.encryptionRounds = encryptionRounds; }
        public String getClassification() { return classification; }
        public void setClassification(String classification) { this.classification = classification; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public Instant getCreatedAt() { return createdAt; }
        public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
        public Instant getReadAt() { return readAt; }
        public void setReadAt(Instant readAt) { this.readAt = readAt; }
        public Instant getExpiresAt() { return expiresAt; }
        public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
        public List<AttachmentSummary> getAttachments() { return attachments; }
        public void setAttachments(List<AttachmentSummary> attachments) { this.attachments = attachments; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String id;
            private String senderUsername;
            private String recipientUsername;
            private String encryptedContent;
            private String encryptedContentKey;
            private String encryptionAlgorithm;
            private int encryptionRounds;
            private String classification;
            private String status;
            private Instant createdAt;
            private Instant readAt;
            private Instant expiresAt;
            private List<AttachmentSummary> attachments;
            
            public Builder id(String id) { this.id = id; return this; }
            public Builder senderUsername(String senderUsername) { this.senderUsername = senderUsername; return this; }
            public Builder recipientUsername(String recipientUsername) { this.recipientUsername = recipientUsername; return this; }
            public Builder encryptedContent(String encryptedContent) { this.encryptedContent = encryptedContent; return this; }
            public Builder encryptedContentKey(String encryptedContentKey) { this.encryptedContentKey = encryptedContentKey; return this; }
            public Builder encryptionAlgorithm(String encryptionAlgorithm) { this.encryptionAlgorithm = encryptionAlgorithm; return this; }
            public Builder encryptionRounds(int encryptionRounds) { this.encryptionRounds = encryptionRounds; return this; }
            public Builder classification(String classification) { this.classification = classification; return this; }
            public Builder status(String status) { this.status = status; return this; }
            public Builder createdAt(Instant createdAt) { this.createdAt = createdAt; return this; }
            public Builder readAt(Instant readAt) { this.readAt = readAt; return this; }
            public Builder expiresAt(Instant expiresAt) { this.expiresAt = expiresAt; return this; }
            public Builder attachments(List<AttachmentSummary> attachments) { this.attachments = attachments; return this; }
            
            public MessageDetail build() {
                return new MessageDetail(id, senderUsername, recipientUsername, encryptedContent,
                        encryptedContentKey, encryptionAlgorithm, encryptionRounds, classification,
                        status, createdAt, readAt, expiresAt, attachments);
            }
        }
    }
    
    /**
     * Decrypted message (after server-side decryption).
     */
    public static class DecryptedMessage {
        private String id;
        private String senderUsername;
        private String content;
        private String classification;
        private Instant createdAt;
        
        public DecryptedMessage() {}
        public DecryptedMessage(String id, String senderUsername, String content, String classification, Instant createdAt) {
            this.id = id;
            this.senderUsername = senderUsername;
            this.content = content;
            this.classification = classification;
            this.createdAt = createdAt;
        }
        
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getSenderUsername() { return senderUsername; }
        public void setSenderUsername(String senderUsername) { this.senderUsername = senderUsername; }
        public String getContent() { return content; }
        public void setContent(String content) { this.content = content; }
        public String getClassification() { return classification; }
        public void setClassification(String classification) { this.classification = classification; }
        public Instant getCreatedAt() { return createdAt; }
        public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String id;
            private String senderUsername;
            private String content;
            private String classification;
            private Instant createdAt;
            
            public Builder id(String id) { this.id = id; return this; }
            public Builder senderUsername(String senderUsername) { this.senderUsername = senderUsername; return this; }
            public Builder content(String content) { this.content = content; return this; }
            public Builder classification(String classification) { this.classification = classification; return this; }
            public Builder createdAt(Instant createdAt) { this.createdAt = createdAt; return this; }
            public DecryptedMessage build() {
                return new DecryptedMessage(id, senderUsername, content, classification, createdAt);
            }
        }
    }
    
    /**
     * Request to decrypt a message.
     */
    public static class DecryptRequest {
        @NotBlank(message = "Message ID is required")
        private String messageId;
        
        /**
         * User's password (to decrypt their private key)
         */
        @NotBlank(message = "Password is required for decryption")
        private String password;
        
        public DecryptRequest() {}
        public DecryptRequest(String messageId, String password) {
            this.messageId = messageId;
            this.password = password;
        }
        
        public String getMessageId() { return messageId; }
        public void setMessageId(String messageId) { this.messageId = messageId; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
    }
    
    /**
     * Attachment summary.
     */
    public static class AttachmentSummary {
        private String id;
        private String filename;
        private String mimeType;
        private long size;
        
        public AttachmentSummary() {}
        public AttachmentSummary(String id, String filename, String mimeType, long size) {
            this.id = id;
            this.filename = filename;
            this.mimeType = mimeType;
            this.size = size;
        }
        
        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getFilename() { return filename; }
        public void setFilename(String filename) { this.filename = filename; }
        public String getMimeType() { return mimeType; }
        public void setMimeType(String mimeType) { this.mimeType = mimeType; }
        public long getSize() { return size; }
        public void setSize(long size) { this.size = size; }
    }
    
    /**
     * Inbox/Sent response with pagination.
     */
    public static class MessageListResponse {
        private List<MessageSummary> messages;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;
        
        public MessageListResponse() {}
        public MessageListResponse(List<MessageSummary> messages, int page, int size, long totalElements, int totalPages) {
            this.messages = messages;
            this.page = page;
            this.size = size;
            this.totalElements = totalElements;
            this.totalPages = totalPages;
        }
        
        public List<MessageSummary> getMessages() { return messages; }
        public void setMessages(List<MessageSummary> messages) { this.messages = messages; }
        public int getPage() { return page; }
        public void setPage(int page) { this.page = page; }
        public int getSize() { return size; }
        public void setSize(int size) { this.size = size; }
        public long getTotalElements() { return totalElements; }
        public void setTotalElements(long totalElements) { this.totalElements = totalElements; }
        public int getTotalPages() { return totalPages; }
        public void setTotalPages(int totalPages) { this.totalPages = totalPages; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private List<MessageSummary> messages;
            private int page;
            private int size;
            private long totalElements;
            private int totalPages;
            
            public Builder messages(List<MessageSummary> messages) { this.messages = messages; return this; }
            public Builder page(int page) { this.page = page; return this; }
            public Builder size(int size) { this.size = size; return this; }
            public Builder totalElements(long totalElements) { this.totalElements = totalElements; return this; }
            public Builder totalPages(int totalPages) { this.totalPages = totalPages; return this; }
            public MessageListResponse build() {
                return new MessageListResponse(messages, page, size, totalElements, totalPages);
            }
        }
    }
    
    /**
     * Delivery acknowledgment (without revealing content).
     */
    public static class DeliveryAck {
        private String messageId;
        private String status;
        private Instant deliveredAt;
        /**
         * HMAC of encrypted content - proves delivery without revealing content
         */
        private String contentHash;
        
        public DeliveryAck() {}
        public DeliveryAck(String messageId, String status, Instant deliveredAt, String contentHash) {
            this.messageId = messageId;
            this.status = status;
            this.deliveredAt = deliveredAt;
            this.contentHash = contentHash;
        }
        
        public String getMessageId() { return messageId; }
        public void setMessageId(String messageId) { this.messageId = messageId; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public Instant getDeliveredAt() { return deliveredAt; }
        public void setDeliveredAt(Instant deliveredAt) { this.deliveredAt = deliveredAt; }
        public String getContentHash() { return contentHash; }
        public void setContentHash(String contentHash) { this.contentHash = contentHash; }
        
        public static Builder builder() { return new Builder(); }
        public static class Builder {
            private String messageId;
            private String status;
            private Instant deliveredAt;
            private String contentHash;
            
            public Builder messageId(String messageId) { this.messageId = messageId; return this; }
            public Builder status(String status) { this.status = status; return this; }
            public Builder deliveredAt(Instant deliveredAt) { this.deliveredAt = deliveredAt; return this; }
            public Builder contentHash(String contentHash) { this.contentHash = contentHash; return this; }
            public DeliveryAck build() {
                return new DeliveryAck(messageId, status, deliveredAt, contentHash);
            }
        }
    }
}

