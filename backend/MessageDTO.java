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

        @Override
        public String toString() {
            return "SendRequest{" + "recipientUsername='" + recipientUsername + '\'' + ", classification=" + classification + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            SendRequest that = (SendRequest) o;
            return Objects.equals(recipientUsername, that.recipientUsername) && Objects.equals(content, that.content) &&
                    classification == that.classification && Objects.equals(expirationHours, that.expirationHours);
        }

        @Override
        public int hashCode() {
            return Objects.hash(recipientUsername, content, classification, expirationHours);
        }

        public static Builder builder() {
            return new Builder();
        }

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
                return new SendRequest(recipientUsername, content, classification, expirationHours, preEncryptedContent, preEncryptedKey, encryptionParams);
            }
        }
    }
    
    public static class EncryptionParams {
        private String mode;
        private int keySize;
        private int rounds;

        public EncryptionParams() {}
        public EncryptionParams(String mode, int keySize, int rounds) {
            this.mode = mode; this.keySize = keySize; this.rounds = rounds;
        }

        public String getMode() { return mode; }
        public void setMode(String mode) { this.mode = mode; }
        public int getKeySize() { return keySize; }
        public void setKeySize(int keySize) { this.keySize = keySize; }
        public int getRounds() { return rounds; }
        public void setRounds(int rounds) { this.rounds = rounds; }

        @Override
        public String toString() {
            return "EncryptionParams{" + "mode='" + mode + '\'' + ", keySize=" + keySize + ", rounds=" + rounds + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            EncryptionParams that = (EncryptionParams) o;
            return keySize == that.keySize && rounds == that.rounds && Objects.equals(mode, that.mode);
        }

        @Override
        public int hashCode() {
            return Objects.hash(mode, keySize, rounds);
        }

        public static Builder builder() { return new Builder(); }

        public static class Builder {
            private String mode;
            private int keySize;
            private int rounds;
            public Builder mode(String mode) { this.mode = mode; return this; }
            public Builder keySize(int keySize) { this.keySize = keySize; return this; }
            public Builder rounds(int rounds) { this.rounds = rounds; return this; }
            public EncryptionParams build() { return new EncryptionParams(mode, keySize, rounds); }
        }
    }
    
    public static class SendResponse {
        private String messageId;
        private String status;
        private Instant sentAt;
        private Instant expiresAt;

        public SendResponse() {}
        public SendResponse(String messageId, String status, Instant sentAt, Instant expiresAt) {
            this.messageId = messageId; this.status = status; this.sentAt = sentAt; this.expiresAt = expiresAt;
        }

        public String getMessageId() { return messageId; }
        public void setMessageId(String messageId) { this.messageId = messageId; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public Instant getSentAt() { return sentAt; }
        public void setSentAt(Instant sentAt) { this.sentAt = sentAt; }
        public Instant getExpiresAt() { return expiresAt; }
        public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }

        @Override
        public String toString() {
            return "SendResponse{" + "messageId='" + messageId + '\'' + ", status='" + status + '\'' + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            SendResponse that = (SendResponse) o;
            return Objects.equals(messageId, that.messageId) && Objects.equals(status, that.status);
        }

        @Override
        public int hashCode() {
            return Objects.hash(messageId, status);
        }

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
            this.id = id; this.senderUsername = senderUsername; this.recipientUsername = recipientUsername;
            this.classification = classification; this.status = status; this.createdAt = createdAt;
            this.expiresAt = expiresAt; this.hasAttachments = hasAttachments;
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

        @Override
        public String toString() {
            return "MessageSummary{" + "id='" + id + '\'' + ", senderUsername='" + senderUsername + '\'' + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            MessageSummary that = (MessageSummary) o;
            return Objects.equals(id, that.id) && Objects.equals(senderUsername, that.senderUsername) &&
                    Objects.equals(recipientUsername, that.recipientUsername);
        }

        @Override
        public int hashCode() {
            return Objects.hash(id, senderUsername, recipientUsername);
        }

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
                return new MessageSummary(id, senderUsername, recipientUsername, classification, status, createdAt, expiresAt, hasAttachments);
            }
        }
    }
    
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
                           String classification, String status, Instant createdAt, Instant readAt, Instant expiresAt,
                           List<AttachmentSummary> attachments) {
            this.id = id; this.senderUsername = senderUsername; this.recipientUsername = recipientUsername;
            this.encryptedContent = encryptedContent; this.encryptedContentKey = encryptedContentKey;
            this.encryptionAlgorithm = encryptionAlgorithm; this.encryptionRounds = encryptionRounds;
            this.classification = classification; this.status = status; this.createdAt = createdAt;
            this.readAt = readAt; this.expiresAt = expiresAt; this.attachments = attachments;
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

        @Override
        public String toString() {
            return "MessageDetail{" + "id='" + id + '\'' + ", senderUsername='" + senderUsername + '\'' + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            MessageDetail that = (MessageDetail) o;
            return Objects.equals(id, that.id);
        }

        @Override
        public int hashCode() {
            return Objects.hash(id);
        }

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
                return new MessageDetail(id, senderUsername, recipientUsername, encryptedContent, encryptedContentKey,
                        encryptionAlgorithm, encryptionRounds, classification, status, createdAt, readAt, expiresAt, attachments);
            }
        }
    }
    
    public static class DecryptedMessage {
        private String id;
        private String senderUsername;
        private String content;
        private String classification;
        private Instant createdAt;

        public DecryptedMessage() {}
        public DecryptedMessage(String id, String senderUsername, String content, String classification, Instant createdAt) {
            this.id = id; this.senderUsername = senderUsername; this.content = content; this.classification = classification; this.createdAt = createdAt;
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

        @Override
        public String toString() {
            return "DecryptedMessage{" + "id='" + id + '\'' + ", senderUsername='" + senderUsername + '\'' + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            DecryptedMessage that = (DecryptedMessage) o;
            return Objects.equals(id, that.id) && Objects.equals(senderUsername, that.senderUsername);
        }

        @Override
        public int hashCode() {
            return Objects.hash(id, senderUsername);
        }

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
            public DecryptedMessage build() { return new DecryptedMessage(id, senderUsername, content, classification, createdAt); }
        }
    }
    
    public static class DecryptRequest {
        @NotBlank(message = "Message ID is required")
        private String messageId;
        @NotBlank(message = "Password is required for decryption")
        private String password;

        public DecryptRequest() {}
        public DecryptRequest(String messageId, String password) {
            this.messageId = messageId; this.password = password;
        }

        public String getMessageId() { return messageId; }
        public void setMessageId(String messageId) { this.messageId = messageId; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }

        @Override
        public String toString() {
            return "DecryptRequest{" + "messageId='" + messageId + '\'' + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            DecryptRequest that = (DecryptRequest) o;
            return Objects.equals(messageId, that.messageId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(messageId);
        }

        public static Builder builder() { return new Builder(); }

        public static class Builder {
            private String messageId;
            private String password;
            public Builder messageId(String messageId) { this.messageId = messageId; return this; }
            public Builder password(String password) { this.password = password; return this; }
            public DecryptRequest build() { return new DecryptRequest(messageId, password); }
        }
    }
    
    public static class AttachmentSummary {
        private String id;
        private String filename;
        private String mimeType;
        private long size;

        public AttachmentSummary() {}
        public AttachmentSummary(String id, String filename, String mimeType, long size) {
            this.id = id; this.filename = filename; this.mimeType = mimeType; this.size = size;
        }

        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getFilename() { return filename; }
        public void setFilename(String filename) { this.filename = filename; }
        public String getMimeType() { return mimeType; }
        public void setMimeType(String mimeType) { this.mimeType = mimeType; }
        public long getSize() { return size; }
        public void setSize(long size) { this.size = size; }

        @Override
        public String toString() {
            return "AttachmentSummary{" + "id='" + id + '\'' + ", filename='" + filename + '\'' + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            AttachmentSummary that = (AttachmentSummary) o;
            return Objects.equals(id, that.id) && Objects.equals(filename, that.filename);
        }

        @Override
        public int hashCode() {
            return Objects.hash(id, filename);
        }

        public static Builder builder() { return new Builder(); }

        public static class Builder {
            private String id;
            private String filename;
            private String mimeType;
            private long size;
            public Builder id(String id) { this.id = id; return this; }
            public Builder filename(String filename) { this.filename = filename; return this; }
            public Builder mimeType(String mimeType) { this.mimeType = mimeType; return this; }
            public Builder size(long size) { this.size = size; return this; }
            public AttachmentSummary build() { return new AttachmentSummary(id, filename, mimeType, size); }
        }
    }
    
    public static class MessageListResponse {
        private List<MessageSummary> messages;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;

        public MessageListResponse() {}
        public MessageListResponse(List<MessageSummary> messages, int page, int size, long totalElements, int totalPages) {
            this.messages = messages; this.page = page; this.size = size; this.totalElements = totalElements; this.totalPages = totalPages;
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

        @Override
        public String toString() {
            return "MessageListResponse{" + "page=" + page + ", size=" + size + ", totalElements=" + totalElements + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            MessageListResponse that = (MessageListResponse) o;
            return page == that.page && size == that.size && totalElements == that.totalElements && totalPages == that.totalPages;
        }

        @Override
        public int hashCode() {
            return Objects.hash(page, size, totalElements, totalPages);
        }

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
            public MessageListResponse build() { return new MessageListResponse(messages, page, size, totalElements, totalPages); }
        }
    }
    
    public static class DeliveryAck {
        private String messageId;
        private String status;
        private Instant deliveredAt;
        private String contentHash;

        public DeliveryAck() {}
        public DeliveryAck(String messageId, String status, Instant deliveredAt, String contentHash) {
            this.messageId = messageId; this.status = status; this.deliveredAt = deliveredAt; this.contentHash = contentHash;
        }

        public String getMessageId() { return messageId; }
        public void setMessageId(String messageId) { this.messageId = messageId; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public Instant getDeliveredAt() { return deliveredAt; }
        public void setDeliveredAt(Instant deliveredAt) { this.deliveredAt = deliveredAt; }
        public String getContentHash() { return contentHash; }
        public void setContentHash(String contentHash) { this.contentHash = contentHash; }

        @Override
        public String toString() {
            return "DeliveryAck{" + "messageId='" + messageId + '\'' + ", status='" + status + '\'' + '}';
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            DeliveryAck that = (DeliveryAck) o;
            return Objects.equals(messageId, that.messageId) && Objects.equals(status, that.status);
        }

        @Override
        public int hashCode() {
            return Objects.hash(messageId, status);
        }

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
            public DeliveryAck build() { return new DeliveryAck(messageId, status, deliveredAt, contentHash); }
        }
    }
}
