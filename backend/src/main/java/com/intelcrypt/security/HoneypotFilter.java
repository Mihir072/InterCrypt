package com.intelcrypt.security;

import com.intelcrypt.config.CryptoConfigProperties;
import com.intelcrypt.service.AuditService;
import com.intelcrypt.entity.AuditLog;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.security.SecureRandom;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Honeypot Filter for Intrusion Detection.
 * 
 * SECURITY FEATURES:
 * - Fake endpoints that look attractive to attackers
 * - Tracks repeat offenders
 * - Injects spam data to waste attacker resources
 * - Silent alerting for security team
 * - Redirects attackers to fake vault
 * 
 * WARNING: This is a deception-based defense mechanism.
 * All interactions are logged for forensic analysis.
 */
@Component
public class HoneypotFilter extends OncePerRequestFilter {
    
    private static final Logger log = LoggerFactory.getLogger(HoneypotFilter.class);
    private final CryptoConfigProperties config;
    private final AuditService auditService;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final SecureRandom random = new SecureRandom();
    
    // Track suspicious IPs and their offense count
    private final Map<String, Integer> suspiciousIps = new ConcurrentHashMap<>();
    
    // Honeypot endpoints that look attractive to attackers
    private static final Set<String> HONEYPOT_PATHS = Set.of(
        "/api/admin/config",
        "/api/admin/users",
        "/api/admin/keys",
        "/api/debug/keys",
        "/api/debug/config",
        "/api/internal/secrets",
        "/api/internal/decrypt",
        "/api/backup/keys",
        "/api/v1/admin",
        "/api/test/decrypt",
        "/.env",
        "/config.json",
        "/secrets.json",
        "/api/swagger.json",
        "/admin.php",
        "/phpmyadmin",
        "/wp-admin",
        "/wp-login.php"
    );
    
    public HoneypotFilter(CryptoConfigProperties config, AuditService auditService) {
        this.config = config;
        this.auditService = auditService;
    }
    
    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {
        
        if (!config.getSecurity().getHoneypot().isEnabled()) {
            filterChain.doFilter(request, response);
            return;
        }
        
        String path = request.getServletPath().toLowerCase();
        String clientIp = getClientIp(request);
        
        // Check if path matches honeypot
        if (isHoneypotPath(path)) {
            handleHoneypotTrigger(request, response, clientIp, path);
            return;
        }
        
        // Check for suspicious patterns in request
        if (hasSuspiciousPatterns(request)) {
            recordSuspiciousActivity(clientIp, "Suspicious request pattern", request);
        }
        
        filterChain.doFilter(request, response);
    }
    
    /**
     * Handle honeypot trigger - log, alert, and respond with fake data.
     */
    private void handleHoneypotTrigger(HttpServletRequest request, 
                                       HttpServletResponse response,
                                       String clientIp, 
                                       String path) throws IOException {
        
        // Increment offense count
        int offenseCount = suspiciousIps.merge(clientIp, 1, Integer::sum);
        
        log.warn("HONEYPOT TRIGGERED: IP={}, Path={}, Offense={}", clientIp, path, offenseCount);
        
        // Audit the intrusion attempt
        auditService.logSecurityEvent(
            AuditLog.EventType.HONEYPOT_TRIGGERED,
            null,
            clientIp,
            request.getHeader("User-Agent"),
            String.format("Honeypot triggered: path=%s, offense=%d", path, offenseCount)
        );
        
        // Check alert threshold
        if (offenseCount >= config.getSecurity().getIntrusion().getAlertThreshold()) {
            triggerSilentAlert(clientIp, offenseCount);
        }
        
        // Respond with fake data or redirect to fake vault
        if (config.getSecurity().getIntrusion().isSpamInjection()) {
            sendFakeData(response, path);
        } else {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        }
    }
    
    /**
     * Check if path matches known honeypot patterns.
     */
    private boolean isHoneypotPath(String path) {
        return HONEYPOT_PATHS.stream().anyMatch(path::contains);
    }
    
    /**
     * Check for suspicious patterns in request.
     */
    private boolean hasSuspiciousPatterns(HttpServletRequest request) {
        String path = request.getServletPath();
        String queryString = request.getQueryString();
        
        // SQL injection patterns
        if (queryString != null && 
            (queryString.contains("'") || 
             queryString.toLowerCase().contains("union") ||
             queryString.toLowerCase().contains("select"))) {
            return true;
        }
        
        // Path traversal
        if (path.contains("..") || path.contains("%2e%2e")) {
            return true;
        }
        
        // XSS patterns
        if (queryString != null &&
            (queryString.contains("<script") || 
             queryString.contains("javascript:"))) {
            return true;
        }
        
        return false;
    }
    
    /**
     * Record suspicious activity.
     */
    private void recordSuspiciousActivity(String clientIp, String reason, HttpServletRequest request) {
        log.warn("Suspicious activity from {}: {}", clientIp, reason);
        
        auditService.logSecurityEvent(
            AuditLog.EventType.SUSPICIOUS_ACTIVITY,
            null,
            clientIp,
            request.getHeader("User-Agent"),
            reason
        );
        
        suspiciousIps.merge(clientIp, 1, Integer::sum);
    }
    
    /**
     * Trigger silent alert for security team.
     */
    private void triggerSilentAlert(String clientIp, int offenseCount) {
        log.error("SECURITY ALERT: Repeat offender detected - IP={}, Offenses={}", 
                 clientIp, offenseCount);
        
        auditService.logSecurityEvent(
            AuditLog.EventType.INTRUSION_DETECTED,
            null,
            clientIp,
            null,
            "Repeat intrusion attempt threshold exceeded"
        );
        
        // In production, this would trigger external alerting (email, SMS, SIEM)
        // For now, we log at ERROR level which can be picked up by monitoring
    }
    
    /**
     * Send fake data to waste attacker resources.
     */
    private void sendFakeData(HttpServletResponse response, String path) throws IOException {
        response.setContentType("application/json");
        
        // Add realistic delay to seem like processing
        try {
            Thread.sleep(random.nextInt(2000) + 500);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        Map<String, Object> fakeData = generateFakeData(path);
        response.setStatus(HttpServletResponse.SC_OK);
        objectMapper.writeValue(response.getOutputStream(), fakeData);
    }
    
    /**
     * Generate convincing-looking fake data.
     */
    private Map<String, Object> generateFakeData(String path) {
        Map<String, Object> data = new HashMap<>();
        
        if (path.contains("key")) {
            // Fake encryption keys
            data.put("status", "success");
            data.put("keys", List.of(
                Map.of("id", UUID.randomUUID(), "type", "AES-256", 
                       "key", generateFakeKey()),
                Map.of("id", UUID.randomUUID(), "type", "RSA-4096", 
                       "key", generateFakeKey())
            ));
        } else if (path.contains("user")) {
            // Fake user data
            data.put("users", List.of(
                Map.of("username", "admin", "email", "admin@internal.local"),
                Map.of("username", "root", "email", "root@internal.local")
            ));
        } else if (path.contains("config") || path.contains("secret")) {
            // Fake configuration
            data.put("database", Map.of(
                "host", "internal-db.local",
                "password", generateFakeKey()
            ));
            data.put("api_key", generateFakeKey());
        } else {
            data.put("status", "success");
            data.put("data", "classified");
        }
        
        return data;
    }
    
    /**
     * Generate fake key that looks real.
     */
    private String generateFakeKey() {
        byte[] fakeKey = new byte[32];
        random.nextBytes(fakeKey);
        return Base64.getEncoder().encodeToString(fakeKey);
    }
    
    /**
     * Extract client IP.
     */
    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
