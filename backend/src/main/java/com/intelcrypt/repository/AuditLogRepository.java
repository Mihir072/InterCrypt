package com.intelcrypt.repository;

import com.intelcrypt.entity.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, UUID> {
    
    /**
     * Find logs by user.
     */
    Page<AuditLog> findByUserIdOrderByTimestampDesc(UUID userId, Pageable pageable);
    
    /**
     * Find logs by event type.
     */
    Page<AuditLog> findByEventTypeOrderByTimestampDesc(AuditLog.EventType eventType, 
                                                        Pageable pageable);
    
    /**
     * Find security-related events.
     */
    @Query("SELECT a FROM AuditLog a WHERE a.eventType IN " +
           "('INTRUSION_DETECTED', 'HONEYPOT_TRIGGERED', 'RATE_LIMIT_EXCEEDED', " +
           "'SUSPICIOUS_ACTIVITY', 'BRUTE_FORCE_DETECTED', 'LOGIN_FAILURE') " +
           "AND a.timestamp > :since ORDER BY a.timestamp DESC")
    List<AuditLog> findSecurityEvents(@Param("since") Instant since);
    
    /**
     * Find logs by IP address.
     */
    List<AuditLog> findByIpAddressOrderByTimestampDesc(String ipAddress);
    
    /**
     * Get the latest log entry (for HMAC chaining).
     */
    @Query("SELECT a FROM AuditLog a ORDER BY a.sequenceNumber DESC LIMIT 1")
    Optional<AuditLog> findLatestLog();
    
    /**
     * Count failed logins for an IP.
     */
    @Query("SELECT COUNT(a) FROM AuditLog a WHERE a.ipAddress = :ipAddress " +
           "AND a.eventType = 'LOGIN_FAILURE' AND a.timestamp > :since")
    long countRecentFailedLogins(@Param("ipAddress") String ipAddress, 
                                 @Param("since") Instant since);
    
    /**
     * Find logs related to a specific resource.
     */
    List<AuditLog> findByResourceIdOrderByTimestampDesc(UUID resourceId);
    
    /**
     * Verify audit log chain integrity.
     */
    @Query("SELECT a FROM AuditLog a WHERE a.sequenceNumber BETWEEN :start AND :end " +
           "ORDER BY a.sequenceNumber ASC")
    List<AuditLog> findLogRange(@Param("start") Long start, @Param("end") Long end);
}
