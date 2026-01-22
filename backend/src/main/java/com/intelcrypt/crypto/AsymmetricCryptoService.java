package com.intelcrypt.crypto;

import com.intelcrypt.config.CryptoConfigProperties;
import com.intelcrypt.exception.CryptoException;
import org.bouncycastle.jce.ECNamedCurveTable;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.jce.spec.ECNamedCurveParameterSpec;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.KeyAgreement;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.security.spec.ECGenParameterSpec;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

/**
 * Asymmetric Encryption Service for Hybrid Encryption.
 * 
 * CRYPTOGRAPHIC DECISIONS:
 * 
 * 1. RSA-OAEP: Uses OAEP padding with SHA-256 for RSA encryption.
 *    PKCS#1 v1.5 padding is NOT used due to padding oracle vulnerabilities.
 * 
 * 2. ECC/ECDH: Elliptic Curve Diffie-Hellman for key agreement.
 *    Uses NIST P-384 (secp384r1) for strong security.
 * 
 * 3. HYBRID ENCRYPTION: RSA/ECC encrypts AES keys, AES encrypts data.
 *    This combines the security of asymmetric crypto with the 
 *    performance of symmetric crypto.
 * 
 * 4. KEY SIZES:
 *    - RSA: 4096-bit (2048 minimum for legacy)
 *    - ECC: P-384 curve (equivalent to ~7680-bit RSA)
 */
@Component
public class AsymmetricCryptoService {
    
    private static final Logger log = LoggerFactory.getLogger(AsymmetricCryptoService.class);
    
    private CryptoConfigProperties config;
    private static final String RSA_ALGORITHM = "RSA";
    private static final String RSA_TRANSFORMATION = "RSA/ECB/OAEPWithSHA-256AndMGF1Padding";
    private static final String EC_ALGORITHM = "EC";
    private static final String ECDH_ALGORITHM = "ECDH";
    private static final SecureRandom secureRandom = new SecureRandom();
    
    /**
     * Default constructor for standalone use.
     */
    public AsymmetricCryptoService() {
        // Allow standalone usage without Spring
    }
    
    /**
     * Spring injection of config.
     */
    @Autowired(required = false)
    public void setConfig(CryptoConfigProperties config) {
        this.config = config;
    }
    
    /**
     * Generate RSA key pair.
     * 
     * @return KeyPair with public and private keys
     */
    public KeyPair generateRSAKeyPair() {
        int keySize = config != null ? config.getCrypto().getRsa().getKeySize() : 4096;
        return generateRSAKeyPair(keySize);
    }
    
    /**
     * Generate RSA key pair with specific size.
     */
    public KeyPair generateRSAKeyPair(int keySize) {
        try {
            if (keySize < 2048) {
                throw new CryptoException("RSA key size must be at least 2048 bits");
            }
            KeyPairGenerator keyGen = KeyPairGenerator.getInstance(RSA_ALGORITHM);
            keyGen.initialize(keySize, secureRandom);
            return keyGen.generateKeyPair();
        } catch (NoSuchAlgorithmException e) {
            throw new CryptoException("Failed to generate RSA key pair", e);
        }
    }
    
    /**
     * Generate ECC key pair for ECDH key exchange.
     * 
     * @return KeyPair with ECC public and private keys
     */
    public KeyPair generateECCKeyPair() {
        String curveName = config != null ? config.getCrypto().getEcc().getCurve() : "secp384r1";
        return generateECKeyPairWithCurve(curveName);
    }
    
    /**
     * Generate ECC key pair with specific key size.
     * @param keySize 256, 384, or 521 bits
     */
    public KeyPair generateECKeyPair(int keySize) {
        String curveName = switch (keySize) {
            case 256 -> "secp256r1";
            case 384 -> "secp384r1";
            case 521 -> "secp521r1";
            default -> throw new CryptoException("Unsupported ECC key size: " + keySize);
        };
        return generateECKeyPairWithCurve(curveName);
    }
    
    private KeyPair generateECKeyPairWithCurve(String curveName) {
        try {
            KeyPairGenerator keyGen = KeyPairGenerator.getInstance(EC_ALGORITHM);
            ECGenParameterSpec ecSpec = new ECGenParameterSpec(curveName);
            keyGen.initialize(ecSpec, secureRandom);
            return keyGen.generateKeyPair();
        } catch (Exception e) {
            throw new CryptoException("Failed to generate ECC key pair", e);
        }
    }
    
