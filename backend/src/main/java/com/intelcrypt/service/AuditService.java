package com.intelcrypt.service;

import com.intelcrypt.config.CryptoConfigProperties;
import com.intelcrypt.entity.AuditLog;
import com.intelcrypt.repository.AuditLogRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Audit Logging Service with Tamper Protection.
 * 
 * SECURITY FEATURES:
 * - All security events are logged
 * - Log entries are chained using HMAC (tamper detection)
 * - Each entry includes reference to previous entry's HMAC
 * - Breaking the chain indicates tampering
 */
@Service
public class AuditService {
    
    private static final Logger log = LoggerFactory.getLogger(AuditService.class);
    
    private final AuditLogRepository auditLogRepository;
    private final CryptoConfigProperties config;
    
    // Sequence number for ordering (in-memory, would be distributed in production)
    private final AtomicLong sequenceGenerator = new AtomicLong(0);
    
    // HMAC key for log integrity (would come from HSM in production)
    private static final byte[] AUDIT_HMAC_KEY = 
        "IntelCrypt-Audit-Integrity-Key-2024".getBytes(StandardCharsets.UTF_8);

    public AuditService(AuditLogRepository auditLogRepository, CryptoConfigProperties config) {
        this.auditLogRepository = auditLogRepository;
        this.config = config;
    }
    
    /**
     * Log a security event with tamper protection.
     */
    @Transactional
    public AuditLog logEvent(AuditLog.EventType eventType, 
                             UUID userId, 
                             String username,
                             UUID resourceId,
                             String resourceType,
                             String ipAddress,
                             String userAgent,
                             String description,
                             AuditLog.EventOutcome outcome,
                             String metadata) {
        
        // Get previous log's HMAC for chaining
        String previousHmac = auditLogRepository.findLatestLog()
            .map(AuditLog::getEntryHmac)
            .orElse("GENESIS");
        
        long sequenceNumber = sequenceGenerator.incrementAndGet();
        
        AuditLog auditLog = AuditLog.builder()
            .userId(userId)
            .username(username)
            .eventType(eventType)
            .resourceId(resourceId)
            .resourceType(resourceType)
            .ipAddress(ipAddress)
            .userAgent(truncateUserAgent(userAgent))
            .description(description)
            .outcome(outcome)
            .sequenceNumber(sequenceNumber)
            .previousHmac(previousHmac)
            .metadata(metadata)
            .build();
        
        // Calculate entry HMAC for tamper detection
        String entryHmac = calculateEntryHmac(auditLog, previousHmac);
        auditLog.setEntryHmac(entryHmac);
        
        AuditLog saved = auditLogRepository.save(auditLog);
        
        log.info("Audit: {} - User: {} - Resource: {} - Outcome: {}", 
                eventType, username, resourceId, outcome);
        
        return saved;
    }
    
    /**
     * Simplified method for security events.
     */
    public void logSecurityEvent(AuditLog.EventType eventType,
                                 UUID userId,
                                 String ipAddress,
                                 String userAgent,
                                 String description) {
        logEvent(eventType, userId, null, null, null, 
                ipAddress, userAgent, description, 
                AuditLog.EventOutcome.SUSPICIOUS, null);
    }
    
    /**
     * Log authentication event.
     */
    public void logAuthEvent(AuditLog.EventType eventType,
                            UUID userId,
                            String username,
                            String ipAddress,
                            String userAgent,
                            AuditLog.EventOutcome outcome,
                            String errorMessage) {
        AuditLog auditLog = logEvent(eventType, userId, username, null, "USER",
                ipAddress, userAgent, 
                outcome == AuditLog.EventOutcome.SUCCESS ? 
                    "Authentication successful" : "Authentication failed",
                outcome, null);
        
        if (errorMessage != null) {
            auditLog.setErrorMessage(errorMessage);
            auditLogRepository.save(auditLog);
        }
    }
    
    /**
     * Log cryptographic operation.
     */
    public void logCryptoEvent(AuditLog.EventType eventType,
                               UUID userId,
                               String username,
                               UUID keyId,
                               String ipAddress,
                               String description) {
        logEvent(eventType, userId, username, keyId, "KEY",
                ipAddress, null, description, 
                AuditLog.EventOutcome.SUCCESS, null);
    }
    
    /**
     * Log message event.
     */
    public void logMessageEvent(AuditLog.EventType eventType,
                                UUID userId,
                                String username,
                                UUID messageId,
                                String ipAddress,
                                String description) {
        logEvent(eventType, userId, username, messageId, "MESSAGE",
                ipAddress, null, description,
                AuditLog.EventOutcome.SUCCESS, null);
    }
    
    /**
     * Verify audit log chain integrity.
     * Returns true if chain is intact, false if tampering detected.
     */
    public boolean verifyChainIntegrity(Long fromSequence, Long toSequence) {
        var logs = auditLogRepository.findLogRange(fromSequence, toSequence);
        
        if (logs.isEmpty()) {
            return true;
        }
        
        String previousHmac = logs.get(0).getPreviousHmac();
        
        for (AuditLog logEntry : logs) {
            // Verify the previous HMAC reference
            if (!previousHmac.equals(logEntry.getPreviousHmac())) {
                log.error("Audit chain broken at sequence {}: expected previous HMAC {}, got {}",
                        logEntry.getSequenceNumber(), previousHmac, logEntry.getPreviousHmac());
                
                logSecurityEvent(AuditLog.EventType.AUDIT_TAMPER_DETECTED,
                        null, "SYSTEM", null,
                        "Audit chain integrity violation at sequence " + logEntry.getSequenceNumber());
                
                return false;
            }
            
            // Verify the entry's own HMAC
            String calculatedHmac = calculateEntryHmac(logEntry, logEntry.getPreviousHmac());
            if (!calculatedHmac.equals(logEntry.getEntryHmac())) {
                log.error("Audit entry tampered at sequence {}", logEntry.getSequenceNumber());
                
                logSecurityEvent(AuditLog.EventType.AUDIT_TAMPER_DETECTED,
                        null, "SYSTEM", null,
                        "Audit entry integrity violation at sequence " + logEntry.getSequenceNumber());
                
                return false;
            }
            
            previousHmac = logEntry.getEntryHmac();
        }
        
        return true;
    }
    
    /**
     * Calculate HMAC for an audit log entry.
     */
    private String calculateEntryHmac(AuditLog entry, String previousHmac) {
        try {
            Mac hmac = Mac.getInstance("HmacSHA256");
            hmac.init(new SecretKeySpec(AUDIT_HMAC_KEY, "HmacSHA256"));
            
            // Include key fields in HMAC calculation
            String data = String.format("%s|%s|%s|%s|%d|%s",
                    previousHmac,
                    entry.getEventType(),
                    entry.getUserId(),
                    entry.getTimestamp() != null ? entry.getTimestamp().toString() : Instant.now().toString(),
                    entry.getSequenceNumber(),
                    entry.getResourceId());
            
            byte[] hmacBytes = hmac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hmacBytes);
            
        } catch (Exception e) {
            log.error("Failed to calculate audit HMAC", e);
            return "ERROR";
        }
    }
    
    /**
     * Truncate user agent to prevent storage issues.
     */
    private String truncateUserAgent(String userAgent) {
        if (userAgent == null) return null;
        return userAgent.length() > 500 ? userAgent.substring(0, 500) : userAgent;
    }
}
