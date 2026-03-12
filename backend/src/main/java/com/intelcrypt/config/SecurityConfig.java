package com.intelcrypt.config;

import com.intelcrypt.security.JwtAuthenticationFilter;
import com.intelcrypt.security.JwtAuthEntryPoint;
import com.intelcrypt.security.HoneypotFilter;
import com.intelcrypt.security.RateLimitFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Lazy;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

/**
 * Security configuration for IntelCrypt.
 * 
 * Implements defense-in-depth security strategy:
 * - JWT-based stateless authentication
 * - Role-based access control (RBAC)
 * - Rate limiting to prevent brute force
 * - Honeypot endpoints for intrusion detection
 * - CORS protection
 * - Session fixation protection (stateless)
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    private final UserDetailsService userDetailsService;
    private final JwtAuthEntryPoint jwtAuthEntryPoint;
    private final HoneypotFilter honeypotFilter;
    private final RateLimitFilter rateLimitFilter;

    public SecurityConfig(@Lazy UserDetailsService userDetailsService,
            JwtAuthEntryPoint jwtAuthEntryPoint,
            HoneypotFilter honeypotFilter,
            RateLimitFilter rateLimitFilter) {
        this.userDetailsService = userDetailsService;
        this.jwtAuthEntryPoint = jwtAuthEntryPoint;
        this.honeypotFilter = honeypotFilter;
        this.rateLimitFilter = rateLimitFilter;
    }

    /**
     * Endpoints that don't require authentication
     */
    private static final String[] PUBLIC_ENDPOINTS = {
            "/api/auth/login",
            "/api/auth/register",
            "/api/auth/refresh",
            "/api/health",
            "/api-docs/**",
            "/swagger-ui/**",
            "/swagger-ui.html",
            "/v3/api-docs/**",
            // WebSocket handshakes — JWT auth handled at STOMP level by interceptor
            "/ws/**",
            "/ws-native/**",
            "/api/files/download/**"
    };

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http, JwtAuthenticationFilter jwtAuthFilter)
            throws Exception {
        http
                // Disable CSRF for stateless API
                .csrf(AbstractHttpConfigurer::disable)

                // Configure CORS
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))

                // Set session management to stateless
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // Set unauthorized handler
                .exceptionHandling(exception -> exception.authenticationEntryPoint(jwtAuthEntryPoint))

                // Configure endpoint authorization
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(PUBLIC_ENDPOINTS).permitAll()
                        // Honeypot endpoints - allow access but log
                        .requestMatchers("/api/admin/**", "/api/debug/**", "/api/internal/**").permitAll()
                        // Admin endpoints
                        .requestMatchers("/api/keys/admin/**").hasRole("ADMIN")
                        // Classified endpoints
                        .requestMatchers("/api/messages/classified/**").hasAnyRole("ADMIN", "CLASSIFIED")
                        // All other endpoints require authentication
                        .anyRequest().authenticated())

                // Set authentication provider
                .authenticationProvider(authenticationProvider())

                // Add custom filters
                .addFilterBefore(rateLimitFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterBefore(honeypotFilter, UsernamePasswordAuthenticationFilter.class)
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        // Security headers
        http.headers(headers -> headers
                .contentSecurityPolicy(csp -> csp.policyDirectives("default-src 'self'"))
                .frameOptions(frame -> frame.deny())
                .xssProtection(xss -> xss.disable()) // Modern browsers handle this
                .contentTypeOptions(contentType -> {
                }));

        return http.build();
    }

    /**
     * Password encoder using Argon2id - winner of the Password Hashing Competition.
     * Provides resistance against GPU/ASIC attacks.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        // Argon2id with memory cost 16MB, 2 iterations, 1 parallelism
        return new Argon2PasswordEncoder(16, 32, 1, 1 << 14, 2);
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        // Allow Flutter web origins (development)
        configuration
                .setAllowedOriginPatterns(List.of("http://localhost:*", "https://localhost:*", "http://127.0.0.1:*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        configuration
                .setAllowedHeaders(Arrays.asList("Authorization", "Content-Type", "X-Request-ID", "Accept", "Origin"));
        configuration.setExposedHeaders(List.of("X-Request-ID", "Authorization"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", configuration);
        source.registerCorsConfiguration("/ws/**", configuration);
        return source;
    }
}
