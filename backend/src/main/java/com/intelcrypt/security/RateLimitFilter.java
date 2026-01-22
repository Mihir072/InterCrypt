package com.intelcrypt.security;

import com.intelcrypt.config.CryptoConfigProperties;
import com.intelcrypt.service.AuditService;
import com.intelcrypt.entity.AuditLog;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Rate Limiting Filter to prevent brute force attacks.
 * 
 * SECURITY FEATURES:
 * - Per-IP rate limiting
 * - Stricter limits for authentication endpoints
 * - Automatic bucket cleanup
 * - Audit logging of rate limit violations
 */
@Component
public class RateLimitFilter extends OncePerRequestFilter {
    
    private static final Logger log = LoggerFactory.getLogger(RateLimitFilter.class);
    private final CryptoConfigProperties config;
    private final AuditService auditService;
    
    // Rate limit buckets per IP address
    private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();
    private final Map<String, Bucket> authBuckets = new ConcurrentHashMap<>();
    
    public RateLimitFilter(CryptoConfigProperties config, AuditService auditService) {
        this.config = config;
        this.auditService = auditService;
    }
    
    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {
        
        String clientIp = getClientIp(request);
        String path = request.getServletPath();
        
        Bucket bucket;
        
        // Stricter rate limiting for auth endpoints
        if (path.startsWith("/api/auth/")) {
            bucket = authBuckets.computeIfAbsent(clientIp, this::createAuthBucket);
        } else {
            bucket = buckets.computeIfAbsent(clientIp, this::createGeneralBucket);
        }
        
        if (bucket.tryConsume(1)) {
            // Add rate limit headers
            response.setHeader("X-RateLimit-Remaining", String.valueOf(bucket.getAvailableTokens()));
            filterChain.doFilter(request, response);
        } else {
            log.warn("Rate limit exceeded for IP: {} on path: {}", clientIp, path);
            
            // Audit the rate limit violation
            auditService.logSecurityEvent(
                AuditLog.EventType.RATE_LIMIT_EXCEEDED,
                null,
                clientIp,
                request.getHeader("User-Agent"),
                "Rate limit exceeded on: " + path
            );
            
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType("application/json");
            response.getWriter().write(
                "{\"error\":\"Too many requests\",\"message\":\"Please slow down\"}"
            );
        }
    }
    
    /**
     * Create rate limit bucket for general endpoints.
     */
    private Bucket createGeneralBucket(String key) {
        int requestsPerMinute = config.getSecurity().getRateLimit().getRequestsPerMinute();
        
        Bandwidth limit = Bandwidth.classic(
            requestsPerMinute,
            Refill.greedy(requestsPerMinute, Duration.ofMinutes(1))
        );
        
        return Bucket.builder().addLimit(limit).build();
    }
    
    /**
     * Create stricter rate limit bucket for auth endpoints.
     */
    private Bucket createAuthBucket(String key) {
        int loginAttempts = config.getSecurity().getRateLimit().getLoginAttempts();
        
        Bandwidth limit = Bandwidth.classic(
            loginAttempts,
            Refill.intervally(loginAttempts, Duration.ofMinutes(1))
        );
        
        return Bucket.builder().addLimit(limit).build();
    }
    
    /**
     * Extract client IP, considering proxies.
     */
    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            // Take the first IP in case of proxy chain
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