    /**
     * Encrypt data using RSA public key (returns raw bytes).
     */
    public byte[] encryptWithPublicKey(byte[] data, PublicKey publicKey) {
        try {
            Cipher cipher = Cipher.getInstance(RSA_TRANSFORMATION);
            cipher.init(Cipher.ENCRYPT_MODE, publicKey, secureRandom);
            return cipher.doFinal(data);
        } catch (Exception e) {
            throw new CryptoException("RSA encryption failed", e);
        }
    }
    
    /**
     * Decrypt data using RSA private key (from raw bytes).
     */
    public byte[] decryptWithPrivateKey(byte[] encryptedData, PrivateKey privateKey) {
        try {
            Cipher cipher = Cipher.getInstance(RSA_TRANSFORMATION);
            cipher.init(Cipher.DECRYPT_MODE, privateKey);
            return cipher.doFinal(encryptedData);
        } catch (Exception e) {
            throw new CryptoException("RSA decryption failed", e);
        }
    }
    
    /**
     * Encrypt data using RSA public key.
     * Used primarily for encrypting AES session keys.
     * 
     * @param data Data to encrypt (should be small, like an AES key)
     * @param publicKey RSA public key
     * @return Base64-encoded ciphertext
     */
    public String encryptWithRSA(byte[] data, PublicKey publicKey) {
        try {
            Cipher cipher = Cipher.getInstance(RSA_TRANSFORMATION);
            cipher.init(Cipher.ENCRYPT_MODE, publicKey, secureRandom);
            byte[] encrypted = cipher.doFinal(data);
            return Base64.getEncoder().encodeToString(encrypted);
        } catch (Exception e) {
            throw new CryptoException("RSA encryption failed", e);
        }
    }
    
    /**
     * Encrypt string data with RSA.
     */
    public String encryptWithRSA(String data, PublicKey publicKey) {
        return encryptWithRSA(data.getBytes(StandardCharsets.UTF_8), publicKey);
    }
    
    /**
     * Decrypt data using RSA private key.
     * 
     * @param encryptedData Base64-encoded ciphertext
     * @param privateKey RSA private key
     * @return Decrypted bytes
     */
    public byte[] decryptWithRSA(String encryptedData, PrivateKey privateKey) {
        try {
            Cipher cipher = Cipher.getInstance(RSA_TRANSFORMATION);
            cipher.init(Cipher.DECRYPT_MODE, privateKey);
            byte[] encrypted = Base64.getDecoder().decode(encryptedData);
            return cipher.doFinal(encrypted);
        } catch (Exception e) {
            throw new CryptoException("RSA decryption failed", e);
        }
    }
    
    /**
     * Perform ECDH key agreement to derive shared secret.
     * 
     * @param privateKey Our private key
     * @param peerPublicKey Peer's public key
     * @return Shared secret bytes (should be processed with KDF)
     */
    public byte[] performECDH(PrivateKey privateKey, PublicKey peerPublicKey) {
        try {
            KeyAgreement keyAgreement = KeyAgreement.getInstance(ECDH_ALGORITHM, BouncyCastleProvider.PROVIDER_NAME);
            keyAgreement.init(privateKey);
            keyAgreement.doPhase(peerPublicKey, true);
            return keyAgreement.generateSecret();
        } catch (Exception e) {
            throw new CryptoException("ECDH key agreement failed", e);
        }
    }
    
    /**
     * Derive AES key from ECDH shared secret using HKDF.
     * 
     * @param sharedSecret ECDH shared secret
     * @param info Context info for key derivation
     * @param keyLength Desired key length in bytes
     * @return AES key
     */
    public SecretKey deriveAESKeyFromECDH(byte[] sharedSecret, byte[] info, int keyLength) {
        try {
            // Use HKDF-SHA256 for key derivation
            MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
            
            // Extract phase
            byte[] prk = sha256.digest(sharedSecret);
            
            // Expand phase (simplified HKDF-Expand)
            javax.crypto.Mac hmac = javax.crypto.Mac.getInstance("HmacSHA256");
            hmac.init(new SecretKeySpec(prk, "HmacSHA256"));
            hmac.update(info);
            hmac.update((byte) 1);
            byte[] okm = hmac.doFinal();
            
            // Truncate to desired length
            byte[] keyBytes = new byte[keyLength];
            System.arraycopy(okm, 0, keyBytes, 0, Math.min(okm.length, keyLength));
            
            return new SecretKeySpec(keyBytes, "AES");
        } catch (Exception e) {
            throw new CryptoException("Key derivation failed", e);
        }
    }
    
