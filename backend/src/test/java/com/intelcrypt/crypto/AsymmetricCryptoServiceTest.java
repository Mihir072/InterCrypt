package com.intelcrypt.crypto;

import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.Security;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for asymmetric (RSA/ECC) encryption operations.
 */
class AsymmetricCryptoServiceTest {
    
    private final AsymmetricCryptoService asymmetricService = new AsymmetricCryptoService();
    
    @BeforeAll
    static void setup() {
        if (Security.getProvider(BouncyCastleProvider.PROVIDER_NAME) == null) {
            Security.addProvider(new BouncyCastleProvider());
        }
    }
    
    @Nested
    @DisplayName("RSA Key Generation Tests")
    class RSAKeyGenerationTests {
        
        @ParameterizedTest
        @CsvSource({"2048", "3072", "4096"})
        @DisplayName("Generate RSA key pairs of different sizes")
        void shouldGenerateRSAKeyPairs(int keySize) {
            KeyPair keyPair = asymmetricService.generateRSAKeyPair(keySize);
            
            assertNotNull(keyPair);
            assertNotNull(keyPair.getPublic());
            assertNotNull(keyPair.getPrivate());
            assertEquals("RSA", keyPair.getPublic().getAlgorithm());
        }
        
        @Test
        @DisplayName("Generated RSA keys should be unique")
        void shouldGenerateUniqueRSAKeys() {
            KeyPair keyPair1 = asymmetricService.generateRSAKeyPair(2048);
            KeyPair keyPair2 = asymmetricService.generateRSAKeyPair(2048);
            
            assertFalse(java.util.Arrays.equals(
                keyPair1.getPublic().getEncoded(),
                keyPair2.getPublic().getEncoded()
            ));
        }
    }
    
    @Nested
    @DisplayName("ECC Key Generation Tests")
    class ECCKeyGenerationTests {
        
        @ParameterizedTest
        @CsvSource({"256", "384", "521"})
        @DisplayName("Generate ECC key pairs of different sizes")
        void shouldGenerateECCKeyPairs(int keySize) {
            KeyPair keyPair = asymmetricService.generateECKeyPair(keySize);
            
            assertNotNull(keyPair);
            assertNotNull(keyPair.getPublic());
            assertNotNull(keyPair.getPrivate());
            assertEquals("EC", keyPair.getPublic().getAlgorithm());
        }
    }
    
    @Nested
    @DisplayName("RSA Encryption/Decryption Tests")
    class RSAEncryptionTests {
        
        @Test
        @DisplayName("Encrypt and decrypt AES key with RSA")
        void shouldEncryptAndDecryptWithRSA() {
            KeyPair keyPair = asymmetricService.generateRSAKeyPair(2048);
            byte[] aesKey = new byte[32]; // 256-bit AES key
            new java.security.SecureRandom().nextBytes(aesKey);
            
            byte[] encrypted = asymmetricService.encryptWithPublicKey(
                aesKey, keyPair.getPublic());
            
            assertNotNull(encrypted);
            assertFalse(java.util.Arrays.equals(aesKey, encrypted));
            
            byte[] decrypted = asymmetricService.decryptWithPrivateKey(
                encrypted, keyPair.getPrivate());
            
            assertArrayEquals(aesKey, decrypted);
        }
        
        @Test
        @DisplayName("RSA encryption with wrong key should fail")
        void shouldFailWithWrongKey() {
            KeyPair keyPair1 = asymmetricService.generateRSAKeyPair(2048);
            KeyPair keyPair2 = asymmetricService.generateRSAKeyPair(2048);
            byte[] data = "Secret key material".getBytes(StandardCharsets.UTF_8);
            
            byte[] encrypted = asymmetricService.encryptWithPublicKey(
                data, keyPair1.getPublic());
            
            // Try to decrypt with wrong private key
            assertThrows(Exception.class, () ->
                asymmetricService.decryptWithPrivateKey(encrypted, keyPair2.getPrivate())
            );
        }
    }
    
    @Nested
    @DisplayName("ECDH Key Exchange Tests")
    class ECDHKeyExchangeTests {
        
        @Test
        @DisplayName("ECDH produces same shared secret for both parties")
        void shouldProduceSameSharedSecret() {
            // Alice generates her key pair
            KeyPair aliceKeyPair = asymmetricService.generateECKeyPair(256);
            
            // Bob generates his key pair
            KeyPair bobKeyPair = asymmetricService.generateECKeyPair(256);
            
            // Alice computes shared secret with Bob's public key
            byte[] aliceSharedSecret = asymmetricService.performECDH(
                aliceKeyPair.getPrivate(), bobKeyPair.getPublic());
            
            // Bob computes shared secret with Alice's public key
            byte[] bobSharedSecret = asymmetricService.performECDH(
                bobKeyPair.getPrivate(), aliceKeyPair.getPublic());
            
            // Both should have the same shared secret
            assertArrayEquals(aliceSharedSecret, bobSharedSecret);
        }
        
