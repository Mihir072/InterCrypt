package com.intelcrypt.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration properties for IntelCrypt cryptographic settings.
 * 
 * SECURITY NOTE: These settings control the strength of encryption.
 * Modifications should be reviewed by a security professional.
 */
@Configuration
@ConfigurationProperties(prefix = "intelcrypt")
public class CryptoConfigProperties {
    
    private Jwt jwt = new Jwt();
    private Crypto crypto = new Crypto();
    private Messaging messaging = new Messaging();
    private Security security = new Security();
    private Audit audit = new Audit();
    
    public Jwt getJwt() { return jwt; }
    public void setJwt(Jwt jwt) { this.jwt = jwt; }
    public Crypto getCrypto() { return crypto; }
    public void setCrypto(Crypto crypto) { this.crypto = crypto; }
    public Messaging getMessaging() { return messaging; }
    public void setMessaging(Messaging messaging) { this.messaging = messaging; }
    public Security getSecurity() { return security; }
    public void setSecurity(Security security) { this.security = security; }
    public Audit getAudit() { return audit; }
    public void setAudit(Audit audit) { this.audit = audit; }
    
    public static class Jwt {
        /**
         * Secret key for JWT signing - MUST be at least 256 bits for HS256
         */
        private String secret;
        
        /**
         * Access token expiration in milliseconds (default: 15 minutes)
         */
        private long expirationMs = 900000;
        
        /**
         * Refresh token expiration in milliseconds (default: 24 hours)
         */
        private long refreshExpirationMs = 86400000;
        
        public String getSecret() { return secret; }
        public void setSecret(String secret) { this.secret = secret; }
        public long getExpirationMs() { return expirationMs; }
        public void setExpirationMs(long expirationMs) { this.expirationMs = expirationMs; }
        public long getRefreshExpirationMs() { return refreshExpirationMs; }
        public void setRefreshExpirationMs(long refreshExpirationMs) { this.refreshExpirationMs = refreshExpirationMs; }
    }
    
    public static class Crypto {
        private Aes aes = new Aes();
        private Rsa rsa = new Rsa();
        private Ecc ecc = new Ecc();
        private KeyRotation keyRotation = new KeyRotation();
        
        public Aes getAes() { return aes; }
        public void setAes(Aes aes) { this.aes = aes; }
        public Rsa getRsa() { return rsa; }
        public void setRsa(Rsa rsa) { this.rsa = rsa; }
        public Ecc getEcc() { return ecc; }
        public void setEcc(Ecc ecc) { this.ecc = ecc; }
        public KeyRotation getKeyRotation() { return keyRotation; }
        public void setKeyRotation(KeyRotation keyRotation) { this.keyRotation = keyRotation; }
        
        public static class Aes {
            /**
             * Default AES key size: 128, 192, 256, or custom extended sizes
             */
            private int defaultKeySize = 256;
            
            /**
             * Default cipher mode: GCM (recommended), CBC, CTR, XTS
             */
            private String defaultMode = "GCM";
            
            /**
             * GCM authentication tag length in bits
             */
            private int gcmTagLength = 128;
            
            /**
             * Number of encryption iterations for multi-round encryption
             */
            private int iterationRounds = 1;
            
            public int getDefaultKeySize() { return defaultKeySize; }
            public void setDefaultKeySize(int defaultKeySize) { this.defaultKeySize = defaultKeySize; }
            public String getDefaultMode() { return defaultMode; }
            public void setDefaultMode(String defaultMode) { this.defaultMode = defaultMode; }
            public int getGcmTagLength() { return gcmTagLength; }
            public void setGcmTagLength(int gcmTagLength) { this.gcmTagLength = gcmTagLength; }
            public int getIterationRounds() { return iterationRounds; }
            public void setIterationRounds(int iterationRounds) { this.iterationRounds = iterationRounds; }
        }
        
        public static class Rsa {
            /**
             * RSA key size for key exchange (minimum 2048, recommended 4096)
             */
            private int keySize = 4096;
            
            public int getKeySize() { return keySize; }
            public void setKeySize(int keySize) { this.keySize = keySize; }
        }
        
        public static class Ecc {
            /**
             * ECC curve for key exchange (secp256r1, secp384r1, secp521r1)
             */
            private String curve = "secp384r1";
            
            public String getCurve() { return curve; }
            public void setCurve(String curve) { this.curve = curve; }
        }
        