    /**
     * Encode public key to PEM format.
     */
    public String encodePublicKey(PublicKey publicKey) {
        String base64 = Base64.getEncoder().encodeToString(publicKey.getEncoded());
        return "-----BEGIN PUBLIC KEY-----\n" + 
               formatBase64(base64) + 
               "\n-----END PUBLIC KEY-----";
    }
    
    /**
     * Encode private key to PEM format.
     * WARNING: Private keys should be encrypted before storage!
     */
    public String encodePrivateKey(PrivateKey privateKey) {
        String base64 = Base64.getEncoder().encodeToString(privateKey.getEncoded());
        return "-----BEGIN PRIVATE KEY-----\n" + 
               formatBase64(base64) + 
               "\n-----END PRIVATE KEY-----";
    }
    
    /**
     * Decode public key from PEM or Base64.
     */
    public PublicKey decodePublicKey(String encoded, String algorithm) {
        try {
            String base64 = encoded
                .replace("-----BEGIN PUBLIC KEY-----", "")
                .replace("-----END PUBLIC KEY-----", "")
                .replaceAll("\\s", "");
            
            byte[] keyBytes = Base64.getDecoder().decode(base64);
            X509EncodedKeySpec spec = new X509EncodedKeySpec(keyBytes);
            
            KeyFactory keyFactory = KeyFactory.getInstance(algorithm);
            return keyFactory.generatePublic(spec);
        } catch (Exception e) {
            throw new CryptoException("Failed to decode public key", e);
        }
    }
    
    /**
     * Decode private key from PEM or Base64.
     */
    public PrivateKey decodePrivateKey(String encoded, String algorithm) {
        try {
            String base64 = encoded
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s", "");
            
            byte[] keyBytes = Base64.getDecoder().decode(base64);
            PKCS8EncodedKeySpec spec = new PKCS8EncodedKeySpec(keyBytes);
            
            KeyFactory keyFactory = KeyFactory.getInstance(algorithm);
            return keyFactory.generatePrivate(spec);
        } catch (Exception e) {
            throw new CryptoException("Failed to decode private key", e);
        }
    }
    
    /**
     * Encrypt private key with password-derived key.
     * Used for secure storage of user private keys.
     */
    public String encryptPrivateKey(PrivateKey privateKey, String password, byte[] salt) {
        try {
            // Derive encryption key from password
            SecretKey encryptionKey = deriveKeyFromPassword(password, salt);
            
            // Encrypt private key with AES-GCM
            byte[] iv = new byte[12];
            secureRandom.nextBytes(iv);
            
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            GCMParameterSpec gcmSpec = new GCMParameterSpec(128, iv);
            cipher.init(Cipher.ENCRYPT_MODE, encryptionKey, gcmSpec);
            
            byte[] encrypted = cipher.doFinal(privateKey.getEncoded());
            
            // Combine IV and ciphertext
            byte[] combined = new byte[iv.length + encrypted.length];
            System.arraycopy(iv, 0, combined, 0, iv.length);
            System.arraycopy(encrypted, 0, combined, iv.length, encrypted.length);
            
            return Base64.getEncoder().encodeToString(combined);
        } catch (Exception e) {
            throw new CryptoException("Failed to encrypt private key", e);
        }
    }
    
