package com.intelcrypt;

import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.security.Security;

/**
 * IntelCrypt - Extended AES-Based Secure Messaging & Data Vault Platform
 * 
 * This application provides military-grade encryption for secure messaging
 * with multi-layer security, active cyber-defense mechanisms, and 
 * end-to-end encryption between parties.
 * 
 * Security Features:
 * - Extended AES encryption (128/192/256/custom key sizes)
 * - Multiple cipher modes (GCM, CBC, CTR, XTS)
 * - Hybrid encryption (AES + RSA/ECC)
 * - JWT-based authentication with RBAC
 * - Honeypot endpoints and intrusion detection
 * - Tamper-resistant audit logging
 * 
 * @author IntelCrypt Security Team
 * @version 1.0.0
 */
@SpringBootApplication
@EnableScheduling
public class IntelCryptApplication {

    public static void main(String[] args) {
        // Register Bouncy Castle as a security provider for extended cryptographic operations
        Security.addProvider(new BouncyCastleProvider());
        
        // Disable insecure algorithms
        Security.setProperty("jdk.tls.disabledAlgorithms", 
            "SSLv3, RC4, DES, MD5withRSA, DH keySize < 2048, EC keySize < 224, 3DES_EDE_CBC, anon, NULL");
        
        SpringApplication.run(IntelCryptApplication.class, args);
    }
}
