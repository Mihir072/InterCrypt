package com.intelcrypt.crypto;

import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.junit.jupiter.params.provider.ValueSource;

import java.nio.charset.StandardCharsets;
import java.security.Security;
import java.util.Base64;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for AES encryption/decryption operations.
 * 
 * Tests all cipher modes, key sizes, and multi-round encryption.
 */
class AESCryptoServiceTest {
    
    private final AESCryptoService aesService = new AESCryptoService();
    
    @BeforeAll
    static void setup() {
        if (Security.getProvider(BouncyCastleProvider.PROVIDER_NAME) == null) {
            Security.addProvider(new BouncyCastleProvider());
        }
    }
    
    @Nested
    @DisplayName("Key Generation Tests")
    class KeyGenerationTests {
        
        @ParameterizedTest
        @ValueSource(ints = {128, 192, 256})
        @DisplayName("Generate AES keys of different sizes")
        void shouldGenerateKeysOfDifferentSizes(int keySize) {
            byte[] key = aesService.generateKey(keySize);
            
            assertNotNull(key);
            assertEquals(keySize / 8, key.length);
        }
        
        @Test
        @DisplayName("Generated keys should be random")
        void shouldGenerateRandomKeys() {
            byte[] key1 = aesService.generateKey(256);
            byte[] key2 = aesService.generateKey(256);
            
            assertNotEquals(
                Base64.getEncoder().encodeToString(key1),
                Base64.getEncoder().encodeToString(key2)
            );
        }
        
        @Test
        @DisplayName("Reject invalid key sizes")
        void shouldRejectInvalidKeySizes() {
            assertThrows(Exception.class, () -> aesService.generateKey(64));
            assertThrows(Exception.class, () -> aesService.generateKey(512));
        }
    }
    
    @Nested
    @DisplayName("Basic Encryption/Decryption Tests")
    class BasicEncryptionTests {
        
        @Test
        @DisplayName("Encrypt and decrypt simple text with AES-GCM")
        void shouldEncryptAndDecryptWithGCM() {
            String plaintext = "Hello, IntelCrypt!";
            byte[] key = aesService.generateKey(256);
            
            EncryptionResult encrypted = aesService.encrypt(
                plaintext.getBytes(StandardCharsets.UTF_8),
                key,
                CipherMode.GCM
            );
            
            assertNotNull(encrypted);
            assertNotNull(encrypted.getCiphertext());
            assertNotNull(encrypted.getIv());
            assertNotEquals(plaintext, new String(encrypted.getCiphertext()));
            
            byte[] decrypted = aesService.decrypt(encrypted, key, CipherMode.GCM);
            
            assertEquals(plaintext, new String(decrypted, StandardCharsets.UTF_8));
        }
        
        @ParameterizedTest
        @EnumSource(CipherMode.class)
        @DisplayName("Encrypt and decrypt with all cipher modes")
        void shouldEncryptAndDecryptWithAllModes(CipherMode mode) {
            String plaintext = "Test message for " + mode.name();
            byte[] key = aesService.generateKey(256);
            
            EncryptionResult encrypted = aesService.encrypt(
                plaintext.getBytes(StandardCharsets.UTF_8),
                key,
                mode
            );
            
            byte[] decrypted = aesService.decrypt(encrypted, key, mode);
            
            assertEquals(plaintext, new String(decrypted, StandardCharsets.UTF_8));
        }
        
        @ParameterizedTest
        @ValueSource(ints = {128, 192, 256})
        @DisplayName("Encrypt and decrypt with different key sizes")
        void shouldEncryptAndDecryptWithDifferentKeySizes(int keySize) {
            String plaintext = "Testing key size: " + keySize;
            byte[] key = aesService.generateKey(keySize);
            
            EncryptionResult encrypted = aesService.encrypt(
                plaintext.getBytes(StandardCharsets.UTF_8),
                key,
                CipherMode.GCM
            );
            
            byte[] decrypted = aesService.decrypt(encrypted, key, CipherMode.GCM);
            
            assertEquals(plaintext, new String(decrypted, StandardCharsets.UTF_8));
        }
    }
    
    @Nested
    @DisplayName("Multi-Round Encryption Tests")
    class MultiRoundEncryptionTests {
        
        @Test
        @DisplayName("Multi-round encryption increases security")
        void shouldApplyMultiRoundEncryption() {
            String plaintext = "Secret message with multiple encryption layers";
            byte[] key = aesService.generateKey(256);
            int rounds = 3;
            
            EncryptionResult encrypted = aesService.encryptMultiRound(
                plaintext.getBytes(StandardCharsets.UTF_8),
                key,
                CipherMode.GCM,
                rounds
            );
            
            assertNotNull(encrypted);
            assertEquals(rounds, encrypted.getEncryptionRounds());
            
            byte[] decrypted = aesService.decryptMultiRound(
                encrypted, key, CipherMode.GCM, rounds);
            
            assertEquals(plaintext, new String(decrypted, StandardCharsets.UTF_8));
        }
        