    /**
     * Decrypt private key with password.
     */
    public PrivateKey decryptPrivateKey(String encryptedKey, String password, 
                                         byte[] salt, String algorithm) {
        try {
            SecretKey decryptionKey = deriveKeyFromPassword(password, salt);
            
            byte[] combined = Base64.getDecoder().decode(encryptedKey);
            byte[] iv = new byte[12];
            byte[] ciphertext = new byte[combined.length - 12];
            
            System.arraycopy(combined, 0, iv, 0, 12);
            System.arraycopy(combined, 12, ciphertext, 0, ciphertext.length);
            
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            GCMParameterSpec gcmSpec = new GCMParameterSpec(128, iv);
            cipher.init(Cipher.DECRYPT_MODE, decryptionKey, gcmSpec);
            
            byte[] decrypted = cipher.doFinal(ciphertext);
            
            PKCS8EncodedKeySpec spec = new PKCS8EncodedKeySpec(decrypted);
            KeyFactory keyFactory = KeyFactory.getInstance(algorithm);
            return keyFactory.generatePrivate(spec);
        } catch (Exception e) {
            throw new CryptoException("Failed to decrypt private key", e);
        }
    }
    
    /**
     * Derive key from password using PBKDF2.
     */
    private SecretKey deriveKeyFromPassword(String password, byte[] salt) throws Exception {
        javax.crypto.SecretKeyFactory factory = 
            javax.crypto.SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        javax.crypto.spec.PBEKeySpec spec = 
            new javax.crypto.spec.PBEKeySpec(password.toCharArray(), salt, 310000, 256);
        byte[] keyBytes = factory.generateSecret(spec).getEncoded();
        return new SecretKeySpec(keyBytes, "AES");
    }
    
    /**
     * Generate cryptographic salt.
     */
    public byte[] generateSalt() {
        byte[] salt = new byte[32];
        secureRandom.nextBytes(salt);
        return salt;
    }
    
    /**
     * Format Base64 for PEM (64 chars per line).
     */
    private String formatBase64(String base64) {
        StringBuilder formatted = new StringBuilder();
        for (int i = 0; i < base64.length(); i += 64) {
            formatted.append(base64, i, Math.min(i + 64, base64.length()));
            if (i + 64 < base64.length()) {
                formatted.append("\n");
            }
        }
        return formatted.toString();
    }
    
    /**
     * Sign data with RSA private key.
     */
    public byte[] sign(byte[] data, PrivateKey privateKey) {
        try {
            Signature signature = Signature.getInstance("SHA256withRSA");
            signature.initSign(privateKey);
            signature.update(data);
            return signature.sign();
        } catch (Exception e) {
            throw new CryptoException("RSA signing failed", e);
        }
    }
    
    /**
     * Verify RSA signature.
     */
    public boolean verify(byte[] data, byte[] signatureBytes, PublicKey publicKey) {
        try {
            Signature signature = Signature.getInstance("SHA256withRSA");
            signature.initVerify(publicKey);
            signature.update(data);
            return signature.verify(signatureBytes);
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Sign data with EC private key (ECDSA).
     */
    public byte[] signEC(byte[] data, PrivateKey privateKey) {
        try {
            Signature signature = Signature.getInstance("SHA256withECDSA");
            signature.initSign(privateKey);
            signature.update(data);
            return signature.sign();
        } catch (Exception e) {
            throw new CryptoException("ECDSA signing failed", e);
        }
    }
    
    /**
     * Verify ECDSA signature.
     */
    public boolean verifyEC(byte[] data, byte[] signatureBytes, PublicKey publicKey) {
        try {
            Signature signature = Signature.getInstance("SHA256withECDSA");
            signature.initVerify(publicKey);
            signature.update(data);
            return signature.verify(signatureBytes);
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Encrypt private key with password (password-based encryption).
     */
    public String encryptPrivateKey(PrivateKey privateKey, String password) {
        return encryptPrivateKey(privateKey, password, generateSalt());
    }
    
    /**
     * Decrypt private key with password.
     */
    public PrivateKey decryptPrivateKey(String encryptedKey, String password, String algorithm) {
        // Extract salt from the encrypted data (first 32 bytes)
        byte[] combined = Base64.getDecoder().decode(encryptedKey);
        byte[] salt = new byte[32];
        byte[] encryptedWithoutSalt = new byte[combined.length - 32];
        System.arraycopy(combined, 0, salt, 0, 32);
        System.arraycopy(combined, 32, encryptedWithoutSalt, 0, encryptedWithoutSalt.length);
        
        String encryptedOnlyCipher = Base64.getEncoder().encodeToString(encryptedWithoutSalt);
        return decryptPrivateKey(encryptedOnlyCipher, password, salt, algorithm);
    }
}
