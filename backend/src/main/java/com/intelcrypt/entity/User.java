package com.intelcrypt.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * User entity representing a platform user.
 * 
 * SECURITY NOTES:
 * - Passwords are never stored in plaintext (Argon2id hashed)
 * - Public key stored for end-to-end encryption
 * - Account lockout after failed login attempts
 */
@Entity
@Table(name = "users", indexes = {
    @Index(name = "idx_user_username", columnList = "username", unique = true),
    @Index(name = "idx_user_email", columnList = "email", unique = true)
})
public class User {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    
    @Column(nullable = false, unique = true, length = 50)
    private String username;
    
    @Column(nullable = false, unique = true, length = 100)
    private String email;
    
    /**
     * Argon2id hashed password - NEVER store plaintext
     */
    @Column(nullable = false, length = 255)
    private String passwordHash;
    
    /**
     * User's public key for E2EE (PEM encoded)
     * Other users use this to encrypt messages for this user
     */
    @Column(columnDefinition = "TEXT")
    private String publicKey;
    
    /**
     * Encrypted private key (encrypted with user's password-derived key)
     * Only the user can decrypt this with their password
     */
    @Column(columnDefinition = "TEXT")
    private String encryptedPrivateKey;
    
    /**
     * Salt used for private key encryption
     */
    @Column(length = 64)
    private String privateKeySalt;
    
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "user_roles", joinColumns = @JoinColumn(name = "user_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "role")
    private Set<Role> roles = new HashSet<>();
    
    @Column(nullable = false)
    private boolean enabled = true;
    
    @Column(nullable = false)
    private boolean accountNonLocked = true;
    
    @Column(nullable = false)
    private int failedLoginAttempts = 0;
    
    @Column
    private Instant lockoutEndTime;
    
    @CreationTimestamp
    @Column(updatable = false)
    private Instant createdAt;
    
    @UpdateTimestamp
    private Instant updatedAt;
    
    @Column
    private Instant lastLoginAt;
    
    /**
     * Security clearance level for message access
     */
    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private ClearanceLevel clearanceLevel = ClearanceLevel.STANDARD;
    
    public enum Role {
        ROLE_USER,
        ROLE_CLASSIFIED,
        ROLE_ADMIN
    }
    
    public enum ClearanceLevel {
        STANDARD,
        CONFIDENTIAL,
        SECRET,
        TOP_SECRET
    }

    public User() {}

    public User(UUID id, String username, String email, String passwordHash, String publicKey,
                String encryptedPrivateKey, String privateKeySalt, Set<Role> roles, boolean enabled,
                boolean accountNonLocked, int failedLoginAttempts, Instant lockoutEndTime,
                Instant createdAt, Instant updatedAt, Instant lastLoginAt, ClearanceLevel clearanceLevel) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.passwordHash = passwordHash;
        this.publicKey = publicKey;
        this.encryptedPrivateKey = encryptedPrivateKey;
        this.privateKeySalt = privateKeySalt;
        this.roles = roles;
        this.enabled = enabled;
        this.accountNonLocked = accountNonLocked;
        this.failedLoginAttempts = failedLoginAttempts;
        this.lockoutEndTime = lockoutEndTime;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.lastLoginAt = lastLoginAt;
        this.clearanceLevel = clearanceLevel;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public String getPublicKey() {
        return publicKey;
    }

    public void setPublicKey(String publicKey) {
        this.publicKey = publicKey;
    }

    public String getEncryptedPrivateKey() {
        return encryptedPrivateKey;
    }

    public void setEncryptedPrivateKey(String encryptedPrivateKey) {
        this.encryptedPrivateKey = encryptedPrivateKey;
    }

    public String getPrivateKeySalt() {
        return privateKeySalt;
    }

    public void setPrivateKeySalt(String privateKeySalt) {
        this.privateKeySalt = privateKeySalt;
    }

    public Set<Role> getRoles() {
        return roles;
    }

    public void setRoles(Set<Role> roles) {
        this.roles = roles;
    }

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public boolean isAccountNonLocked() {
        return accountNonLocked;
    }

    public void setAccountNonLocked(boolean accountNonLocked) {
        this.accountNonLocked = accountNonLocked;
    }

    public int getFailedLoginAttempts() {
        return failedLoginAttempts;
    }

    public void setFailedLoginAttempts(int failedLoginAttempts) {
        this.failedLoginAttempts = failedLoginAttempts;
    }

    public Instant getLockoutEndTime() {
        return lockoutEndTime;
    }

    public void setLockoutEndTime(Instant lockoutEndTime) {
        this.lockoutEndTime = lockoutEndTime;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }

    public Instant getLastLoginAt() {
        return lastLoginAt;
    }

    public void setLastLoginAt(Instant lastLoginAt) {
        this.lastLoginAt = lastLoginAt;
    }

    public ClearanceLevel getClearanceLevel() {
        return clearanceLevel;
    }

    public void setClearanceLevel(ClearanceLevel clearanceLevel) {
        this.clearanceLevel = clearanceLevel;
    }
    
    /**
     * Increment failed login attempts and lock account if threshold exceeded
     */
    public void recordFailedLogin(int maxAttempts, int lockoutMinutes) {
        this.failedLoginAttempts++;
        if (this.failedLoginAttempts >= maxAttempts) {
            this.accountNonLocked = false;
            this.lockoutEndTime = Instant.now().plusSeconds(lockoutMinutes * 60L);
        }
    }
    
    /**
     * Reset login attempts on successful authentication
     */
    public void recordSuccessfulLogin() {
        this.failedLoginAttempts = 0;
        this.accountNonLocked = true;
        this.lockoutEndTime = null;
        this.lastLoginAt = Instant.now();
    }
    
    /**
     * Check if lockout has expired
     */
    public boolean isLockoutExpired() {
        if (this.lockoutEndTime == null) return true;
        return Instant.now().isAfter(this.lockoutEndTime);
    }

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", username='" + username + '\'' +
                ", email='" + email + '\'' +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        User user = (User) o;
        return Objects.equals(id, user.id) && Objects.equals(username, user.username) &&
                Objects.equals(email, user.email);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, username, email);
    }

    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private UUID id;
        private String username;
        private String email;
        private String passwordHash;
        private String publicKey;
        private String encryptedPrivateKey;
        private String privateKeySalt;
        private Set<Role> roles = new HashSet<>();
        private boolean enabled = true;
        private boolean accountNonLocked = true;
        private int failedLoginAttempts = 0;
        private Instant lockoutEndTime;
        private Instant createdAt;
        private Instant updatedAt;
        private Instant lastLoginAt;
        private ClearanceLevel clearanceLevel = ClearanceLevel.STANDARD;

        public Builder id(UUID id) {
            this.id = id;
            return this;
        }

        public Builder username(String username) {
            this.username = username;
            return this;
        }

        public Builder email(String email) {
            this.email = email;
            return this;
        }

        public Builder passwordHash(String passwordHash) {
            this.passwordHash = passwordHash;
            return this;
        }

        public Builder publicKey(String publicKey) {
            this.publicKey = publicKey;
            return this;
        }

        public Builder encryptedPrivateKey(String encryptedPrivateKey) {
            this.encryptedPrivateKey = encryptedPrivateKey;
            return this;
        }

        public Builder privateKeySalt(String privateKeySalt) {
            this.privateKeySalt = privateKeySalt;
            return this;
        }

        public Builder roles(Set<Role> roles) {
            this.roles = roles;
            return this;
        }

        public Builder enabled(boolean enabled) {
            this.enabled = enabled;
            return this;
        }

        public Builder accountNonLocked(boolean accountNonLocked) {
            this.accountNonLocked = accountNonLocked;
            return this;
        }

        public Builder failedLoginAttempts(int failedLoginAttempts) {
            this.failedLoginAttempts = failedLoginAttempts;
            return this;
        }

        public Builder lockoutEndTime(Instant lockoutEndTime) {
            this.lockoutEndTime = lockoutEndTime;
            return this;
        }

        public Builder createdAt(Instant createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public Builder updatedAt(Instant updatedAt) {
            this.updatedAt = updatedAt;
            return this;
        }

        public Builder lastLoginAt(Instant lastLoginAt) {
            this.lastLoginAt = lastLoginAt;
            return this;
        }

        public Builder clearanceLevel(ClearanceLevel clearanceLevel) {
            this.clearanceLevel = clearanceLevel;
            return this;
        }

        public User build() {
            return new User(id, username, email, passwordHash, publicKey, encryptedPrivateKey,
                    privateKeySalt, roles, enabled, accountNonLocked, failedLoginAttempts,
                    lockoutEndTime, createdAt, updatedAt, lastLoginAt, clearanceLevel);
        }
    }
}