        @Test
        @DisplayName("Wrong round count should fail decryption")
        void shouldFailWithWrongRoundCount() {
            String plaintext = "Multi-round test";
            byte[] key = aesService.generateKey(256);
            
            EncryptionResult encrypted = aesService.encryptMultiRound(
                plaintext.getBytes(StandardCharsets.UTF_8),
                key,
                CipherMode.GCM,
                3
            );
            
            // Try to decrypt with wrong round count
            assertThrows(Exception.class, () -> 
                aesService.decryptMultiRound(encrypted, key, CipherMode.GCM, 2)
            );
        }
    }
    
    @Nested
    @DisplayName("Edge Cases and Security Tests")
    class EdgeCaseTests {
        
        @Test
        @DisplayName("Encrypt empty data")
        void shouldHandleEmptyData() {
            byte[] key = aesService.generateKey(256);
            byte[] emptyData = new byte[0];
            
            EncryptionResult encrypted = aesService.encrypt(emptyData, key, CipherMode.GCM);
            byte[] decrypted = aesService.decrypt(encrypted, key, CipherMode.GCM);
            
            assertArrayEquals(emptyData, decrypted);
        }
        
        @Test
        @DisplayName("Encrypt large data")
        void shouldHandleLargeData() {
            byte[] key = aesService.generateKey(256);
            byte[] largeData = new byte[10 * 1024 * 1024]; // 10 MB
            new java.util.Random().nextBytes(largeData);
            
            EncryptionResult encrypted = aesService.encrypt(largeData, key, CipherMode.GCM);
            byte[] decrypted = aesService.decrypt(encrypted, key, CipherMode.GCM);
            
            assertArrayEquals(largeData, decrypted);
        }
        
        @Test
        @DisplayName("Decrypt with wrong key should fail")
        void shouldFailWithWrongKey() {
            String plaintext = "Sensitive data";
            byte[] correctKey = aesService.generateKey(256);
            byte[] wrongKey = aesService.generateKey(256);
            
            EncryptionResult encrypted = aesService.encrypt(
                plaintext.getBytes(StandardCharsets.UTF_8),
                correctKey,
                CipherMode.GCM
            );
            
            assertThrows(Exception.class, () ->
                aesService.decrypt(encrypted, wrongKey, CipherMode.GCM)
            );
        }
        
        @Test
        @DisplayName("Tampered ciphertext should fail GCM authentication")
        void shouldDetectTampering() {
            String plaintext = "Authentic message";
            byte[] key = aesService.generateKey(256);
            
            EncryptionResult encrypted = aesService.encrypt(
                plaintext.getBytes(StandardCharsets.UTF_8),
                key,
                CipherMode.GCM
            );
            
            // Tamper with ciphertext
            byte[] tamperedCiphertext = encrypted.getCiphertext().clone();
            tamperedCiphertext[0] ^= 0xFF;
            
            EncryptionResult tampered = EncryptionResult.builder()
                .ciphertext(tamperedCiphertext)
                .iv(encrypted.getIv())
                .build();
            
            assertThrows(Exception.class, () ->
                aesService.decrypt(tampered, key, CipherMode.GCM)
            );
        }
        
        @Test
        @DisplayName("Unicode content should be preserved")
        void shouldHandleUnicode() {
            String plaintext = "Hello 世界! 🔐🛡️ Привет мир! مرحبا";
            byte[] key = aesService.generateKey(256);
            
            EncryptionResult encrypted = aesService.encrypt(
                plaintext.getBytes(StandardCharsets.UTF_8),
                key,
                CipherMode.GCM
            );
            
            byte[] decrypted = aesService.decrypt(encrypted, key, CipherMode.GCM);
            
            assertEquals(plaintext, new String(decrypted, StandardCharsets.UTF_8));
        }
    }
    
    @Nested
    @DisplayName("Password-Based Key Derivation Tests")
    class KeyDerivationTests {
        
        @Test
        @DisplayName("Derive key from password using PBKDF2")
        void shouldDeriveKeyFromPassword() {
            String password = "SecureP@ssw0rd!";
            byte[] salt = aesService.generateSalt();
            
            byte[] key1 = aesService.deriveKey(password, salt, 256);
            byte[] key2 = aesService.deriveKey(password, salt, 256);
            
            assertNotNull(key1);
            assertEquals(32, key1.length);
            assertArrayEquals(key1, key2); // Same password + salt = same key
        }
        
        @Test
        @DisplayName("Different salts produce different keys")
        void shouldProduceDifferentKeysWithDifferentSalts() {
            String password = "SamePassword";
            
            byte[] key1 = aesService.deriveKey(password, aesService.generateSalt(), 256);
            byte[] key2 = aesService.deriveKey(password, aesService.generateSalt(), 256);
            
            assertFalse(java.util.Arrays.equals(key1, key2));
        }
    }
}
