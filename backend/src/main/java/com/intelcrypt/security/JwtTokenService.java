package com.intelcrypt.security;

import com.intelcrypt.config.CryptoConfigProperties;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;

/**
 * JWT Token Service for authentication.
 * 
 * SECURITY NOTES:
 * - Uses HS256 with 256-bit+ secret key
 * - Short-lived access tokens (15 min default)
 * - Separate refresh tokens for session extension
 * - Tokens include unique JTI for revocation tracking
 */
@Service
public class JwtTokenService {
    
    private static final Logger log = LoggerFactory.getLogger(JwtTokenService.class);
    
    private final CryptoConfigProperties config;
    
    public JwtTokenService(CryptoConfigProperties config) {
        this.config = config;
    }
    
    /**
     * Extract username from token.
     */
    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }
    
    /**
     * Extract expiration date from token.
     */
    public Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }
    
    /**
     * Extract token ID (jti) for revocation tracking.
     */
    public String extractTokenId(String token) {
        return extractClaim(token, Claims::getId);
    }
    
    /**
     * Extract any claim from token.
     */
    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }
    
    /**
     * Generate access token for user.
     */
    public String generateToken(UserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("roles", userDetails.getAuthorities().stream()
            .map(Object::toString)
            .toList());
        return generateToken(claims, userDetails);
    }
    
    /**
     * Generate token with extra claims.
     */
    public String generateToken(Map<String, Object> extraClaims, UserDetails userDetails) {
        return buildToken(extraClaims, userDetails, config.getJwt().getExpirationMs());
    }
    
    /**
     * Generate refresh token.
     */
    public String generateRefreshToken(UserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("type", "refresh");
        return buildToken(claims, userDetails, config.getJwt().getRefreshExpirationMs());
    }
    
    /**
     * Build JWT token.
     */
    private String buildToken(Map<String, Object> extraClaims, UserDetails userDetails, long expiration) {
        return Jwts.builder()
            .claims(extraClaims)
            .subject(userDetails.getUsername())
            .id(UUID.randomUUID().toString()) // Unique token ID for revocation
            .issuedAt(new Date())
            .expiration(new Date(System.currentTimeMillis() + expiration))
            .signWith(getSigningKey(), Jwts.SIG.HS256)
            .compact();
    }
    
    /**
     * Validate token against user details.
     */
    public boolean isTokenValid(String token, UserDetails userDetails) {
        try {
            final String username = extractUsername(token);
            return username.equals(userDetails.getUsername()) && !isTokenExpired(token);
        } catch (JwtException e) {
            log.warn("Invalid JWT token: {}", e.getMessage());
            return false;
        }
    }
    
    /**
     * Check if token is expired.
     */
    public boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }
    
    /**
     * Check if this is a refresh token.
     */
    public boolean isRefreshToken(String token) {
        try {
            Claims claims = extractAllClaims(token);
            return "refresh".equals(claims.get("type"));
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Parse and validate token, extracting all claims.
     */
    private Claims extractAllClaims(String token) {
        return Jwts.parser()
            .verifyWith(getSigningKey())
            .build()
            .parseSignedClaims(token)
            .getPayload();
    }
    
    /**
     * Get signing key from configuration.
     * SECURITY: Key must be at least 256 bits for HS256.
     */
    private SecretKey getSigningKey() {
        String secret = config.getJwt().getSecret();
        // Ensure minimum key length
        if (secret.length() < 32) {
            throw new SecurityException("JWT secret must be at least 256 bits (32 characters)");
        }
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }
}
