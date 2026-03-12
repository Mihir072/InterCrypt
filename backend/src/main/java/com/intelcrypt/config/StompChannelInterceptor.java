package com.intelcrypt.config;

import com.intelcrypt.security.JwtTokenService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Component;

/**
 * STOMP channel interceptor for JWT authentication.
 *
 * <p>
 * Validates the Bearer token on STOMP CONNECT frames so only
 * authenticated users can subscribe/send via WebSocket.
 */
@Component
public class StompChannelInterceptor implements ChannelInterceptor {

    private static final Logger log = LoggerFactory.getLogger(StompChannelInterceptor.class);

    private final JwtTokenService jwtTokenService;
    private final UserDetailsService userDetailsService;

    public StompChannelInterceptor(JwtTokenService jwtTokenService,
            UserDetailsService userDetailsService) {
        this.jwtTokenService = jwtTokenService;
        this.userDetailsService = userDetailsService;
    }

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

        if (accessor == null)
            return message;

        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            String authHeader = accessor.getFirstNativeHeader("Authorization");

            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                String token = authHeader.substring(7);
                try {
                    String username = jwtTokenService.extractUsername(token);
                    if (username != null && !jwtTokenService.isTokenExpired(token)) {
                        UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                        if (jwtTokenService.isTokenValid(token, userDetails)) {
                            UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                                    userDetails, null, userDetails.getAuthorities());
                            accessor.setUser(auth);
                            log.debug("WebSocket authenticated user: {}", username);
                        }
                    }
                } catch (Exception e) {
                    log.warn("WebSocket JWT validation failed: {}", e.getMessage());
                    // Return null to reject the connection
                    return null;
                }
            } else {
                log.warn("WebSocket CONNECT without Authorization header — rejected");
                return null;
            }
        }

        return message;
    }
}
