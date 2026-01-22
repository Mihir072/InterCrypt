package com.intelcrypt.crypto;

import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.Security;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for hybrid encryption (AES + RSA/ECC).
 * 
 * Tests end-to-end encryption scenarios.
 */
class HybridCryptoServiceTest {
    
    private final HybridCryptoService hybridService = new HybridCryptoService();
    private final AsymmetricCryptoService asymmetricService = new AsymmetricCryptoService();
    
    @BeforeAll
    static void setup() {
        if (Security.getProvider(BouncyCastleProvider.PROVIDER_NAME) == null) {
            Security.addProvider(new BouncyCastleProvider());
        }
    }
    
    @Nested
    @DisplayName("Hybrid Encryption Tests (AES + RSA)")
    class HybridRSATests {
        
        @Test
        @DisplayName("Encrypt and decrypt with hybrid AES-RSA")
        void shouldEncryptAndDecryptWithHybridRSA() {
            // Recipient generates RSA key pair
            KeyPair recipientKeys = asymmetricService.generateRSAKeyPair(2048);
            
            String plaintext = "This is a secure message encrypted with hybrid encryption";
            
            // Sender encrypts with recipient's public key
            HybridCryptoService.HybridEncryptionResult encrypted = 
                hybridService.encryptHybrid(
                    plaintext.getBytes(StandardCharsets.UTF_8),
                    recipientKeys.getPublic(),
                    CipherMode.GCM,
                    256
                );
            
            assertNotNull(encrypted);
            assertNotNull(encrypted.getEncryptedData());
            assertNotNull(encrypted.getEncryptedKey());
            assertNotNull(encrypted.getIv());
            
            // Recipient decrypts with their private key
            byte[] decrypted = hybridService.decryptHybrid(
                encrypted,
                recipientKeys.getPrivate()
            );
            
            assertEquals(plaintext, new String(decrypted, StandardCharsets.UTF_8));
        }
        
        @Test
        @DisplayName("Hybrid encryption with different AES key sizes")
        void shouldWorkWithDifferentAESKeySizes() {
            KeyPair recipientKeys = asymmetricService.generateRSAKeyPair(2048);
            String plaintext = "Testing different key sizes";
            
            for (int keySize : new int[]{128, 192, 256}) {
                HybridCryptoService.HybridEncryptionResult encrypted = 
                    hybridService.encryptHybrid(
                        plaintext.getBytes(StandardCharsets.UTF_8),
                        recipientKeys.getPublic(),
                        CipherMode.GCM,
                        keySize
                    );
                
                byte[] decrypted = hybridService.decryptHybrid(
                    encrypted,
                    recipientKeys.getPrivate()
                );
                
                assertEquals(plaintext, new String(decrypted, StandardCharsets.UTF_8));
            }
        }
        
        @Test
        @DisplayName("Wrong private key fails hybrid decryption")
        void shouldFailWithWrongPrivateKey() {
            KeyPair recipientKeys = asymmetricService.generateRSAKeyPair(2048);
            KeyPair attackerKeys = asymmetricService.generateRSAKeyPair(2048);
            
            String plaintext = "Confidential message";
            
            HybridCryptoService.HybridEncryptionResult encrypted = 
                hybridService.encryptHybrid(
                    plaintext.getBytes(StandardCharsets.UTF_8),
                    recipientKeys.getPublic(),
                    CipherMode.GCM,
                    256
                );
            
            // Attacker tries to decrypt with their private key
            assertThrows(Exception.class, () ->
                hybridService.decryptHybrid(encrypted, attackerKeys.getPrivate())
            );
        }
    }
    
    @Nested
    @DisplayName("End-to-End Encryption Simulation")
    class E2ESimulationTests {
        