        public static class KeyRotation {
            private boolean enabled = true;
            private int intervalDays = 30;
            
            public boolean isEnabled() { return enabled; }
            public void setEnabled(boolean enabled) { this.enabled = enabled; }
            public int getIntervalDays() { return intervalDays; }
            public void setIntervalDays(int intervalDays) { this.intervalDays = intervalDays; }
        }
    }
    
    public static class Messaging {
        private int defaultExpirationHours = 24;
        private int maxAttachmentSizeMb = 25;
        private boolean enableSteganography = false;
        
        public int getDefaultExpirationHours() { return defaultExpirationHours; }
        public void setDefaultExpirationHours(int defaultExpirationHours) { this.defaultExpirationHours = defaultExpirationHours; }
        public int getMaxAttachmentSizeMb() { return maxAttachmentSizeMb; }
        public void setMaxAttachmentSizeMb(int maxAttachmentSizeMb) { this.maxAttachmentSizeMb = maxAttachmentSizeMb; }
        public boolean isEnableSteganography() { return enableSteganography; }
        public void setEnableSteganography(boolean enableSteganography) { this.enableSteganography = enableSteganography; }
    }
    
    public static class Security {
        private RateLimit rateLimit = new RateLimit();
        private Honeypot honeypot = new Honeypot();
        private Intrusion intrusion = new Intrusion();
        
        public RateLimit getRateLimit() { return rateLimit; }
        public void setRateLimit(RateLimit rateLimit) { this.rateLimit = rateLimit; }
        public Honeypot getHoneypot() { return honeypot; }
        public void setHoneypot(Honeypot honeypot) { this.honeypot = honeypot; }
        public Intrusion getIntrusion() { return intrusion; }
        public void setIntrusion(Intrusion intrusion) { this.intrusion = intrusion; }
        
        public static class RateLimit {
            private int requestsPerMinute = 60;
            private int loginAttempts = 5;
            private int lockoutDurationMinutes = 15;
            
            public int getRequestsPerMinute() { return requestsPerMinute; }
            public void setRequestsPerMinute(int requestsPerMinute) { this.requestsPerMinute = requestsPerMinute; }
            public int getLoginAttempts() { return loginAttempts; }
            public void setLoginAttempts(int loginAttempts) { this.loginAttempts = loginAttempts; }
            public int getLockoutDurationMinutes() { return lockoutDurationMinutes; }
            public void setLockoutDurationMinutes(int lockoutDurationMinutes) { this.lockoutDurationMinutes = lockoutDurationMinutes; }
        }
        
        public static class Honeypot {
            private boolean enabled = true;
            private String fakeEndpoints = "/api/admin/config,/api/debug/keys,/api/internal/secrets";
            
            public boolean isEnabled() { return enabled; }
            public void setEnabled(boolean enabled) { this.enabled = enabled; }
            public String getFakeEndpoints() { return fakeEndpoints; }
            public void setFakeEndpoints(String fakeEndpoints) { this.fakeEndpoints = fakeEndpoints; }
        }
        
        public static class Intrusion {
            private boolean enabled = true;
            private int alertThreshold = 3;
            private boolean spamInjection = true;
            
            public boolean isEnabled() { return enabled; }
            public void setEnabled(boolean enabled) { this.enabled = enabled; }
            public int getAlertThreshold() { return alertThreshold; }
            public void setAlertThreshold(int alertThreshold) { this.alertThreshold = alertThreshold; }
            public boolean isSpamInjection() { return spamInjection; }
            public void setSpamInjection(boolean spamInjection) { this.spamInjection = spamInjection; }
        }
    }
    
    public static class Audit {
        private boolean enabled = true;
        private boolean logEncryptionEvents = true;
        private boolean logKeyUsage = true;
        private boolean tamperProtection = true;
        
        public boolean isEnabled() { return enabled; }
        public void setEnabled(boolean enabled) { this.enabled = enabled; }
        public boolean isLogEncryptionEvents() { return logEncryptionEvents; }
        public void setLogEncryptionEvents(boolean logEncryptionEvents) { this.logEncryptionEvents = logEncryptionEvents; }
        public boolean isLogKeyUsage() { return logKeyUsage; }
        public void setLogKeyUsage(boolean logKeyUsage) { this.logKeyUsage = logKeyUsage; }
        public boolean isTamperProtection() { return tamperProtection; }
        public void setTamperProtection(boolean tamperProtection) { this.tamperProtection = tamperProtection; }
    }
}
