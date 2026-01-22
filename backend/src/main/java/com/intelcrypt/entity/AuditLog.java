package com.intelcrypt.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Tamper-resistant audit log entity.
 * 
 * SECURITY NOTES:
 * - All security-relevant events are logged
 * - Logs are chained using HMAC for tamper detection
 * - Previous log's HMAC is included in current log's signature
 * - Log entries cannot be modified without detection
 */
@Entity
@Table(name = "audit_logs", indexes = {
    @Index(name = "idx_audit_user", columnList = "user_id"),
    @Index(name = "idx_audit_event", columnList = "eventType"),
    @Index(name = "idx_audit_timestamp", columnList = "timestamp"),
    @Index(name = "idx_audit_resource", columnList = "resourceId")
})
public class AuditLog {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    
    /**
     * User who performed the action (null for system events)
     */
    @Column
    private UUID userId;
    
    /**
     * Username at time of event (denormalized for audit trail)
     */
    @Column(length = 50)
    private String username;
    
    /**
     * Type of security event
     */
    @Enumerated(EnumType.STRING)
    @Column(length = 50, nullable = false)
    private EventType eventType;
    
    /**
     * Detailed event description
     */
    @Column(length = 500)
    private String description;
    
    /**
     * Resource affected (message ID, key ID, etc.)
     */
    @Column
    private UUID resourceId;
    
    /**
     * Resource type (MESSAGE, KEY, USER, etc.)
     */
    @Column(length = 30)
    private String resourceType;
    
    /**
     * Client IP address
     */
    @Column(length = 45) // IPv6 max length
    private String ipAddress;
    
    /**
     * User agent string
     */
    @Column(length = 500)
    private String userAgent;
    
    /**
     * Request ID for correlation
     */
    @Column(length = 36)
    private String requestId;
    
    /**
     * Event outcome
     */
    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private EventOutcome outcome;
    
    /**
     * Error message if outcome is FAILURE
     */
    @Column(length = 500)
    private String errorMessage;
    
    @CreationTimestamp
    @Column(updatable = false)
    private Instant timestamp;
    
    /**
     * Sequence number for ordering within a session
     */
    @Column
    private Long sequenceNumber;
    
    /**
     * HMAC of this log entry for integrity
     * Computed over: previousHmac + eventType + userId + timestamp + resourceId
     */
    @Column(length = 128, nullable = false)
    private String entryHmac;
    
    /**
     * Reference to previous log's HMAC for chain integrity
     */
    @Column(length = 128)
    private String previousHmac;
    
    /**
     * Additional metadata (JSON)
     */
    @Column(columnDefinition = "TEXT")
    private String metadata;
    
    // Constructors
    public AuditLog() {
        this.outcome = EventOutcome.SUCCESS;
    }
    
    public AuditLog(UUID id, UUID userId, String username, EventType eventType,
                    String description, UUID resourceId, String resourceType,
                    String ipAddress, String userAgent, String requestId,
                    EventOutcome outcome, String errorMessage, Instant timestamp,
                    Long sequenceNumber, String entryHmac, String previousHmac, String metadata) {
        this.id = id;
        this.userId = userId;
        this.username = username;
        this.eventType = eventType;
        this.description = description;
        this.resourceId = resourceId;
        this.resourceType = resourceType;
        this.ipAddress = ipAddress;
        this.userAgent = userAgent;
        this.requestId = requestId;
        this.outcome = outcome != null ? outcome : EventOutcome.SUCCESS;
        this.errorMessage = errorMessage;
        this.timestamp = timestamp;
        this.sequenceNumber = sequenceNumber;
        this.entryHmac = entryHmac;
        this.previousHmac = previousHmac;
        this.metadata = metadata;
    }
    
    // Getters and Setters
    public UUID getId() {
        return id;
    }
    
    public void setId(UUID id) {
        this.id = id;
    }
    
    public UUID getUserId() {
        return userId;
    }
    
    public void setUserId(UUID userId) {
        this.userId = userId;
    }
    
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public EventType getEventType() {
        return eventType;
    }
    
    public void setEventType(EventType eventType) {
        this.eventType = eventType;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public UUID getResourceId() {
        return resourceId;
    }
    
    public void setResourceId(UUID resourceId) {
        this.resourceId = resourceId;
    }
    
    public String getResourceType() {
        return resourceType;
    }
    
    public void setResourceType(String resourceType) {
        this.resourceType = resourceType;
    }
    
    public String getIpAddress() {
        return ipAddress;
    }
    
    public void setIpAddress(String ipAddress) {
        this.ipAddress = ipAddress;
    }
    
    public String getUserAgent() {
        return userAgent;
    }
    
    public void setUserAgent(String userAgent) {
        this.userAgent = userAgent;
    }
    
    public String getRequestId() {
        return requestId;
    }
    
    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }
    
    public EventOutcome getOutcome() {
        return outcome;
    }
    
    public void setOutcome(EventOutcome outcome) {
        this.outcome = outcome;
    }
    