        @Test
        @DisplayName("Simulate E2EE message exchange between Alice and Bob")
        void shouldSimulateE2EMessageExchange() {
            // Both users generate their key pairs
            KeyPair aliceKeys = asymmetricService.generateRSAKeyPair(2048);
            KeyPair bobKeys = asymmetricService.generateRSAKeyPair(2048);
            
            // Alice sends a message to Bob
            String aliceMessage = "Hello Bob! This is Alice.";
            
            HybridCryptoService.HybridEncryptionResult encryptedForBob = 
                hybridService.encryptHybrid(
                    aliceMessage.getBytes(StandardCharsets.UTF_8),
                    bobKeys.getPublic(),  // Encrypt with Bob's public key
                    CipherMode.GCM,
                    256
                );
            
            // Bob decrypts with his private key
            byte[] decryptedByBob = hybridService.decryptHybrid(
                encryptedForBob,
                bobKeys.getPrivate()
            );
            
            assertEquals(aliceMessage, new String(decryptedByBob, StandardCharsets.UTF_8));
            
            // Bob replies to Alice
            String bobReply = "Hi Alice! Got your message.";
            
            HybridCryptoService.HybridEncryptionResult encryptedForAlice = 
                hybridService.encryptHybrid(
                    bobReply.getBytes(StandardCharsets.UTF_8),
                    aliceKeys.getPublic(),  // Encrypt with Alice's public key
                    CipherMode.GCM,
                    256
                );
            
            // Alice decrypts with her private key
            byte[] decryptedByAlice = hybridService.decryptHybrid(
                encryptedForAlice,
                aliceKeys.getPrivate()
            );
            
            assertEquals(bobReply, new String(decryptedByAlice, StandardCharsets.UTF_8));
        }
        
        @Test
        @DisplayName("Eve cannot decrypt intercepted message")
        void shouldPreventEavesdropping() {
            KeyPair aliceKeys = asymmetricService.generateRSAKeyPair(2048);
            KeyPair bobKeys = asymmetricService.generateRSAKeyPair(2048);
            KeyPair eveKeys = asymmetricService.generateRSAKeyPair(2048);
            
            String secretMessage = "TOP SECRET: Nuclear launch codes...";
            
            // Alice encrypts for Bob
            HybridCryptoService.HybridEncryptionResult encrypted = 
                hybridService.encryptHybrid(
                    secretMessage.getBytes(StandardCharsets.UTF_8),
                    bobKeys.getPublic(),
                    CipherMode.GCM,
                    256
                );
            
            // Eve intercepts and tries to decrypt
            assertThrows(Exception.class, () ->
                hybridService.decryptHybrid(encrypted, eveKeys.getPrivate())
            );
            
            // Eve tries with Alice's private key (sender's key)
            assertThrows(Exception.class, () ->
                hybridService.decryptHybrid(encrypted, aliceKeys.getPrivate())
            );
            
            // Only Bob can decrypt
            byte[] decrypted = hybridService.decryptHybrid(encrypted, bobKeys.getPrivate());
            assertEquals(secretMessage, new String(decrypted, StandardCharsets.UTF_8));
        }
    }
    
    @Nested
    @DisplayName("Multi-Round Hybrid Encryption Tests")
    class MultiRoundHybridTests {
        
        @Test
        @DisplayName("Multi-round hybrid encryption for maximum security")
        void shouldApplyMultiRoundHybridEncryption() {
            KeyPair recipientKeys = asymmetricService.generateRSAKeyPair(2048);
            String plaintext = "Ultra-secure message with multi-round encryption";
            int rounds = 3;
            
            HybridCryptoService.HybridEncryptionResult encrypted = 
                hybridService.encryptHybridMultiRound(
                    plaintext.getBytes(StandardCharsets.UTF_8),
                    recipientKeys.getPublic(),
                    CipherMode.GCM,
                    256,
                    rounds
                );
            
            assertNotNull(encrypted);
            assertEquals(rounds, encrypted.getEncryptionRounds());
            
            byte[] decrypted = hybridService.decryptHybridMultiRound(
                encrypted,
                recipientKeys.getPrivate(),
                rounds
            );
            
            assertEquals(plaintext, new String(decrypted, StandardCharsets.UTF_8));
        }
    }
    
    @Nested
    @DisplayName("Performance Tests")
    class PerformanceTests {
        
        @Test
        @DisplayName("Hybrid encryption handles large messages efficiently")
        void shouldHandleLargeMessages() {
            KeyPair recipientKeys = asymmetricService.generateRSAKeyPair(2048);
            
            // 1 MB message
            byte[] largeMessage = new byte[1024 * 1024];
            new java.security.SecureRandom().nextBytes(largeMessage);
            
            long startTime = System.currentTimeMillis();
            
            HybridCryptoService.HybridEncryptionResult encrypted = 
                hybridService.encryptHybrid(
                    largeMessage,
                    recipientKeys.getPublic(),
                    CipherMode.GCM,
                    256
                );
            
            byte[] decrypted = hybridService.decryptHybrid(
                encrypted,
                recipientKeys.getPrivate()
            );
            
            long duration = System.currentTimeMillis() - startTime;
            
            assertArrayEquals(largeMessage, decrypted);
            
            // Should complete within reasonable time (< 5 seconds for 1MB)
            assertTrue(duration < 5000, 
                "Encryption/decryption took too long: " + duration + "ms");
        }
    }
}