        @Test
        @DisplayName("Different key pairs produce different shared secrets")
        void shouldProduceDifferentSecretsWithDifferentKeys() {
            KeyPair alice = asymmetricService.generateECKeyPair(256);
            KeyPair bob = asymmetricService.generateECKeyPair(256);
            KeyPair eve = asymmetricService.generateECKeyPair(256);
            
            byte[] aliceBobSecret = asymmetricService.performECDH(
                alice.getPrivate(), bob.getPublic());
            
            byte[] aliceEveSecret = asymmetricService.performECDH(
                alice.getPrivate(), eve.getPublic());
            
            assertFalse(java.util.Arrays.equals(aliceBobSecret, aliceEveSecret));
        }
    }
    
    @Nested
    @DisplayName("Digital Signature Tests")
    class SignatureTests {
        
        @Test
        @DisplayName("Sign and verify message with RSA")
        void shouldSignAndVerifyWithRSA() {
            KeyPair keyPair = asymmetricService.generateRSAKeyPair(2048);
            byte[] message = "Message to sign".getBytes(StandardCharsets.UTF_8);
            
            byte[] signature = asymmetricService.sign(message, keyPair.getPrivate());
            
            assertNotNull(signature);
            assertTrue(asymmetricService.verify(message, signature, keyPair.getPublic()));
        }
        
        @Test
        @DisplayName("Sign and verify message with ECDSA")
        void shouldSignAndVerifyWithECDSA() {
            KeyPair keyPair = asymmetricService.generateECKeyPair(256);
            byte[] message = "ECDSA signed message".getBytes(StandardCharsets.UTF_8);
            
            byte[] signature = asymmetricService.signEC(message, keyPair.getPrivate());
            
            assertNotNull(signature);
            assertTrue(asymmetricService.verifyEC(message, signature, keyPair.getPublic()));
        }
        
        @Test
        @DisplayName("Tampered message fails signature verification")
        void shouldFailVerificationForTamperedMessage() {
            KeyPair keyPair = asymmetricService.generateRSAKeyPair(2048);
            byte[] originalMessage = "Original message".getBytes(StandardCharsets.UTF_8);
            byte[] tamperedMessage = "Tampered message".getBytes(StandardCharsets.UTF_8);
            
            byte[] signature = asymmetricService.sign(originalMessage, keyPair.getPrivate());
            
            assertFalse(asymmetricService.verify(tamperedMessage, signature, keyPair.getPublic()));
        }
    }
    
    @Nested
    @DisplayName("Key Encoding Tests")
    class KeyEncodingTests {
        
        @Test
        @DisplayName("Encode and decode RSA public key")
        void shouldEncodeAndDecodeRSAPublicKey() {
            KeyPair keyPair = asymmetricService.generateRSAKeyPair(2048);
            
            String encoded = asymmetricService.encodePublicKey(keyPair.getPublic());
            assertNotNull(encoded);
            
            java.security.PublicKey decoded = asymmetricService.decodePublicKey(
                encoded, "RSA");
            
            assertArrayEquals(keyPair.getPublic().getEncoded(), decoded.getEncoded());
        }
        
        @Test
        @DisplayName("Encode and decode EC public key")
        void shouldEncodeAndDecodeECPublicKey() {
            KeyPair keyPair = asymmetricService.generateECKeyPair(256);
            
            String encoded = asymmetricService.encodePublicKey(keyPair.getPublic());
            assertNotNull(encoded);
            
            java.security.PublicKey decoded = asymmetricService.decodePublicKey(
                encoded, "EC");
            
            assertArrayEquals(keyPair.getPublic().getEncoded(), decoded.getEncoded());
        }
        
        @Test
        @DisplayName("Encrypt and decrypt private key with password")
        void shouldEncryptAndDecryptPrivateKey() {
            KeyPair keyPair = asymmetricService.generateRSAKeyPair(2048);
            String password = "StrongPassword123!";
            
            String encryptedPrivateKey = asymmetricService.encryptPrivateKey(
                keyPair.getPrivate(), password);
            
            assertNotNull(encryptedPrivateKey);
            assertFalse(encryptedPrivateKey.isEmpty());
            
            java.security.PrivateKey decrypted = asymmetricService.decryptPrivateKey(
                encryptedPrivateKey, password, "RSA");
            
            assertArrayEquals(keyPair.getPrivate().getEncoded(), decrypted.getEncoded());
        }
        
        @Test
        @DisplayName("Wrong password fails private key decryption")
        void shouldFailWithWrongPassword() {
            KeyPair keyPair = asymmetricService.generateRSAKeyPair(2048);
            
            String encryptedPrivateKey = asymmetricService.encryptPrivateKey(
                keyPair.getPrivate(), "CorrectPassword");
            
            assertThrows(Exception.class, () ->
                asymmetricService.decryptPrivateKey(
                    encryptedPrivateKey, "WrongPassword", "RSA")
            );
        }
    }
}
