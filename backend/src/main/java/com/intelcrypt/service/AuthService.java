package com.intelcrypt.service;

import com.intelcrypt.dto.AuthDTO;
import com.intelcrypt.entity.AuditLog;
import com.intelcrypt.entity.User;
import com.intelcrypt.exception.ResourceNotFoundException;
import com.intelcrypt.exception.SecurityPolicyException;
import com.intelcrypt.repository.UserRepository;
import com.intelcrypt.security.JwtTokenService;
import com.intelcrypt.security.UserPrincipal;
import com.intelcrypt.crypto.HybridCryptoService;
import com.intelcrypt.config.CryptoConfigProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Lazy;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Set;

/**
 * Authentication and User Management Service.
 * 
 * SECURITY FEATURES:
 * - Argon2id password hashing
 * - Account lockout after failed attempts
 * - JWT token generation and validation
 * - Key pair generation on registration
 * - Audit logging of all auth events
 */
@Service
public class AuthService implements UserDetailsService {
    
    private static final Logger log = LoggerFactory.getLogger(AuthService.class);
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenService jwtTokenService;
    private final AuthenticationManager authenticationManager;
    private final HybridCryptoService hybridCryptoService;
    private final AuditService auditService;
    private final CryptoConfigProperties config;
    
    public AuthService(UserRepository userRepository,
                      PasswordEncoder passwordEncoder,
                      JwtTokenService jwtTokenService,
                      @Lazy AuthenticationManager authenticationManager,
                      HybridCryptoService hybridCryptoService,
                      AuditService auditService,
                      CryptoConfigProperties config) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenService = jwtTokenService;
        this.authenticationManager = authenticationManager;
        this.hybridCryptoService = hybridCryptoService;
        this.auditService = auditService;
        this.config = config;
    }
    
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
        return new UserPrincipal(user);
    }
    
    /**
     * Register a new user.
     */
    @Transactional
    public AuthDTO.AuthResponse register(AuthDTO.RegisterRequest request, String ipAddress, String userAgent) {
        // Check for existing username/email
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new SecurityPolicyException("Username already exists");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new SecurityPolicyException("Email already registered");
        }
        
        // Validate password strength
        validatePasswordStrength(request.getPassword());
        
        // Generate user key pair (for E2EE)
        var keyPair = hybridCryptoService.generateUserKeyPair(request.getPassword());
        
        // Create user
        User user = User.builder()
            .username(request.getUsername())
            .email(request.getEmail())
            .passwordHash(passwordEncoder.encode(request.getPassword()))
            .publicKey(keyPair.publicKey())
            .encryptedPrivateKey(keyPair.encryptedPrivateKey())
            .privateKeySalt(keyPair.salt())
            .roles(Set.of(User.Role.ROLE_USER))
            .clearanceLevel(User.ClearanceLevel.STANDARD)
            .enabled(true)
            .accountNonLocked(true)
            .build();
        
        user = userRepository.save(user);
        
        // Generate tokens
        UserPrincipal principal = new UserPrincipal(user);
        String accessToken = jwtTokenService.generateToken(principal);
        String refreshToken = jwtTokenService.generateRefreshToken(principal);
        
        // Audit log
        auditService.logAuthEvent(
            AuditLog.EventType.USER_CREATED,
            user.getId(),
            user.getUsername(),
            ipAddress,
            userAgent,
            AuditLog.EventOutcome.SUCCESS,
            null
        );
        
        log.info("User registered: {}", user.getUsername());
        
        return buildAuthResponse(user, accessToken, refreshToken);
    }
    
    /**
     * Authenticate user and generate tokens.
     * Supports login with either username or email.
     */
    @Transactional
    public AuthDTO.AuthResponse login(AuthDTO.LoginRequest request, String ipAddress, String userAgent) {
        // Support login with either username or email
        String usernameOrEmail = request.getUsername();
        User user = userRepository.findByUsernameOrEmail(usernameOrEmail, usernameOrEmail)
            .orElse(null);
        
        try {
            // Check if account is locked
            if (user != null && !user.isAccountNonLocked()) {
                if (!user.isLockoutExpired()) {
                    auditService.logAuthEvent(
                        AuditLog.EventType.LOGIN_FAILURE,
                        user.getId(),
                        user.getUsername(),
                        ipAddress,
                        userAgent,
                        AuditLog.EventOutcome.BLOCKED,
                        "Account locked"
                    );
                    throw new LockedException("Account is locked. Try again later.");
                }
                // Lockout expired, unlock account
                user.setAccountNonLocked(true);
                user.setFailedLoginAttempts(0);
                userRepository.save(user);
            }
            
            // Attempt authentication - use the actual username from found user
            String actualUsername = user != null ? user.getUsername() : usernameOrEmail;
            Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(actualUsername, request.getPassword())
            );
            
            SecurityContextHolder.getContext().setAuthentication(authentication);
            
            // Successful login
            user = userRepository.findByUsername(actualUsername).orElseThrow();
            user.recordSuccessfulLogin();
            userRepository.save(user);
            
            UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
            String accessToken = jwtTokenService.generateToken(principal);
            String refreshToken = jwtTokenService.generateRefreshToken(principal);
            
            auditService.logAuthEvent(
                AuditLog.EventType.LOGIN_SUCCESS,
                user.getId(),
                user.getUsername(),
                ipAddress,
                userAgent,
                AuditLog.EventOutcome.SUCCESS,
                null
            );
            
            log.info("User logged in: {}", user.getUsername());
            
            return buildAuthResponse(user, accessToken, refreshToken);
            
        } catch (BadCredentialsException e) {
            // Record failed attempt
            if (user != null) {
                int maxAttempts = config.getSecurity().getRateLimit().getLoginAttempts();
                int lockoutMinutes = config.getSecurity().getRateLimit().getLockoutDurationMinutes();
                user.recordFailedLogin(maxAttempts, lockoutMinutes);
                userRepository.save(user);
                
                if (!user.isAccountNonLocked()) {
                    auditService.logAuthEvent(
                        AuditLog.EventType.ACCOUNT_LOCKED,
                        user.getId(),
                        user.getUsername(),
                        ipAddress,
                        userAgent,
                        AuditLog.EventOutcome.BLOCKED,
                        "Account locked due to failed attempts"
                    );
                }
            }
            
            auditService.logAuthEvent(
                AuditLog.EventType.LOGIN_FAILURE,
                user != null ? user.getId() : null,
                request.getUsername(),
                ipAddress,
                userAgent,
                AuditLog.EventOutcome.FAILURE,
                "Invalid credentials"
            );
            
            throw e;
        }
    }
    
    /**
     * Refresh access token using refresh token.
     */
    public AuthDTO.AuthResponse refreshToken(String refreshToken) {
        if (!jwtTokenService.isRefreshToken(refreshToken)) {
            throw new SecurityPolicyException("Invalid refresh token");
        }
        
        String username = jwtTokenService.extractUsername(refreshToken);
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new ResourceNotFoundException("User", username));
        
        UserPrincipal principal = new UserPrincipal(user);
        
        if (!jwtTokenService.isTokenValid(refreshToken, principal)) {
            throw new SecurityPolicyException("Refresh token expired or invalid");
        }
        
        String newAccessToken = jwtTokenService.generateToken(principal);
        String newRefreshToken = jwtTokenService.generateRefreshToken(principal);
        
        auditService.logAuthEvent(
            AuditLog.EventType.TOKEN_REFRESH,
            user.getId(),
            user.getUsername(),
            null, null,
            AuditLog.EventOutcome.SUCCESS,
            null
        );
        
        return buildAuthResponse(user, newAccessToken, newRefreshToken);
    }
    
    /**
     * Change user password.
     */
    @Transactional
    public void changePassword(String username, AuthDTO.ChangePasswordRequest request, 
                               String ipAddress, String userAgent) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new ResourceNotFoundException("User", username));
        
        // Verify current password
        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            auditService.logAuthEvent(
                AuditLog.EventType.PASSWORD_CHANGE,
                user.getId(),
                user.getUsername(),
                ipAddress,
                userAgent,
                AuditLog.EventOutcome.FAILURE,
                "Invalid current password"
            );
            throw new BadCredentialsException("Current password is incorrect");
        }
        
        validatePasswordStrength(request.getNewPassword());
        
        // Re-encrypt private key with new password
        var keyPair = hybridCryptoService.generateUserKeyPair(request.getNewPassword());
        
        // Update user
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        user.setEncryptedPrivateKey(keyPair.encryptedPrivateKey());
        user.setPrivateKeySalt(keyPair.salt());
        // Note: Public key stays the same
        
        userRepository.save(user);
        
        auditService.logAuthEvent(
            AuditLog.EventType.PASSWORD_CHANGE,
            user.getId(),
            user.getUsername(),
            ipAddress,
            userAgent,
            AuditLog.EventOutcome.SUCCESS,
            null
        );
        
        log.info("Password changed for user: {}", username);
    }
    
    /**
     * Get current authenticated user.
     */
    public User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserPrincipal principal) {
            return principal.getUser();
        }
        throw new SecurityPolicyException("No authenticated user");
    }
    
    /**
     * Build authentication response.
     */
    private AuthDTO.AuthResponse buildAuthResponse(User user, String accessToken, String refreshToken) {
        return AuthDTO.AuthResponse.builder()
            .accessToken(accessToken)
            .refreshToken(refreshToken)
            .tokenType("Bearer")
            .expiresIn(config.getJwt().getExpirationMs() / 1000)
            .user(AuthDTO.UserInfo.builder()
                .id(user.getId().toString())
                .username(user.getUsername())
                .email(user.getEmail())
                .roles(user.getRoles().stream().map(Enum::name).toArray(String[]::new))
                .clearanceLevel(user.getClearanceLevel().name())
                .build())
            .build();
    }
    
    /**
     * Validate password strength.
     */
    private void validatePasswordStrength(String password) {
        if (password.length() < 12) {
            throw new SecurityPolicyException("Password must be at least 12 characters");
        }
        
        boolean hasUpper = password.chars().anyMatch(Character::isUpperCase);
        boolean hasLower = password.chars().anyMatch(Character::isLowerCase);
        boolean hasDigit = password.chars().anyMatch(Character::isDigit);
        boolean hasSpecial = password.chars().anyMatch(c -> !Character.isLetterOrDigit(c));
        
        if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
            throw new SecurityPolicyException(
                "Password must contain uppercase, lowercase, digit, and special character");
        }
    }
}