    public String getErrorMessage() {
        return errorMessage;
    }
    
    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }
    
    public Instant getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(Instant timestamp) {
        this.timestamp = timestamp;
    }
    
    public Long getSequenceNumber() {
        return sequenceNumber;
    }
    
    public void setSequenceNumber(Long sequenceNumber) {
        this.sequenceNumber = sequenceNumber;
    }
    
    public String getEntryHmac() {
        return entryHmac;
    }
    
    public void setEntryHmac(String entryHmac) {
        this.entryHmac = entryHmac;
    }
    
    public String getPreviousHmac() {
        return previousHmac;
    }
    
    public void setPreviousHmac(String previousHmac) {
        this.previousHmac = previousHmac;
    }
    
    public String getMetadata() {
        return metadata;
    }
    
    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        AuditLog auditLog = (AuditLog) o;
        return Objects.equals(id, auditLog.id);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
    
    @Override
    public String toString() {
        return "AuditLog{" +
                "id=" + id +
                ", userId=" + userId +
                ", username='" + username + '\'' +
                ", eventType=" + eventType +
                ", outcome=" + outcome +
                ", timestamp=" + timestamp +
                '}';
    }
    
    // Builder
    public static Builder builder() {
        return new Builder();
    }
    
    public static class Builder {
        private UUID id;
        private UUID userId;
        private String username;
        private EventType eventType;
        private String description;
        private UUID resourceId;
        private String resourceType;
        private String ipAddress;
        private String userAgent;
        private String requestId;
        private EventOutcome outcome = EventOutcome.SUCCESS;
        private String errorMessage;
        private Instant timestamp;
        private Long sequenceNumber;
        private String entryHmac;
        private String previousHmac;
        private String metadata;
        
        public Builder id(UUID id) {
            this.id = id;
            return this;
        }
        
        public Builder userId(UUID userId) {
            this.userId = userId;
            return this;
        }
        
        public Builder username(String username) {
            this.username = username;
            return this;
        }
        
        public Builder eventType(EventType eventType) {
            this.eventType = eventType;
            return this;
        }
        
        public Builder description(String description) {
            this.description = description;
            return this;
        }
        
        public Builder resourceId(UUID resourceId) {
            this.resourceId = resourceId;
            return this;
        }
        
        public Builder resourceType(String resourceType) {
            this.resourceType = resourceType;
            return this;
        }
        
        public Builder ipAddress(String ipAddress) {
            this.ipAddress = ipAddress;
            return this;
        }
        
        public Builder userAgent(String userAgent) {
            this.userAgent = userAgent;
            return this;
        }
        
        public Builder requestId(String requestId) {
            this.requestId = requestId;
            return this;
        }
        
        public Builder outcome(EventOutcome outcome) {
            this.outcome = outcome;
            return this;
        }
        
        public Builder errorMessage(String errorMessage) {
            this.errorMessage = errorMessage;
            return this;
        }
        
        public Builder timestamp(Instant timestamp) {
            this.timestamp = timestamp;
            return this;
        }
        
        public Builder sequenceNumber(Long sequenceNumber) {
            this.sequenceNumber = sequenceNumber;
            return this;
        }
        
        public Builder entryHmac(String entryHmac) {
            this.entryHmac = entryHmac;
            return this;
        }
        
        public Builder previousHmac(String previousHmac) {
            this.previousHmac = previousHmac;
            return this;
        }
        
        public Builder metadata(String metadata) {
            this.metadata = metadata;
            return this;
        }
        
        public AuditLog build() {
            return new AuditLog(id, userId, username, eventType, description, 
                              resourceId, resourceType, ipAddress, userAgent,
                              requestId, outcome, errorMessage, timestamp,
                              sequenceNumber, entryHmac, previousHmac, metadata);
        }
    }
    
    public enum EventType {
        // Authentication events
        LOGIN_SUCCESS,
        LOGIN_FAILURE,
        LOGOUT,
        TOKEN_REFRESH,
        PASSWORD_CHANGE,
        ACCOUNT_LOCKED,
        ACCOUNT_UNLOCKED,
        
        // Cryptographic events
        KEY_GENERATED,
        KEY_ROTATED,
        KEY_DELETED,
        KEY_ACCESSED,
        ENCRYPTION_PERFORMED,
        DECRYPTION_PERFORMED,
        
        // Message events
        MESSAGE_SENT,
        MESSAGE_RECEIVED,
        MESSAGE_READ,
        MESSAGE_DELETED,
        MESSAGE_EXPIRED,
        
        // Security events
        INTRUSION_DETECTED,
        HONEYPOT_TRIGGERED,
        RATE_LIMIT_EXCEEDED,
        SUSPICIOUS_ACTIVITY,
        BRUTE_FORCE_DETECTED,
        
        // Administrative events
        USER_CREATED,
        USER_MODIFIED,
        USER_DELETED,
        ROLE_CHANGED,
        CLEARANCE_CHANGED,
        
        // System events
        SYSTEM_STARTUP,
        SYSTEM_SHUTDOWN,
        CONFIG_CHANGED,
        AUDIT_TAMPER_DETECTED
    }
    
    public enum EventOutcome {
        SUCCESS,
        FAILURE,
        BLOCKED,
        SUSPICIOUS
    }
}
